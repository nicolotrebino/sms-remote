import 'package:flutter/material.dart';

import '../models/command_button_config.dart';

extension CommandIconStyle on CommandIcon {
  IconData get data => switch (this) {
    CommandIcon.melody => Icons.music_note_outlined,
    CommandIcon.light => Icons.lightbulb_outline,
    CommandIcon.church => Icons.church_outlined,
    CommandIcon.bell => Icons.notifications_active_outlined,
    CommandIcon.hammer => Icons.gavel_outlined,
  };

  String get label => switch (this) {
    CommandIcon.melody => 'Melodia',
    CommandIcon.light => 'Luce',
    CommandIcon.church => 'Chiesa',
    CommandIcon.bell => 'Distesa',
    CommandIcon.hammer => 'Martello',
  };
}

extension CommandColorStyle on CommandColor {
  Color get seed => switch (this) {
    CommandColor.green => const Color(0xFF18856B),
    CommandColor.amber => const Color(0xFFBE790A),
    CommandColor.purple => const Color(0xFF8054C5),
    CommandColor.blue => const Color(0xFF217DB3),
  };

  String get label => switch (this) {
    CommandColor.green => 'Verde',
    CommandColor.amber => 'Ambra',
    CommandColor.purple => 'Viola',
    CommandColor.blue => 'Azzurro',
  };
}
