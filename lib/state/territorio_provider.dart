import 'package:flutter/foundation.dart';

import '../logic/bairros.dart';
import '../logic/indicadores.dart';
import '../logic/motor_alertas.dart';
import '../models/alerta.dart';
import '../models/carga.dart';
import '../models/clima.dart';
import '../models/manancial.dart';
import '../models/ocorrencia.dart';
import '../models/satelite.dart';
import '../services/armazenamento_local.dart';
import '../services/clima_servico.dart';
import '../services/mananciais_servico.dart';
import '../services/ocorrencias_servico.dart';
import '../services/satelite_servico.dart';
import 'configuracoes_provider.dart';

/// Estado GLOBAL dos dados do território: carrega as três fontes, controla carregamento e erro,
/// guarda as ocorrências registradas no aparelho e as avaliações humanas, e calcula os alertas.
class TerritorioProvider extends ChangeNotifier {
  TerritorioProvider({
    required this.configuracoes,
    required ArmazenamentoLocal local,
    required ClimaServico clima,
    required MananciaisServico mananciais,
    required OcorrenciasServico ocorrencias,
    SateliteServico? satelite,
  })  : _local = local,
        _sateliteServico = satelite ?? SateliteServico(),
        _climaServico = clima,
        _mananciaisServico = mananciais,
        _ocorrenciasServico = ocorrencias {
    _carregarDadosLocais();
    configuracoes.addListener(_aoMudarConfiguracoes);
  }

  final ConfiguracoesProvider configuracoes;
  final ArmazenamentoLocal _local;
  final ClimaServico _climaServico;
  final MananciaisServico _mananciaisServico;
  final OcorrenciasServico _ocorrenciasServico;
  final SateliteServico _sateliteServico;

  // Mananciais
  StatusCarga statusMananciais = StatusCarga.carregando;
  Carga<List<SistemaManancial>>? mananciais;
  String? erroMananciais;

  // Clima
  StatusCarga statusClima = StatusCarga.carregando;
  Carga<List<DiaClima>>? clima;
  String? erroClima;

  // Ocorrências
  StatusCarga statusOcorrencias = StatusCarga.carregando;
  Carga<List<Ocorrencia>>? ocorrenciasRemotas;
  String? erroOcorrencias;

  // Satélite (CNN pré-calculada) e equipes acionadas por gestores
  List<LeituraSatelite> satelite = const [];
  Set<String> _equipesAcionadas = {};

  List<Ocorrencia> _locais = [];
  Map<String, AvaliacaoHumana> _avaliacoes = {};

  /// Ocorrências de exemplo somadas às registradas neste aparelho.
  List<Ocorrencia> get ocorrencias {
    final lista = [..._locais, ...?ocorrenciasRemotas?.dados];
    lista.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
    return lista;
  }

  bool get carregandoAlgo =>
      statusMananciais == StatusCarga.carregando ||
      statusClima == StatusCarga.carregando ||
      statusOcorrencias == StatusCarga.carregando;

  List<Alerta>? _alertasCache;

  /// Alertas calculados com os limiares atuais (recalculados quando dados ou limiares mudam).
  List<Alerta> get alertas {
    return _alertasCache ??= gerarAlertas(
      sistemas: mananciais?.dados ?? const [],
      clima: clima?.dados ?? const [],
      ocorrencias: ocorrencias,
      limiares: configuracoes.limiares,
      agora: DateTime.now(),
      mananciaisSinteticos: mananciais?.origem == OrigemDados.simulado,
      satelite: satelite,
    );
  }

  Alerta? alertaPorId(String id) {
    for (final a in alertas) {
      if (a.id == id) return a;
    }
    return null;
  }

  AvaliacaoHumana? avaliacaoDe(String alertaId) => _avaliacoes[alertaId];

  bool equipeAcionada(String ocorrenciaId) => _equipesAcionadas.contains(ocorrenciaId);

  /// Decisão humana do gestor: aciona (ou desfaz) a equipe de campo para uma ocorrência.
  Future<void> alternarEquipe(String ocorrenciaId) async {
    if (!_equipesAcionadas.remove(ocorrenciaId)) _equipesAcionadas.add(ocorrenciaId);
    await _local.salvarJson(Chaves.equipesAcionadas, _equipesAcionadas.toList());
    notifyListeners();
  }

  /// Indicador de benefício social: pessoas afetadas em bairros cujos alertas
  /// já foram avaliados por um gestor e encaminhados para ação.
  int get pessoasComAlertaEncaminhado => alertas
      .where((a) => _avaliacoes[a.id]?.decisao == DecisaoHumana.encaminhado)
      .fold(0, (s, a) => s + a.pessoasAlcancadas);

  /// Pessoas afetadas com relatos que geraram algum alerta (avisadas antecipadamente aos gestores).
  int get pessoasEmAlertasAtivos => alertas.fold(0, (s, a) => s + a.pessoasAlcancadas);

  int get alertasAvaliados => alertas.where((a) => _avaliacoes.containsKey(a.id)).length;

