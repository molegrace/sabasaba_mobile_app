part of '../../../main.dart';

class PolylineMatcher {
  const PolylineMatcher();

  static RouteMatch? matchPositionToRoute(
    GeoPoint point,
    List<GeoPoint> route,
  ) {
    if (route.length < 2) return null;
    final segmentLengths = <double>[];
    for (var index = 0; index < route.length - 1; index++) {
      segmentLengths.add(geoDistanceMeters(route[index], route[index + 1]));
    }
    final totalDistance = segmentLengths.fold<double>(
      0,
      (sum, item) => sum + item,
    );
    var completedBeforeSegment = 0.0;
    RouteMatch? best;
    for (var index = 0; index < route.length - 1; index++) {
      final projection = _projectOntoSegment(
        point,
        route[index],
        route[index + 1],
      );
      final distance = geoDistanceMeters(point, projection.projected);
      final progress =
          completedBeforeSegment + segmentLengths[index] * projection.fraction;
      if (best == null || distance < best.distanceFromRoute) {
        best = RouteMatch(
          projectedPosition: projection.projected,
          distanceFromRoute: distance,
          progressDistance: progress,
          remainingDistance: math.max(0, totalDistance - progress),
          totalDistance: totalDistance,
          segmentIndex: index,
          remainingRoute: [projection.projected, ...route.skip(index + 1)],
        );
      }
      completedBeforeSegment += segmentLengths[index];
    }
    return best;
  }

  static RouteMatch? matchPositionAtDistance(
    List<GeoPoint> route,
    double progressDistance,
  ) {
    if (route.length < 2) return null;
    var totalDistance = 0.0;
    for (var index = 0; index < route.length - 1; index++) {
      totalDistance += geoDistanceMeters(route[index], route[index + 1]);
    }
    final target = progressDistance.clamp(0.0, totalDistance).toDouble();
    var completed = 0.0;
    for (var index = 0; index < route.length - 1; index++) {
      final segmentLength = geoDistanceMeters(route[index], route[index + 1]);
      if (completed + segmentLength >= target) {
        final fraction = segmentLength == 0
            ? 0.0
            : (target - completed) / segmentLength;
        final projected = GeoPoint(
          route[index].lng +
              (route[index + 1].lng - route[index].lng) * fraction,
          route[index].lat +
              (route[index + 1].lat - route[index].lat) * fraction,
        );
        return RouteMatch(
          projectedPosition: projected,
          distanceFromRoute: 0,
          progressDistance: target,
          remainingDistance: totalDistance - target,
          totalDistance: totalDistance,
          segmentIndex: index,
          remainingRoute: [projected, ...route.skip(index + 1)],
        );
      }
      completed += segmentLength;
    }
    return null;
  }
}
