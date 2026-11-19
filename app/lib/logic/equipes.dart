import '../models/ocorrencia.dart';
import '../models/satelite.dart';

/// Ocorrência na fila das equipes de campo, com a confiança da IA.
class ItemEquipe {
  const ItemEquipe({required this.ocorrencia, required this.confianca, required this.relatosNoBairro, this.satelite});
  final Ocorrencia ocorrencia;
  final double confianca; // 0 a 1
  final int relatosNoBairro; // últimos 7 dias
  final LeituraSatelite? satelite;
}

const _ordemPrioridade = {'Alta': 0, 'Média': 1, 'Baixa': 2};

/// Confiança da IA: 0,4 + 0,1 por relato no bairro (7 dias), mais 0,05 se há leitura de satélite.
/// Fica entre 0,4 e 0,9. É a mesma ideia dos alertas de ocorrências.
double confiancaIa({required int relatosNoBairro, required bool temSatelite}) =>
    (0.4 + 0.1 * relatosNoBairro + (temSatelite ? 0.05 : 0)).clamp(0.4, 0.9).toDouble();

/// Monta a fila: equipes ainda não acionadas primeiro; dentro de cada grupo, por prioridade
/// (alta, média, baixa) e depois por confiança (maior primeiro) e data (mais recente primeiro).
List<ItemEquipe> montarFilaEquipes({
  required List<Ocorrencia> ocorrencias,
  required List<LeituraSatelite> satelite,
  required DateTime agora,
  Set<String> acionadas = const {},
}) {
  final limite = agora.subtract(const Duration(days: 7));
  final itens = [
    for (final o in ocorrencias)
      () {
        final relatos = ocorrencias.where((x) => x.bairro == o.bairro && x.criadoEm.isAfter(limite)).length;
        final sat = leituraDoBairro(satelite, o.bairro);
        return ItemEquipe(
          ocorrencia: o,
          confianca: confiancaIa(relatosNoBairro: relatos, temSatelite: sat != null),
          relatosNoBairro: relatos,
          satelite: sat,
        );
      }(),
  ];
  int ordem(ItemEquipe i) => _ordemPrioridade[i.ocorrencia.prioridade] ?? 3;
  itens.sort((a, b) {
    final porAcionada = (acionadas.contains(a.ocorrencia.id) ? 1 : 0).compareTo(acionadas.contains(b.ocorrencia.id) ? 1 : 0);
    if (porAcionada != 0) return porAcionada;
    final porPrioridade = ordem(a).compareTo(ordem(b));
    if (porPrioridade != 0) return porPrioridade;
    final porConfianca = b.confianca.compareTo(a.confianca);
    return porConfianca != 0 ? porConfianca : b.ocorrencia.criadoEm.compareTo(a.ocorrencia.criadoEm);
  });
  return itens;
}
