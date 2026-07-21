part of '../../../../main.dart';

class MapTileLayer extends StatelessWidget {
  const MapTileLayer({
    required this.data,
    required this.tileStyle,
    required this.refreshGeneration,
  });

  final ExhibitionMapData data;
  final MapTileStyle tileStyle;
  final int refreshGeneration;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final projection = data.projectionFor(size);
        final visibleBounds = projection.visibleBounds;
        final zoom = tileStyle.zoom;
        final maxTile = (1 << zoom) - 1;
        final minX = _clampTile(
          _lngToTileX(visibleBounds.minLng, zoom) - 1,
          maxTile,
        );
        final maxX = _clampTile(
          _lngToTileX(visibleBounds.maxLng, zoom) + 1,
          maxTile,
        );
        final minY = _clampTile(
          _latToTileY(visibleBounds.maxLat, zoom) - 1,
          maxTile,
        );
        final maxY = _clampTile(
          _latToTileY(visibleBounds.minLat, zoom) + 1,
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