  List<IndicadoresManancial> get indicadoresMananciais =>
      (mananciais?.dados ?? const <SistemaManancial>[])
          .where((s) => s.serie.length >= 30)
          .map((s) => IndicadoresManancial.calcular(s, configuracoes.limiares))
          .toList();

  IndicadoresClima? get indicadoresClima {
    final dias = clima?.dados;
    return dias == null || dias.isEmpty ? null : IndicadoresClima.calcular(dias);
  }

  IndicadoresOcorrencias get indicadoresOcorrencias => IndicadoresOcorrencias.calcular(ocorrencias, DateTime.now());

  void _aoMudarConfiguracoes() {
    _alertasCache = null;
    notifyListeners();
  }

  void _atualizar() {
    _alertasCache = null;
    notifyListeners();
  }

  void _carregarDadosLocais() {
    final locais = _local.json(Chaves.ocorrenciasLocais);
    if (locais is List) {
      _locais = locais.cast<Map<String, dynamic>>().map(Ocorrencia.fromJson).toList();
    }
    final equipes = _local.json(Chaves.equipesAcionadas);
    if (equipes is List) _equipesAcionadas = equipes.map((e) => e.toString()).toSet();
    final avaliacoes = _local.json(Chaves.avaliacoes);
    if (avaliacoes is List) {
      _avaliacoes = {
        for (final a in avaliacoes.cast<Map<String, dynamic>>().map(AvaliacaoHumana.fromJson)) a.alertaId: a,
      };
    }
  }

  Future<void> carregarTudo() async {
    await Future.wait([carregarMananciais(), carregarClima(), carregarOcorrencias(), carregarSatelite()]);
  }

  Future<void> carregarSatelite() async {
    try {
      satelite = await _sateliteServico.buscar();
    } catch (_) {
      satelite = const []; // sem leitura de satélite o app segue funcionando
    }
    _atualizar();
  }

  Future<void> carregarMananciais() async {
    statusMananciais = StatusCarga.carregando;
    notifyListeners();
    try {
      mananciais = await _mananciaisServico.buscar();
      statusMananciais = StatusCarga.pronto;
      erroMananciais = null;
    } catch (e) {
      statusMananciais = StatusCarga.erro;
      erroMananciais = 'Não foi possível carregar os dados dos mananciais.';
    }
    _atualizar();
  }

  Future<void> carregarClima() async {
    statusClima = StatusCarga.carregando;
    notifyListeners();
    try {
      clima = await _climaServico.buscar();
      statusClima = StatusCarga.pronto;
      erroClima = null;
    } catch (e) {
      statusClima = StatusCarga.erro;
      erroClima = 'Sem conexão e sem dados de clima salvos. Conecte-se à internet e tente de novo.';
    }
    _atualizar();
  }

  Future<void> carregarOcorrencias() async {
    statusOcorrencias = StatusCarga.carregando;
    notifyListeners();
    try {
      ocorrenciasRemotas = await _ocorrenciasServico.buscar();
      statusOcorrencias = StatusCarga.pronto;
      erroOcorrencias = null;
    } catch (e) {
      statusOcorrencias = StatusCarga.erro;
      erroOcorrencias = 'Não foi possível carregar as ocorrências.';
    }
    _atualizar();
  }

  /// Registra a ocorrência neste aparelho (protótipo sem servidor): ela entra nos painéis, nos alertas e na fila das equipes.
  Future<void> registrarOcorrencia({
    required String bairro,
    required String tipo,
    required double horasSemAgua,
    required int pessoasAfetadas,
    required String descricao,
  }) async {
    final coordenada = bairrosAquaRede[bairro];
    final nova = Ocorrencia(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      bairro: bairro,
      tipo: tipo,
      horasSemAgua: horasSemAgua,
      pessoasAfetadas: pessoasAfetadas,
      descricao: descricao,
      prioridade: calcularPrioridade(tipo: tipo, horasSemAgua: horasSemAgua, pessoasAfetadas: pessoasAfetadas),
      lat: coordenada?[0],
      lng: coordenada?[1],
      criadoEm: DateTime.now(),
    );

    _locais = [nova, ..._locais];
    await _salvarLocais();
    _atualizar();
  }

  Future<void> _salvarLocais() =>
      _local.salvarJson(Chaves.ocorrenciasLocais, _locais.map((o) => o.toJson()).toList());

  /// Registra a decisão humana sobre um alerta (somente perfil gestor).
  Future<void> avaliarAlerta(String alertaId, DecisaoHumana decisao, String justificativa) async {
    _avaliacoes[alertaId] = AvaliacaoHumana(
      alertaId: alertaId,
      decisao: decisao,
      justificativa: justificativa.trim(),
      data: DateTime.now(),
    );
    await _local.salvarJson(Chaves.avaliacoes, _avaliacoes.values.map((a) => a.toJson()).toList());
    _atualizar();
  }

  /// Usado ao revogar o consentimento: limpa os dados em memória.
  void limparDadosLocais() {
    _locais = [];
    _avaliacoes = {};
    _equipesAcionadas = {};
    _atualizar();
  }

  @override
  void dispose() {
    configuracoes.removeListener(_aoMudarConfiguracoes);
    super.dispose();
  }
}
