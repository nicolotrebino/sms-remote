import 'package:flutter/material.dart';

import '../models/command_button_config.dart';

extension CommandIconStyle on CommandIcon {
  IconData get data => switch (this) {
    CommandIcon.melody => Icons.music_note_outlined,
    CommandIcon.tune => Icons.tune,
    CommandIcon.light => Icons.lightbulb_outline,
    CommandIcon.lock => Icons.lock_outline,
    CommandIcon.home => Icons.home_outlined,
  };

  String get label => switch (this) {
    CommandIcon.melody => 'Melodia',
    CommandIcon.tune => 'Regolazione',
    CommandIcon.light => 'Luce',
    CommandIcon.lock => 'Serratura',
    CommandIcon.home => 'Casa',
  };
}

extension CommandColorStyle on CommandColor {
  Color get seed => switch (this) {
    CommandColor.green => const Color(0xFF18856B),
    CommandColor.amber => const Color(0xFFBE790A),
    CommandColor.purple => const Color(0xFF8054C5),
    CommandColor.blue => const Color(0xFF217DB3),
    CommandColor.coral => const Color(0xFFC4553E),
    CommandColor.pink => const Color(0xFFB34485),
  };

  String get label => switch (this) {
    CommandColor.green => 'Verde',
    CommandColor.amber => 'Ambra',
    CommandColor.purple => 'Viola',
    CommandColor.blue => 'Azzurro',
    CommandColor.coral => 'Corallo',
    CommandColor.pink => 'Rosa',
  };
}
