import 'package:geolocator/geolocator.dart';

class Node {
  final String name;
  final String mission;
  final double lat;
  final double lon;

  Node(this.name, this.mission, this.lat, this.lon);
}

class NodeService {
  final List<Node> nodes = [
    Node("Nodo Alpha (Centro Histórico)", "Hackear servidor de notas", 4.695610, -74.217093),
    Node("Nodo Beta (Parque Principal)", "Interceptar señal de radio", 4.736500, -74.256500),
    Node("Nodo Gamma (Zona Industrial)", "Sabotaje de drones", 4.734900, -74.253900),
  ];

  Future<Node?> getNearestNode(Position userPos) async {
    Node? nearest;
    double minDistance = double.infinity;

    for (var node in nodes) {
      double distance = Geolocator.distanceBetween(
        userPos.latitude,
        userPos.longitude,
        node.lat,
        node.lon,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearest = node;
      }
    }
    return nearest;
  }

  Future<Node?> getNearestNodeInRange(Position userPos, double maxDistance) async {
    Node? nearest;
    double minDistance = double.infinity;

    for (var node in nodes) {
      double distance = Geolocator.distanceBetween(
        userPos.latitude,
        userPos.longitude,
        node.lat,
        node.lon,
      );
      if (distance <= maxDistance && distance < minDistance) {
        minDistance = distance;
        nearest = node;
      }
    }
    return nearest;
  }
}