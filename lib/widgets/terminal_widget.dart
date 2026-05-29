import 'package:flutter/material.dart';

class TerminalWidget extends StatelessWidget {
  final String message;
  final bool missionCompleted;

  const TerminalWidget({
    super.key,
    required this.message,
    this.missionCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: colorScheme.background.withOpacity(0.8),
      child: Text(
        message,
        style: TextStyle(
          fontFamily: 'Courier',
          color: missionCompleted ? colorScheme.secondary : colorScheme.primary,
          fontSize: 16,
          shadows: [
            Shadow(
              color: missionCompleted ? colorScheme.secondary : colorScheme.primary,
              blurRadius: 10,
            ),
          ],
        ),
      ),
    );
  }
}