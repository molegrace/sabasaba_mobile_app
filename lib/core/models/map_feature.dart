part of '../../main.dart';

class MapFeature {
  MapFeature({
    required this.layer,
    required this.index,
    required this.featureId,
    required this.id,
    required this.code,
    required this.polygons,
    required this.lines,
    required this.points,
    required this.rawProperties,
    this.layerKey = '',
    this.layerName = '',
    this.layerColor = const Color(0xff0284c7),
    this.layerFill = const Color(0xff38bdf8),
  });

  final Layer layer;
  final int index;

  /// The database UUID of this feature (top-level `id` from the features table).
  final String? featureId;
  final Object? id;
  final String? code;
  final List<List<GeoPoint>> polygons;
  final List<List<GeoPoint>> lines;
  final List<GeoPoint> points;

  /// Full raw properties map from Supabase for use in the detail panel.
  final Map<String, dynamic> rawProperties;

  /// The editor key and display name supplied by the map manager.
  final String layerKey;
  final String layerName;
  final Color layerColor;
  final Color layerFill;

  String get key =>
      '${layer.name}-$index-${featureId ?? id ?? code ?? 'feature'}';

  String get shortCode {
    final raw = (code?.isNotEmpty ?? false) ? code! : '${id ?? index + 1}';
    return raw.replaceAll(RegExp('[^A-Za-z0-9]'), '').toUpperCase();
  }

  String get title {
    if (layer == Layer.building) {
      if (code != null && code!.isNotEmpty) {
        return code!;
      }
      return 'Area ${index + 1}';
    }
    if (layer == Layer.road) {
      return 'Route ${id ?? index + 1}';
    }
    return '${layer.label} ${id ?? index + 1}';
  }

  List<String> get services {
    final numeric = int.tryParse('${id ?? index + 1}') ?? index + 1;
    const groups = [
      ['Trade booth', 'Product display', 'Visitor support'],
      ['Food court', 'Refreshments', 'Seating nearby'],
      ['Business services', 'Information desk', 'Registration'],
      ['Agriculture pavilion', 'Equipment demo', 'Supplier stands'],
      ['Retail showcase', 'Payments', 'Customer care'],
      ['Technology zone', 'Device demo', 'Connectivity help'],
    ];
    return groups[numeric.abs() % groups.length];
  }

  String get serviceLine => services.join('  |  ');

  String get searchText {
    return [
      title,
      shortCode,
      code,
      id,
      ...services,
    ].whereType<Object>().join(' ').toLowerCase();
  }

  Iterable<GeoPoint> get allPoints sync* {
    for (final polygon in polygons) {
      yield* polygon;
    }
    for (final line in lines) {
      yield* line;
    }
    yield* points;
  }

  GeoPoint get center {
    final items = allPoints.toList();
    final lng =
        items.map((point) => point.lng).reduce((a, b) => a + b) / items.length;
    final lat =
        items.map((point) => point.lat).reduce((a, b) => a + b) / items.length;
    return GeoPoint(lng, lat);
  }

