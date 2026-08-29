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

/// Offering model for products and services provided by exhibitors.
class Offering {
  final String? id;
  final String? type; // 'product' | 'service' | 'offering'
  final String? title;
  final String? description;
  final String? priceText;
  final String? imageUrl;

  Offering({
    this.id,
    this.type,
    this.title,
    this.description,
    this.priceText,
    this.imageUrl,
  });

  factory Offering.fromJson(Map<String, dynamic> json) {
    return Offering(
      id: json['id'] as String?,
      type: json['type'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      priceText: json['priceText'] as String? ?? json['price_text'] as String?,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'priceText': priceText,
      'imageUrl': imageUrl,
    };
  }
}

/// City driving route result from OSRM API combined with indoor fairground path.
class CityRouteResult {
  final double distance;
  final double duration;
  final List<GeoPoint> coordinates;
  final double walkingDistance;
  final double walkingDuration;
  final String destinationId;
  final String destinationLabel;

  CityRouteResult({
    required this.distance,
    required this.duration,
    required this.coordinates,
    required this.walkingDistance,
    required this.walkingDuration,
    required this.destinationId,
    required this.destinationLabel,
  });
}

/// A navigable location derived from a map feature.
/// Includes rich metadata for the navigator detail panel.
class RoutingLocation {
  final String id; // database feature UUID
  final String? featureId;
  final String label;
  final String description;
  final GeoPoint position;
  final String nodeId;
  final String layerName;
  final String? companyName;
  final String? industry;
  final List<String>? industries;
  final String? logoUrl;
  final List<dynamic>? photos;
  final List<dynamic>? team;
  final List<Offering>? offerings;
  final List<String>? searchTerms;
  final Map<String, dynamic> properties;

  RoutingLocation({
    required this.id,
    this.featureId,
    required this.label,
    required this.description,
    required this.position,
    required this.nodeId,
    this.layerName = '',
    this.companyName,
    this.industry,
    this.industries,
    this.logoUrl,
    this.photos,
    this.team,
    this.offerings,
    this.searchTerms,
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

/// Finds a mapped route. When the destination is in a disconnected road
/// section, returns only the existing-road path that gets closest to it.
RouteResult? findNavigableRoute(
  String startId,
  String endId,
  List<RoutingNode> nodes,
  List<RoutingEdge> edges,
) {
  final connected = shortestPath(startId, endId, edges);
  if (connected != null) return connected;

  final nodeById = {for (final n in nodes) n.id: n};
  final destinationNode = nodeById[endId];
  if (!nodeById.containsKey(startId) || destinationNode == null) return null;

  double distanceBetween(RoutingNode left, RoutingNode right) {
    const earthRadiusMeters = 6371000.0;
    double toRadians(double deg) => (deg * math.pi) / 180.0;
    final latDelta = toRadians(right.latitude - left.latitude);
    final lngDelta = toRadians(right.longitude - left.longitude);
    final leftLat = toRadians(left.latitude);
    final rightLat = toRadians(right.latitude);
    final haversine = math.sin(latDelta / 2) * math.sin(latDelta / 2) +
        math.cos(leftLat) *
            math.cos(rightLat) *
            math.sin(lngDelta / 2) *
            math.sin(lngDelta / 2);
    final bounded = math.min(1.0, math.max(0.0, haversine));
    return earthRadiusMeters * 2 * math.atan2(math.sqrt(bounded), math.sqrt(1.0 - bounded));
  }

  if (edges.isEmpty) return null;
  final graph = <String, List<MapEntry<String, double>>>{};
  void connect(String source, String target, double dist) {
    graph.putIfAbsent(source, () => []).add(MapEntry(target, dist));
  }
  for (final edge in edges) {
    final src = edge.sourceNodeId;
    final dst = edge.targetNodeId;
    if (src == null || dst == null) continue;
    connect(src, dst, edge.distance);
    if (edge.bidirectional) connect(dst, src, edge.distance);
  }

  final distances = <String, double>{startId: 0.0};
  final previous = <String, String>{};
  final pending = <String>{startId};

  while (pending.isNotEmpty) {
    String? current;
    var currentDistance = double.infinity;
    for (final nid in pending) {
      final d = distances[nid] ?? double.infinity;
      if (d < currentDistance) {
        current = nid;
        currentDistance = d;
      }
    }
    if (current == null) break;
    pending.remove(current);

    for (final neighbor in graph[current] ?? const []) {
      final neighborId = neighbor.key;
      final neighborDist = neighbor.value;
      final nextDist = currentDistance + neighborDist;
      if (nextDist < (distances[neighborId] ?? double.infinity)) {
        distances[neighborId] = nextDist;
        previous[neighborId] = current;
        pending.add(neighborId);
      }
    }
  }

  String closestReachableId = startId;
  var closestDistance = double.infinity;

  for (final reachableId in distances.keys) {
    final reachableNode = nodeById[reachableId];
    if (reachableNode == null) continue;
    final destDist = distanceBetween(reachableNode, destinationNode);
    if (destDist < closestDistance) {
      closestReachableId = reachableId;
      closestDistance = destDist;
    }
  }

  final dist = distances[closestReachableId];
  if (dist == null) return null;

  final nodeIds = <String>[closestReachableId];
  while (nodeIds.first != startId) {
    final predecessor = previous[nodeIds.first];
    if (predecessor == null) return null;
    nodeIds.insert(0, predecessor);
  }

  return RouteResult(nodeIds: nodeIds, distance: dist);
}

/// Returns walking time label for a distance in meters.
/// Matches the web navigator's walkingTimeLabel function.
String walkingTimeLabel(double distanceMeters) {
  final minutes = math.max(1, (distanceMeters / (5000 / 60)).ceil());
  return '~$minutes minute${minutes == 1 ? '' : 's'}';
}

/// Returns travel time label for city + walking duration in seconds.
String travelTimeLabel(double durationSeconds) {
  final minutes = math.max(1, (durationSeconds / 60).round());
  if (minutes < 60) return '~$minutes min';
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  return '~$hours hr${remainingMinutes > 0 ? ' $remainingMinutes min' : ''}';
}

