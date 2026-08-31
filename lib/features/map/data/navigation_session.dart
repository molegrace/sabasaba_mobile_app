part of '../../../main.dart';

class NavigationSession {
  NavigationSession({
    required this.destinationId,
    required this.destinationName,
    required this.route,
  }) {
    if (route.length >= 2) {
      _tracker = NavigationProgressTracker(route);
      _status = NavigationStatus.navigating;
    } else {
      _status = NavigationStatus.error;
    }
  }

  final String destinationId;
  final String destinationName;
  final List<GeoPoint> route;

  NavigationProgressTracker? _tracker;
  NavigationStatus _status = NavigationStatus.idle;
  NavigationProgress? _currentProgress;

  NavigationStatus get status => _status;
  NavigationProgress? get currentProgress => _currentProgress;

  NavigationProgress? processReading(NavigationReading reading) {
    if (_status == NavigationStatus.arrived ||
        _status == NavigationStatus.idle ||
        _tracker == null) {
      return _currentProgress;
    }

    if (!isNavigationReadingValid(reading)) {
      return _currentProgress;
    }

    final progress = _tracker!.update(reading);
    _currentProgress = progress;
    _status = progress.status;
    return progress;
  }

  void stop() {
    _status = NavigationStatus.idle;
    _currentProgress = null;
  }
}
