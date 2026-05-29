import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/faction_provider.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final factionProvider = context.watch<FactionProvider>();

    return Semantics(
      label: "Imagen: Logo facción ${factionProvider.currentFaction}",
      child: Image.asset(
        factionProvider.currentLogo,
        height: 120,
      ),
    );
  }
}
