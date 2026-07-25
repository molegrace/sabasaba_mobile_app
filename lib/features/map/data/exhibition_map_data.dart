part of '../../../main.dart';

/// Lightweight metadata about the active exhibition fetched from Supabase.
class Exhibition {
  const Exhibition({
    required this.id,
    required this.title,
    required this.status,
    this.startDate,
    this.endDate,
    this.year,
  });

  final String id;
  final String title;
  final String status;
  final String? startDate;
  final String? endDate;
  final int? year;

  factory Exhibition.fromJson(Map<String, dynamic> json) {
    return Exhibition(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'SabaSaba Exhibition',
      status: json['status'] as String? ?? 'ongoing',
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      year: json['year'] as int?,
    );
  }
}

/// Internal helper for layer metadata.
class _LayerMeta {
  final String id;
  final String editorKey;
  final String name;
  final String? color;
  final String? fill;

  const _LayerMeta({
    required this.id,
    required this.editorKey,
    required this.name,
    this.color,
    this.fill,
  });
}

/// Internal helper for a raw navigable feature from Supabase.
class _RawFeature {
  final String id; // database UUID
  final String layerId;
  final Map<String, dynamic> geometry;
  final Map<String, dynamic> properties;

  const _RawFeature({
    required this.id,
    required this.layerId,
    required this.geometry,
    required this.properties,
  });

