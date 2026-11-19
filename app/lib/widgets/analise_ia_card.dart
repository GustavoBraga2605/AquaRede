import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/formatadores.dart';
import '../logic/bairros.dart';
import '../logic/equipes.dart';
import '../models/satelite.dart';
import '../state/territorio_provider.dart';
import 'componentes.dart';

/// Painel "Análise da IA" mostrado no formulário: satélite (CNN), clima, confiança e prioridade sugerida.
/// A equipe só é acionada por um gestor, na aba Equipes.
class AnaliseIaCard extends StatelessWidget {
  const AnaliseIaCard({super.key, required this.bairro, required this.tipo, required this.horasSemAgua, required this.pessoas});
  final String? bairro;
  final String? tipo;
  final double? horasSemAgua;
  final int? pessoas;

  @override
  Widget build(BuildContext context) {
    if (bairro == null) return const SizedBox.shrink();
    final t = context.watch<TerritorioProvider>();
    final tema = Theme.of(context);
    final sat = leituraDoBairro(t.satelite, bairro!);
    final clima = t.indicadoresClima;
    final limite = DateTime.now().subtract(const Duration(days: 7));
    // +1: o relato que está sendo registrado agora
    final relatos = t.ocorrencias.where((o) => o.bairro == bairro && o.criadoEm.isAfter(limite)).length + 1;
    final confianca = confiancaIa(relatosNoBairro: relatos, temSatelite: sat != null);
    final prioridade = (tipo != null && horasSemAgua != null && pessoas != null)
        ? calcularPrioridade(tipo: tipo!, horasSemAgua: horasSemAgua!, pessoasAfetadas: pessoas!)
        : null;

    return Card(
      color: tema.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(Espaco.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.psychology_rounded),
            const SizedBox(width: Espaco.sm),
            Text('Análise da IA', style: tema.textTheme.titleMedium),
          ]),
          const SizedBox(height: Espaco.sm),
          _Linha(
            icone: Icons.satellite_alt_rounded,
            texto: sat == null
                ? 'Satélite (CNN): sem leitura para este bairro.'
                : 'Satélite (CNN): ${sat.classeRotulo}, confiança de ${formatarNumero(sat.confianca * 100)}%.',
          ),
          _Linha(
            icone: Icons.wb_sunny_rounded,
            texto: clima == null
                ? 'Clima: sem dados no momento.'
                : 'Clima: ${clima.diasSemChuva} dia(s) sem chuva'
                    '${clima.tMaxPrevista3d == null ? '' : ' · máxima prevista de ${formatarNumero(clima.tMaxPrevista3d!, casas: 1)} °C'}.',
          ),
          _Linha(icone: Icons.groups_rounded, texto: '$relatos relato(s) no bairro em 7 dias, contando este.'),
          if (prioridade != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Espaco.xs),
              child: Row(children: [
                const Text('Prioridade sugerida: '),
                SeloNivel(rotulo: prioridade, cor: corDaPrioridade(context, prioridade)),
              ]),
            ),
          const SizedBox(height: Espaco.sm),
          BarraConfianca(valor: confianca, rotulo: 'da IA'),
          const SizedBox(height: Espaco.sm),
          Text(
            'A IA organiza as evidências, mas a equipe só é acionada por um gestor (aba Equipes). '
            '${sat == null ? '' : 'Satélite: ${sat.origem}. '}A CNN classifica a cobertura do solo, não mede volume de água.',
            style: tema.textTheme.bodySmall,
          ),
        ]),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.icone, required this.texto});
  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icone, size: 18),
          const SizedBox(width: Espaco.sm),
          Expanded(child: Text(texto)),
        ]),
      );
}
