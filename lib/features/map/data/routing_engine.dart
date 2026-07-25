part of '../../../main.dart';

class RoutingNode {
  final String id;
  final double latitude;
  final double longitude;

  RoutingNode({
    required this.id,
    required this.latitude,
    required this.longitude,
  });

  factory RoutingNode.fromJson(Map<String, dynamic> json) {
    return RoutingNode(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class RoutingEdge {
  final String id;
  final String? sourceNodeId;
  final String? targetNodeId;
  final double distance;
  final bool bidirectional;

  RoutingEdge({
    required this.id,
    this.sourceNodeId,
    this.targetNodeId,
    required this.distance,
    required this.bidirectional,
  });

  factory RoutingEdge.fromJson(Map<String, dynamic> json) {
    return RoutingEdge(
      id: json['id'] as String,
      sourceNodeId: json['source_node_id'] as String?,
      targetNodeId: json['target_node_id'] as String?,
      distance: (json['distance'] as num).toDouble(),
      bidirectional: json['bidirectional'] as bool? ?? true,
    );
  }
}

class RouteResult {
  final List<String> nodeIds;
  final double distance;

  RouteResult({required this.nodeIds, required this.distance});
}

/// A navigable location derived from a map feature.
/// Includes rich metadata for the navigator detail panel.
class RoutingLocation {
  final String id; // database feature UUID
  final String label;
  final String description;
  final GeoPoint position;
  final String nodeId;
  final String layerName;
  final String? companyName;
  final Map<String, dynamic> properties;

  RoutingLocation({
    required this.id,
    required this.label,
    required this.description,
    required this.position,
    required this.nodeId,
    this.layerName = '',
    this.companyName,
    this.properties = const {},
  });
}

RoutingNode nearestNode(GeoPoint position, List<RoutingNode> nodes) {
  var nearest = nodes.first;
  var nearestDistance = double.infinity;
  for (final node in nodes) {
    final lngDelta = node.longitude - position.lng;
    final latDelta = node.latitude - position.lat;
    final distance = lngDelta * lngDelta + latDelta * latDelta;
    if (distance < nearestDistance) {
      nearest = node;
      nearestDistance = distance;
    }
  }
  return nearest;
}

RouteResult? shortestPath(
  String startId,
  String endId,
  List<RoutingEdge> edges,
) {
  if (edges.isEmpty) return null;
  final graph = <String, List<MapEntry<String, double>>>{};

  void connect(String source, String target, double distance) {
    graph.putIfAbsent(source, () => []).add(MapEntry(target, distance));
  }

  for (final edge in edges) {
    final src = edge.sourceNodeId;
    final dst = edge.targetNodeId;
    if (src == null || dst == null) continue;
    connect(src, dst, edge.distance);
    if (edge.bidirectional) {
      connect(dst, src, edge.distance);
    }
  }

  final distances = <String, double>{startId: 0.0};
  final previous = <String, String>{};
  final pending = <String>{startId};

  while (pending.isNotEmpty) {
    String? current;
    var currentDistance = double.infinity;

    for (final nodeId in pending) {
      final d = distances[nodeId] ?? double.infinity;
      if (d < currentDistance) {
        current = nodeId;
        currentDistance = d;
      }
    }

    if (current == null) break;
    pending.remove(current);

    if (current == endId) break;

    final neighbors = graph[current] ?? const [];
    for (final neighbor in neighbors) {
      final neighborId = neighbor.key;
      final neighborDist = neighbor.value;
      final nextDistance = currentDistance + neighborDist;

      final currentNeighborDistance = distances[neighborId] ?? double.infinity;
      if (nextDistance < currentNeighborDistance) {
        distances[neighborId] = nextDistance;
        previous[neighborId] = current;
        pending.add(neighborId);
      }
    }
  }

  final distance = distances[endId];
  if (distance == null) return null;

  final nodeIds = <String>[endId];
  while (nodeIds.first != startId) {
    final predecessor = previous[nodeIds.first];
    if (predecessor == null) return null;
    nodeIds.insert(0, predecessor);
  }

  return RouteResult(nodeIds: nodeIds, distance: distance);
}

/// Returns walking time label for a distance in meters.
/// Matches the web navigator's walkingTimeLabel function.
String walkingTimeLabel(double distanceMeters) {
  final minutes = math.max(1, (distanceMeters / (5000 / 60)).ceil());
  return '~$minutes minute${minutes == 1 ? '' : 's'}';
}
