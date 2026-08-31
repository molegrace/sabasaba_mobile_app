part of '../../../main.dart';

class WrongDirectionDetector {
  int _backwardCount = 0;

  bool processReading({
    required double progressDelta,
    required double movement,
    required double? speed,
  }) {
    final moving =
        movement >= NavigationConfig.minimumMovement || (speed ?? 0) >= 0.5;

    if (moving && progressDelta < -NavigationConfig.backwardTolerance) {
      _backwardCount++;
    } else if (progressDelta >= -NavigationConfig.backwardTolerance) {
      _backwardCount = 0;
    }

    return _backwardCount >= NavigationConfig.wrongDirectionReadings;
  }

  void reset() {
    _backwardCount = 0;
  }
}
