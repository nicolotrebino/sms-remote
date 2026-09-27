import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_remote/services/sms_service.dart';

class MemoryPreferences implements SharedPreferencesAsync {
  final values = <String, String>{};
  final _failures = <String>{};
  bool get failRead => _failures.contains('read');
  set failRead(bool value) =>
      value ? _failures.add('read') : _failures.remove('read');
  bool get failWrite => _failures.contains('write');
  set failWrite(bool value) =>
      value ? _failures.add('write') : _failures.remove('write');

  @override
  Future<String?> getString(String key) async {
    if (failRead) throw StateError('Read failed');
    return values[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    if (failWrite) throw StateError('Write failed');
    values[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RecordingSmsService extends SmsService {
  final sent = <({String recipient, String text})>[];

  @override
  Future<SmsResult> send({
    required String recipient,
    required String text,
  }) async {
    sent.add((recipient: recipient, text: text));
    return SmsResult.sent;
  }
}
