import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../logic/bairros.dart';
import '../logic/validadores.dart';
import '../state/territorio_provider.dart';
import '../widgets/analise_ia_card.dart';

/// Formulário do cidadão para registrar uma ocorrência anônima.
class RegistrarOcorrenciaTela extends StatefulWidget {
  const RegistrarOcorrenciaTela({super.key, this.bairroInicial});
  final String? bairroInicial;

  @override
  State<RegistrarOcorrenciaTela> createState() => _RegistrarOcorrenciaTelaState();
}

class _RegistrarOcorrenciaTelaState extends State<RegistrarOcorrenciaTela> {
  final _form = GlobalKey<FormState>();
  final _horas = TextEditingController();
  final _pessoas = TextEditingController();
  final _descricao = TextEditingController();
  String? _bairro;
  String? _tipo;
  bool _semDadosPessoais = false;
  bool _enviando = false;
  Uint8List? _foto; // só para pré-visualização: não é salva nem enviada

  @override
  void initState() {
    super.initState();
    if (bairrosAquaRede.containsKey(widget.bairroInicial)) _bairro = widget.bairroInicial;
  }

  @override
  void dispose() {
    _horas.dispose();
    _pessoas.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _escolherFoto(ImageSource origem) async {
    try {
      final arquivo = await ImagePicker().pickImage(source: origem, maxWidth: 1024, imageQuality: 80);
      if (arquivo == null) return;
      final bytes = await arquivo.readAsBytes();
      if (mounted) setState(() => _foto = bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir a foto.')));
    }
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confira os campos destacados em vermelho.')),
      );
      return;
    }
    setState(() => _enviando = true);
    await context.read<TerritorioProvider>().registrarOcorrencia(
          bairro: _bairro!,
          tipo: _tipo!,
          horasSemAgua: double.parse(_horas.text.trim().replaceAll(',', '.')),
          pessoasAfetadas: int.parse(_pessoas.text.trim()),
          descricao: _descricao.text.trim(),
        );
    if (!mounted) return;
    setState(() => _enviando = false);
    await showDialog<void>(
      context: context,
      builder: (contexto) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded),
        title: const Text('Ocorrência registrada'),
        content: const Text('Seu relato foi salvo neste aparelho e já faz parte dos indicadores, dos alertas e da fila das equipes.'),
        actions: [TextButton(onPressed: () => Navigator.of(contexto).pop(), child: const Text('OK'))],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final bairros = bairrosAquaRede.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar ocorrência')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(Espaco.md),
          children: [
            Text('Seu relato é anônimo e ajuda a mostrar onde o problema é mais grave.', style: tema.textTheme.bodyLarge),
            const SizedBox(height: Espaco.lg),
            DropdownButtonFormField<String>(
              initialValue: _bairro,
              decoration: const InputDecoration(labelText: 'Bairro', prefixIcon: Icon(Icons.location_on_rounded)),
              items: [for (final b in bairros) DropdownMenuItem(value: b, child: Text(b))],
              onChanged: (v) => setState(() => _bairro = v),
              validator: Validadores.bairro,
            ),
            const SizedBox(height: Espaco.lg),
            FormField<String>(
              initialValue: _tipo,
              validator: Validadores.tipo,
              builder: (campo) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tipo de ocorrência', style: tema.textTheme.titleSmall),
                const SizedBox(height: Espaco.sm),
                Wrap(spacing: Espaco.sm, runSpacing: Espaco.sm, children: [
                  for (final t in tiposOcorrencia)
                    ChoiceChip(
                      label: Text(t),
                      selected: _tipo == t,
                      onSelected: (_) {
                        setState(() => _tipo = t);
                        campo.didChange(t);
                      },
                    ),
                ]),
                if (campo.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: Espaco.sm, left: Espaco.sm),
                    child: Text(campo.errorText!, style: TextStyle(color: tema.colorScheme.error, fontSize: 12)),
                  ),
              ]),
            ),
            const SizedBox(height: Espaco.lg),
            TextFormField(
              controller: _horas,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Horas sem água',
                helperText: 'Use 0 se a água não chegou a faltar.',
                prefixIcon: Icon(Icons.schedule_rounded),
              ),
              validator: Validadores.horasSemAgua,
            ),
            const SizedBox(height: Espaco.md),
            TextFormField(
              controller: _pessoas,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Pessoas afetadas',
                helperText: 'Na sua casa ou na rua, se souber.',
                prefixIcon: Icon(Icons.groups_rounded),
              ),
              validator: Validadores.pessoasAfetadas,
            ),
            const SizedBox(height: Espaco.md),
            TextFormField(
              controller: _descricao,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: 'Ex.: Cano estourado na esquina desde ontem.',
                helperText: 'Não escreva nome, telefone ou e-mail.',
              ),
              validator: Validadores.descricao,
            ),
            const SizedBox(height: Espaco.md),
            Text('Foto (opcional)', style: tema.textTheme.titleSmall),
            const SizedBox(height: Espaco.sm),
            Wrap(spacing: Espaco.sm, runSpacing: Espaco.sm, children: [
              OutlinedButton.icon(
                onPressed: () => _escolherFoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Escolher foto'),
              ),
              if (!kIsWeb)
                OutlinedButton.icon(
                  onPressed: () => _escolherFoto(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_rounded),
                  label: const Text('Tirar foto'),
                ),
              if (_foto != null)
                TextButton(onPressed: () => setState(() => _foto = null), child: const Text('Remover')),
            ]),
            if (_foto != null)
              Padding(
                padding: const EdgeInsets.only(top: Espaco.sm),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Espaco.raio),
                  child: Image.memory(_foto!, height: 160, fit: BoxFit.cover, semanticLabel: 'Foto da ocorrência'),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: Espaco.xs),
              child: Text('A foto aparece só nesta tela: não é salva nem enviada. Evite rostos e placas.',
                  style: tema.textTheme.bodySmall),
            ),
            const SizedBox(height: Espaco.md),
            AnimatedBuilder(
              animation: Listenable.merge([_horas, _pessoas]),
              builder: (_, __) => AnaliseIaCard(
                bairro: _bairro,
                tipo: _tipo,
                horasSemAgua: double.tryParse(_horas.text.trim().replaceAll(',', '.')),
                pessoas: int.tryParse(_pessoas.text.trim()),
              ),
            ),
            FormField<bool>(
              initialValue: _semDadosPessoais,
              validator: (v) => v == true ? null : 'Confirme para enviar.',
              builder: (campo) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CheckboxListTile(
                  value: _semDadosPessoais,
                  onChanged: (v) {
                    setState(() => _semDadosPessoais = v ?? false);
                    campo.didChange(v);
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Confirmo que o relato não tem dados pessoais (nome, telefone, endereço exato).'),
                ),
                if (campo.hasError)
                  Text(campo.errorText!, style: TextStyle(color: tema.colorScheme.error, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: Espaco.lg),
            FilledButton.icon(
              onPressed: _enviando ? null : _enviar,
              icon: _enviando
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
              label: Text(_enviando ? 'Salvando...' : 'Registrar ocorrência'),
            ),
            const SizedBox(height: Espaco.xl),
          ],
        ),
      ),
    );
  }
}
