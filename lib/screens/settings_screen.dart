import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/command_button_config.dart';
import '../services/storage_service.dart';
import '../widgets/command_button_style.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.initialSettings,
    required this.storage,
  });

  final AppSettings initialSettings;
  final StorageService storage;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _recipient;
  late final List<TextEditingController> _names;
  late final List<TextEditingController> _texts;
  late final List<bool> _confirmations;
  late final List<CommandIcon> _icons;
  late final List<CommandColor> _colors;
  bool _saving = false;
  bool _dirty = false;
  bool _allowPop = false;
  bool _askingToDiscard = false;

  @override
  void initState() {
    super.initState();
    final settings = widget.initialSettings;
    _recipient = TextEditingController(text: settings.recipient);
    _icons = settings.buttons.map((b) => b.icon).toList();
    _colors = settings.buttons.map((b) => b.color).toList();
    _names = settings.buttons
        .map((b) => TextEditingController(text: b.name))
        .toList();
    _texts = settings.buttons
        .map((b) => TextEditingController(text: b.smsText))
        .toList();
    _confirmations = settings.buttons
        .map((b) => b.requireConfirmation)
        .toList();
  }

  @override
  void dispose() {
    _recipient.dispose();
    for (final controller in [..._names, ..._texts]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _requestExit() async {
    if (_saving || _askingToDiscard) return;
    _askingToDiscard = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scartare le modifiche?'),
        content: const Text('Le modifiche non salvate andranno perse.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continua a modificare'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Scarta'),
          ),
        ],
      ),
    );
    _askingToDiscard = false;
    if (discard == true && mounted) _close();
  }

  void _close([AppSettings? settings]) {
    setState(() => _allowPop = true);
    // Attende che PopScope recepisca canPop prima di chiudere la schermata.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(settings);
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final settings = AppSettings(
      recipient: AppSettings.normalizePhone(_recipient.text),
      buttons: List.generate(
        AppSettings.buttonCount,
        (index) => CommandButtonConfig(
          name: _names[index].text.trim(),
          // Gli spazi possono far parte del protocollo del dispositivo.
          smsText: _texts[index].text,
          requireConfirmation: _confirmations[index],
          icon: _icons[index],
          color: _colors[index],
        ),
      ),
    );
    setState(() => _saving = true);
    try {
      await widget.storage.save(settings);
      if (mounted) _close(settings);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Salvataggio non riuscito. Le modifiche sono ancora qui: riprova.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<AppSettings>(
      canPop: _allowPop || (!_dirty && !_saving),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Impostazioni')),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Le impostazioni vengono salvate solo su questo dispositivo.',
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _recipient,
                        enabled: !_saving,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Numero destinatario',
                          hintText: '+39 333 1234567',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: AppSettings.validateRecipient,
                        onChanged: (_) => _markDirty(),
                      ),
                      const SizedBox(height: 24),
                      for (
                        var index = 0;
                        index < AppSettings.buttonCount;
                        index++
                      )
                        Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Pulsante ${index + 1}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _names[index],
                                  enabled: !_saving,
                                  decoration: const InputDecoration(
                                    labelText: 'Nome',
                                  ),
                                  textInputAction: TextInputAction.next,
                                  validator: CommandButtonConfig.validateName,
                                  onChanged: (_) => _markDirty(),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _texts[index],
                                  enabled: !_saving,
                                  decoration: const InputDecoration(
                                    labelText: 'Testo SMS',
                                  ),
                                  minLines: 2,
                                  maxLines: 5,
                                  keyboardType: TextInputType.multiline,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  validator:
                                      CommandButtonConfig.validateSmsText,
                                  onChanged: (_) => _markDirty(),
                                ),
                                const SizedBox(height: 20),
                                const Text('Icona'),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final icon in CommandIcon.values)
                                      ChoiceChip(
                                        key: ValueKey(
                                          'icon_${index}_${icon.name}',
                                        ),
                                        avatar: Icon(icon.data, size: 20),
                                        label: Text(icon.label),
                                        selected: _icons[index] == icon,
                                        onSelected: _saving
                                            ? null
                                            : (_) => setState(() {
                                                _icons[index] = icon;
                                                _dirty = true;
                                              }),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text('Colore'),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final color in CommandColor.values)
                                      ChoiceChip(
                                        key: ValueKey(
                                          'color_${index}_${color.name}',
                                        ),
                                        avatar: Icon(
                                          Icons.circle,
                                          color: color.seed,
                                          size: 20,
                                        ),
                                        label: Text(color.label),
                                        selected: _colors[index] == color,
                                        onSelected: _saving
                                            ? null
                                            : (_) => setState(() {
                                                _colors[index] = color;
                                                _dirty = true;
                                              }),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Chiedi conferma'),
                                  value: _confirmations[index],
                                  onChanged: _saving
                                      ? null
                                      : (value) => setState(() {
                                          _confirmations[index] = value;
                                          _dirty = true;
                                        }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(
                          _saving ? 'Salvataggio…' : 'Salva impostazioni',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
