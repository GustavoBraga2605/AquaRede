/// Leitura da CNN de imagens de satélite para um bairro (resultado pré-calculado no Colab).
class LeituraSatelite {
  const LeituraSatelite({
    required this.bairro,
    required this.classe,
    required this.confianca,
    this.probabilidades = const {},
    this.origem = '',
  });

  final String bairro;

  /// agua, urbano, vegetacao_densa ou campo_aberto (mesmas classes do notebook).
  final String classe;

  /// Confiança de 0 a 1.
  final double confianca;
  final Map<String, double> probabilidades;
  final String origem;

  factory LeituraSatelite.fromJson(Map<String, dynamic> json, {String origem = ''}) {
    final prob = json['probabilidades'];
    return LeituraSatelite(
      bairro: (json['bairro'] ?? '').toString(),
      classe: (json['classe'] ?? '').toString(),
      confianca: ((json['confianca'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0).toDouble(),
      probabilidades: prob is Map ? {for (final e in prob.entries) e.key.toString(): (e.value as num).toDouble()} : const {},
      origem: origem,
    );
  }

  String get classeRotulo {
    switch (classe) {
      case 'agua':
        return "Corpo d'água";
      case 'urbano':
        return 'Área urbana densa';
      case 'vegetacao_densa':
        return 'Vegetação densa';
      case 'campo_aberto':
        return 'Campo aberto';
      default:
        return classe;
    }
  }
}

/// Procura a leitura do bairro, ignorando maiúsculas e espaços nas pontas.
LeituraSatelite? leituraDoBairro(List<LeituraSatelite> leituras, String bairro) {
  final alvo = bairro.trim().toLowerCase();
  for (final l in leituras) {
    if (l.bairro.trim().toLowerCase() == alvo) return l;
  }
  return null;
}
