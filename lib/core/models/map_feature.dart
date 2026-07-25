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

  String get key => '${layer.name}-$index-${featureId ?? id ?? code ?? 'feature'}';

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
    int index,
  ) {
    final featureId = feature['id'] as String?; // database UUID
    final properties = feature['properties'] as Map<String, dynamic>? ?? {};
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final type = geometry['type'] as String;
    final coordinates = geometry['coordinates'];

    final polygons = <List<GeoPoint>>[];
    final lines = <List<GeoPoint>>[];
    final points = <GeoPoint>[];

    if (type == 'MultiPolygon') {
      for (final polygonGroup in coordinates as List<dynamic>) {
        for (final ring in polygonGroup as List<dynamic>) {
          polygons.add(_parseLine(ring as List<dynamic>));
        }
      }
    } else if (type == 'MultiLineString') {
      for (final line in coordinates as List<dynamic>) {
        lines.add(_parseLine(line as List<dynamic>));
      }
    } else if (type == 'Point') {
      points.add(_parsePoint(coordinates as List<dynamic>));
    }

    final nameVal = properties['name'] ??
        properties['booth_code'] ??
        properties['number'] ??
        properties['1'] ??
        properties['id'];

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
    );
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
    17,
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  ),
  satellite(
    'Satellite',
    Icons.satellite_alt_outlined,
    Color(0xff243327),
    Color(0xff697a48),
    17,
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  ),
  terrain(
    'Terrain',
    Icons.terrain_outlined,
    Color(0xffe3ead7),
    Color(0xff6d9467),
    16,
    'https://tile.opentopomap.org/{z}/{x}/{y}.png',
  ),
  light(
    'Light',
    Icons.wb_sunny_outlined,
    Color(0xfff4f6f2),
    Color(0xff87968d),
    17,
    'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
  );

  const MapTileStyle(
    this.label,
    this.icon,
    this.fallbackColor,
    this.accentColor,
    this.zoom,
    this.urlTemplate,
  );

  final String label;
  final IconData icon;
  final Color accentColor;
  final Color fallbackColor;
  final int zoom;
  final String urlTemplate;

  String tileUrl(int x, int y, int z) {
    return urlTemplate
        .replaceAll('{z}', '$z')
        .replaceAll('{x}', '$x')
        .replaceAll('{y}', '$y');
  }
}
