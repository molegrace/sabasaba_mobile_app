part of '../../../../main.dart';

class MapCanvas extends StatelessWidget {
  const MapCanvas({
    required this.data,
    required this.filteredAreas,
    required this.selectedArea,
    required this.selectedService,
    required this.tileStyle,
    required this.tileRefreshGeneration,
    required this.rotation,
    required this.controller,
    required this.onRotationStart,
    required this.onRotationUpdate,
    required this.onDoubleTap,
    required this.onSelectArea,
    this.categoryFilter = 'all',
    this.route,
    this.startPoint,
    this.endPoint,
  });

  final ExhibitionMapData data;
  final List<MapFeature> filteredAreas;
  final MapFeature? selectedArea;
  final VisitorService? selectedService;
  final MapTileStyle tileStyle;
  final int tileRefreshGeneration;
  final double rotation;
  final TransformationController controller;
  final VoidCallback onRotationStart;
  final ValueChanged<double> onRotationUpdate;
  final VoidCallback onDoubleTap;
  final ValueChanged<MapFeature> onSelectArea;
  final String categoryFilter;
  final RouteResult? route;
  final GeoPoint? startPoint;
  final GeoPoint? endPoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xffdfe7dc)),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: onDoubleTap,
            onTapUp: (details) {
              final scenePoint = controller.toScene(details.localPosition);
              final hit = data.hitTest(
                _unrotatePoint(scenePoint, size, rotation),
                size,
              );
              if (hit != null) {
                onSelectArea(hit);
              }
            },
            child: InteractiveViewer(
              transformationController: controller,
              minScale: minMapScale,
              maxScale: maxMapScale,
              boundaryMargin: const EdgeInsets.all(36),
              onInteractionStart: (_) => onRotationStart(),
              onInteractionUpdate: (details) {
                if (details.pointerCount > 1 &&
                    details.rotation.abs() > 0.002) {
                  onRotationUpdate(details.rotation);
                }
              },
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Transform.rotate(
                  angle: rotation,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MapTileLayer(
                        data: data,
                        tileStyle: tileStyle,
                        refreshGeneration: tileRefreshGeneration,
                      ),
                      CustomPaint(
                        painter: ExhibitionMapPainter(
                          data: data,
                          filteredAreas: filteredAreas,
                          selectedArea: selectedArea,
                          selectedService: selectedService,
                          categoryFilter: categoryFilter,
                          route: route,
                          startPoint: startPoint,
                          endPoint: endPoint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Offset _unrotatePoint(Offset point, Size size, double angle) {
    final center = Offset(size.width / 2, size.height / 2);
    final translated = point - center;
    final cosA = math.cos(-angle);
    final sinA = math.sin(-angle);
    return Offset(
          translated.dx * cosA - translated.dy * sinA,
          translated.dx * sinA + translated.dy * cosA,
        ) +
        center;
  }
}

class ExhibitionMapPainter extends CustomPainter {
  ExhibitionMapPainter({
    required this.data,
    required this.filteredAreas,
    required this.selectedArea,
    required this.selectedService,
    this.categoryFilter = 'all',
    this.route,
    this.startPoint,
    this.endPoint,
  });

  final ExhibitionMapData data;
  final List<MapFeature> filteredAreas;
  final MapFeature? selectedArea;
  final VisitorService? selectedService;
  final String categoryFilter;
  final RouteResult? route;
  final GeoPoint? startPoint;
  final GeoPoint? endPoint;

  @override
  void paint(Canvas canvas, Size size) {
    final projection = data.projectionFor(size);
    final filteredIds = filteredAreas.map((feature) => feature.key).toSet();

    final boundaryPaint = Paint()
      ..color = const Color(0xb8c99b57)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final boundaryHaloPaint = Paint()
      ..color = const Color(0x44ffffff)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final boundary in data.boundaries) {
      for (final line in boundary.lines) {
        final path = _linePath(line, projection);
        canvas.drawPath(path, boundaryHaloPaint);
        canvas.drawPath(path, boundaryPaint);
      }
    }

    final roadPaint = Paint()
      ..color = const Color(0xffc8c8c8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final road in data.roads) {
      for (final line in road.lines) {
        final path = _linePath(line, projection);
        canvas.drawPath(path, roadPaint);
      }
    }



    for (final building in data.buildings) {
      final isSelected = selectedArea != null &&
          (selectedArea!.featureId != null
              ? selectedArea!.featureId == building.featureId
              : selectedArea!.key == building.key);
      final isFiltered = filteredIds.contains(building.key);

      final buildingColor = building.rawProperties['company_name'] != null
          ? const Color(0xff1aa987) // allocated exhibitor: solid teal
          : const Color(0xffb0b0b0); // unallocated: solid grey

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = isSelected ? const Color(0xff14b8a6) : buildingColor;

      for (final polygon in building.polygons) {
        final path = _polygonPath(polygon, projection);
        canvas.drawPath(path, fillPaint);
      }

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.0 : 0.8
        ..color = isSelected
            ? const Color(0xff0f766e)
            : const Color(0xcc124e43);

      for (final polygon in building.polygons) {
        canvas.drawPath(_polygonPath(polygon, projection), strokePaint);
      }

      if (!isSelected && isFiltered && filteredAreas.length < 24) {
        _drawLabel(canvas, building, projection, isSelected);
      }
    }



    _drawRoundabouts(canvas, projection);

    // Draw red filter indicator dots on top of matching features when categoryFilter != 'all'
    if (categoryFilter != 'all' && categoryFilter != 'more') {
      final redDotFill = Paint()
        ..color = const Color(0xffef4444)
        ..style = PaintingStyle.fill;
      final redDotBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (final feature in filteredAreas) {
        final center = projection.project(feature.center);
        canvas.drawCircle(center, 7, redDotFill);
        canvas.drawCircle(center, 7, redDotBorder);
      }
    }


    // Paint route polyline if found
    final activeRoute = route;
    if (activeRoute != null && startPoint != null && endPoint != null) {
      final routePoints = <Offset>[];
      final nodeById = {for (final node in data.nodes) node.id: node};
      for (final nodeId in activeRoute.nodeIds) {
        final node = nodeById[nodeId];
        if (node != null) {
          routePoints.add(
            projection.project(GeoPoint(node.longitude, node.latitude)),
          );
        }
      }

      if (routePoints.isNotEmpty) {
        final routePaint = Paint()
          ..color = const Color(0xff0284c7) // sky-600 - matches web
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        _drawDashedPolyline(canvas, routePoints, routePaint);

        // Paint start as an emerald dot (matching web's emerald-500).
        final startOffset = projection.project(startPoint!);
        canvas.drawCircle(startOffset, 5, Paint()..color = Colors.white);
        canvas.drawCircle(
          startOffset,
          4,
          Paint()..color = const Color(0xff10b981), // emerald-500
        );

        // Paint the destination as a rose location pin (matching web's rose-500).
        final endOffset = projection.project(endPoint!);
        final destinationPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(Icons.location_pin.codePoint),
            style: TextStyle(
              color: const Color(0xfff43f5e), // rose-500 - matches web
              fontSize: 16,
              fontFamily: Icons.location_pin.fontFamily,
              package: Icons.location_pin.fontPackage,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        destinationPainter.paint(
          canvas,
          Offset(
            endOffset.dx - destinationPainter.width / 2,
            endOffset.dy - destinationPainter.height,
          ),
        );
      }
    }

    final service = selectedService;
    if (service != null) {
      _drawServiceMarker(canvas, service, projection);
    }
  }

  void _drawDashedPolyline(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    const dashWidth = 4.0;
    const dashSpace = 2.0;
    var distance = 0.0;

    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        final len = math.min(dashWidth, pathMetric.length - distance);
        final extract = pathMetric.extractPath(distance, distance + len);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }
  }

  @override
  bool shouldRepaint(covariant ExhibitionMapPainter oldDelegate) {
    return data != oldDelegate.data ||
        filteredAreas != oldDelegate.filteredAreas ||
        selectedArea != oldDelegate.selectedArea ||
        selectedService != oldDelegate.selectedService ||
        categoryFilter != oldDelegate.categoryFilter ||
        route != oldDelegate.route ||
        startPoint != oldDelegate.startPoint ||
        endPoint != oldDelegate.endPoint;
  }


  void _drawServiceMarker(
    Canvas canvas,
    VisitorService service,
    MapProjection projection,
  ) {
    final point = projection.project(service.area.center);
    final shadowPaint = Paint()..color = const Color(0x44000000);
    final markerPaint = Paint()..color = const Color(0xfff26430);
    final centerPaint = Paint()..color = Colors.white;
    final labelPaint = Paint()..color = const Color(0xff0b4238);

    final markerPath = Path()
      ..addOval(Rect.fromCircle(center: point.translate(0, -12), radius: 14))
      ..moveTo(point.dx - 7, point.dy - 1)
      ..lineTo(point.dx, point.dy + 12)
      ..lineTo(point.dx + 7, point.dy - 1)
      ..close();
    canvas.drawCircle(point.translate(2, 3), 16, shadowPaint);
    canvas.drawPath(markerPath, markerPaint);
    canvas.drawCircle(point.translate(0, -12), 6, centerPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: service.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 150);
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        point.dx - textPainter.width / 2 - 10,
        point.dy + 18,
        textPainter.width + 20,
        textPainter.height + 10,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(labelRect, labelPaint);
    textPainter.paint(canvas, Offset(labelRect.left + 10, labelRect.top + 5));
  }

  void _drawLabel(
    Canvas canvas,
    MapFeature building,
    MapProjection projection,
    bool selected,
  ) {
    final center = projection.project(building.center);
    final textPainter = TextPainter(
      text: TextSpan(
        text: building.title,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xff073f36),
          fontWeight: FontWeight.w800,
          fontSize: selected ? 14 : 11,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center.translate(0, -20),
        width: textPainter.width + 16,
        height: textPainter.height + 8,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = selected ? const Color(0xff0b4238) : Colors.white,
    );
    textPainter.paint(canvas, Offset(rect.left + 8, rect.top + 4));
  }

  void _drawRoundabouts(Canvas canvas, MapProjection projection) {
    final roadPaint = Paint()
      ..color = const Color(0xffc8c8c8)
      ..style = PaintingStyle.fill;

    final roundabouts = [
      const GeoPoint(39.278831168638066, -6.864770815767824),
      const GeoPoint(39.280398417925295, -6.866317090268083),
    ];

    for (final roundabout in roundabouts) {
      final center = projection.project(roundabout);
      canvas.drawCircle(center, 2.5, roadPaint);
    }
  }

  Path _polygonPath(List<GeoPoint> polygon, MapProjection projection) {
    final path = Path();
    for (var i = 0; i < polygon.length; i++) {
      final point = projection.project(polygon[i]);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  Path _linePath(List<GeoPoint> line, MapProjection projection) {
    final path = Path();
    for (var i = 0; i < line.length; i++) {
      final point = projection.project(line[i]);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path;
  }
}
