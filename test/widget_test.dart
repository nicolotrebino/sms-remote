import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_remote/main.dart';
import 'package:sms_remote/models/app_settings.dart';
import 'package:sms_remote/models/command_button_config.dart';
import 'package:sms_remote/services/storage_service.dart';
import 'package:sms_remote/widgets/command_button.dart';

import 'test_support.dart';

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Impostazioni'));
  await tester.pumpAndSettle();
}

Future<void> tapSave(WidgetTester tester) async {
  final save = find.widgetWithText(FilledButton, 'Salva impostazioni');
  await tester.ensureVisible(save);
  await tester.tap(save);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('First launch shows four disabled commands', (tester) async {
    await tester.pumpWidget(
      SmsRemoteApp(
        storage: StorageService(preferences: MemoryPreferences()),
        sms: RecordingSmsService(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CommandButton), findsNWidgets(4));
    for (final button in tester.widgetList<CommandButton>(
      find.byType(CommandButton),
    )) {
      expect(button.onPressed, isNull);
    }
  });

  testWidgets('Settings validate, save all fields and update Home', (
    tester,
  ) async {
    final preferences = MemoryPreferences();
    final storage = StorageService(preferences: preferences);
    await tester.pumpWidget(
      SmsRemoteApp(storage: storage, sms: RecordingSmsService()),
    );
    await tester.pumpAndSettle();
    await openSettings(tester);
    await tapSave(tester);
    expect(find.text('Inserisci il numero destinatario.'), findsOneWidget);
    expect(preferences.values, isEmpty);
    await tester.tap(find.text('Pulsante 1'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.ensureVisible(fields.at(0));
    await tester.enterText(fields.at(0), '+39 333 1234567');
    await tester.enterText(fields.at(1), 'Luci');
    await tester.ensureVisible(fields.at(2));
    await tester.enterText(fields.at(2), ' ON\n');
    final iconChoice = find.byKey(const ValueKey('icon_0_light'));
    for (final removed in ['power', 'bolt', 'sms', 'gate']) {
      expect(find.byKey(ValueKey('icon_0_$removed')), findsNothing);
    }
    final colorChoice = find.byKey(const ValueKey('color_0_blue'));
    await tester.ensureVisible(iconChoice);
    await tester.tap(iconChoice);
    await tester.pumpAndSettle();
    await tester.ensureVisible(colorChoice);
    await tester.tap(colorChoice);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(SwitchListTile).first);
    await tester.tap(find.byType(SwitchListTile).first);
    await tapSave(tester);
    expect(find.text('GSM Remote'), findsOneWidget);
    expect(find.text('Luci'), findsOneWidget);
    final saved = await StorageService(preferences: preferences).load();
    expect(saved.recipient, '+393331234567');
    expect(saved.buttons.first.smsText, ' ON\n');
    expect(saved.buttons.first.requireConfirmation, isFalse);
    expect(saved.buttons.first.icon, CommandIcon.light);
    expect(saved.buttons.first.color, CommandColor.blue);
    final homeButton = tester.widget<CommandButton>(
      find.byType(CommandButton).first,
    );
    expect(homeButton.config.icon, CommandIcon.light);
    expect(homeButton.config.color, CommandColor.blue);
    expect(find.byIcon(Icons.lightbulb_outline), findsWidgets);
    await openSettings(tester);
    await tester.tap(find.text('Pulsante 1'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(fields.at(1)).controller!.text, 'Luci');
    expect(tester.widget<ChoiceChip>(iconChoice).selected, isTrue);
    expect(tester.widget<ChoiceChip>(colorChoice).selected, isTrue);
  });

  testWidgets('Confirmation cancel, accept and direct SMS request', (
    tester,
  ) async {
    final storage = StorageService(preferences: MemoryPreferences());
    await storage.save(
      AppSettings(
        recipient: '12345',
        buttons: List.generate(
          4,
          (i) => CommandButtonConfig(
            name: 'Tasto $i',
            smsText: 'CMD$i',
            requireConfirmation: i == 0,
          ),
        ),
      ),
    );
    final sms = RecordingSmsService();
    await tester.pumpWidget(SmsRemoteApp(storage: storage, sms: sms));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tasto 0'));
    await tester.pumpAndSettle();
    expect(sms.sent, isEmpty);
    expect(find.text('CMD0'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(sms.sent, isEmpty);
    await tester.tap(find.text('Tasto 0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continua'));
    await tester.pumpAndSettle();
    expect(sms.sent.single, (recipient: '12345', text: 'CMD0'));
    expect(
      find.text('SMS inviato alla rete. Consegna non confermata.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Tasto 1'));
    await tester.tap(find.text('Tasto 1'));
    await tester.pumpAndSettle();
    expect(sms.sent, hasLength(2));
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'Failed save keeps edits, back navigation asks before discarding',
    (tester) async {
      final preferences = MemoryPreferences()..failWrite = true;
      await tester.pumpWidget(
        SmsRemoteApp(
          storage: StorageService(preferences: preferences),
          sms: RecordingSmsService(),
        ),
      );
      await tester.pumpAndSettle();
      await openSettings(tester);
      await tester.enterText(find.byType(TextFormField).first, '12345');
      await tapSave(tester);
      expect(find.textContaining('Salvataggio non riuscito'), findsOneWidget);
      expect(find.text('Impostazioni'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Scartare le modifiche?'), findsOneWidget);
      await tester.tap(find.text('Scarta'));
      await tester.pumpAndSettle();
      expect(find.text('GSM Remote'), findsOneWidget);
      expect(preferences.values, isEmpty);
    },
  );

  testWidgets('Load error offers retry', (tester) async {
    final preferences = MemoryPreferences()..failRead = true;
    await tester.pumpWidget(
      SmsRemoteApp(
        storage: StorageService(preferences: preferences),
        sms: RecordingSmsService(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Impossibile leggere'), findsOneWidget);
    preferences.failRead = false;
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();
    expect(find.byType(CommandButton), findsNWidgets(4));
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'Branded small screen with large text in ${brightness.name} mode',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpWidget(
          SmsRemoteApp(
            storage: StorageService(preferences: MemoryPreferences()),
            sms: RecordingSmsService(),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byType(CommandButton).first)).brightness,
          brightness,
        );
        final logoFinder = find.byType(Image);
        final logo = tester.widget<Image>(logoFinder);
        expect(
          (logo.image as AssetImage).assetName,
          'assets/images/trebino.png',
        );
        expect(logo.fit, BoxFit.contain);
        expect(logo.color, isNull);
        expect(logo.semanticLabel, 'Trebino S.n.c.');
        expect(tester.getRect(logoFinder).right, lessThanOrEqualTo(320));
        expect(find.byType(CommandButton), findsNWidgets(4));
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Comando 4'));
        await tester.pumpAndSettle();
        expect(find.text('Comando 4').hitTestable(), findsOneWidget);
        expect(find.byTooltip('Impostazioni').hitTestable(), findsOneWidget);
        await openSettings(tester);
        await tapSave(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
