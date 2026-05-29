import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/node_service.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/terminal_widget.dart';
import '../widgets/matrix_background.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Node? nearestNode;
  double? distance;
  Position? _lastPosition;
  bool _checkingLocation = false;
  bool _locationChecked = false;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLocationUpdates() async {
    if (_checkingLocation) return;
    _checkingLocation = true;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("GPS desactivado");
      setState(() {
        nearestNode = null;
        distance = null;
      });
      _checkingLocation = false;
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("Permiso denegado");
        _checkingLocation = false;
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint("Permisos bloqueados para siempre");
      _checkingLocation = false;
      return;
    }

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position pos) async {
      await _updateNearestNode(pos);
    }, onError: (error) {
      debugPrint('Error en stream de ubicación: $error');
    });

    _checkingLocation = false;
  }

  Future<void> _updateNearestNode(Position pos) async {
    _lastPosition = pos;

    NodeService service = NodeService();
    Node? node = await service.getNearestNodeInRange(pos, 500);

    double? newDistance;
    if (node != null) {
      newDistance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        node.lat,
        node.lon,
      );
    }

    if (!mounted) return;

    setState(() {
      nearestNode = node;
      distance = newDistance;
      _locationChecked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isAuthenticated) {
      if (_positionSubscription == null && !_checkingLocation) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _startLocationUpdates();
          }
        });
      }
    } else {
      _positionSubscription?.cancel();
      _positionSubscription = null;
    }

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            const MatrixBackground(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!authProvider.isLocked)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.greenAccent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => authProvider.authenticate(),
                        child: Text(
                          "🔐 ESCANEAR HUELLA",
                          style: TextStyle(
                            fontFamily: 'Courier',
                            color: Colors.greenAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.greenAccent,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: authProvider.isLocked ? Colors.redAccent : Colors.greenAccent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black.withOpacity(0.8),
                      boxShadow: [
                        BoxShadow(
                          color: (authProvider.isLocked ? Colors.redAccent : Colors.greenAccent).withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      authProvider.statusMessage.isEmpty
                          ? "Esperando autenticación..."
                          : authProvider.statusMessage,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        color: authProvider.isLocked ? Colors.redAccent : Colors.greenAccent,
                        fontSize: authProvider.isLocked ? 18 : 14,
                        fontWeight: authProvider.isLocked ? FontWeight.bold : FontWeight.normal,
                        shadows: [
                          Shadow(
                            color: authProvider.isLocked ? Colors.redAccent : Colors.greenAccent,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final allNodesDistances = _lastPosition != null
        ? NodeService().nodes.map((node) {
            return MapEntry(node, Geolocator.distanceBetween(
              _lastPosition!.latitude,
              _lastPosition!.longitude,
              node.lat,
              node.lon,
            ));
          }).toList()
        : <MapEntry<Node, double>>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "ShadowNet Terminal",
          style: TextStyle(
            fontFamily: 'Courier',
            color: Colors.greenAccent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.greenAccent,
                blurRadius: 10,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const MatrixBackground(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TerminalWidget(
                  message: nearestNode != null
                      ? "📡 Nodo Detectado: ${nearestNode!.name}\n"
                          "Misión: ${nearestNode!.mission}\n"
                          "Distancia: ${distance?.toStringAsFixed(0)} metros"
                      : _locationChecked
                          ? "🌍 No hay nodos disponibles a menos de 500 metros"
                          : "⏳ Buscando nodos...",
                  missionCompleted: nearestNode != null,
                ),
                const SizedBox(height: 20),

              // Botón para ir a la nueva pantalla de perfil dinámico
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                  child: const Text("Ir a Perfil Camaleón"),
                ),


                if (_lastPosition != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.black.withOpacity(0.8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tu ubicación: ${_lastPosition!.latitude.toStringAsFixed(6)}, ${_lastPosition!.longitude.toStringAsFixed(6)}",
                          style: TextStyle(
                            fontFamily: 'Courier',
                            color: Colors.greenAccent,
                            fontSize: 14,
                            shadows: [
                              Shadow(
                                color: Colors.greenAccent,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "NODOS DISPONIBLES:",
                          style: TextStyle(
                            fontFamily: 'Courier',
                            color: Colors.greenAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.greenAccent,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 240,
                          child: ListView.builder(
                            itemCount: allNodesDistances.length,
                            itemBuilder: (context, index) {
                              final entry = allNodesDistances[index];
                              final node = entry.key;
                              final dist = entry.value;
                              final isNear = dist <= 500;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isNear ? Colors.greenAccent : Colors.orangeAccent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.black.withOpacity(0.7),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isNear ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isNear ? Icons.gps_fixed : Icons.gps_not_fixed,
                                      color: isNear ? Colors.greenAccent : Colors.orangeAccent,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            node.name,
                                            style: TextStyle(
                                              fontFamily: 'Courier',
                                              color: isNear ? Colors.greenAccent : Colors.orangeAccent,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  color: isNear ? Colors.greenAccent : Colors.orangeAccent,
                                                  blurRadius: 5,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            node.mission,
                                            style: TextStyle(
                                              fontFamily: 'Courier',
                                              color: Colors.white70,
                                              fontSize: 12,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.white70,
                                                  blurRadius: 3,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "${dist.toStringAsFixed(0)} m",
                                          style: TextStyle(
                                            fontFamily: 'Courier',
                                            color: isNear ? Colors.greenAccent : Colors.orangeAccent,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              Shadow(
                                                color: isNear ? Colors.greenAccent : Colors.orangeAccent,
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isNear ? 'CERCANO' : 'FUERA DE RANGO',
                                          style: TextStyle(
                                            fontFamily: 'Courier',
                                            color: isNear ? Colors.greenAccent : Colors.orangeAccent,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}