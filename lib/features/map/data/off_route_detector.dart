part of '../../../main.dart';

class OffRouteDetector {
  int _offRouteCount = 0;
  int _recoveryCount = 0;

  ({bool isOffRoute, bool isRecovered}) processReading({
    required double distanceFromRoute,
    required double accuracy,
  }) {
    final effectiveOffRouteDistance = math.max(
      NavigationConfig.offRouteDistance,
      accuracy * 1.25,
    );
    final effectiveRecoveryDistance = math.max(
      NavigationConfig.recoveryDistance,
      accuracy,
    );

    if (distanceFromRoute > effectiveOffRouteDistance) {
      _offRouteCount++;
      _recoveryCount = 0;
    } else if (distanceFromRoute <= effectiveRecoveryDistance) {
      _recoveryCount++;
      _offRouteCount = 0;
    }

    return (
      isOffRoute: _offRouteCount >= NavigationConfig.offRouteReadings,
      isRecovered: _recoveryCount >= NavigationConfig.recoveryReadings,
    );
  }

  void reset() {
    _offRouteCount = 0;
    _recoveryCount = 0;
  }
}
