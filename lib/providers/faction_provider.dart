import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class FactionProvider extends ChangeNotifier {
  String _currentFaction = "Hacker";
  String _currentLogo = "assets/hacker.jpg";
  Color _themeColor = Colors.greenAccent;

  String get currentFaction => _currentFaction;
  String get currentLogo => _currentLogo;
  Color get themeColor => _themeColor;

  Future<void> changeFaction(String faction, String logoPath) async {
    _currentFaction = faction;
    _currentLogo = logoPath;

    try {
      final PaletteGenerator palette = await PaletteGenerator.fromImageProvider(
        AssetImage(logoPath),
      );
      _themeColor = palette.dominantColor?.color ?? Colors.greenAccent;
    } catch (e) {
      _themeColor = Colors.greenAccent;
    }

    notifyListeners();
  }
}