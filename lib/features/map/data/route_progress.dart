part of '../../../main.dart';

class RouteProgress {
  const RouteProgress({
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
