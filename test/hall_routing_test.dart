import 'package:flutter_test/flutter_test.dart';
import 'package:sabasaba_mobile_app/main.dart';

void main() {
  final hall = MapFeature(
    layer: Layer.building,
    index: 0,
    featureId: 'hall-1',
    id: 'hall-1',
    code: 'Hall 1',
    polygons: const [
      [
        GeoPoint(39.270, -6.861),
        GeoPoint(39.272, -6.861),
        GeoPoint(39.272, -6.859),
        GeoPoint(39.270, -6.859),
        GeoPoint(39.270, -6.861),
      ],
    ],
    lines: const [],
    points: const [],
    rawProperties: const {},
  );

  RoutingNode node(String id, double longitude, double latitude) {
    return RoutingNode(id: id, latitude: latitude, longitude: longitude);
  }

  RoutingEdge edge(String id, String source, String target) {
    return RoutingEdge(
      id: id,
      sourceNodeId: source,
      targetNodeId: target,
      distance: 100,
      bidirectional: true,
    );
  }

  test('excludes nodes strictly inside the hall', () {
    final result = findHallExteriorApproachNode(hall, [
      node('inside', 39.2701, -6.860),
      node('west-entrance', 39.2699, -6.860),
      node('farther-path', 39.2723, -6.860),
    ]);

    expect(result?.id, 'west-entrance');
    expect(
      isPositionStrictlyInsideHall(
        GeoPoint(result!.longitude, result.latitude),
        hall.polygons,
      ),
      isFalse,
    );
  });

  test(
    'uses a reachable exterior node instead of a disconnected closer node',
    () {
      final nodes = [
        node('gate', 39.268, -6.860),
        node('connected-approach', 39.2697, -6.860),
        node('disconnected-approach', 39.2699, -6.860),
      ];

      final result = findReachableHallExteriorApproachNode(
        hall: hall,
        nodes: nodes,
        edges: [edge('gate-path', 'gate', 'connected-approach')],
        networkAnchorNodeId: 'gate',
      );

      expect(result?.id, 'connected-approach');
    },
  );

  test('treats a hall boundary node as a valid doorway', () {
    expect(
      isPositionStrictlyInsideHall(
        const GeoPoint(39.270, -6.860),
        hall.polygons,
      ),
      isFalse,
    );
  });
}
