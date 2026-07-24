part of '../../../main.dart';

class ExhibitionMapData {
  static const _mapCacheKey = 'sabasaba-exhibition-map-v1';
  static final Uri _mapEndpoint = Uri.parse(
    'https://sabasaba.alphabeti.co.tz/api/map',
  );

  ExhibitionMapData({
    required this.buildings,
    required this.roads,
    required this.trees,
    required this.boundaries,
    required this.bounds,
    required this.nodes,
    required this.edges,
    required this.locations,
  });

  final List<MapFeature> buildings;
  final List<MapFeature> roads;
  final List<MapFeature> trees;
  final List<MapFeature> boundaries;
  final GeoBounds bounds;
  final List<RoutingNode> nodes;
  final List<RoutingEdge> edges;
  final List<RoutingLocation> locations;

  static Future<ExhibitionMapData> load() async {
    Map<String, dynamic> payload;
    try {
      final response = await http
          .get(_mapEndpoint, headers: const {'accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Map API returned ${response.statusCode} ${response.reasonPhrase ?? ''}'
              .trim(),
        );
      }
      payload = jsonDecode(response.body) as Map<String, dynamic>;
      await DefaultCacheManager().putFile(
        _mapEndpoint.toString(),
        response.bodyBytes,
        key: _mapCacheKey,
        maxAge: const Duration(days: 365),
        fileExtension: 'json',
      );
    } catch (networkError) {
      final cached = await DefaultCacheManager().getFileFromCache(
        _mapCacheKey,
        ignoreMemCache: true,
      );
      if (cached == null) {
        rethrow;
      }
      final cachedBytes = await cached.file.readAsBytes();
      payload = jsonDecode(utf8.decode(cachedBytes)) as Map<String, dynamic>;
    }

    final data = payload['data'] as Map<String, dynamic>?;
    final layers = data?['layers'] as List<dynamic>?;
    if (layers == null) {
      print('SabaSaba Map API Error: No layers found in payload: $payload');
      throw const FormatException('Map API response does not contain layers.');
    }

    print(
      'SabaSaba Map API - Available Layers: ${layers.map((l) => l?['id']).toList()}',
    );

    var buildings = <MapFeature>[];
    final List<MapFeature> roads;
    final List<MapFeature> trees;
    final List<MapFeature> boundaries;

    try {
      final boothsFeatures = _loadFeatures(layers, 'booths', Layer.building);
      final spacesFeatures = _loadFeatures(layers, 'spaces', Layer.building);
      final buildingsFeatures = _loadFeatures(layers, 'buildings', Layer.building);
      buildings = [...boothsFeatures, ...spacesFeatures, ...buildingsFeatures];

      roads = _loadFeatures(layers, 'roads', Layer.road);
      trees = _loadFeatures(layers, 'trees', Layer.tree);
      boundaries = _loadFeatures(layers, 'boundary', Layer.boundary);
    } catch (e, stackTrace) {
      print('SabaSaba Map Parsing Failed: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }

    // Fallback: If both booths and buildings layers have 0 features in the API response,
    // fetch features of layers with editor_key in ('spaces', 'buildings', 'booths') directly from Supabase REST API!
    if (buildings.isEmpty) {
      try {
        final headers = {
          'apikey': 'sb_publishable_AMEQ6X4TMeyGz1JlCledzg_9k2ojRkV',
          'Authorization':
              'Bearer sb_publishable_AMEQ6X4TMeyGz1JlCledzg_9k2ojRkV',
          'Accept': 'application/json',
        };

        final mapResponse = await http
            .get(
              Uri.parse(
                'https://iqmcidsxvbsbbukjloew.supabase.co/rest/v1/maps?is_active=eq.true&select=id',
              ),
              headers: headers,
            )
            .timeout(const Duration(seconds: 5));

        if (mapResponse.statusCode == 200) {
          final mapsJson = jsonDecode(mapResponse.body) as List<dynamic>;
          if (mapsJson.isNotEmpty) {
            final mapId = mapsJson.first['id'] as String;

            final layerResponse = await http
                .get(
                  Uri.parse(
                    'https://iqmcidsxvbsbbukjloew.supabase.co/rest/v1/layers?map_id=eq.$mapId&editor_key=in.("spaces","buildings","booths")&select=id,editor_key',
                  ),
                  headers: headers,
                )
                .timeout(const Duration(seconds: 5));

            if (layerResponse.statusCode == 200) {
              final layersJson =
                  jsonDecode(layerResponse.body) as List<dynamic>;

              final targetLayerIds = <String>[];
              for (final layerItem in layersJson) {
                final editorKey = layerItem['editor_key'] as String?;
                if (editorKey == 'spaces' || editorKey == 'buildings' || editorKey == 'booths') {
                  targetLayerIds.add(layerItem['id'] as String);
                }
              }

              if (targetLayerIds.isNotEmpty) {
                final tempBuildings = <MapFeature>[];
                for (final targetLayerId in targetLayerIds) {
                  final featuresResponse = await http
                      .get(
                        Uri.parse(
                          'https://iqmcidsxvbsbbukjloew.supabase.co/rest/v1/features?layer_id=eq.$targetLayerId&select=id,geometry,properties',
                        ),
                        headers: headers,
                      )
                      .timeout(const Duration(seconds: 5));

                  if (featuresResponse.statusCode == 200) {
                    final featuresJson =
                        jsonDecode(featuresResponse.body) as List<dynamic>;
                    tempBuildings.addAll([
                      for (var i = 0; i < featuresJson.length; i++)
                        MapFeature.fromJson(
                          featuresJson[i] as Map<String, dynamic>,
                          Layer.building,
                          tempBuildings.length + i,
                        ),
                    ]);
                  }
                }
                buildings = tempBuildings;
                print(
                  'SabaSaba Map API - Fallback fetched ${buildings.length} building features from Supabase REST.',
                );
              }
            }
          }
        }
      } catch (e) {
        print('Supabase buildings fallback failed: $e');
      }
    }

    final allPoints = [
      for (final feature in [...buildings, ...roads, ...trees, ...boundaries])
        ...feature.allPoints,
    ];
    if (allPoints.isEmpty) {
      throw const FormatException('Map API returned no renderable geometry.');
    }

    // Parse routing nodes and edges
    final routingNodesRaw = data?['routingNodes'] as List<dynamic>? ?? const [];
    var nodes = routingNodesRaw
        .map((item) => RoutingNode.fromJson(item as Map<String, dynamic>))
        .toList();

    final routingEdgesRaw = data?['routingEdges'] as List<dynamic>? ?? const [];
    var edges = routingEdgesRaw
        .map((item) => RoutingEdge.fromJson(item as Map<String, dynamic>))
        .toList();

    // Fallback: Query Supabase REST API directly if routing graph is missing from map API response
    if (nodes.isEmpty) {
      try {
        final headers = {
          'apikey': 'sb_publishable_AMEQ6X4TMeyGz1JlCledzg_9k2ojRkV',
          'Authorization':
              'Bearer sb_publishable_AMEQ6X4TMeyGz1JlCledzg_9k2ojRkV',
          'Accept': 'application/json',
        };

        // 1. Get active map ID
        final mapResponse = await http
            .get(
              Uri.parse(
                'https://iqmcidsxvbsbbukjloew.supabase.co/rest/v1/maps?is_active=eq.true&select=id',
              ),
              headers: headers,
            )
            .timeout(const Duration(seconds: 5));

        if (mapResponse.statusCode == 200) {
          final mapsJson = jsonDecode(mapResponse.body) as List<dynamic>;
          if (mapsJson.isNotEmpty) {
            final mapId = mapsJson.first['id'] as String;

            // 2. Fetch routing nodes
            final nodesResponse = await http
                .get(
                  Uri.parse(
                    'https://iqmcidsxvbsbbukjloew.supabase.co/rest/v1/routing_nodes?map_id=eq.$mapId&select=id,latitude,longitude',
                  ),
                  headers: headers,
                )
                .timeout(const Duration(seconds: 5));

            if (nodesResponse.statusCode == 200) {
              final nodesJson = jsonDecode(nodesResponse.body) as List<dynamic>;
              nodes = nodesJson
                  .map(
                    (item) =>
                        RoutingNode.fromJson(item as Map<String, dynamic>),
                  )
                  .toList();
            }

            // 3. Fetch routing edges
            final edgesResponse = await http
                .get(
                  Uri.parse(
                    'https://iqmcidsxvbsbbukjloew.supabase.co/rest/v1/routing_edges?map_id=eq.$mapId&select=id,source_node_id,target_node_id,distance,bidirectional',
                  ),
                  headers: headers,
                )
                .timeout(const Duration(seconds: 5));

            if (edgesResponse.statusCode == 200) {
              final edgesJson = jsonDecode(edgesResponse.body) as List<dynamic>;
              edges = edgesJson
                  .map(
                    (item) =>
                        RoutingEdge.fromJson(item as Map<String, dynamic>),
                  )
                  .toList();
            }
          }
        }
      } catch (e) {
        print('Supabase REST fallback failed: $e');
      }
    }

    // Map locations
    final locations = <RoutingLocation>[];
    if (nodes.isNotEmpty) {
      for (final building in buildings) {
        final position = building.center;
        final node = nearestNode(position, nodes);
        locations.add(
          RoutingLocation(
            id: building.key,
            label: building.title,
            description: 'Area',
            position: position,
            nodeId: node.id,
          ),
        );
      }
      locations.sort((a, b) => a.label.compareTo(b.label));
    }

    print('SabaSaba Map API - parsed buildings count: ${buildings.length}');
    print('SabaSaba Map API - parsed nodes count: ${nodes.length}');
    print('SabaSaba Map API - parsed edges count: ${edges.length}');
    print('SabaSaba Map API - parsed locations count: ${locations.length}');

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

  static List<MapFeature> _loadFeatures(
    List<dynamic> layers,
    String layerId,
    Layer layer,
  ) {
    final layerJson = layers.cast<Map<String, dynamic>?>().firstWhere(
      (item) => item?['id'] == layerId,
      orElse: () => null,
    );
    if (layerJson == null) {
      print('SabaSaba Map Warning: Layer $layerId not found in API response.');
      return const [];
    }
    final geoJson = layerJson['geojson'] as Map<String, dynamic>?;
    if (geoJson == null) {
      print('SabaSaba Map Warning: Layer $layerId is missing geojson object.');
      return const [];
    }
    final features = geoJson['features'] as List<dynamic>?;
    if (features == null) {
      print('SabaSaba Map Warning: Layer $layerId is missing features array.');
      return const [];
    }

    return [
      for (var i = 0; i < features.length; i++)
        MapFeature.fromJson(features[i] as Map<String, dynamic>, layer, i),
    ];
  }

  List<MapFeature> searchBuildings(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return buildings;
    }

    return buildings.where((feature) {
      return feature.searchText.contains(normalized);
    }).toList();
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
        if ((path..close()).contains(scenePoint)) {
          return building;
        }
      }
    }
    return null;
  }

  MapProjection projectionFor(Size size) {
    return MapProjection(bounds: bounds, size: size);
  }
}
