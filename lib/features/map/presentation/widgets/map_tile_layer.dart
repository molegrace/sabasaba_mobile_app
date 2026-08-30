part of '../../../../main.dart';

class MapTileLayer extends StatelessWidget {
  const MapTileLayer({
    super.key,
    required this.data,
    required this.tileStyle,
    required this.refreshGeneration,
    required this.controller,
    required this.rotation,
  });

  final ExhibitionMapData data;
  final MapTileStyle tileStyle;
  final int refreshGeneration;
  final TransformationController controller;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final projection = data.projectionFor(size);
            final visibleBounds = _visibleGeoBounds(size, projection);

            final currentScale = math.max(
              minMapScale,
              controller.value.getMaxScaleOnAxis(),
            );
            final zoomOffset = (math.log(currentScale) / math.ln2).round();
            final mapZoom = (initialMapZoom + zoomOffset)
                .clamp(minMapZoom, maxMapZoom)
                .toInt();
            final zoom = math.min(mapZoom, tileStyle.maxNativeZoom);

            final maxTile = (1 << zoom) - 1;

            // Leaflet keeps a two-tile buffer around the viewport so a small
            // pan does not expose an unloaded edge.
            const keepBuffer = 2;
            final minX = _clampTile(
              _lngToTileX(visibleBounds.minLng, zoom) - keepBuffer,
              maxTile,
            );
            final maxX = _clampTile(
              _lngToTileX(visibleBounds.maxLng, zoom) + keepBuffer,
              maxTile,
            );
            final minY = _clampTile(
              _latToTileY(visibleBounds.maxLat, zoom) - keepBuffer,
              maxTile,
            );
            final maxY = _clampTile(
              _latToTileY(visibleBounds.minLat, zoom) + keepBuffer,
              maxTile,
            );

            return ColoredBox(
              color: tileStyle.fallbackColor,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var x = minX; x <= maxX; x++)
                    for (var y = minY; y <= maxY; y++)
                      TileImage(
                        key: ValueKey(tileStyle.tileUrl(x, y, zoom)),
                        rect: _tileRect(x, y, zoom, projection),
                        url: tileStyle.tileUrl(x, y, zoom),
                        fallbackColor: tileStyle.fallbackColor,
                        refreshGeneration: refreshGeneration,
                      ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  GeoBounds _visibleGeoBounds(Size size, MapProjection projection) {
    final center = size.center(Offset.zero);
    final sceneCorners =
        <Offset>[
              Offset.zero,
              Offset(size.width, 0),
              Offset(size.width, size.height),
              Offset(0, size.height),
            ]
            .map(controller.toScene)
            .map((point) {
              final translated = point - center;
              final cosA = math.cos(-rotation);
              final sinA = math.sin(-rotation);
              return Offset(
                    translated.dx * cosA - translated.dy * sinA,
                    translated.dx * sinA + translated.dy * cosA,
                  ) +
                  center;
            })
            .map(projection.unproject)
            .toList();

    return GeoBounds.fromPoints(sceneCorners);
  }

  Rect _tileRect(int x, int y, int zoom, MapProjection projection) {
    final northWest = _tileToPoint(x, y, zoom);
    final southEast = _tileToPoint(x + 1, y + 1, zoom);
    return Rect.fromPoints(
      projection.project(northWest),
      projection.project(southEast),
    );
  }

  GeoPoint _tileToPoint(int x, int y, int zoom) {
    final scale = math.pow(2, zoom).toDouble();
    final lng = x / scale * 360 - 180;
    final mercator = math.pi * (1 - 2 * y / scale);
    final sinhMercator = (math.exp(mercator) - math.exp(-mercator)) / 2;
    final lat = math.atan(sinhMercator) * 180 / math.pi;
    return GeoPoint(lng, lat);
  }

  int _lngToTileX(double lng, int zoom) {
    final scale = math.pow(2, zoom).toDouble();
    return ((lng + 180) / 360 * scale).floor();
  }

  int _latToTileY(double lat, int zoom) {
    final clampedLat = lat.clamp(-85.05112878, 85.05112878).toDouble();
    final latRad = clampedLat * math.pi / 180;
    final scale = math.pow(2, zoom).toDouble();
    return ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
            2 *
            scale)
        .floor();
  }

  int _clampTile(int value, int maxTile) {
    return value.clamp(0, maxTile).toInt();
  }
}

class TileImage extends StatefulWidget {
  const TileImage({
    super.key,
    required this.rect,
    required this.url,
    required this.fallbackColor,
    required this.refreshGeneration,
  });

  final Rect rect;
  final String url;
  final Color fallbackColor;
  final int refreshGeneration;

  @override
  State<TileImage> createState() => _TileImageState();
}

class _TileImageState extends State<TileImage> {
  late Future<List<int>> _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(TileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loadImage();
    } else if (oldWidget.refreshGeneration != widget.refreshGeneration) {
      unawaited(_refreshImage());
    }
  }

  void _loadImage() {
    _imageBytes = _loadCachedImage(widget.url);
  }

  Future<List<int>> _loadCachedImage(String url) async {
    final cacheManager = DefaultCacheManager();
    final cached = await cacheManager.getFileFromCache(url);
    final file = cached?.file ?? await cacheManager.getSingleFile(url);
    return file.readAsBytes();
  }

  Future<void> _refreshImage() async {
    final url = widget.url;
    try {
      final refreshed = await DefaultCacheManager().downloadFile(
        url,
        force: true,
      );
      final bytes = await refreshed.file.readAsBytes();
      if (mounted && widget.url == url) {
        setState(() => _imageBytes = Future.value(bytes));
      }
    } catch (_) {
      // Keep displaying the cached tile when a background refresh fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.rect.left,
      top: widget.rect.top,
      width: math.max(1, widget.rect.width),
      height: math.max(1, widget.rect.height),
      child: FutureBuilder<List<int>>(
        future: _imageBytes,
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes == null) {
            return ColoredBox(color: widget.fallbackColor);
          }
          return Image.memory(
            Uint8List.fromList(bytes),
            fit: BoxFit.fill,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) {
              return ColoredBox(color: widget.fallbackColor);
            },
          );
        },
      ),
    );
  }
}
