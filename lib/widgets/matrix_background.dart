import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class MatrixBackground extends StatefulWidget {
  const MatrixBackground({super.key});

  @override
  State<MatrixBackground> createState() => _MatrixBackgroundState();
}

class _MatrixBackgroundState extends State<MatrixBackground> {
  final List<MatrixColumn> _columns = [];
  final Random _random = Random();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeColumns();
    _startAnimation();
  }

  void _initializeColumns() {
    for (int i = 0; i < 20; i++) {
      _columns.add(MatrixColumn(
        x: i * 20.0,
        speed: _random.nextDouble() * 2 + 1,
        length: _random.nextInt(15) + 5,
      ));
    }
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          for (var column in _columns) {
            column.update();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return CustomPaint(
      painter: MatrixPainter(_columns, accentColor: accent),
      child: Container(),
    );
  }
}

class MatrixColumn {
  double x;
  double y = 0;
  final double speed;
  final int length;
  final List<String> chars = [];

  MatrixColumn({required this.x, required this.speed, required this.length}) {
    for (int i = 0; i < length; i++) {
      chars.add(String.fromCharCode(Random().nextInt(94) + 33));
    }
  }

  void update() {
    y += speed;
    if (y > 800) {
      y = -length * 20.0;
      // Regenerar caracteres
      for (int i = 0; i < length; i++) {
        chars[i] = String.fromCharCode(Random().nextInt(94) + 33);
      }
    }
  }
}

class MatrixPainter extends CustomPainter {
  final List<MatrixColumn> columns;
  final Color accentColor;

  MatrixPainter(this.columns, {required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (var column in columns) {
      for (int i = 0; i < column.chars.length; i++) {
        final yPos = column.y - i * 20.0;
        if (yPos > 0 && yPos < size.height) {
          final opacity = (column.chars.length - i) / column.chars.length;
          paint.color = accentColor.withOpacity(opacity * 0.6);

          textPainter.text = TextSpan(
            text: column.chars[i],
            style: TextStyle(
              color: paint.color,
              fontSize: 16,
              fontFamily: 'Courier',
              shadows: [
                Shadow(
                  color: accentColor,
                  blurRadius: 10,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(column.x, yPos));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}