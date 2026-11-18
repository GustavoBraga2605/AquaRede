import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/satelite.dart';

/// Lê o resultado da CNN de satélite exportado do Colab (assets/dados/satelite_bairros.json).
/// A CNN NÃO roda dentro do app: o app usa as classes já calculadas para os bairros-piloto.
class SateliteServico {
  Future<List<LeituraSatelite>> buscar() async {
    final bruto = jsonDecode(await rootBundle.loadString('assets/dados/satelite_bairros.json')) as Map<String, dynamic>;
    final origem = (bruto['origem'] ?? 'Resultado pré-calculado da CNN (Colab)').toString();
    return (bruto['bairros'] as List)
        .map((e) => LeituraSatelite.fromJson(e as Map<String, dynamic>, origem: origem))
        .toList();
  }
}
