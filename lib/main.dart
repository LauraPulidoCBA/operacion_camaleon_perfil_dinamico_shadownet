"import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/faction_provider.dart';
import 'screens/main_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FactionProvider()),
      ],
      child: const ShadowNetApp(),
    ),
  );
}

class ShadowNetApp extends StatelessWidget {
  const ShadowNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final factionProvider = context.watch<FactionProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShadowNet + Operación Camaleón',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: factionProvider.themeColor,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.jetBrainsMonoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const MainScreen(), // Aquí sigue arrancando ShadowNet
      routes: {
        '/profile': (context) => const ProfileScreen(), // Nueva pantalla
      },
    );
  }
}"