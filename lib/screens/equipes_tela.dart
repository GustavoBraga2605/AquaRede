import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../logic/equipes.dart';
import '../models/carga.dart';
import '../state/configuracoes_provider.dart';
import '../state/territorio_provider.dart';
import '../widgets/componentes.dart';
import '../widgets/estados.dart';

/// Fila das equipes de campo: ocorrências por prioridade (alta, média, baixa) e confiança da IA.
/// Quem aciona a equipe é sempre um gestor (decisão humana).
class EquipesTela extends StatelessWidget {
  const EquipesTela({super.key});

  String _quando(DateTime d) {
    final h = DateTime.now().difference(d).inHours;
    if (h < 1) return 'agora há pouco';
    if (h < 48) return 'há ${h}h';
    return 'há ${h ~/ 24} dias';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TerritorioProvider>();
    final gestor = context.watch<ConfiguracoesProvider>().ehGestor;
    final tema = Theme.of(context);

    if (t.statusOcorrencias == StatusCarga.carregando && t.ocorrencias.isEmpty) {
      return const Center(child: Carregando(mensagem: 'Carregando ocorrências...'));
    }
    if (t.statusOcorrencias == StatusCarga.erro && t.ocorrencias.isEmpty) {
      return Center(child: ErroView(mensagem: t.erroOcorrencias ?? 'Erro.', aoTentarDeNovo: t.carregarOcorrencias));
    }
    final fila = montarFilaEquipes(
      ocorrencias: t.ocorrencias,
      satelite: t.satelite,
      agora: DateTime.now(),
      acionadas: {for (final o in t.ocorrencias) if (t.equipeAcionada(o.id)) o.id},
    );
    if (fila.isEmpty) return const Center(child: VazioView(mensagem: 'Nenhuma ocorrência na fila das equipes.'));

    int conta(String p) => fila.where((i) => i.ocorrencia.prioridade == p && !t.equipeAcionada(i.ocorrencia.id)).length;
    final acionadas = fila.where((i) => t.equipeAcionada(i.ocorrencia.id)).length;

    return RefreshIndicator(
      onRefresh: t.carregarTudo,
      child: ListView(
        padding: const EdgeInsets.all(Espaco.md),
        children: [
          const AvisoDecisaoHumana(compacto: true),
          const SizedBox(height: Espaco.md),
          Wrap(spacing: Espaco.sm, runSpacing: Espaco.sm, children: [
            SeloNivel(rotulo: 'Alta: ${conta('Alta')}', cor: corDaPrioridade(context, 'Alta')),
            SeloNivel(rotulo: 'Média: ${conta('Média')}', cor: corDaPrioridade(context, 'Média')),
            SeloNivel(rotulo: 'Baixa: ${conta('Baixa')}', cor: corDaPrioridade(context, 'Baixa')),
            SeloNivel(rotulo: 'Equipes acionadas: $acionadas', cor: tema.colorScheme.primary, icone: Icons.engineering_rounded),
          ]),
          if (!gestor)
            Padding(
              padding: const EdgeInsets.only(top: Espaco.sm),
              child: Text('Para acionar equipes, mude o perfil para Gestor em Ajustes.', style: tema.textTheme.bodySmall),
            ),
          const SizedBox(height: Espaco.sm),
          for (final item in fila) _CartaoEquipe(item: item, gestor: gestor, quando: _quando(item.ocorrencia.criadoEm)),
          const SizedBox(height: Espaco.xl),
        ],
      ),
    );
  }
}

class _CartaoEquipe extends StatelessWidget {
  const _CartaoEquipe({required this.item, required this.gestor, required this.quando});
  final ItemEquipe item;
  final bool gestor;
  final String quando;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TerritorioProvider>();
    final tema = Theme.of(context);
    final o = item.ocorrencia;
    final acionada = t.equipeAcionada(o.id);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Espaco.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SeloNivel(rotulo: o.prioridade, cor: corDaPrioridade(context, o.prioridade)),
            const SizedBox(width: Espaco.sm),
            Expanded(child: Text('${o.bairro} · ${o.tipo}', style: tema.textTheme.titleMedium)),
          ]),
          const SizedBox(height: Espaco.xs),
          Text(
            '${o.pessoasAfetadas} pessoa(s) · ${o.horasSemAgua.toStringAsFixed(0)} h sem água · $quando'
            '${o.descricao.isEmpty ? '' : '\n${o.descricao}'}',
            style: tema.textTheme.bodyMedium,
          ),
          const SizedBox(height: Espaco.sm),
          BarraConfianca(valor: item.confianca, rotulo: 'da IA'),
          const SizedBox(height: Espaco.xs),
          Text(
            '${item.relatosNoBairro} relato(s) no bairro em 7 dias'
            '${item.satelite == null ? '' : ' · Satélite (CNN): ${item.satelite!.classeRotulo}'}',
            style: tema.textTheme.bodySmall,
          ),
          const SizedBox(height: Espaco.sm),
          if (acionada)
            Row(children: [
              Icon(Icons.check_circle_rounded, color: tema.colorScheme.primary),
              const SizedBox(width: Espaco.sm),
              const Expanded(child: Text('Equipe acionada')),
              if (gestor) TextButton(onPressed: () => t.alternarEquipe(o.id), child: const Text('Desfazer')),
            ])
          else if (gestor)
            FilledButton.tonalIcon(
              onPressed: () => t.alternarEquipe(o.id),
              icon: const Icon(Icons.engineering_rounded),
              label: const Text('Chamar equipe'),
            )
          else
            Text('Aguardando decisão de um gestor.', style: tema.textTheme.bodySmall),
        ]),
      ),
    );
  }
}
