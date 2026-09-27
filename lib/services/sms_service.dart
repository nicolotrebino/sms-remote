import 'package:flutter/services.dart';

import '../models/app_settings.dart';
import '../models/command_button_config.dart';

enum SmsResult { sent }

/// Invia l'SMS direttamente tramite il servizio telefonico di Android.
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
    final result = await channel.invokeMethod<String>('send', {
      'recipient': AppSettings.normalizePhone(recipient),
      'text': text,
    });
    return switch (result) {
      'sent' => SmsResult.sent,
      _ => throw PlatformException(code: 'unexpected_result'),
    };
  }
}
