import 'command_button_config.dart';

class AppSettings {
  AppSettings({
    required this.recipient,
    required List<CommandButtonConfig> buttons,
  }) : buttons = List.unmodifiable(buttons) {
    if (buttons.length != buttonCount) {
      throw ArgumentError('Sono necessari esattamente $buttonCount pulsanti.');
    }
  }

  static const buttonCount = 4;
  final String recipient;
  final List<CommandButtonConfig> buttons;

  factory AppSettings.defaults() => AppSettings(
    recipient: '',
    buttons: List.generate(
      buttonCount,
      (index) => CommandButtonConfig(
        name: 'Comando ${index + 1}',
        smsText: 'COMANDO_${index + 1}',
        icon: CommandIcon.values[index],
        color: CommandColor.values[index],
      ),
    ),
  );

  static String normalizePhone(String value) =>
      value.replaceAll(RegExp(r'[\s()\-]'), '');

  static String? validateRecipient(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Inserisci il numero destinatario.';
    }
    if (!RegExp(r'^\+?[0-9]{3,15}$').hasMatch(normalizePhone(value))) {
      return 'Usa da 3 a 15 cifre, con prefisso + facoltativo.';
    }
    return null;
  }

  bool get isReady =>
      validateRecipient(recipient) == null &&
      buttons.every(
        (button) =>
            CommandButtonConfig.validateName(button.name) == null &&
            CommandButtonConfig.validateSmsText(button.smsText) == null,
      );

  Map<String, Object> toJson() => {
    'version': 1,
    'recipient': recipient,
    'buttons': buttons.map((button) => button.toJson()).toList(),
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final recipient = json['recipient'];
    final buttons = json['buttons'];
    if (json['version'] != 1 ||
        recipient is! String ||
        (recipient.isNotEmpty && validateRecipient(recipient) != null) ||
        buttons is! List ||
        buttons.length != buttonCount) {
      throw const FormatException('Impostazioni non valide.');
    }
    return AppSettings(
      recipient: recipient,
      buttons: buttons.asMap().entries.map((entry) {
        final item = entry.value;
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Configurazione pulsante non valida.');
        }
        return CommandButtonConfig.fromJson(
          item,
          defaultIcon: CommandIcon.values[entry.key],
          defaultColor: CommandColor.values[entry.key],
        );
      }).toList(),
    );
  }
}
