import 'package:flutter/material.dart';

import '../models/command_button_config.dart';
import 'command_button_style.dart';

class CommandButton extends StatelessWidget {
  const CommandButton({
    super.key,
    required this.config,
    required this.onPressed,
    this.isBusy = false,
  });

  final CommandButtonConfig config;
  final VoidCallback? onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(
      seedColor: config.color.seed,
      brightness: Theme.of(context).brightness,
    );
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        minimumSize: const Size.fromHeight(104),
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Row(
        children: [
          if (isBusy)
            const SizedBox.square(
              dimension: 26,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(config.icon.data, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              config.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: onPressed == null ? null : colors.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
