import 'package:flutter_test/flutter_test.dart';
import 'package:sms_remote/models/app_settings.dart';
import 'package:sms_remote/models/command_button_config.dart';
import 'package:sms_remote/services/storage_service.dart';

import 'test_support.dart';

void main() {
  test('First launch has exactly four commands and no recipient', () async {
    final settings = await StorageService(
      preferences: MemoryPreferences(),
    ).load();
    expect(settings.buttons, hasLength(4));
    expect(settings.recipient, isEmpty);
    expect(settings.isReady, isFalse);
    expect(() => AppSettings(recipient: '', buttons: []), throwsArgumentError);
  });

  test('All fields survive a new storage service instance', () async {
    final preferences = MemoryPreferences();
    final settings = AppSettings(
      recipient: '+393331234567',
      buttons: List.generate(
        4,
        (i) => CommandButtonConfig(
          name: 'Luce $i',
          smsText: '  ON $i\n',
          requireConfirmation: i.isEven,
          icon: CommandIcon.values[i],
          color: CommandColor.values[(i + 3) % CommandColor.values.length],
        ),
      ),
    );
    await StorageService(preferences: preferences).save(settings);
    final loaded = await StorageService(preferences: preferences).load();
    expect(loaded.toJson(), settings.toJson());
    expect(() => loaded.buttons.clear(), throwsUnsupportedError);
  });

  test('Settings without appearance use current defaults', () {
    final json = AppSettings.defaults().toJson();
    for (final button in json['buttons'] as List) {
      (button as Map).remove('icon');
      button.remove('color');
    }
    final loaded = AppSettings.fromJson(json);
    for (var i = 0; i < 4; i++) {
      expect(loaded.buttons[i].icon, CommandIcon.values[i]);
      expect(loaded.buttons[i].color, CommandColor.values[i]);
    }
    final first = (json['buttons'] as List).first as Map;
    first['icon'] = 'unknown';
    first['color'] = 123;
    expect(AppSettings.fromJson(json).buttons.first.icon, CommandIcon.melody);
    expect(AppSettings.fromJson(json).buttons.first.color, CommandColor.green);
  });

  test('Retired icons migrate without changing command content', () {
    const replacements = {
      'power': CommandIcon.tune,
      'bolt': CommandIcon.light,
      'sms': CommandIcon.melody,
      'gate': CommandIcon.lock,
    };
    for (final entry in replacements.entries) {
      final json = const CommandButtonConfig(
        name: 'Campane',
        smsText: ' MELODIA 1\n',
        requireConfirmation: false,
        color: CommandColor.purple,
      ).toJson();
      json['icon'] = entry.key;
      final loaded = CommandButtonConfig.fromJson(json);
      expect(loaded.icon, entry.value);
      expect(loaded.name, 'Campane');
      expect(loaded.smsText, ' MELODIA 1\n');
      expect(loaded.requireConfirmation, isFalse);
      expect(loaded.color, CommandColor.purple);
      expect(loaded.toJson()['icon'], entry.value.name);
    }
  });

  test('Corrupt data is reported and never overwritten during load', () async {
    final preferences = MemoryPreferences();
    final storage = StorageService(preferences: preferences);
    for (final invalid in [
      'broken',
      '[]',
      '{"version":1,"recipient":"","buttons":[]}',
    ]) {
      preferences.values[StorageService.settingsKey] = invalid;
      await expectLater(storage.load(), throwsFormatException);
      expect(preferences.values[StorageService.settingsKey], invalid);
    }
  });

  test(
    'Invalid settings cannot be saved and storage errors propagate',
    () async {
      final preferences = MemoryPreferences();
      final storage = StorageService(preferences: preferences);
      await expectLater(
        storage.save(AppSettings.defaults()),
        throwsArgumentError,
      );
      preferences.failRead = true;
      await expectLater(storage.load(), throwsStateError);
      preferences.failWrite = true;
      await expectLater(
        storage.save(
          AppSettings(
            recipient: '12345',
            buttons: AppSettings.defaults().buttons,
          ),
        ),
        throwsStateError,
      );
    },
  );

  test('Phone and command validation reject blank and malformed inputs', () {
    for (final phone in [
      '',
      '  ',
      '++3912345',
      '123abc',
      '12',
      '1234567890123456',
    ]) {
      expect(AppSettings.validateRecipient(phone), isNotNull);
    }
    expect(AppSettings.validateRecipient('+39 (333) 123-4567'), isNull);
    expect(AppSettings.normalizePhone('+39 (333) 123-4567'), '+393331234567');
    expect(CommandButtonConfig.validateName('  '), isNotNull);
    expect(CommandButtonConfig.validateName('x' * 41), isNotNull);
    expect(CommandButtonConfig.validateSmsText('\n  '), isNotNull);
    expect(CommandButtonConfig.validateSmsText('ON\nOFF'), isNull);
  });
}
