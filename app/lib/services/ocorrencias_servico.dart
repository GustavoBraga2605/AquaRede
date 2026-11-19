import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/carga.dart';
import '../models/ocorrencia.dart';

/// Fonte de ocorrências do protótipo, 100% local (sem servidor): lê as ocorrências SINTÉTICAS de exemplo
/// embutidas no app. As ocorrências registradas pelo usuário ficam salvas no aparelho (TerritorioProvider).
class OcorrenciasServico {
  Future<Carga<List<Ocorrencia>>> buscar() async {
    await Future<void>.delayed(const Duration(milliseconds: 300)); // simula a latência de uma fonte de dados
    return Carga(dados: await _exemplos(), origem: OrigemDados.exemplo, atualizadoEm: DateTime.now());
  }

  Future<List<Ocorrencia>> _exemplos() async {
    final bruto = jsonDecode(await rootBundle.loadString('assets/dados/ocorrencias_exemplo.json')) as Map<String, dynamic>;
    final agora = DateTime.now();
    return (bruto['ocorrencias'] as List).cast<Map<String, dynamic>>().map((json) {
      final dias = (json['diasAtras'] as num).toInt();
      return Ocorrencia.fromJson({
        ...json,
        'criadoEm': agora.subtract(Duration(days: dias, hours: dias * 3 % 11)).toUtc().toIso8601String(),
      });
    }).toList();
  }
}
