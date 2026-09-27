import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_settings.dart';
import '../services/sms_service.dart';
import '../services/storage_service.dart';
import '../widgets/command_button.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.storage, required this.sms});

  final StorageService storage;
  final SmsService sms;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppSettings? _settings;
  bool _loading = true;
  bool _loadFailed = false;
  int? _activeCommand;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final settings = await widget.storage.load();
      if (mounted) setState(() => _settings = settings);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openSettings() async {
    final settings = await Navigator.of(context).push<AppSettings>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          initialSettings: _settings ?? AppSettings.defaults(),
          storage: widget.storage,
        ),
      ),
    );
    if (settings != null && mounted) {
      setState(() {
        _settings = settings;
        _loadFailed = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSentFeedback() {
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: colors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: colors.onPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'SMS inviato alla rete. Consegna non confermata.',
                  style: TextStyle(color: colors.onPrimary),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _send(int index) async {
    final settings = _settings;
    if (settings == null || !settings.isReady || _activeCommand != null) return;
    final command = settings.buttons[index];
    setState(() => _activeCommand = index);
    try {
      if (command.requireConfirmation) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Inviare ${command.name}?'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Destinatario: ${settings.recipient}'),
                  const SizedBox(height: 16),
                  Text(command.smsText),
                  const SizedBox(height: 16),
                  const Text(
                    'Dopo la conferma l’SMS partirà direttamente, senza '
                    'aprire un’altra app. Potrebbero applicarsi tariffe '
                    'dell’operatore.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continua'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }
      setState(() => _sending = true);
      await widget.sms.send(
        recipient: settings.recipient,
        text: command.smsText,
      );
      if (mounted) {
        _showSentFeedback();
      }
    } on PlatformException catch (error) {
      if (mounted) {
        _showMessage(switch (error.code) {
          'unavailable' =>
            'SMS non disponibili. Verifica che il dispositivo sia configurato per inviare SMS.',
          'busy' => 'Un’altra schermata è aperta. Chiudila e riprova.',
          'permission_denied' =>
            'Permesso SMS negato. Concedi a GSM Remote il permesso di inviare SMS nelle impostazioni Android.',
          'sim_not_selected' =>
            'Seleziona una SIM predefinita per gli SMS nelle impostazioni Android.',
          'send_timeout' =>
            'Android non ha restituito l’esito. Controlla i messaggi inviati prima di riprovare.',
          'send_failed' =>
            'Invio non riuscito. Verifica il servizio telefonico e riprova.',
          _ => 'Impossibile aprire il messaggio. Riprova.',
        });
      }
    } on MissingPluginException {
      if (mounted) {
        _showMessage('Invio SMS disponibile solo nell’app Android.');
      }
    } catch (_) {
      if (mounted) _showMessage('Impossibile aprire il messaggio. Riprova.');
    } finally {
      if (mounted) {
        setState(() {
          _activeCommand = null;
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 20,
        centerTitle: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Image.asset(
          'assets/images/trebino.png',
          width: 152,
          height: 38,
          fit: BoxFit.contain,
          semanticLabel: 'Trebino S.n.c.',
        ),
        actions: [
          IconButton(
            tooltip: 'Impostazioni',
            onPressed: _loading || _activeCommand != null
                ? null
                : _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadFailed
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Impossibile leggere le impostazioni. Riprova oppure '
                        'apri Impostazioni per configurarle di nuovo.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Riprova'),
                      ),
                    ],
                  ),
                ),
              )
            : settings == null
            ? const SizedBox.shrink()
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'GSM Remote',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          settings.isReady
                              ? 'Destinatario · ${settings.recipient}'
                              : 'Apri Impostazioni per configurare il destinatario e i comandi.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Scegli un comando per inviare un SMS direttamente. '
                          'Potrebbero applicarsi tariffe dell’operatore.',
                        ),
                        const SizedBox(height: 24),
                        for (
                          var index = 0;
                          index < AppSettings.buttonCount;
                          index++
                        ) ...[
                          CommandButton(
                            config: settings.buttons[index],
                            isBusy: _sending && _activeCommand == index,
                            onPressed:
                                settings.isReady && _activeCommand == null
                                ? () => _send(index)
                                : null,
                          ),
                          if (index < AppSettings.buttonCount - 1)
                            const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
