import 'package:aquarede/logic/equipes.dart';
import 'package:aquarede/logic/motor_alertas.dart';
import 'package:aquarede/models/limiares.dart';
import 'package:aquarede/models/ocorrencia.dart';
import 'package:aquarede/models/satelite.dart';
import 'package:flutter_test/flutter_test.dart';

final agora = DateTime(2026, 11, 18, 12);

Ocorrencia oco(String id, String bairro, String prioridade, {String tipo = 'Falta de água', int horasAtras = 5}) => Ocorrencia(
      id: id,
      bairro: bairro,
      tipo: tipo,
      horasSemAgua: 10,
      pessoasAfetadas: 5,
      descricao: '',
      prioridade: prioridade,
      lat: 0,
      lng: 0,
      criadoEm: agora.subtract(Duration(hours: horasAtras)),
    );

const urbano = LeituraSatelite(bairro: 'Brasilândia', classe: 'urbano', confianca: 0.81);

void main() {
  group('Fila das equipes', () {
    test('ordena por prioridade e, dentro dela, por confiança', () {
      final fila = montarFilaEquipes(
        ocorrencias: [
          oco('a', 'Capão Redondo', 'Baixa'),
          oco('b', 'Brasilândia', 'Média'),
          oco('c', 'Brasilândia', 'Alta'),
          oco('d', 'Capão Redondo', 'Alta'),
        ],
        satelite: const [urbano],
        agora: agora,
      );
      expect(fila.map((i) => i.ocorrencia.id).toList(), ['c', 'd', 'b', 'a']);
    });

    test('equipes já acionadas vão para o fim da fila', () {
      final fila = montarFilaEquipes(
        ocorrencias: [oco('a', 'Brasilândia', 'Alta'), oco('b', 'Brasilândia', 'Baixa')],
        satelite: const [],
        agora: agora,
        acionadas: {'a'},
      );
      expect(fila.first.ocorrencia.id, 'b');
    });

    test('leitura de satélite aumenta a confiança em 0,05', () {
      expect(confiancaIa(relatosNoBairro: 2, temSatelite: true) - confiancaIa(relatosNoBairro: 2, temSatelite: false), closeTo(0.05, 1e-9));
      expect(confiancaIa(relatosNoBairro: 20, temSatelite: true), 0.9);
      expect(confiancaIa(relatosNoBairro: 0, temSatelite: false), 0.4);
    });
  });

  group('Satélite nos alertas de ocorrências', () {
    final tres = [oco('1', 'Brasilândia', 'Média'), oco('2', 'Brasilândia', 'Média'), oco('3', 'Brasilândia', 'Alta')];
    List gerar({List<LeituraSatelite> sat = const []}) => gerarAlertas(
          sistemas: const [],
          clima: const [],
          ocorrencias: tres,
          limiares: const Limiares(),
          agora: agora,
          satelite: sat,
        );

    test('sem leitura, o alerta não cita o satélite', () {
      final a = gerar().single;
      expect(a.evidencias.any((e) => e.contains('Satélite')), isFalse);
    });

    test('com leitura, o satélite entra como evidência, com limitação e mais confiança', () {
      final sem = gerar().single;
      final com = gerar(sat: const [urbano]).single;
      expect(com.evidencias.any((e) => e.contains('Satélite (CNN)')), isTrue);
      expect(com.limitacoes.any((e) => e.contains('não mede volume de água')), isTrue);
      expect(com.confianca, greaterThan(sem.confianca));
    });
  });
}