  factory _RawFeature.fromJson(Map<String, dynamic> json) {
    return _RawFeature(
      id: json['id'] as String,
      layerId: json['layer_id'] as String? ?? '',
      geometry: json['geometry'] as Map<String, dynamic>? ?? {},
      properties: json['properties'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Compute centroid of the feature's geometry.
  GeoPoint? get center {
    final coords = geometry['coordinates'];
    if (coords == null) return null;
    final positions = _collectGeoPoints(coords);
    if (positions.isEmpty) return null;
    final totalLng = positions.fold(0.0, (sum, p) => sum + p.lng);
    final totalLat = positions.fold(0.0, (sum, p) => sum + p.lat);
    return GeoPoint(totalLng / positions.length, totalLat / positions.length);
  }

  static List<GeoPoint> _collectGeoPoints(dynamic value) {
    if (value is! List) return [];
    if (value.length >= 2 && value[0] is num && value[1] is num) {
      return [
        GeoPoint(
          (value[0] as num).toDouble(),
          (value[1] as num).toDouble(),
        ),
      ];
    }
    return [for (final v in value) ..._collectGeoPoints(v)];
  }
}

class ExhibitionMapData {
  static const _supabaseUrl = 'https://iqmcidsxvbsbbukjloew.supabase.co/rest/v1';
  static const _supabaseKey = 'sb_publishable_AMEQ6X4TMeyGz1JlCledzg_9k2ojRkV';
  static const _headers = {
    'apikey': _supabaseKey,
    'Authorization': 'Bearer $_supabaseKey',
    'Accept': 'application/json',
  };

  ExhibitionMapData({
    required this.buildings,
    required this.roads,
    required this.trees,
    required this.boundaries,
    required this.bounds,
    required this.nodes,
    required this.edges,
    required this.locations,
    this.exhibition,
  });

  final List<MapFeature> buildings;
  final List<MapFeature> roads;
  final List<MapFeature> trees;
  final List<MapFeature> boundaries;
  final GeoBounds bounds;
  final List<RoutingNode> nodes;
  final List<RoutingEdge> edges;
  final List<RoutingLocation> locations;

  /// Metadata about the active exhibition.
  final Exhibition? exhibition;

  // ---------------------------------------------------------------------------
  // Load from Supabase — single source of truth
  // ---------------------------------------------------------------------------
  static Future<ExhibitionMapData> load() async {
    // 1. Find the latest ongoing or closed exhibition
    final exhibitionResponse = await http
        .get(
          Uri.parse(
            '$_supabaseUrl/exhibitions'
            '?status=in.(ongoing,closed)&order=start_date.desc&limit=1&select=*',
          ),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));

    _assertOk(exhibitionResponse, 'exhibitions');
    final exhibitionList =
        jsonDecode(exhibitionResponse.body) as List<dynamic>;
    if (exhibitionList.isEmpty) {
      throw const FormatException(
        'No ongoing or closed exhibition found in the database.',
      );
    }
    final exhibition =
        Exhibition.fromJson(exhibitionList.first as Map<String, dynamic>);
    print('SabaSaba - Active exhibition: ${exhibition.title} (${exhibition.status})');

    // 2. Get the active map for this exhibition
    final mapResponse = await http
        .get(
          Uri.parse(
            '$_supabaseUrl/maps'
            '?exhibition_id=eq.${exhibition.id}&is_active=eq.true&limit=1&select=id',
          ),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));

    _assertOk(mapResponse, 'maps');
    final mapList = jsonDecode(mapResponse.body) as List<dynamic>;
    if (mapList.isEmpty) {
      throw FormatException(
        'No active map found for exhibition "${exhibition.title}".',
      );
    }
    final mapId = mapList.first['id'] as String;
    print('SabaSaba - Map ID: $mapId');

    // 3. Load all layers for this map (now includes name, color, fill)
    final layersResponse = await http
        .get(
          Uri.parse(
            '$_supabaseUrl/layers?map_id=eq.$mapId&select=id,editor_key,name,color,fill',
          ),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));

    _assertOk(layersResponse, 'layers');
    final layerList = jsonDecode(layersResponse.body) as List<dynamic>;
    print(
      'SabaSaba - Layers: ${layerList.map((l) => l['editor_key']).toList()}',
    );

    // Build lookup maps
    final layerIdByKey = <String, String>{};
    final layerMetaById = <String, _LayerMeta>{};
    final allLayerMeta = <_LayerMeta>[];

    for (final item in layerList) {
      final key = item['editor_key'] as String?;
      final id = item['id'] as String?;
      final name = item['name'] as String? ?? key ?? 'Unknown';
      final color = item['color'] as String?;
      final fill = item['fill'] as String?;
      if (key != null && id != null) {
        layerIdByKey[key] = id;
        final meta = _LayerMeta(
          id: id,
          editorKey: key,
          name: name,
          color: color,
          fill: fill,
        );
        layerMetaById[id] = meta;
        allLayerMeta.add(meta);
      }
    }

    // 4. Fetch canvas feature sets
    const buildingLayerKeys = ['booths', 'spaces', 'buildings'];
    final buildingLayerIds = buildingLayerKeys
        .map((k) => layerIdByKey[k])
        .whereType<String>()
        .toList();

    final roadLayerId = layerIdByKey['roads'];
    final treeLayerId = layerIdByKey['trees'];
    final boundaryLayerId = layerIdByKey['boundary'];

    // 5. Determine navigable layer IDs (all except roads/trees/boundary)
    const skipKeys = {'roads', 'boundary', 'trees'};
    final navigableLayerIds = allLayerMeta
        .where((l) => !skipKeys.contains(l.editorKey))
        .map((l) => l.id)
        .toList();

    // 6. Fetch all data in parallel
    final buildingsFuture = _fetchFeatures(buildingLayerIds, Layer.building);
    final roadsFuture = _fetchFeaturesForLayer(roadLayerId, Layer.road);
    final treesFuture = _fetchFeaturesForLayer(treeLayerId, Layer.tree);
    final boundariesFuture = _fetchFeaturesForLayer(boundaryLayerId, Layer.boundary);
    final nodesFuture = _fetchNodes(mapId);
    final edgesFuture = _fetchEdges(mapId);
    // Fetch all navigable features in a single request
    final navigableFeaturesFuture = navigableLayerIds.isNotEmpty
        ? _fetchNavigableFeatures(navigableLayerIds)
        : Future.value(<_RawFeature>[]);

    final buildings = await buildingsFuture;
    final roads = await roadsFuture;
    final trees = await treesFuture;
    final boundaries = await boundariesFuture;
    final nodes = await nodesFuture;
    final edges = await edgesFuture;
    final navigableFeatures = await navigableFeaturesFuture;

    print(
      'SabaSaba - buildings: ${buildings.length}, roads: ${roads.length}, '
      'trees: ${trees.length}, boundaries: ${boundaries.length}',
    );
    print('SabaSaba - nodes: ${nodes.length}, edges: ${edges.length}');
    print('SabaSaba - navigable features: ${navigableFeatures.length}');

    final allPoints = [
      for (final f in [...buildings, ...roads, ...trees, ...boundaries])
        ...f.allPoints,
    ];
    if (allPoints.isEmpty) {
      throw const FormatException('Map returned no renderable geometry.');
    }

    // 7. Build routing locations from ALL navigable layer features
    // Matches the web navigator's location-building logic.
    final locations = <RoutingLocation>[];
    if (nodes.isNotEmpty) {
      for (var i = 0; i < navigableFeatures.length; i++) {
        final rawFeature = navigableFeatures[i];
        final position = rawFeature.center;
        if (position == null) continue;

        final node = nearestNode(position, nodes);
        final layerMeta = layerMetaById[rawFeature.layerId];
        final layerName = layerMeta?.name ?? '';
        final props = rawFeature.properties;
        final companyName = props['company_name'] as String?;

        // Build label matching web's featureLabel function
        final baseValue = props['name'] ??
            props['booth_code'] ??
            props['number'] ??
            props['1'] ??
            props['id'];
        final labelText =
            baseValue != null ? baseValue.toString() : '$layerName ${i + 1}';
        final label =
            companyName != null ? '$labelText ($companyName)' : labelText;
        final description = companyName != null
            ? 'Exhibitor: $companyName • $layerName'
            : layerName;

        locations.add(
          RoutingLocation(
            id: rawFeature.id,
            label: label,
            description: description,
            position: position,
            nodeId: node.id,
            layerName: layerName,
            companyName: companyName,
            properties: props,
          ),
        );
      }
      locations.sort((a, b) => a.label.compareTo(b.label));
    }

    return ExhibitionMapData(
      buildings: buildings,
      roads: roads,
      trees: trees,
      boundaries: boundaries,
      bounds: GeoBounds.fromPoints(allPoints),
      nodes: nodes,
      edges: edges,
      locations: locations,
      exhibition: exhibition,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Fetches features from multiple layer IDs, merging them into one list.
  static Future<List<MapFeature>> _fetchFeatures(
    List<String> layerIds,
    Layer layer,
  ) async {
    final result = <MapFeature>[];
    for (final layerId in layerIds) {
      final fetched = await _fetchFeaturesForLayer(
        layerId,
        layer,
        indexOffset: result.length,
      );
      result.addAll(fetched);
    }
    return result;
  }

  /// Fetches features for a single layer ID (returns [] if layerId is null).
  static Future<List<MapFeature>> _fetchFeaturesForLayer(
    String? layerId,
    Layer layer, {
    int indexOffset = 0,
  }) async {
    if (layerId == null) return [];
    final response = await http
        .get(
          Uri.parse(
            '$_supabaseUrl/features'
            '?layer_id=eq.$layerId&select=id,geometry,properties',
          ),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    _assertOk(response, 'features[$layerId]');
    final list = jsonDecode(response.body) as List<dynamic>;
    return [
      for (var i = 0; i < list.length; i++)
        MapFeature.fromJson(
          list[i] as Map<String, dynamic>,
          layer,
          indexOffset + i,
        ),
    ];
  }

  /// Fetches raw features from multiple navigable layer IDs in one request.
  static Future<List<_RawFeature>> _fetchNavigableFeatures(
    List<String> layerIds,
  ) async {
    if (layerIds.isEmpty) return [];
    final idsStr = layerIds.join(',');
    final response = await http
        .get(
          Uri.parse(
            '$_supabaseUrl/features'
            '?layer_id=in.($idsStr)'
            '&select=id,layer_id,geometry,properties',
          ),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 15));
    _assertOk(response, 'navigable_features');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((item) => _RawFeature.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<RoutingNode>> _fetchNodes(String mapId) async {
    final response = await http
        .get(
          Uri.parse(
            '$_supabaseUrl/routing_nodes'
            '?map_id=eq.$mapId&select=id,latitude,longitude',
          ),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    _assertOk(response, 'routing_nodes');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((item) => RoutingNode.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<RoutingEdge>> _fetchEdges(String mapId) async {
    final response = await http
        .get(
          Uri.parse(
            '$_supabaseUrl/routing_edges'
            '?map_id=eq.$mapId'
            '&select=id,source_node_id,target_node_id,distance,bidirectional',
          ),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    _assertOk(response, 'routing_edges');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((item) => RoutingEdge.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static void _assertOk(http.Response response, String label) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Supabase $label returned ${response.statusCode}: ${response.body}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Map query helpers
  // ---------------------------------------------------------------------------

  List<MapFeature> searchBuildings(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return buildings;
    return buildings.where((f) => f.searchText.contains(normalized)).toList();
  }

  MapFeature? hitTest(Offset scenePoint, Size size) {
    final projection = projectionFor(size);
    for (final building in buildings.reversed) {
      for (final polygon in building.polygons) {
        final path = Path();
        for (var i = 0; i < polygon.length; i++) {
          final point = projection.project(polygon[i]);
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        if ((path..close()).contains(scenePoint)) return building;
      }
    }
    return null;
  }

  MapProjection projectionFor(Size size) {
    return MapProjection(bounds: bounds, size: size);
  }
}
