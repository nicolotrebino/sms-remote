import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_remote/services/sms_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(SmsService.channel, (call) async {
      calls.add(call);
      return 'sent';
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(SmsService.channel, null));

  test(
    'Sends normalized recipient and exact text through the native service',
    () async {
      const text = ' ON + & ? # 50% è 🚀\nOFF ';
      final result = await SmsService().send(
        recipient: '+39 (333) 123-4567',
        text: text,
      );
      expect(result, SmsResult.sent);
      expect(calls.single.method, 'send');
      expect(calls.single.arguments, {
        'recipient': '+393331234567',
        'text': text,
      });
    },
  );

  test('Rejects invalid inputs before calling native code', () async {
    await expectLater(
      SmsService().send(recipient: '', text: 'ON'),
      throwsArgumentError,
    );
    await expectLater(
      SmsService().send(recipient: '12345', text: ' '),
      throwsArgumentError,
    );
    expect(calls, isEmpty);
  });

  test(
    'Propagates unavailable and failed results instead of reporting success',
    () async {
      for (final code in ['unavailable', 'send_failed', 'busy']) {
        messenger.setMockMethodCallHandler(SmsService.channel, (_) async {
          throw PlatformException(code: code);
        });
        await expectLater(
          SmsService().send(recipient: '12345', text: 'ON'),
          throwsA(
            isA<PlatformException>().having(
              (error) => error.code,
              'code',
              code,
            ),
          ),
        );
      }
    },
  );

  test('Unknown or missing native results never count as sent', () async {
    for (final result in ['unknown', null]) {
      messenger.setMockMethodCallHandler(
        SmsService.channel,
        (_) async => result,
      );
      await expectLater(
        SmsService().send(recipient: '12345', text: 'ON'),
        throwsA(isA<PlatformException>()),
      );
    }
    messenger.setMockMethodCallHandler(SmsService.channel, null);
    await expectLater(
      SmsService().send(recipient: '12345', text: 'ON'),
      throwsA(isA<MissingPluginException>()),
    );
  });
}
