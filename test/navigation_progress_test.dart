import 'package:flutter_test/flutter_test.dart';
import 'package:sabasaba_mobile_app/main.dart';

void main() {
  const route = [
    GeoPoint(39.27, -6.86),
    GeoPoint(39.271, -6.86),
    GeoPoint(39.272, -6.86),
  ];

  NavigationReading reading(GeoPoint point, int index, {double accuracy = 4}) {
    return NavigationReading(
      position: point,
      accuracy: accuracy,
      timestamp: DateTime.fromMillisecondsSinceEpoch(index * 5000),
      speed: 1.2,
    );
  }

  test('validates current readings and rejects invalid or stale GPS data', () {
    final now = DateTime.fromMillisecondsSinceEpoch(100000);
    final current = NavigationReading(
      position: const GeoPoint(39.27, -6.86),
      accuracy: 4,
      timestamp: now,
      speed: 1,
      heading: 90,
    );
    final stale = NavigationReading(
      position: const GeoPoint(39.27, -6.86),
      accuracy: 4,
      timestamp: DateTime.fromMillisecondsSinceEpoch(1),
    );
    final invalid = NavigationReading(
      position: const GeoPoint(double.nan, -6.86),
      accuracy: 4,
      timestamp: now,
    );

    expect(isNavigationReadingValid(current, now: now), isTrue);
    expect(isNavigationReadingValid(stale, now: now), isFalse);
    expect(isNavigationReadingValid(invalid, now: now), isFalse);
  });

  test('projects onto and trims the route', () {
    final match = matchPositionToRoute(
      const GeoPoint(39.2705, -6.86001),
      route,
    )!;
    expect(match.segmentIndex, 0);
    expect(match.remainingRoute, hasLength(3));
    expect(match.progressDistance, greaterThan(50));
    expect(match.distanceFromRoute, lessThan(2));
  });

  test('remaining distance reduces while walking forward', () {
    final tracker = NavigationProgressTracker(route);
    final first = tracker.update(reading(const GeoPoint(39.2702, -6.86), 1));
    final second = tracker.update(reading(const GeoPoint(39.2712, -6.86), 2));
    expect(second.remainingDistance, lessThan(first.remainingDistance));
  });

  test('unreliable readings do not trigger off route', () {
    final tracker = NavigationProgressTracker(route);
    final progress = tracker.update(
      reading(const GeoPoint(39.27, -6.87), 1, accuracy: 80),
    );
    expect(progress.reliable, isFalse);
    expect(progress.status, NavigationStatus.navigating);
  });

  test('off route requires consecutive readings and recovers', () {
    final tracker = NavigationProgressTracker(route);
    tracker.update(reading(const GeoPoint(39.2702, -6.8603), 1));
    tracker.update(reading(const GeoPoint(39.2703, -6.8603), 2));
    expect(
      tracker.update(reading(const GeoPoint(39.2704, -6.8603), 3)).status,
      NavigationStatus.offRoute,
    );
    tracker.update(reading(const GeoPoint(39.2705, -6.86), 4));
    expect(
      tracker.update(reading(const GeoPoint(39.2706, -6.86), 5)).status,
      NavigationStatus.navigating,
    );
  });

  test('detects sustained backwards walking', () {
    final tracker = NavigationProgressTracker(route);
    tracker.update(reading(const GeoPoint(39.2716, -6.86), 1));
    tracker.update(reading(const GeoPoint(39.2715, -6.86), 2));
    tracker.update(reading(const GeoPoint(39.2713, -6.86), 3));
    expect(
      tracker.update(reading(const GeoPoint(39.2711, -6.86), 4)).status,
      NavigationStatus.wrongDirection,
    );
  });

  test('arrival requires two readings', () {
    final tracker = NavigationProgressTracker(route);
    expect(
      tracker.update(reading(const GeoPoint(39.27195, -6.86), 1)).status,
      NavigationStatus.navigating,
    );
    expect(
      tracker.update(reading(const GeoPoint(39.27199, -6.86), 2)).status,
      NavigationStatus.arrived,
    );
  });
}
