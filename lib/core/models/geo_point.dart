part of '../../main.dart';

class GeoPoint {
  const GeoPoint(this.lng, this.lat);

  final double lng;
  final double lat;

  double get latitude => lat;
  double get longitude => lng;
}


class GeoBounds {
  const GeoBounds({
    required this.minLng,
    required this.maxLng,
    required this.minLat,
    required this.maxLat,
  });

  final double minLng;
  final double maxLng;
  final double minLat;
  final double maxLat;

  factory GeoBounds.fromPoints(List<GeoPoint> points) {
    return GeoBounds(
      minLng: points.map((point) => point.lng).reduce(math.min),
      maxLng: points.map((point) => point.lng).reduce(math.max),
      minLat: points.map((point) => point.lat).reduce(math.min),
      maxLat: points.map((point) => point.lat).reduce(math.max),
    );
  }
}

class MapProjection {
  MapProjection({required this.bounds, required this.size});

  final GeoBounds bounds;
  final Size size;

  Rect get mapRect {
    final metrics = _metrics;
    return Rect.fromLTWH(
      metrics.left,
      metrics.top,
      metrics.mapWidth,
      metrics.mapHeight,
    );
  }

  GeoBounds get visibleBounds {
    return GeoBounds.fromPoints([
      unproject(Offset.zero),
      unproject(Offset(size.width, 0)),
      unproject(Offset(size.width, size.height)),
      unproject(Offset(0, size.height)),
    ]);
  }

  Offset project(GeoPoint point) {
    final metrics = _metrics;
    final x = metrics.left + (point.lng - bounds.minLng) * metrics.scale;
    final y = metrics.top + (bounds.maxLat - point.lat) * metrics.scale;
    return Offset(x, y);
  }

  GeoPoint unproject(Offset point) {
    final metrics = _metrics;
    final lng = bounds.minLng + (point.dx - metrics.left) / metrics.scale;
    final lat = bounds.maxLat - (point.dy - metrics.top) / metrics.scale;
    return GeoPoint(lng, lat);
  }

  ProjectionMetrics get _metrics {
    const padding = 64.0;
    final availableWidth = math.max(1.0, size.width - padding * 2);
    final availableHeight = math.max(1.0, size.height - padding * 2);
    final lngRange = math.max(0.000001, bounds.maxLng - bounds.minLng);
    final latRange = math.max(0.000001, bounds.maxLat - bounds.minLat);
    final scale = math.min(
      availableWidth / lngRange,
      availableHeight / latRange,
    );
    final mapWidth = lngRange * scale;
    final mapHeight = latRange * scale;
    final left = (size.width - mapWidth) / 2;
    final top = (size.height - mapHeight) / 2;
    return ProjectionMetrics(
      left: left,
      top: top,
      scale: scale,
      mapWidth: mapWidth,
      mapHeight: mapHeight,
    );
  }
}

class ProjectionMetrics {
  const ProjectionMetrics({
    required this.left,
    required this.top,
    required this.scale,
    required this.mapWidth,
    required this.mapHeight,
  });

  final double left;
  final double top;
  final double scale;
  final double mapWidth;
  final double mapHeight;
}