  factory MapFeature.fromJson(
    Map<String, dynamic> feature,
    Layer layer,
    int index, {
    String? colorHex,
    String? fillHex,
    String layerKey = '',
    String layerName = '',
  }) {
    final featureId = feature['id'] as String?; // database UUID
    final properties = feature['properties'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(feature['properties'] as Map)
        : <String, dynamic>{
            if (feature['public_id'] != null) 'id': feature['public_id'],
            if (feature['label'] != null) 'name': feature['label'],
            if (feature['code'] != null) 'code': feature['code'],
            if (feature['status'] != null) 'status': feature['status'],
          };
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final type = geometry['type'] as String;
    final coordinates = geometry['coordinates'];

    final polygons = <List<GeoPoint>>[];
    final lines = <List<GeoPoint>>[];
    final points = <GeoPoint>[];

    if (type == 'Polygon') {
      for (final ring in coordinates as List<dynamic>) {
        polygons.add(_parseLine(ring as List<dynamic>));
      }
    } else if (type == 'MultiPolygon') {
      for (final polygonGroup in coordinates as List<dynamic>) {
        for (final ring in polygonGroup as List<dynamic>) {
          polygons.add(_parseLine(ring as List<dynamic>));
        }
      }
    } else if (type == 'LineString') {
      lines.add(_parseLine(coordinates as List<dynamic>));
    } else if (type == 'MultiLineString') {
      for (final line in coordinates as List<dynamic>) {
        lines.add(_parseLine(line as List<dynamic>));
      }
    } else if (type == 'Point') {
      points.add(_parsePoint(coordinates as List<dynamic>));
    }

    final nameVal =
        properties['name'] ??
        properties['booth_code'] ??
        properties['number'] ??
        properties['1'] ??
        properties['id'];

    final cHex = colorHex ?? properties['color']?.toString();
    final fHex = fillHex ?? properties['fill']?.toString();

    final defaultColor = layer == Layer.road
        ? const Color(0xff34d399)
        : (layer == Layer.boundary
              ? const Color(0xff0f766e)
              : (layer == Layer.tree
                    ? const Color(0xff059669)
                    : const Color(0xff374151)));

    final defaultFill = layer == Layer.road
        ? const Color(0xff34d399)
        : (layer == Layer.boundary
              ? const Color(0x220d9488)
              : (layer == Layer.tree
                    ? const Color(0xff10b981)
                    : const Color(0xff949e9b)));

    return MapFeature(
      layer: layer,
      index: index,
      featureId: featureId,
      id: properties['id'],
      code: nameVal?.toString(),
      polygons: polygons,
      lines: lines,
      points: points,
      rawProperties: properties,
      layerKey: layerKey,
      layerName: layerName,
      layerColor: _parseHexColor(cHex, defaultColor),
      layerFill: _parseHexColor(fHex, defaultFill),
    );
  }

  static Color _parseHexColor(String? colorStr, Color fallback) {
    if (colorStr == null || colorStr.trim().isEmpty) return fallback;
    final str = colorStr.trim();
    if (str.startsWith('#')) {
      final hex = str.replaceAll('#', '');
      if (hex.length == 6) {
        final val = int.tryParse('ff$hex', radix: 16);
        if (val != null) return Color(val);
      } else if (hex.length == 8) {
        final val = int.tryParse(hex, radix: 16);
        if (val != null) return Color(val);
      }
    }
    return fallback;
  }

  static List<GeoPoint> _parseLine(List<dynamic> line) {
    return line.map((point) => _parsePoint(point as List<dynamic>)).toList();
  }

  static GeoPoint _parsePoint(List<dynamic> value) {
    return GeoPoint((value[0] as num).toDouble(), (value[1] as num).toDouble());
  }
}

enum Layer {
  building('Area'),
  road('Road'),
  tree('Tree'),
  boundary('Boundary');

  const Layer(this.label);
  final String label;
}

enum MapTileStyle {
  openStreetMap(
    'OpenStreetMap',
    Icons.map_outlined,
    Color(0xfff2efe9),
    Color(0xff5c8f6c),
    19,
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  ),
  satellite(
    'Satellite',
    Icons.satellite_alt_outlined,
    Color(0xff243327),
    Color(0xff697a48),
    19,
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  ),
  terrain(
    'Terrain',
    Icons.terrain_outlined,
    Color(0xffe3ead7),
    Color(0xff6d9467),
    17,
    'https://tile.opentopomap.org/{z}/{x}/{y}.png',
  ),
  light(
    'Light',
    Icons.wb_sunny_outlined,
    Color(0xfff4f6f2),
    Color(0xff87968d),
    20,
    'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
  );

  const MapTileStyle(
    this.label,
    this.icon,
    this.fallbackColor,
    this.accentColor,
    this.maxNativeZoom,
    this.urlTemplate,
  );

  final String label;
  final IconData icon;
  final Color accentColor;
  final Color fallbackColor;

  /// Highest zoom level for which the provider has real tile imagery.
  ///
  /// Above this level the navigator scales the highest-resolution tiles, just
  /// like Leaflet's `maxNativeZoom` option on the web navigator.
  final int maxNativeZoom;
  final String urlTemplate;

  String tileUrl(int x, int y, int z) {
    return urlTemplate
        .replaceAll('{z}', '$z')
        .replaceAll('{x}', '$x')
        .replaceAll('{y}', '$y');
  }
}
