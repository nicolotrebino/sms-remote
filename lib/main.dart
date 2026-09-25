import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/sms_service.dart';
import 'services/storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SmsRemoteApp(storage: StorageService(), sms: SmsService()));
}

class SmsRemoteApp extends StatelessWidget {
  const SmsRemoteApp({super.key, required this.storage, required this.sms});

  final StorageService storage;
  final SmsService sms;

  ThemeData _theme(Brightness brightness) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFC9AF48),
      brightness: brightness,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      errorMaxLines: 3,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telecomando SMS',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: HomeScreen(storage: storage, sms: sms),
    );
  }
}
