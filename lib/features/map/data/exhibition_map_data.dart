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
  final bool visible;

  const _LayerMeta({
    required this.id,
    required this.editorKey,
    required this.name,
    this.color,
    this.fill,
    this.visible = true,
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
    final rawProps = json['properties'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['properties'] as Map)
        : <String, dynamic>{
            if (json['public_id'] != null) 'id': json['public_id'],
            if (json['label'] != null) 'name': json['label'],
            if (json['code'] != null) 'code': json['code'],
            if (json['status'] != null) 'status': json['status'],
          };
    return _RawFeature(
      id: json['id'] as String,
      layerId: json['layer_id'] as String? ?? '',
      geometry: json['geometry'] as Map<String, dynamic>? ?? {},
      properties: rawProps,
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
  static const navigatorApiUrl = String.fromEnvironment(
    'SABASABA_MAP_API_URL',
    defaultValue: 'https://77.alphabeti.co.tz/api/map',
  );
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
    Object? apiError;
    try {
      return await _loadFromNavigatorApi();
    } catch (error) {
      apiError = error;
      debugPrint('SabaSaba - navigator API unavailable: $error');
    }

    try {
      return await _loadFromSupabase();
    } catch (fallbackError) {
      throw Exception(
        'Could not load the navigator map. API error: $apiError. '
        'Fallback error: $fallbackError',
      );
    }
  }

  static Future<ExhibitionMapData> _loadFromNavigatorApi() async {
    final response = await http
        .get(
          Uri.parse(navigatorApiUrl),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Navigator API returned ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Navigator API returned an invalid payload.');
    }
    final root = Map<String, dynamic>.from(decoded);
    final rawData = root['data'];
    if (rawData is! Map) {
      final rawError = root['error'];
      final message = rawError is Map ? rawError['message'] : rawError;
      throw FormatException(message?.toString() ?? 'Navigator map data is missing.');
    }
    final data = Map<String, dynamic>.from(rawData);
    final rawLayers = data['layers'] is List ? data['layers'] as List : const [];
    final nodes = (data['routingNodes'] is List
            ? data['routingNodes'] as List
            : const [])
        .whereType<Map>()
        .map((row) => RoutingNode.fromJson(Map<String, dynamic>.from(row)))
        .toList();
    final edges = (data['routingEdges'] is List
            ? data['routingEdges'] as List
            : const [])
        .whereType<Map>()
        .map((row) => RoutingEdge.fromJson(Map<String, dynamic>.from(row)))
        .toList();

    final buildings = <MapFeature>[];
    final roads = <MapFeature>[];
    final trees = <MapFeature>[];
    final boundaries = <MapFeature>[];
    final rawNavigableFeatures = <_RawFeature>[];
    final layerMetaById = <String, _LayerMeta>{};

    for (final rawLayer in rawLayers.whereType<Map>()) {
      final layer = Map<String, dynamic>.from(rawLayer);
      final editorKey =
          layer['editor_key']?.toString() ?? layer['id']?.toString() ?? '';
      final layerId = layer['id']?.toString() ?? editorKey;
      final layerName = layer['name']?.toString() ?? editorKey;
      final meta = _LayerMeta(
        id: layerId,
        editorKey: editorKey,
        name: layerName,
        color: layer['color']?.toString(),
        fill: layer['fill']?.toString(),
        visible: layer['visible'] as bool? ?? true,
      );
      layerMetaById[layerId] = meta;

      final rawFeatures =
          layer['features'] is List ? layer['features'] as List : const [];
      final targetLayer = editorKey == 'roads'
          ? Layer.road
          : editorKey == 'trees'
              ? Layer.tree
              : editorKey == 'boundary'
                  ? Layer.boundary
                  : Layer.building;

      for (var index = 0; index < rawFeatures.length; index++) {
        final rawFeature = rawFeatures[index];
        if (rawFeature is! Map) continue;
        final feature = Map<String, dynamic>.from(rawFeature);
        if (feature['geometry'] is! Map) continue;

        final parsed = MapFeature.fromJson(
          feature,
          targetLayer,
          index,
          colorHex: meta.color,
          fillHex: meta.fill,
          layerKey: editorKey,
          layerName: layerName,
        );
        switch (targetLayer) {
          case Layer.road:
            roads.add(parsed);
          case Layer.tree:
            trees.add(parsed);
          case Layer.boundary:
            boundaries.add(parsed);
          case Layer.building:
            buildings.add(parsed);
        }

        if (targetLayer == Layer.building) {
          rawNavigableFeatures.add(
            _RawFeature.fromJson({...feature, 'layer_id': layerId}),
          );
        }
      }
    }

    final locations = nodes.isEmpty
        ? <RoutingLocation>[]
        : _buildLocations(rawNavigableFeatures, nodes, layerMetaById);
    _appendNavigationDestinations(
      locations,
      data['navigationDestinations'],
      buildings,
      nodes,
    );
    locations.sort((left, right) => left.label.compareTo(right.label));

    final allPoints = [
      for (final feature in [...buildings, ...roads, ...trees, ...boundaries])
        ...feature.allPoints,
    ];
    if (allPoints.isEmpty) {
      throw const FormatException(
        'Navigator API returned no renderable geometry.',
      );
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
    );
  }

  static List<RoutingLocation> _buildLocations(
    List<_RawFeature> features,
    List<RoutingNode> nodes,
    Map<String, _LayerMeta> layerMetaById,
  ) {
    final locations = <RoutingLocation>[];
    for (var index = 0; index < features.length; index++) {
      final rawFeature = features[index];
      final position = rawFeature.center;
      if (position == null) continue;
      final layerName = layerMetaById[rawFeature.layerId]?.name ?? '';
      final props = rawFeature.properties;
      final rawCompany = props['company_name'] ??
          props['companyName'] ??
          props['company'] ??
          props['exhibitor'];
      final companyName =
          rawCompany != null && rawCompany.toString().trim().isNotEmpty
              ? rawCompany.toString().trim()
              : null;
      final rawIndustry = props['industry'] ??
          props['industry_name'] ??
          props['sector'] ??
          props['category'];
      final industries = props['industries'] is List
          ? (props['industries'] as List)
              .map((item) => item.toString())
              .toList()
          : rawIndustry == null
              ? <String>[]
              : [rawIndustry.toString()];
      final offerings = props['offerings'] is List
          ? (props['offerings'] as List)
              .whereType<Map>()
              .map(
                (item) => Offering.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
          : null;
      final baseValue = props['name'] ??
          props['booth_code'] ??
          props['number'] ??
          props['1'] ??
          props['id'];
      final labelText = baseValue?.toString() ?? '$layerName ${index + 1}';
      final boothNumber = props['booth_number']?.toString();
      final boothTag = boothNumber == null || boothNumber.isEmpty
          ? ''
          : ' • ${boothNumber.startsWith('Booth') ? boothNumber : 'Booth $boothNumber'}';
      final label = companyName == null ? labelText : '$labelText ($companyName)';
      final description = companyName == null
          ? layerName
          : 'Exhibitor: $companyName$boothTag'
              '${industries.isEmpty ? '' : ' (${industries.join(', ')})'} • $layerName';

      locations.add(
        RoutingLocation(
          id: rawFeature.id,
          featureId: rawFeature.id,
          label: label,
          description: description,
          position: position,
          nodeId: nearestNode(position, nodes).id,
          layerName: layerName,
          companyName: companyName,
          industry: industries.firstOrNull,
          industries: industries.isEmpty ? null : industries,
          logoUrl: props['logo_url']?.toString(),
          photos: props['photos'] is List ? props['photos'] as List : null,
          team: props['team'] is List ? props['team'] as List : null,
          offerings: offerings,
          searchTerms: [
            if (boothNumber != null) boothNumber,
            layerName,
            if (props['legacy_products'] != null)
              props['legacy_products'].toString(),
          ],
          properties: props,
        ),
      );
    }
    return locations;
  }

  static void _appendNavigationDestinations(
    List<RoutingLocation> locations,
    dynamic rawDestinations,
    List<MapFeature> features,
    List<RoutingNode> nodes,
  ) {
    if (rawDestinations is! List || nodes.isEmpty) return;
    final featureById = {
      for (final feature in features)
        if (feature.featureId != null) feature.featureId!: feature,
    };
    for (final rawDestination in rawDestinations.whereType<Map>()) {
      final destination = Map<String, dynamic>.from(rawDestination);
      final hallFeatureId = destination['hall_feature_id']?.toString();
      final hallFeature = featureById[hallFeatureId];
      if (hallFeature == null) continue;
      final id = destination['id']?.toString();
      final companyName = destination['company_name']?.toString();
      final boothNumber = destination['booth_number']?.toString();
      if (id == null || companyName == null || boothNumber == null) continue;
      final industries = destination['industries'] is List
          ? (destination['industries'] as List)
              .map((item) => item.toString())
              .toList()
          : <String>[];
      final offerings = destination['offerings'] is List
          ? (destination['offerings'] as List)
              .whereType<Map>()
              .map(
                (item) => Offering.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
          : null;
      final hallName =
          destination['hall_name']?.toString() ?? hallFeature.layerName;
      final properties = <String, dynamic>{
        'company_name': companyName,
        'company_id': destination['company_id'],
        'description': destination['description'],
        'logo_url': destination['logo_url'],
        'photos': destination['photos'],
        'team': destination['team'],
        'industries': industries,
        'industry': industries.firstOrNull,
        'offerings': destination['offerings'],
        'booth_number': boothNumber,
      };
      locations.add(
        RoutingLocation(
          id: id,
          featureId: hallFeatureId,
          label: '$companyName · Booth $boothNumber',
          description: 'Booth $boothNumber · $hallName',
          position: hallFeature.center,
          nodeId: nearestNode(hallFeature.center, nodes).id,
          layerName: hallName,
          companyName: companyName,
          industry: industries.firstOrNull,
          industries: industries.isEmpty ? null : industries,
          logoUrl: destination['logo_url']?.toString(),
          photos: destination['photos'] is List
              ? destination['photos'] as List
              : null,
          team: destination['team'] is List
              ? destination['team'] as List
              : null,
          offerings: offerings,
          searchTerms: [
            boothNumber,
            hallName,
            if (destination['legacy_products'] != null)
              destination['legacy_products'].toString(),
          ],
          properties: properties,
        ),
      );
    }
  }

  static Future<ExhibitionMapData> _loadFromSupabase() async {
    try {
      // 1. Find the latest ongoing or closed exhibition
      final exhibitionResponse = await http
          .get(
            Uri.parse(
              '$_supabaseUrl/exhibitions'
              '?status=in.(ongoing,closed)&order=start_date.desc&limit=1&select=*',
            ),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

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
          .timeout(const Duration(seconds: 30));

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
              '$_supabaseUrl/layers?map_id=eq.$mapId&select=id,editor_key,name,color,fill,visible',
            ),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

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
            visible: item['visible'] as bool? ?? true,
          );
          layerMetaById[id] = meta;
          allLayerMeta.add(meta);
        }
      }

      // 4. Fetch canvas feature sets
      const nonNavigableKeys = {'roads', 'boundary', 'trees'};
      final buildingLayerIds = allLayerMeta
          .where(
            (layer) =>
                layer.visible && !nonNavigableKeys.contains(layer.editorKey),
          )
          .map((layer) => layer.id)
          .toList();

      String? visibleLayerId(String key) {
        final id = layerIdByKey[key];
        return id != null && (layerMetaById[id]?.visible ?? true) ? id : null;
      }

      final roadLayerId = visibleLayerId('roads');
      final treeLayerId = visibleLayerId('trees');
      final boundaryLayerId = visibleLayerId('boundary');

      // 5. Determine navigable layer IDs (all except roads/trees/boundary)
      final navigableLayerIds = allLayerMeta
          .where(
            (layer) =>
                layer.visible && !nonNavigableKeys.contains(layer.editorKey),
          )
          .map((l) => l.id)
          .toList();

      // 6. Fetch all data in parallel
      final buildingsFuture = _fetchFeatures(buildingLayerIds, Layer.building, layerMetaById);
      final roadsFuture = _fetchFeaturesForLayer(roadLayerId, Layer.road, layerMeta: layerMetaById[roadLayerId]);
      final treesFuture = _fetchFeaturesForLayer(treeLayerId, Layer.tree, layerMeta: layerMetaById[treeLayerId]);
      final boundariesFuture = _fetchFeaturesForLayer(boundaryLayerId, Layer.boundary, layerMeta: layerMetaById[boundaryLayerId]);
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
          final rawComp = props['company_name'] ??
              props['companyName'] ??
              props['company'] ??
              props['exhibitor'];


          final companyName =
              rawComp != null && rawComp.toString().trim().isNotEmpty
                  ? rawComp.toString().trim()
                  : null;

          final rawInd = props['industry'] ??
              props['industry_name'] ??
              props['sector'] ??
              props['category'];
          final industries = props['industries'] is List
              ? (props['industries'] as List).map((e) => e.toString()).toList()
              : (rawInd != null ? [rawInd.toString()] : <String>[]);
          final industry = industries.isNotEmpty ? industries.first : null;

          final logoUrl = props['logo_url']?.toString();
          final photos = props['photos'] is List ? props['photos'] as List : null;
          final team = props['team'] is List ? props['team'] as List : null;
          final offerings = props['offerings'] is List
              ? (props['offerings'] as List)
                  .map((o) => Offering.fromJson(Map<String, dynamic>.from(o as Map)))
                  .toList()
              : null;

          final boothNumberStr = props['booth_number']?.toString();
          final boothTag = boothNumberStr != null
              ? ' • ${boothNumberStr.startsWith('Booth') ? boothNumberStr : 'Booth $boothNumberStr'}'
              : '';

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
              ? 'Exhibitor: $companyName$boothTag${industries.isNotEmpty ? ' (${industries.join(', ')})' : ''} • $layerName'
              : layerName;

          locations.add(
            RoutingLocation(
              id: rawFeature.id,
              featureId: rawFeature.id,
              label: label,
              description: description,
              position: position,
              nodeId: node.id,
              layerName: layerName,
              companyName: companyName,
              industry: industry,
              industries: industries.isNotEmpty ? industries : null,
              logoUrl: logoUrl,
              photos: photos,
              team: team,
              offerings: offerings,
              searchTerms: [
                if (boothNumberStr != null) boothNumberStr,
                layerName,
                if (props['legacy_products'] != null) props['legacy_products'].toString(),
              ],
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
    } on TimeoutException {
      throw Exception('Map loading timed out. Please check internet connection and try again.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Map loading timed out. Please check internet connection and try again.');
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Fetches features from multiple layer IDs in parallel.
  static Future<List<MapFeature>> _fetchFeatures(
    List<String> layerIds,
    Layer layer,
    Map<String, _LayerMeta> layerMetaById,
  ) async {
    final futures = layerIds.map(
      (id) => _fetchFeaturesForLayer(id, layer, layerMeta: layerMetaById[id]),
    );
    final results = await Future.wait(futures);
    final merged = <MapFeature>[];
    for (final list in results) {
      merged.addAll(list);
    }
    return merged;
  }

  /// Fetches features for a single layer ID (returns [] if layerId is null).
  static Future<List<MapFeature>> _fetchFeaturesForLayer(
    String? layerId,
    Layer layer, {
    int indexOffset = 0,
    _LayerMeta? layerMeta,
  }) async {
    if (layerId == null) return [];
    final response = await http
        .get(
          Uri.parse(
            '$_supabaseUrl/features'
            '?layer_id=eq.$layerId&select=id,label,code,status,public_id,geometry_type,geometry,sort_order',
          ),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 30));
    _assertOk(response, 'features[$layerId]');
    final list = jsonDecode(response.body) as List<dynamic>;
    return [
      for (var i = 0; i < list.length; i++)
        MapFeature.fromJson(
          list[i] as Map<String, dynamic>,
          layer,
          indexOffset + i,
          colorHex: layerMeta?.color,
          fillHex: layerMeta?.fill,
          layerKey: layerMeta?.editorKey ?? '',
          layerName: layerMeta?.name ?? '',
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
            '&select=id,layer_id,label,code,status,public_id,geometry_type,geometry,sort_order',
          ),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 30));
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
        .timeout(const Duration(seconds: 30));
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
        .timeout(const Duration(seconds: 30));
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
      for (final point in building.points) {
        if ((projection.project(point) - scenePoint).distance <= 12) {
          return building;
        }
      }
      for (final line in building.lines) {
        final projected = line.map(projection.project).toList();
        for (var index = 1; index < projected.length; index++) {
          if (_distanceToSegment(
                scenePoint,
                projected[index - 1],
                projected[index],
              ) <=
              8) {
            return building;
          }
        }
      }
    }
    return null;
  }

  static double _distanceToSegment(Offset point, Offset start, Offset end) {
    final segment = end - start;
    final lengthSquared = segment.dx * segment.dx + segment.dy * segment.dy;
    if (lengthSquared == 0) return (point - start).distance;
    final relative = point - start;
    final ratio = ((relative.dx * segment.dx + relative.dy * segment.dy) /
            lengthSquared)
        .clamp(0.0, 1.0);
    final closest = start + segment * ratio;
    return (point - closest).distance;
  }

  MapProjection projectionFor(Size size) {
    return MapProjection(bounds: bounds, size: size);
  }
}
