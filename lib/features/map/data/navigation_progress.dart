part of '../../../main.dart';

enum NavigationStatus {
  idle,
  locating,
  navigating,
  offRoute,
  wrongDirection,
  rerouting,
  arrived,
  error,
}

class NavigationConfig {
  static const maximumAccuracy = 30.0;
  static const maximumReadingAge = Duration(seconds: 30);
  static const futureReadingTolerance = Duration(seconds: 5);
  static const offRouteDistance = 20.0;
  static const recoveryDistance = 12.0;
  static const offRouteReadings = 3;
  static const recoveryReadings = 2;
  static const backwardTolerance = 7.0;
  static const wrongDirectionReadings = 3;
  static const minimumMovement = 3.0;
  static const arrivalDistance = 10.0;
  static const arrivalReadings = 2;
  static const onSiteNodeDistance = 120.0;
}

class NavigationReading {
  const NavigationReading({
    required this.position,
    required this.accuracy,
    required this.timestamp,
    this.speed,
    this.heading,
  });

  final GeoPoint position;
  final double accuracy;
  final DateTime timestamp;
  final double? speed;
  final double? heading;
}

bool isNavigationReadingValid(
  NavigationReading reading, {
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  final longitude = reading.position.lng;
  final latitude = reading.position.lat;
  return longitude.isFinite &&
      latitude.isFinite &&
      longitude >= -180 &&
      longitude <= 180 &&
      latitude >= -90 &&
      latitude <= 90 &&
      reading.accuracy.isFinite &&
      reading.accuracy >= 0 &&
      reading.timestamp.isAfter(
        currentTime.subtract(NavigationConfig.maximumReadingAge),
      ) &&
      reading.timestamp.isBefore(
        currentTime.add(NavigationConfig.futureReadingTolerance),
      );
}

class RouteMatch {
  const RouteMatch({
    required this.projectedPosition,
    required this.distanceFromRoute,
    required this.progressDistance,
    required this.remainingDistance,
    required this.totalDistance,
    required this.segmentIndex,
    required this.remainingRoute,
  });

  final GeoPoint projectedPosition;
  final double distanceFromRoute;
  final double progressDistance;
  final double remainingDistance;
  final double totalDistance;
  final int segmentIndex;
  final List<GeoPoint> remainingRoute;
}

class NavigationProgress {
  const NavigationProgress({
    required this.match,
    required this.status,
    required this.reliable,
    this.message,
  });

  final RouteMatch match;
  final NavigationStatus status;
  final bool reliable;
  final String? message;

  GeoPoint get projectedPosition => match.projectedPosition;
  double get distanceFromRoute => match.distanceFromRoute;
  double get progressDistance => match.progressDistance;
  double get remainingDistance => match.remainingDistance;
  int get segmentIndex => match.segmentIndex;
  List<GeoPoint> get remainingRoute => match.remainingRoute;
}

double geoDistanceMeters(GeoPoint left, GeoPoint right) {
  const earthRadiusMeters = 6371000.0;
  double toRadians(double degrees) => degrees * math.pi / 180;
  final latitudeDelta = toRadians(right.lat - left.lat);
  final longitudeDelta = toRadians(right.lng - left.lng);
  final leftLatitude = toRadians(left.lat);
  final rightLatitude = toRadians(right.lat);
  final haversine =
      math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
      math.cos(leftLatitude) *
          math.cos(rightLatitude) *
          math.sin(longitudeDelta / 2) *
          math.sin(longitudeDelta / 2);
  final bounded = math.min(1.0, math.max(0.0, haversine));
  return earthRadiusMeters *
      2 *
      math.atan2(math.sqrt(bounded), math.sqrt(1 - bounded));
}

({GeoPoint projected, double fraction}) _projectOntoSegment(
  GeoPoint point,
  GeoPoint start,
  GeoPoint end,
) {
  final referenceLatitude =
      ((point.lat + start.lat + end.lat) / 3) * math.pi / 180;
  final metersPerLongitudeDegree = 111320 * math.cos(referenceLatitude);
  const metersPerLatitudeDegree = 110540.0;
  final segmentX = (end.lng - start.lng) * metersPerLongitudeDegree;
  final segmentY = (end.lat - start.lat) * metersPerLatitudeDegree;
  final pointX = (point.lng - start.lng) * metersPerLongitudeDegree;
  final pointY = (point.lat - start.lat) * metersPerLatitudeDegree;
  final squaredLength = segmentX * segmentX + segmentY * segmentY;
  final fraction = squaredLength == 0
      ? 0.0
      : ((pointX * segmentX + pointY * segmentY) / squaredLength)
            .clamp(0.0, 1.0)
            .toDouble();
  return (
    projected: GeoPoint(
      start.lng + (end.lng - start.lng) * fraction,
      start.lat + (end.lat - start.lat) * fraction,
    ),
    fraction: fraction,
  );
}

RouteMatch? matchPositionToRoute(GeoPoint point, List<GeoPoint> route) {
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

RouteMatch? matchPositionAtDistance(
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
        route[index].lng + (route[index + 1].lng - route[index].lng) * fraction,
        route[index].lat + (route[index + 1].lat - route[index].lat) * fraction,
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

class NavigationProgressTracker {
  NavigationProgressTracker(this.route) {
    final initial = matchPositionToRoute(route.first, route);
    if (initial == null) {
      throw ArgumentError(
        'A navigation route requires at least two coordinates.',
      );
    }
    _lastProgress = NavigationProgress(
      match: initial,
      status: NavigationStatus.navigating,
      reliable: true,
    );
  }

  final List<GeoPoint> route;
  var _offRouteCount = 0;
  var _recoveryCount = 0;
  var _backwardCount = 0;
  var _arrivalCount = 0;
  var _displayedProgress = 0.0;
  NavigationReading? _previousReading;
  late NavigationProgress _lastProgress;

  NavigationProgress update(NavigationReading reading) {
    final match = matchPositionToRoute(reading.position, route);
    if (match == null) return _lastProgress;
    if (!reading.accuracy.isFinite ||
        reading.accuracy > NavigationConfig.maximumAccuracy) {
      _lastProgress = NavigationProgress(
        match: _lastProgress.match,
        status: _lastProgress.status,
        reliable: false,
        message: _lastProgress.message,
      );
      return _lastProgress;
    }

    final effectiveOffRouteDistance = math.max(
      NavigationConfig.offRouteDistance,
      reading.accuracy * 1.25,
    );
    final effectiveRecoveryDistance = math.max(
      NavigationConfig.recoveryDistance,
      reading.accuracy,
    );
    if (match.distanceFromRoute > effectiveOffRouteDistance) {
      _offRouteCount++;
      _recoveryCount = 0;
    } else if (match.distanceFromRoute <= effectiveRecoveryDistance) {
      _recoveryCount++;
      _offRouteCount = 0;
    }

    final previous = _previousReading;
    final movement = previous == null
        ? 0.0
        : geoDistanceMeters(previous.position, reading.position);
    final moving =
        movement >= NavigationConfig.minimumMovement ||
        (reading.speed ?? 0) >= 0.5;
    final progressDelta =
        match.progressDistance - _lastProgress.progressDistance;
    if (moving && progressDelta < -NavigationConfig.backwardTolerance) {
      _backwardCount++;
    } else if (progressDelta >= -NavigationConfig.backwardTolerance) {
      _backwardCount = 0;
    }

    _arrivalCount =
        match.remainingDistance <= NavigationConfig.arrivalDistance &&
            match.distanceFromRoute <= effectiveOffRouteDistance
        ? _arrivalCount + 1
        : 0;
    var status = NavigationStatus.navigating;
    String? message;
    if (_arrivalCount >= NavigationConfig.arrivalReadings) {
      status = NavigationStatus.arrived;
      message = 'You have arrived at your destination.';
    } else if (_offRouteCount >= NavigationConfig.offRouteReadings ||
        (_lastProgress.status == NavigationStatus.offRoute &&
            _recoveryCount < NavigationConfig.recoveryReadings)) {
      status = NavigationStatus.offRoute;
      message =
          'You are off the required path. Return to the highlighted route or recalculate.';
    } else if (_backwardCount >= NavigationConfig.wrongDirectionReadings) {
      status = NavigationStatus.wrongDirection;
      message =
          'You are moving away from the destination. Turn back toward the highlighted route.';
    } else if ((_lastProgress.status == NavigationStatus.offRoute ||
            _lastProgress.status == NavigationStatus.wrongDirection) &&
        _recoveryCount >= NavigationConfig.recoveryReadings) {
      message = 'You are back on the correct route.';
    }

    if (match.progressDistance >=
        _displayedProgress - NavigationConfig.backwardTolerance) {
      _displayedProgress = math.max(_displayedProgress, match.progressDistance);
    } else if (status == NavigationStatus.wrongDirection) {
      _displayedProgress = match.progressDistance;
    }
    final displayedMatch =
        matchPositionAtDistance(route, _displayedProgress) ?? match;
    _previousReading = reading;
    _lastProgress = NavigationProgress(
      match: RouteMatch(
        projectedPosition: displayedMatch.projectedPosition,
        distanceFromRoute: match.distanceFromRoute,
        progressDistance: displayedMatch.progressDistance,
        remainingDistance: displayedMatch.remainingDistance,
        totalDistance: displayedMatch.totalDistance,
        segmentIndex: displayedMatch.segmentIndex,
        remainingRoute: displayedMatch.remainingRoute,
      ),
      status: status,
      reliable: true,
      message: message,
    );
    return _lastProgress;
  }
}
