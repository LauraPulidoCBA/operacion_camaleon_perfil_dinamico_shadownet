import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/faction_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/logo_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // El provider se usa en widgets hijos si es necesario

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: "Pantalla de perfil del agente",
          child: Text(
            "Operación Camaleón",
            style: GoogleFonts.urbanist(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo central dinámico
            const LogoWidget(),
            const SizedBox(height: 30),

            // Selector de facción
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _FactionButton(label: "Hacker", logo: "assets/hacker.jpg"),
                SizedBox(width: 20),
                _FactionButton(label: "Enforcer", logo: "assets/enforcer.jpg"),
                SizedBox(width: 20),
                _FactionButton(label: "Ghost", logo: "assets/ghost.jpg"),
              ],
            ),

            const SizedBox(height: 40),

            // Botón de cerrar sesión
            Semantics(
              label: "Botón: Finalizar misión y borrar rastro",
              button: true,
              child: ElevatedButton(
                onPressed: () {
                  final authProvider = context.read<AuthProvider>();
                  authProvider.logout();

                  // Resetear facción al cerrar sesión
                  final factionProvider = context.read<FactionProvider>();
                  factionProvider.resetFaction();

                  Navigator.pop(context);
                },
                child: const Text("Cerrar Sesión"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactionButton extends StatelessWidget {
  final String label;
  final String logo;

  const _FactionButton({required this.label, required this.logo});

  @override
  Widget build(BuildContext context) {
    final factionProvider = context.read<FactionProvider>();

    return Semantics(
      label: "Botón: Seleccionar facción $label",
      button: true,
      child: ElevatedButton(
        onPressed: () async {
          await factionProvider.changeFaction(label, logo);
        },
        child: Text(label),
      ),
    );
  }
}
