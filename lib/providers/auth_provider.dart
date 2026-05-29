import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:vibration/vibration.dart';

class AuthProvider extends ChangeNotifier {
  final LocalAuthentication auth = LocalAuthentication();

  bool _isAuthenticated = false;
  int _failedAttempts = 0;
  bool _isLocked = false;
  String _statusMessage = "";

  bool get isAuthenticated => _isAuthenticated;
  bool get isLocked => _isLocked;
  String get statusMessage => _statusMessage;

  // Metodo de autenticacion biometrica
  Future<void> authenticate() async {
    if (_isLocked) return;

    try {
      bool canCheck = await auth.canCheckBiometrics;
      bool isSupported = await auth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        debugPrint("Biometría no disponible");
        _statusMessage = "⚠️ Biometría no disponible en este dispositivo";
        notifyListeners();
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Escanea tu huella para acceder a ShadowNet',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        _isAuthenticated = true;
        _failedAttempts = 0;
        _statusMessage = "";
        debugPrint("✅ Autenticación exitosa");
      } else {
        _failedAttempts++;
        debugPrint("❌ Intento fallido: $_failedAttempts de 3");
        _statusMessage = "❌ Huella no reconocida. Intentos fallidos: $_failedAttempts/3";

        if (_failedAttempts >= 3) {
          await _triggerSelfDestruct();
          return;
        }
      }

      notifyListeners();
    } on PlatformException catch (e) {
      debugPrint("ERROR BIOMETRIA: ${e.code} - ${e.message}");

      if (e.code.contains('LockedOut') || e.code.contains('PermanentlyLockedOut')) {
        _failedAttempts = 3;
        _statusMessage = "⚠️ Autenticación bloqueada por demasiados intentos";
        notifyListeners();
        await _triggerSelfDestruct();
        return;
      }

      if (e.code == 'NotEnrolled' ||
          e.code == 'NotAvailable' ||
          e.code == 'PasscodeNotSet') {
        _statusMessage = "⚠️ Biometría no disponible: ${e.message}";
        notifyListeners();
        return;
      }

      if (e.code == 'LockedOut' ||
          e.code == 'UserCanceled' ||
          e.code == 'AppCanceled') {
        _statusMessage = "❌ Autenticación cancelada o bloqueada";
        notifyListeners();
        return;
      }

      _statusMessage = "⚠️ Error de biometría: ${e.message}";
      notifyListeners();
    } catch (e) {
      debugPrint("ERROR BIOMETRIA GENERAL: $e");
      _statusMessage = "⚠️ Error inesperado: $e";
      notifyListeners();
    }
  }

  // Metodo de autodestruccion
  Future<void> _triggerSelfDestruct() async {
    _isAuthenticated = false;
    _isLocked = true;
    _statusMessage = "⚠️ PROTOCOLO DE AUTODESTRUCCIÓN INICIADO\n🔐 BLOQUEADO 5 SEGUNDOS";
    
    debugPrint("🚨 AUTODESTRUCCIÓN ACTIVADA - Vibrando 5 segundos");
    notifyListeners();

    if (await Vibration.hasVibrator()) {
      try {
        await Vibration.vibrate(duration: 5000);
      } catch (e) {
        debugPrint("Error al vibrar: $e");
      }
    }

    await Future.delayed(const Duration(seconds: 5));

    _failedAttempts = 0;
    _isLocked = false;
    _statusMessage = "✅ Sistema desbloqueado. Intenta nuevamente.";
    debugPrint("✅ Sistema desbloqueado");

    notifyListeners();
  }

  // Metodo de logout
  void logout() {
    _isAuthenticated = false;
    _statusMessage = "🔒 Sesión cerrada";
    notifyListeners();
  }
}