import 'package:flutter/services.dart';

import '../models/app_settings.dart';
import '../models/command_button_config.dart';

enum SmsResult { opened, sent, cancelled }

/// Apre il compositore nativo. L'utente completa l'invio nella UI di sistema.
class SmsService {
  static const channel = MethodChannel('sms_remote/sms');

  Future<SmsResult> send({
    required String recipient,
    required String text,
  }) async {
    if (AppSettings.validateRecipient(recipient) != null ||
        CommandButtonConfig.validateSmsText(text) != null) {
      throw ArgumentError('Numero o testo SMS non valido.');
    }
    final result = await channel.invokeMethod<String>('compose', {
      'recipient': AppSettings.normalizePhone(recipient),
      'text': text,
    });
    return switch (result) {
      'opened' => SmsResult.opened,
      'sent' => SmsResult.sent,
      'cancelled' => SmsResult.cancelled,
      _ => throw PlatformException(code: 'unexpected_result'),
    };
  }
}
