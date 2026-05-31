import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const SabaSabaApp());
}

class SabaSabaApp extends StatelessWidget {
  const SabaSabaApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xff0f8b6f);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SabaSaba Exhibition Map',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff3f6f1),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w800),
          titleMedium: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      home: const ExhibitionMapScreen(),
    );
  }
}

class ExhibitionMapScreen extends StatefulWidget {
  const ExhibitionMapScreen({super.key});

  @override
  State<ExhibitionMapScreen> createState() => _ExhibitionMapScreenState();
}

class _ExhibitionMapScreenState extends State<ExhibitionMapScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TransformationController _transformController =
      TransformationController();

  late Future<ExhibitionMapData> _mapFuture;
  String _query = '';
  bool _searchFocused = false;
  double _mapRotation = 0;
  double _gestureRotationStart = 0;
  int _selectedNavIndex = 0;
  MapFeature? _selectedArea;

  @override
  void initState() {
    super.initState();
    _mapFuture = ExhibitionMapData.load();
    _searchFocusNode.addListener(() {
      setState(() => _searchFocused = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: (index) {
          _searchFocusNode.unfocus();
          setState(() => _selectedNavIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'Info',
          ),
        ],
      ),
      body: FutureBuilder<ExhibitionMapData>(
        future: _mapFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MapError(message: snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return const _LoadingMap();
          }

          final data = snapshot.data!;
          final visibleAreas = data.searchBuildings(_query);
          final activeArea =
              _selectedArea != null && visibleAreas.contains(_selectedArea)
                  ? _selectedArea
                  : visibleAreas.length == 1
                      ? visibleAreas.first
                      : _selectedArea;
          final modalArea = _selectedArea;

          if (_selectedNavIndex == 1) {
            return _ServicesTab(
              areas: data.buildings,
              selectedArea: activeArea,
              onSelectArea: (area) {
                setState(() {
                  _selectedArea = area;
                  _selectedNavIndex = 0;
                });
              },
            );
          }

          if (_selectedNavIndex == 2) {
            return _InfoTab(
              buildingCount: data.buildings.length,
              roadCount: data.roads.length,
              treeCount: data.trees.length,
            );
          }

          return SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final searchShowingResults =
                    _searchFocused && _query.trim().isNotEmpty;
                final panel = _SearchPanel(
                  query: _query,
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  areas: visibleAreas,
                  selectedArea: activeArea,
                  showResults: searchShowingResults,
                  onQueryChanged: (value) {
                    setState(() {
                      _query = value;
                      if (value.isEmpty) {
                        _selectedArea = null;
                      }
                    });
                  },
                  onSelectArea: (area) {
                    setState(() => _selectedArea = area);
                    _searchFocusNode.unfocus();
                  },
                  onClear: () {
                    _searchController.clear();
                    setState(() {
                      _query = '';
                      _selectedArea = null;
                    });
                  },
                );

                return Stack(
                  children: [
                    Positioned.fill(
                      child: _MapCanvas(
                        data: data,
                        filteredAreas: visibleAreas,
                        selectedArea: activeArea,
                        rotation: _mapRotation,
                        controller: _transformController,
                        onRotationStart: () {
                          _gestureRotationStart = _mapRotation;
                        },
                        onRotationUpdate: (angle) {
                          setState(() {
                            _mapRotation = _gestureRotationStart + angle;
                          });
                        },
                        onSelectArea: (area) {
                          setState(() => _selectedArea = area);
                          _searchFocusNode.unfocus();
                        },
                      ),
                    ),
                    if (modalArea != null)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            setState(() => _selectedArea = null);
                          },
                        ),
                      ),
                    Positioned(
                      left: 16,
                      right: wide ? null : 16,
                      top: 14,
                      width: wide ? 350 : null,
                      bottom: wide ? 18 : null,
                      child: panel,
                    ),
                    if (modalArea != null && !wide)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: _SelectedAreaModal(
                          area: modalArea,
                          onClose: () {
                            setState(() => _selectedArea = null);
                          },
                        ),
                      ),
                    if (modalArea != null && wide)
                      Positioned(
                        right: 18,
                        bottom: 18,
                        width: 310,
                        child: _SelectedAreaModal(
                          area: modalArea,
                          onClose: () {
                            setState(() => _selectedArea = null);
                          },
                        ),
                      ),
                    if (wide || !searchShowingResults)
                      Positioned(
                        right: 16,
                        top: wide ? 14 : 98,
                        child: _MapControls(
                          onZoomIn: () => _zoom(1.22),
                          onZoomOut: () => _zoom(0.82),
                          onReset: () {
                            _transformController.value = Matrix4.identity();
                            setState(() => _mapRotation = 0);
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _zoom(double factor) {
    final current = _transformController.value;
    _transformController.value = current.scaled(factor, factor);
  }

}

class _MapCanvas extends StatelessWidget {
  const _MapCanvas({
    required this.data,
    required this.filteredAreas,
    required this.selectedArea,
    required this.rotation,
    required this.controller,
    required this.onRotationStart,
    required this.onRotationUpdate,
    required this.onSelectArea,
  });

  final ExhibitionMapData data;
  final List<MapFeature> filteredAreas;
  final MapFeature? selectedArea;
  final double rotation;
  final TransformationController controller;
  final VoidCallback onRotationStart;
  final ValueChanged<double> onRotationUpdate;
  final ValueChanged<MapFeature> onSelectArea;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xffeaf4ef), Color(0xfff7ead7)],
            ),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
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
              minScale: 0.7,
              maxScale: 8,
              boundaryMargin: const EdgeInsets.all(220),
              onInteractionStart: (_) => onRotationStart(),
              onInteractionUpdate: (details) {
                if (details.pointerCount > 1 && details.rotation.abs() > 0.002) {
                  onRotationUpdate(details.rotation);
                }
              },
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: CustomPaint(
                  painter: ExhibitionMapPainter(
                    data: data,
                    filteredAreas: filteredAreas,
                    selectedArea: selectedArea,
                    rotation: rotation,
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
    required this.rotation,
  });

  final ExhibitionMapData data;
  final List<MapFeature> filteredAreas;
  final MapFeature? selectedArea;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotation);
    canvas.translate(-size.width / 2, -size.height / 2);

    final projection = data.projectionFor(size);
    final muted = filteredAreas.length != data.buildings.length;
    final filteredIds = filteredAreas.map((feature) => feature.key).toSet();

    _paintSoftGrid(canvas, size);

    final boundaryPaint = Paint()
      ..color = const Color(0xb8c99b57)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final boundaryHaloPaint = Paint()
      ..color = const Color(0x44ffffff)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final boundary in data.boundaries) {
      for (final line in boundary.lines) {
        final path = _linePath(line, projection);
        canvas.drawPath(path, boundaryHaloPaint);
        canvas.drawPath(path, boundaryPaint);
      }
    }

    final roadShadowPaint = Paint()
      ..color = const Color(0x332d4b43)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final roadEdgePaint = Paint()
      ..color = const Color(0xffd89b48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final roadPaint = Paint()
      ..color = const Color(0xfffffff8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final roadCenterPaint = Paint()
      ..color = const Color(0x88c9772d)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final road in data.roads) {
      for (final line in road.lines) {
        final path = _linePath(line, projection);
        canvas.drawPath(path, roadShadowPaint);
        canvas.drawPath(path, roadEdgePaint);
        canvas.drawPath(path, roadPaint);
        canvas.drawPath(path, roadCenterPaint);
      }
    }

    for (final building in data.buildings) {
      final isSelected = selectedArea?.key == building.key;
      final isFiltered = filteredIds.contains(building.key);
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = isSelected
            ? const Color(0xfff26430)
            : isFiltered
                ? const Color(0xff1aa987)
                : muted
                    ? const Color(0xff8bb8aa)
                    : const Color(0xff50b89d);

      for (final polygon in building.polygons) {
        final path = _polygonPath(polygon, projection);
        canvas.drawPath(path, paint);
      }
    }

    for (final building in data.buildings) {
      final isSelected = selectedArea?.key == building.key;
      final isFiltered = filteredIds.contains(building.key);
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.2 : 1.3
        ..color = isSelected ? const Color(0xff70210d) : const Color(0xcc124e43);

      for (final polygon in building.polygons) {
        canvas.drawPath(_polygonPath(polygon, projection), stroke);
      }

      if (!isSelected && isFiltered && filteredAreas.length < 24) {
        _drawLabel(canvas, building, projection, isSelected);
      }
    }

    _drawRoundabouts(canvas, projection);

    final treePaint = Paint()
      ..color = const Color(0xff2d7d46)
      ..style = PaintingStyle.fill;
    final treeHaloPaint = Paint()
      ..color = const Color(0xffffffff)
      ..style = PaintingStyle.fill;
    for (final tree in data.trees) {
      final point = projection.project(tree.points.first);
      canvas.drawCircle(point, 4.2, treeHaloPaint);
      canvas.drawCircle(point, 2.7, treePaint);
    }

    canvas.restore();
    _drawCompass(canvas, size, rotation);
  }

  @override
  bool shouldRepaint(covariant ExhibitionMapPainter oldDelegate) {
    return data != oldDelegate.data ||
        filteredAreas != oldDelegate.filteredAreas ||
        selectedArea != oldDelegate.selectedArea ||
        rotation != oldDelegate.rotation;
  }

  void _paintSoftGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x1a315c52)
      ..strokeWidth = 1;
    const gap = 56.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
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
    textPainter.paint(
      canvas,
      Offset(
        rect.left + 8,
        rect.top + 4,
      ),
    );
  }

  void _drawCompass(Canvas canvas, Size size, double rotation) {
    final base = Offset(size.width - 52, size.height - 82);
    final paint = Paint()
      ..color = const Color(0xdd0b4238)
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(rotation);
    final path = Path()
      ..moveTo(0, -28)
      ..lineTo(-10, 12)
      ..lineTo(0, 5)
      ..lineTo(10, 12)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();

    final tp = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          color: Color(0xff0b4238),
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelPoint = _rotateOffset(base.translate(0, -48), base, rotation);
    tp.paint(canvas, labelPoint.translate(-tp.width / 2, 0));
  }

  Offset _rotateOffset(Offset point, Offset center, double angle) {
    final translated = point - center;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    return Offset(
          translated.dx * cosA - translated.dy * sinA,
          translated.dx * sinA + translated.dy * cosA,
        ) +
        center;
  }

  void _drawRoundabouts(Canvas canvas, MapProjection projection) {
    final outerPaint = Paint()
      ..color = const Color(0xffd89b48)
      ..style = PaintingStyle.fill;
    final roadPaint = Paint()
      ..color = const Color(0xfffffff8)
      ..style = PaintingStyle.fill;
    final islandPaint = Paint()
      ..color = const Color(0xff65b98e)
      ..style = PaintingStyle.fill;
    final islandStrokePaint = Paint()
      ..color = const Color(0xffffffff)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final roundabouts = [
      const GeoPoint(39.278831168638066, -6.864770815767824),
      const GeoPoint(39.280398417925295, -6.866317090268083),
    ];

    for (final roundabout in roundabouts) {
      final center = projection.project(roundabout);
      canvas.drawCircle(center, 6.8, outerPaint);
      canvas.drawCircle(center, 5, roadPaint);
      canvas.drawCircle(center, 2.5, islandPaint);
      canvas.drawCircle(center, 2.5, islandStrokePaint);
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

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.query,
    required this.controller,
    required this.focusNode,
    required this.areas,
    required this.selectedArea,
    required this.showResults,
    required this.onQueryChanged,
    required this.onSelectArea,
    required this.onClear,
  });

  final String query;
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<MapFeature> areas;
  final MapFeature? selectedArea;
  final bool showResults;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<MapFeature> onSelectArea;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      shadowColor: Colors.black26,
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onQueryChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search area, pavilion, service...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: onClear,
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: const Color(0xfff2f5f3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (showResults) ...[
                const SizedBox(height: 12),
                Flexible(
                  child: areas.isEmpty
                      ? const _EmptyResults()
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: areas.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final area = areas[index];
                            final selected = area.key == selectedArea?.key;
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              selected: selected,
                              leading: CircleAvatar(
                                radius: 17,
                                backgroundColor: selected
                                    ? const Color(0xfff26430)
                                    : const Color(0xffe4f4ee),
                                child: Text(
                                  area.shortCode,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xff0b4238),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              title: Text(
                                area.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                area.serviceLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => onSelectArea(area),
                            );
                          },
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedAreaModal extends StatelessWidget {
  const _SelectedAreaModal({
    required this.area,
    required this.onClose,
  });

  final MapFeature area;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      shadowColor: Colors.black26,
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place, color: Color(0xfff26430)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    area.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              area.serviceLine,
              style: const TextStyle(color: Color(0xff40534d)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: area.services
                  .map(
                    (service) => Chip(
                      side: BorderSide.none,
                      backgroundColor: const Color(0xffe4f4ee),
                      label: Text(service),
                      avatar: const Icon(Icons.storefront, size: 18),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicesTab extends StatelessWidget {
  const _ServicesTab({
    required this.areas,
    required this.selectedArea,
    required this.onSelectArea,
  });

  final List<MapFeature> areas;
  final MapFeature? selectedArea;
  final ValueChanged<MapFeature> onSelectArea;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: const Text('Services'),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index.isOdd) {
                    return const SizedBox(height: 8);
                  }

                  final area = areas[index ~/ 2];
                  final selected = area.key == selectedArea?.key;

                  return Material(
                    color: selected ? const Color(0xffffeee7) : Colors.white,
                    elevation: selected ? 4 : 1,
                    shadowColor: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: selected
                            ? const Color(0xfff26430)
                            : const Color(0xffe4f4ee),
                        child: Text(
                          area.shortCode,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xff0b4238),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: Text(
                        area.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        area.serviceLine,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => onSelectArea(area),
                    ),
                  );
                },
                childCount: areas.isEmpty ? 0 : areas.length * 2 - 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({
    required this.buildingCount,
    required this.roadCount,
    required this.treeCount,
  });

  final int buildingCount;
  final int roadCount;
  final int treeCount;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        children: [
          Text(
            'SabaSaba Exhibition',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xff0b4238),
                ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use the map to find areas, services, routes, and nearby landmarks.',
            style: TextStyle(color: Color(0xff40534d)),
          ),
          const SizedBox(height: 18),
          _InfoTile(
            icon: Icons.storefront,
            title: '$buildingCount exhibition areas',
            subtitle: 'Tap any building on the map to view services.',
          ),
          _InfoTile(
            icon: Icons.alt_route,
            title: '$roadCount routes',
            subtitle: 'Zoom, pan, and rotate the map for easier navigation.',
          ),
          _InfoTile(
            icon: Icons.park,
            title: '$treeCount mapped trees',
            subtitle: 'Green markers help orient visitors around the grounds.',
          ),
          const SizedBox(height: 10),
          const _LegendRow(color: Color(0xff1aa987), label: 'Exhibition area'),
          const _LegendRow(color: Color(0xfff26430), label: 'Selected area'),
          const _LegendRow(color: Color(0xffd89b48), label: 'Road and boundary'),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xffe4f4ee),
            child: Icon(icon, color: const Color(0xff0b4238)),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Zoom in',
            onPressed: onZoomIn,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Zoom out',
            onPressed: onZoomOut,
            icon: const Icon(Icons.remove),
          ),
          IconButton(
            tooltip: 'Reset map',
            onPressed: onReset,
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}

class _LoadingMap extends StatelessWidget {
  const _LoadingMap();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: 46,
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _MapError extends StatelessWidget {
  const _MapError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Could not load SabaSaba map.\n$message',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'No matching services found.',
          style: TextStyle(color: Color(0xff5f6f69)),
        ),
      ),
    );
  }
}

class ExhibitionMapData {
  ExhibitionMapData({
    required this.buildings,
    required this.roads,
    required this.trees,
    required this.boundaries,
    required this.bounds,
  });

  final List<MapFeature> buildings;
  final List<MapFeature> roads;
  final List<MapFeature> trees;
  final List<MapFeature> boundaries;
  final GeoBounds bounds;

  static Future<ExhibitionMapData> load() async {
    final buildings = await _loadFeatures('data/majengo.geojson', Layer.building);
    final roads = await _loadFeatures('data/barabara.geojson', Layer.road);
    final trees = await _loadFeatures('data/miti.geojson', Layer.tree);
    final boundaries = await _loadFeatures('data/mpaka.geojson', Layer.boundary);
    final allPoints = [
      for (final feature in [...buildings, ...roads, ...trees, ...boundaries])
        ...feature.allPoints,
    ];

    return ExhibitionMapData(
      buildings: buildings,
      roads: roads,
      trees: trees,
      boundaries: boundaries,
      bounds: GeoBounds.fromPoints(allPoints),
    );
  }

  static Future<List<MapFeature>> _loadFeatures(String path, Layer layer) async {
    final raw = await rootBundle.loadString(path);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final features = json['features'] as List<dynamic>;

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

class MapFeature {
  MapFeature({
    required this.layer,
    required this.index,
    required this.id,
    required this.code,
    required this.polygons,
    required this.lines,
    required this.points,
  });

  final Layer layer;
  final int index;
  final Object? id;
  final String? code;
  final List<List<GeoPoint>> polygons;
  final List<List<GeoPoint>> lines;
  final List<GeoPoint> points;

  String get key => '${layer.name}-$index-${id ?? code ?? 'feature'}';

  String get shortCode {
    final raw = (code?.isNotEmpty ?? false) ? code! : '${id ?? index + 1}';
    return raw.replaceAll(RegExp('[^A-Za-z0-9]'), '').toUpperCase();
  }

  String get title {
    if (layer == Layer.building) {
      final label = shortCode.isEmpty ? '${index + 1}' : shortCode;
      return 'Area $label';
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
    final lng = items.map((point) => point.lng).reduce((a, b) => a + b) /
        items.length;
    final lat = items.map((point) => point.lat).reduce((a, b) => a + b) /
        items.length;
    return GeoPoint(lng, lat);
  }

  factory MapFeature.fromJson(
    Map<String, dynamic> feature,
    Layer layer,
    int index,
  ) {
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

    return MapFeature(
      layer: layer,
      index: index,
      id: properties['id'],
      code: (properties['1'] ?? properties['name'])?.toString(),
      polygons: polygons,
      lines: lines,
      points: points,
    );
  }

  static List<GeoPoint> _parseLine(List<dynamic> line) {
    return line.map((point) => _parsePoint(point as List<dynamic>)).toList();
  }

  static GeoPoint _parsePoint(List<dynamic> value) {
    return GeoPoint(
      (value[0] as num).toDouble(),
      (value[1] as num).toDouble(),
    );
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

class GeoPoint {
  const GeoPoint(this.lng, this.lat);

  final double lng;
  final double lat;
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

  Offset project(GeoPoint point) {
    const padding = 64.0;
    final availableWidth = math.max(1.0, size.width - padding * 2);
    final availableHeight = math.max(1.0, size.height - padding * 2);
    final lngRange = math.max(0.000001, bounds.maxLng - bounds.minLng);
    final latRange = math.max(0.000001, bounds.maxLat - bounds.minLat);
    final scale = math.min(availableWidth / lngRange, availableHeight / latRange);
    final mapWidth = lngRange * scale;
    final mapHeight = latRange * scale;
    final left = (size.width - mapWidth) / 2;
    final top = (size.height - mapHeight) / 2;
    final x = left + (point.lng - bounds.minLng) * scale;
    final y = top + (bounds.maxLat - point.lat) * scale;
    return Offset(x, y);
  }
}
