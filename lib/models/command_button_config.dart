enum CommandIcon { melody, light, church, bell, hammer }

enum CommandColor { green, amber, purple, blue }

class CommandButtonConfig {
  const CommandButtonConfig({
    required this.name,
    required this.smsText,
    this.requireConfirmation = true,
    this.icon = CommandIcon.melody,
    this.color = CommandColor.green,
  });

  final String name;
  final String smsText;
  final bool requireConfirmation;
  final CommandIcon icon;
  final CommandColor color;

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Inserisci un nome.';
    if (value.trim().length > 40) return 'Usa al massimo 40 caratteri.';
    return null;
  }

  static String? validateSmsText(String? value) {
    if (value == null || value.trim().isEmpty) return 'Inserisci il testo SMS.';
    return null;
  }

  Map<String, Object> toJson() => {
    'name': name,
    'smsText': smsText,
    'requireConfirmation': requireConfirmation,
    'icon': icon.name,
    'color': color.name,
  };

  factory CommandButtonConfig.fromJson(
    Map<String, dynamic> json, {
    CommandIcon defaultIcon = CommandIcon.melody,
    CommandColor defaultColor = CommandColor.green,
  }) {
    // Migra le icone ritirate senza perdere gli altri campi del comando.
    final iconName = switch (json['icon']) {
      'power' || 'tune' || 'home' => 'church',
      'bolt' => 'light',
      'sms' => 'melody',
      'gate' => 'church',
      'lock' => 'hammer',
      final value => value,
    };
    final colorName = switch (json['color']) {
      'coral' => 'amber',
      'pink' => 'purple',
      final value => value,
    };
    final name = json['name'];
    final smsText = json['smsText'];
    final confirmation = json['requireConfirmation'];
    if (name is! String ||
        smsText is! String ||
        confirmation is! bool ||
        validateName(name) != null ||
        validateSmsText(smsText) != null) {
      throw const FormatException('Configurazione pulsante non valida.');
    }
    return CommandButtonConfig(
      name: name,
      smsText: smsText,
      requireConfirmation: confirmation,
      icon:
          CommandIcon.values
              .where((value) => value.name == iconName)
              .firstOrNull ??
          defaultIcon,
      color:
          CommandColor.values
              .where((value) => value.name == colorName)
              .firstOrNull ??
          defaultColor,
    );
  }
}
