import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const double _minMapScale = 0.7;
const double _maxMapScale = 6;

void main() {
  runApp(const SabaSabaApp());
}

class SabaSabaApp extends StatelessWidget {
  const SabaSabaApp({super.key, this.mapData});

  final Future<ExhibitionMapData>? mapData;

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
      home: ExhibitionMapScreen(mapData: mapData),
    );
  }
}

class ExhibitionMapScreen extends StatefulWidget {
  const ExhibitionMapScreen({super.key, this.mapData});

  final Future<ExhibitionMapData>? mapData;

  @override
  State<ExhibitionMapScreen> createState() => _ExhibitionMapScreenState();
}

class _ExhibitionMapScreenState extends State<ExhibitionMapScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _authNameController = TextEditingController();
  final TextEditingController _authEmailController = TextEditingController();
  final TextEditingController _authPasswordController = TextEditingController();
  final TextEditingController _exhibitorNameController =
      TextEditingController();
  final TextEditingController _exhibitorEmailController =
      TextEditingController();
  final TextEditingController _boothNameController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TransformationController _transformController =
      TransformationController();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  late Future<ExhibitionMapData> _mapFuture;
  bool _isOffline = false;
  String _query = '';
  bool _searchFocused = false;
  double _mapRotation = 0;
  double _gestureRotationStart = 0;
  int _selectedNavIndex = 0;
  bool _registerMode = false;
  bool _exhibitorRegisterMode = false;
  bool _locationAllowed = false;
  MapTileStyle _tileStyle = MapTileStyle.openStreetMap;
  UserAccount? _account;
  UserAccount? _exhibitorAccount;
  String _boothName = 'SabaSaba Exhibitor Booth';
  final List<String> _exhibitorProducts = [
    'Product display',
    'Customer support',
  ];
  final List<VisitorInquiry> _visitorInquiries = [
    VisitorInquiry(
      visitor: 'Asha M.',
      message: 'Do you accept mobile payments?',
    ),
    VisitorInquiry(
      visitor: 'Daniel K.',
      message: 'What time will the product demo start?',
    ),
  ];
  MapFeature? _selectedArea;
  VisitorService? _selectedService;
  bool _routingMode = false;
  bool _routeMinimized = false;
  String _startLocationId = '';
  String _endLocationId = '';
  RouteResult? _currentRoute;
  String? _routeNotice;

  @override
  void initState() {
    super.initState();
    _mapFuture = widget.mapData ?? ExhibitionMapData.load();
    if (widget.mapData == null) {
      _monitorConnectivity();
    }
    _boothNameController.text = _boothName;
    _searchFocusNode.addListener(() {
      setState(() => _searchFocused = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _searchController.dispose();
    _authNameController.dispose();
    _authEmailController.dispose();
    _authPasswordController.dispose();
    _exhibitorNameController.dispose();
    _exhibitorEmailController.dispose();
    _boothNameController.dispose();
    _productController.dispose();
    _replyController.dispose();
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
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge),
            label: 'Exhibitor',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'You',
          ),
        ],
      ),
      body: Column(
        children: [
          _ConnectionBanner(isOffline: _isOffline),
          Expanded(
            child: FutureBuilder<ExhibitionMapData>(
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
                    _selectedArea != null &&
                        visibleAreas.contains(_selectedArea)
                    ? _selectedArea
                    : visibleAreas.length == 1
                    ? visibleAreas.first
                    : _selectedArea;
                final modalArea = _selectedService == null
                    ? _selectedArea
                    : null;

                if (_selectedNavIndex == 1) {
                  return _ServicesTab(
                    areas: data.buildings,
                    selectedService: _selectedService,
                    onSelectService: _openService,
                  );
                }

                if (_selectedNavIndex == 2) {
                  return _InfoTab(
                    buildingCount: data.buildings.length,
                    roadCount: data.roads.length,
                    treeCount: data.trees.length,
                  );
                }

                if (_selectedNavIndex == 3) {
                  return _ExhibitorTab(
                    account: _exhibitorAccount,
                    registerMode: _exhibitorRegisterMode,
                    nameController: _exhibitorNameController,
                    emailController: _exhibitorEmailController,
                    boothNameController: _boothNameController,
                    productController: _productController,
                    replyController: _replyController,
                    boothName: _boothName,
                    products: _exhibitorProducts,
                    inquiries: _visitorInquiries,
                    onToggleMode: () {
                      setState(
                        () => _exhibitorRegisterMode = !_exhibitorRegisterMode,
                      );
                    },
                    onSubmit: () {
                      final email = _exhibitorEmailController.text.trim();
                      final fallbackName = email.isEmpty
                          ? 'Exhibitor'
                          : email.split('@').first;
                      setState(() {
                        _exhibitorAccount = UserAccount(
                          name:
                              _exhibitorRegisterMode &&
                                  _exhibitorNameController.text
                                      .trim()
                                      .isNotEmpty
                              ? _exhibitorNameController.text.trim()
                              : fallbackName,
                          email: email.isEmpty
                              ? 'exhibitor@sabasaba.local'
                              : email,
                        );
                      });
                    },
                    onSaveBooth: () {
                      final value = _boothNameController.text.trim();
                      if (value.isEmpty) {
                        return;
                      }
                      setState(() => _boothName = value);
                    },
                    onAddProduct: () {
                      final value = _productController.text.trim();
                      if (value.isEmpty) {
                        return;
                      }
                      setState(() {
                        _exhibitorProducts.add(value);
                        _productController.clear();
                      });
                    },
                    onReply: (index) {
                      final reply = _replyController.text.trim();
                      if (reply.isEmpty) {
                        return;
                      }
                      setState(() {
                        _visitorInquiries[index] = _visitorInquiries[index]
                            .copyWith(response: reply);
                        _replyController.clear();
                      });
                    },
                    onLogout: () {
                      setState(() => _exhibitorAccount = null);
                    },
                  );
                }

                if (_selectedNavIndex == 4) {
                  return _YouTab(
                    account: _account,
                    registerMode: _registerMode,
                    nameController: _authNameController,
                    emailController: _authEmailController,
                    passwordController: _authPasswordController,
                    onToggleMode: () {
                      setState(() => _registerMode = !_registerMode);
                    },
                    onSubmit: () {
                      final email = _authEmailController.text.trim();
                      final fallbackName = email.isEmpty
                          ? 'Visitor'
                          : email.split('@').first;
                      setState(() {
                        _account = UserAccount(
                          name:
                              _registerMode &&
                                  _authNameController.text.trim().isNotEmpty
                              ? _authNameController.text.trim()
                              : fallbackName,
                          email: email.isEmpty
                              ? 'visitor@sabasaba.local'
                              : email,
                        );
                        _authPasswordController.clear();
                      });
                    },
                    onLogout: () {
                      setState(() => _account = null);
                    },
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
                          setState(() {
                            _selectedArea = area;
                            _selectedService = null;
                          });
                          _searchFocusNode.unfocus();
                        },
                        onClear: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                            _selectedArea = null;
                            _selectedService = null;
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
                              selectedService: _selectedService,
                              tileStyle: _tileStyle,
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
                                if (!_routingMode) {
                                  setState(() {
                                    _selectedArea = area;
                                    _selectedService = null;
                                  });
                                  _searchFocusNode.unfocus();
                                }
                              },
                              route: _currentRoute,
                              startPoint: _currentRoute == null || _startLocationId.isEmpty
                                  ? null
                                  : data.locations.firstWhere((loc) => loc.id == _startLocationId, orElse: () => data.locations.first).position,
                              endPoint: _currentRoute == null || _endLocationId.isEmpty
                                  ? null
                                  : data.locations.firstWhere((loc) => loc.id == _endLocationId, orElse: () => data.locations.first).position,
                            ),
                          ),
                          if (modalArea != null && !_routingMode)
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
                            child: _routingMode
                                ? (_routeMinimized
                                    ? _MinimizedRouteHeader(
                                        startLabel: data.locations.firstWhere((loc) => loc.id == _startLocationId, orElse: () => data.locations.first).label,
                                        endLabel: data.locations.firstWhere((loc) => loc.id == _endLocationId, orElse: () => data.locations.first).label,
                                        distance: _currentRoute?.distance ?? 0.0,
                                        onEdit: () {
                                          setState(() => _routeMinimized = false);
                                        },
                                        onClose: () {
                                          _clearRoute();
                                        },
                                      )
                                    : _RouteInputPanel(
                                        locations: data.locations,
                                        startId: _startLocationId,
                                        endId: _endLocationId,
                                        notice: _routeNotice,
                                        onStartChanged: (id) {
                                          setState(() {
                                            _startLocationId = id;
                                            _currentRoute = null;
                                            _routeMinimized = false;
                                          });
                                        },
                                        onEndChanged: (id) {
                                          setState(() {
                                            _endLocationId = id;
                                            _currentRoute = null;
                                            _routeMinimized = false;
                                          });
                                        },
                                        onFindRoute: () => _calculateRoute(data),
                                        onSwap: _swapLocations,
                                        onBack: () {
                                          setState(() {
                                            _routingMode = false;
                                            _clearRoute();
                                          });
                                        },
                                      ))
                                : panel,
                          ),
                          if (modalArea != null && !wide && !_routingMode)
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
                          if (modalArea != null && wide && !_routingMode)
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
                          if (_selectedService != null && !wide && !_routingMode)
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 14,
                              child: _SelectedServiceNavigationCard(
                                service: _selectedService!,
                                onClose: () {
                                  setState(() => _selectedService = null);
                                },
                              ),
                            ),
                          if (_selectedService != null && wide && !_routingMode)
                            Positioned(
                              right: 18,
                              bottom: 18,
                              width: 310,
                              child: _SelectedServiceNavigationCard(
                                service: _selectedService!,
                                onClose: () {
                                  setState(() => _selectedService = null);
                                },
                              ),
                            ),
                          if (wide || !searchShowingResults)
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              right: 16,
                              top: wide
                                  ? 14
                                  : (_routingMode && !_routeMinimized ? 260.0 : 98.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _MapControls(
                                    tileStyle: _tileStyle,
                                    onTileStyleChanged: (style) {
                                      setState(() => _tileStyle = style);
                                    },
                                    onZoomIn: () => _zoom(1.22),
                                    onZoomOut: () => _zoom(0.82),
                                    onReset: () {
                                      _transformController.value =
                                          Matrix4.identity();
                                      setState(() => _mapRotation = 0);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _CompassControl(rotation: _mapRotation),
                                  if (!_routingMode) ...[
                                    const SizedBox(height: 12),
                                    FloatingActionButton(
                                      mini: true,
                                      backgroundColor: const Color(0xff0b4238),
                                      foregroundColor: Colors.white,
                                      onPressed: () {
                                        setState(() {
                                          _routingMode = true;
                                          _routeMinimized = false;
                                        });
                                      },
                                      child: const Icon(Icons.directions),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _monitorConnectivity() async {
    final connectivity = Connectivity();
    _connectivitySubscription = connectivity.onConnectivityChanged.listen(
      _updateConnectivity,
    );
    _updateConnectivity(await connectivity.checkConnectivity());
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    if (!mounted) {
      return;
    }
    final isOffline =
        results.isEmpty || results.contains(ConnectivityResult.none);
    final reconnected = _isOffline && !isOffline;
    setState(() {
      _isOffline = isOffline;
      if (reconnected) {
        _mapFuture = ExhibitionMapData.load();
      }
    });
  }

  void _zoom(double factor) {
    final current = _transformController.value;
    final currentScale = current.getMaxScaleOnAxis();
    final nextScale = (currentScale * factor).clamp(_minMapScale, _maxMapScale);
    if (currentScale == nextScale) {
      return;
    }

    final adjustedFactor = nextScale / currentScale;
    _transformController.value = current.scaled(adjustedFactor, adjustedFactor);
  }

  Future<void> _openService(VisitorService service) async {
    if (!_locationAllowed) {
      final allowed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Allow location access?'),
            content: Text(
              'SabaSaba needs your device location to show directions to ${service.title}.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Allow'),
              ),
            ],
          );
        },
      );

      if (allowed != true || !mounted) {
        return;
      }
      _locationAllowed = true;
    }

    setState(() {
      _selectedService = service;
      _selectedArea = service.area;
      _selectedNavIndex = 0;
    });
    _searchFocusNode.unfocus();
  }

  void _clearRoute() {
    setState(() {
      _startLocationId = '';
      _endLocationId = '';
      _currentRoute = null;
      _routeNotice = null;
      _routeMinimized = false;
    });
  }

  void _swapLocations() {
    setState(() {
      final temp = _startLocationId;
      _startLocationId = _endLocationId;
      _endLocationId = temp;
      if (_currentRoute != null) {
        _currentRoute = null;
        _routeMinimized = false;
      }
    });
  }

  void _calculateRoute(ExhibitionMapData data) {
    setState(() => _routeNotice = null);
    if (_startLocationId.isEmpty || _endLocationId.isEmpty) {
      setState(() => _routeNotice = 'Please select both start and end locations.');
      return;
    }
    if (_startLocationId == _endLocationId) {
      setState(() => _routeNotice = 'Start and end locations must be different.');
      return;
    }

    final start = data.locations.firstWhere((loc) => loc.id == _startLocationId);
    final end = data.locations.firstWhere((loc) => loc.id == _endLocationId);
    final result = shortestPath(start.nodeId, end.nodeId, data.edges);
    if (result == null) {
      setState(() => _routeNotice = 'No path was found between these locations.');
      return;
    }

    setState(() {
      _currentRoute = result;
      _routeMinimized = true;
    });
  }
}

class _MapCanvas extends StatelessWidget {
  const _MapCanvas({
    required this.data,
    required this.filteredAreas,
    required this.selectedArea,
    required this.selectedService,
    required this.tileStyle,
    required this.rotation,
    required this.controller,
    required this.onRotationStart,
    required this.onRotationUpdate,
    required this.onSelectArea,
    this.route,
    this.startPoint,
    this.endPoint,
  });

  final ExhibitionMapData data;
  final List<MapFeature> filteredAreas;
  final MapFeature? selectedArea;
  final VisitorService? selectedService;
  final MapTileStyle tileStyle;
  final double rotation;
  final TransformationController controller;
  final VoidCallback onRotationStart;
  final ValueChanged<double> onRotationUpdate;
  final ValueChanged<MapFeature> onSelectArea;
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
              minScale: _minMapScale,
              maxScale: _maxMapScale,
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
                      _MapTileLayer(data: data, tileStyle: tileStyle),
                      CustomPaint(
                        painter: ExhibitionMapPainter(
                          data: data,
                          filteredAreas: filteredAreas,
                          selectedArea: selectedArea,
                          selectedService: selectedService,
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
    this.route,
    this.startPoint,
    this.endPoint,
  });

  final ExhibitionMapData data;
  final List<MapFeature> filteredAreas;
  final MapFeature? selectedArea;
  final VisitorService? selectedService;
  final RouteResult? route;
  final GeoPoint? startPoint;
  final GeoPoint? endPoint;

  @override
  void paint(Canvas canvas, Size size) {
    final projection = data.projectionFor(size);
    final muted = filteredAreas.length != data.buildings.length;
    final filteredIds = filteredAreas.map((feature) => feature.key).toSet();

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
        ..color = isSelected
            ? const Color(0xff70210d)
            : const Color(0xcc124e43);

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

    // Paint route polyline if found
    final activeRoute = route;
    if (activeRoute != null && startPoint != null && endPoint != null) {
      final routePoints = <Offset>[];
      final nodeById = {for (final node in data.nodes) node.id: node};
      for (final nodeId in activeRoute.nodeIds) {
        final node = nodeById[nodeId];
        if (node != null) {
          routePoints.add(projection.project(GeoPoint(node.longitude, node.latitude)));
        }
      }

      if (routePoints.isNotEmpty) {
        final routePaint = Paint()
          ..color = const Color(0xff4a90e2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        _drawDashedPolyline(canvas, routePoints, routePaint);

        // Paint start marker (Green)
        final startOffset = projection.project(startPoint!);
        canvas.drawCircle(startOffset, 8, Paint()..color = Colors.white);
        canvas.drawCircle(startOffset, 7, Paint()..color = const Color(0xff4CAF50));

        // Paint end marker (Red)
        final endOffset = projection.project(endPoint!);
        canvas.drawCircle(endOffset, 8, Paint()..color = Colors.white);
        canvas.drawCircle(endOffset, 7, Paint()..color = const Color(0xffF44336));
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

    const dashWidth = 8.0;
    const dashSpace = 6.0;
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

class _MapTileLayer extends StatelessWidget {
  const _MapTileLayer({required this.data, required this.tileStyle});

  final ExhibitionMapData data;
  final MapTileStyle tileStyle;

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
                  _TileImage(
                    rect: _tileRect(x, y, zoom, projection),
                    url: tileStyle.tileUrl(x, y, zoom),
                    fallbackColor: tileStyle.fallbackColor,
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

class _TileImage extends StatelessWidget {
  const _TileImage({
    required this.rect,
    required this.url,
    required this.fallbackColor,
  });

  final Rect rect;
  final String url;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: math.max(1, rect.width),
      height: math.max(1, rect.height),
      child: Image.network(
        url,
        fit: BoxFit.fill,
        errorBuilder: (_, __, ___) {
          return ColoredBox(color: fallbackColor);
        },
      ),
    );
  }
}

class _RouteInputPanel extends StatelessWidget {
  const _RouteInputPanel({
    required this.locations,
    required this.startId,
    required this.endId,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onFindRoute,
    required this.onSwap,
    required this.onBack,
    this.notice,
  });

  final List<RoutingLocation> locations;
  final String startId;
  final String endId;
  final ValueChanged<String> onStartChanged;
  final ValueChanged<String> onEndChanged;
  final VoidCallback onFindRoute;
  final VoidCallback onSwap;
  final VoidCallback onBack;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      shadowColor: Colors.black26,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xff0b4238)),
                  onPressed: onBack,
                  tooltip: 'Exit route finder',
                ),
                const SizedBox(width: 4),
                const Text(
                  'Route Finder',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xff0b4238),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.swap_vert, color: Color(0xff0b4238)),
                  onPressed: onSwap,
                  tooltip: 'Swap locations',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xfff2f5f3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: startId.isEmpty ? null : startId,
                  hint: const Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xff4CAF50), size: 12),
                      SizedBox(width: 8),
                      Text('Select starting point', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                  items: locations.map((loc) {
                    return DropdownMenuItem<String>(
                      value: loc.id,
                      child: Row(
                        children: [
                          const Icon(Icons.circle, color: Color(0xff4CAF50), size: 12),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loc.label,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) onStartChanged(val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xfff2f5f3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: endId.isEmpty ? null : endId,
                  hint: const Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xffF44336), size: 12),
                      SizedBox(width: 8),
                      Text('Select destination', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                  items: locations.map((loc) {
                    return DropdownMenuItem<String>(
                      value: loc.id,
                      child: Row(
                        children: [
                          const Icon(Icons.circle, color: Color(0xffF44336), size: 12),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loc.label,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) onEndChanged(val);
                  },
                ),
              ),
            ),
            if (notice != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xfffff3cd),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  notice!,
                  style: const TextStyle(color: Color(0xff664d03), fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff0b4238),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onFindRoute,
              icon: const Icon(Icons.directions, size: 20),
              label: const Text(
                'Find Route',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimizedRouteHeader extends StatelessWidget {
  const _MinimizedRouteHeader({
    required this.startLabel,
    required this.endLabel,
    required this.distance,
    required this.onEdit,
    required this.onClose,
  });

  final String startLabel;
  final String endLabel;
  final double distance;
  final VoidCallback onEdit;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      shadowColor: Colors.black26,
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions, color: Color(0xff0b4238), size: 20),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$startLabel → $endLabel',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xff0b4238),
                  ),
                ),
                Text(
                  'Distance: ${distance.toStringAsFixed(0)} meters',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(999),
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xffe4f4ee),
                child: Icon(Icons.edit, color: Color(0xff0b4238), size: 14),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(999),
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xffffebee),
                child: Icon(Icons.close, color: Color(0xffc62828), size: 14),
              ),
            ),
          ],
        ),
      ),
    );
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          elevation: 12,
          shadowColor: Colors.black26,
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search area, pavilion, service...',
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 15,
              ),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: onClear,
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (showResults) ...[
          const SizedBox(height: 8),
          Material(
            elevation: 12,
            shadowColor: Colors.black26,
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
            ),
          ),
        ],
      ],
    );
  }
}

class _SelectedAreaModal extends StatelessWidget {
  const _SelectedAreaModal({required this.area, required this.onClose});

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

class _SelectedServiceNavigationCard extends StatelessWidget {
  const _SelectedServiceNavigationCard({
    required this.service,
    required this.onClose,
  });

  final VisitorService service;
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xffffeee7),
                  child: Icon(service.icon, color: const Color(0xfff26430)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    service.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              service.description,
              style: const TextStyle(color: Color(0xff40534d)),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Follow the highlighted marker to ${service.title}.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.near_me),
              label: const Text('Navigate'),
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
    required this.selectedService,
    required this.onSelectService,
  });

  final List<MapFeature> areas;
  final VisitorService? selectedService;
  final ValueChanged<VisitorService> onSelectService;

  @override
  Widget build(BuildContext context) {
    final services = VisitorService.forAreas(areas);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        children: [
          Text(
            'Services',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xff0b4238),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Find essential visitor facilities and open their location on the map.',
            style: TextStyle(color: Color(0xff40534d)),
          ),
          const SizedBox(height: 16),
          for (final service in services) ...[
            _VisitorServiceTile(
              service: service,
              selected: selectedService?.title == service.title,
              onTap: () => onSelectService(service),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _VisitorServiceTile extends StatelessWidget {
  const _VisitorServiceTile({
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final VisitorService service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xffffeee7) : Colors.white,
      elevation: selected ? 4 : 1,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: CircleAvatar(
          backgroundColor: selected ? const Color(0xfff26430) : service.tint,
          child: Icon(
            service.icon,
            color: selected ? Colors.white : const Color(0xff0b4238),
          ),
        ),
        title: Text(
          service.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          service.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.near_me_outlined),
        onTap: onTap,
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
          const _LegendRow(
            color: Color(0xffd89b48),
            label: 'Road and boundary',
          ),
        ],
      ),
    );
  }
}

class _ExhibitorTab extends StatelessWidget {
  const _ExhibitorTab({
    required this.account,
    required this.registerMode,
    required this.nameController,
    required this.emailController,
    required this.boothNameController,
    required this.productController,
    required this.replyController,
    required this.boothName,
    required this.products,
    required this.inquiries,
    required this.onToggleMode,
    required this.onSubmit,
    required this.onSaveBooth,
    required this.onAddProduct,
    required this.onReply,
    required this.onLogout,
  });

  final UserAccount? account;
  final bool registerMode;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController boothNameController;
  final TextEditingController productController;
  final TextEditingController replyController;
  final String boothName;
  final List<String> products;
  final List<VisitorInquiry> inquiries;
  final VoidCallback onToggleMode;
  final VoidCallback onSubmit;
  final VoidCallback onSaveBooth;
  final VoidCallback onAddProduct;
  final ValueChanged<int> onReply;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final currentAccount = account;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        children: [
          Text(
            'Exhibitor',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xff0b4238),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage your booth, services, and visitor enquiries.',
            style: TextStyle(color: Color(0xff40534d)),
          ),
          const SizedBox(height: 14),
          if (currentAccount == null)
            _ExhibitorLoginCard(
              registerMode: registerMode,
              nameController: nameController,
              emailController: emailController,
              onToggleMode: onToggleMode,
              onSubmit: onSubmit,
            )
          else ...[
            _ExhibitorHeader(account: currentAccount, onLogout: onLogout),
            _ExhibitorBoothCard(
              boothName: boothName,
              controller: boothNameController,
              onSave: onSaveBooth,
            ),
            _ExhibitorProductsCard(
              products: products,
              controller: productController,
              onAdd: onAddProduct,
            ),
            _ExhibitorInquiryCard(
              inquiries: inquiries,
              replyController: replyController,
              onReply: onReply,
            ),
          ],
        ],
      ),
    );
  }
}

class _ExhibitorLoginCard extends StatelessWidget {
  const _ExhibitorLoginCard({
    required this.registerMode,
    required this.nameController,
    required this.emailController,
    required this.onToggleMode,
    required this.onSubmit,
  });

  final bool registerMode;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final VoidCallback onToggleMode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              registerMode ? 'Register exhibitor' : 'Exhibitor login',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (registerMode) ...[
              _AccountField(
                controller: nameController,
                icon: Icons.badge_outlined,
                label: 'Exhibitor name',
              ),
              const SizedBox(height: 10),
            ],
            _AccountField(
              controller: emailController,
              icon: Icons.email_outlined,
              label: 'Business email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onSubmit,
              icon: Icon(registerMode ? Icons.person_add : Icons.login),
              label: Text(registerMode ? 'Register / Login' : 'Login'),
            ),
            TextButton(
              onPressed: onToggleMode,
              child: Text(
                registerMode
                    ? 'Already registered? Login'
                    : 'New exhibitor? Register',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExhibitorHeader extends StatelessWidget {
  const _ExhibitorHeader({required this.account, required this.onLogout});

  final UserAccount account;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xff0b4238),
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.white,
            child: Text(
              account.initials,
              style: const TextStyle(
                color: Color(0xff0b4238),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          title: Text(
            account.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            account.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xffd6eee6)),
          ),
          trailing: IconButton(
            tooltip: 'Logout',
            onPressed: onLogout,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _ExhibitorBoothCard extends StatelessWidget {
  const _ExhibitorBoothCard({
    required this.boothName,
    required this.controller,
    required this.onSave,
  });

  final String boothName;
  final TextEditingController controller;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return _ExhibitorSection(
      icon: Icons.storefront,
      title: 'Manage booth profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(boothName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _AccountField(
            controller: controller,
            icon: Icons.edit_location_alt_outlined,
            label: 'Booth name or profile title',
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save booth profile'),
          ),
        ],
      ),
    );
  }
}

class _ExhibitorProductsCard extends StatelessWidget {
  const _ExhibitorProductsCard({
    required this.products,
    required this.controller,
    required this.onAdd,
  });

  final List<String> products;
  final TextEditingController controller;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return _ExhibitorSection(
      icon: Icons.inventory_2_outlined,
      title: 'Update products / services',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final product in products)
                Chip(
                  side: BorderSide.none,
                  backgroundColor: const Color(0xffe4f4ee),
                  avatar: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(product),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _AccountField(
            controller: controller,
            icon: Icons.add_business_outlined,
            label: 'Add product or service',
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add item'),
          ),
        ],
      ),
    );
  }
}

class _ExhibitorInquiryCard extends StatelessWidget {
  const _ExhibitorInquiryCard({
    required this.inquiries,
    required this.replyController,
    required this.onReply,
  });

  final List<VisitorInquiry> inquiries;
  final TextEditingController replyController;
  final ValueChanged<int> onReply;

  @override
  Widget build(BuildContext context) {
    return _ExhibitorSection(
      icon: Icons.question_answer_outlined,
      title: 'Visitor enquiries',
      child: Column(
        children: [
          for (var i = 0; i < inquiries.length; i++) ...[
            _InquiryTile(
              inquiry: inquiries[i],
              replyController: replyController,
              onReply: () => onReply(i),
            ),
            if (i != inquiries.length - 1) const Divider(height: 18),
          ],
        ],
      ),
    );
  }
}

class _InquiryTile extends StatelessWidget {
  const _InquiryTile({
    required this.inquiry,
    required this.replyController,
    required this.onReply,
  });

  final VisitorInquiry inquiry;
  final TextEditingController replyController;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
          title: Text(
            inquiry.visitor,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(inquiry.message),
        ),
        if (inquiry.response != null)
          Padding(
            padding: const EdgeInsets.only(left: 56, bottom: 8),
            child: Text(
              'Response: ${inquiry.response}',
              style: const TextStyle(
                color: Color(0xff0b4238),
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else ...[
          _AccountField(
            controller: replyController,
            icon: Icons.reply_outlined,
            label: 'Reply to visitor',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onReply,
              icon: const Icon(Icons.send_outlined),
              label: const Text('Respond'),
            ),
          ),
        ],
      ],
    );
  }
}

class _ExhibitorSection extends StatelessWidget {
  const _ExhibitorSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xffe4f4ee),
                    child: Icon(icon, color: const Color(0xff0b4238)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _YouTab extends StatelessWidget {
  const _YouTab({
    required this.account,
    required this.registerMode,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.onToggleMode,
    required this.onSubmit,
    required this.onLogout,
  });

  final UserAccount? account;
  final bool registerMode;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onToggleMode;
  final VoidCallback onSubmit;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final currentAccount = account;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        children: [
          Text(
            'You',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xff0b4238),
            ),
          ),
          const SizedBox(height: 14),
          if (currentAccount == null)
            _AuthCard(
              registerMode: registerMode,
              nameController: nameController,
              emailController: emailController,
              passwordController: passwordController,
              onToggleMode: onToggleMode,
              onSubmit: onSubmit,
            )
          else
            _AccountCard(account: currentAccount, onLogout: onLogout),
        ],
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.registerMode,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.onToggleMode,
    required this.onSubmit,
  });

  final bool registerMode;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onToggleMode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              registerMode ? 'Create account' : 'Login',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (registerMode) ...[
              _AccountField(
                controller: nameController,
                icon: Icons.badge_outlined,
                label: 'Full name',
              ),
              const SizedBox(height: 10),
            ],
            _AccountField(
              controller: emailController,
              icon: Icons.email_outlined,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            _AccountField(
              controller: passwordController,
              icon: Icons.lock_outline,
              label: 'Password',
              obscureText: true,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onSubmit,
              icon: Icon(registerMode ? Icons.person_add : Icons.login),
              label: Text(registerMode ? 'Register' : 'Login'),
            ),
            TextButton(
              onPressed: onToggleMode,
              child: Text(
                registerMode
                    ? 'Already have an account? Login'
                    : 'New visitor? Register',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account, required this.onLogout});

  final UserAccount account;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xff0b4238),
                  child: Text(
                    account.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        account.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xff40534d)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _InfoTile(
              icon: Icons.bookmark_outline,
              title: 'Saved places',
              subtitle: 'Bookmarked booths and services will appear here.',
            ),
            const _InfoTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Updates for services and exhibition events.',
            ),
            OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountField extends StatelessWidget {
  const _AccountField({
    required this.controller,
    required this.icon,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xfff2f5f3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
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
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
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
    required this.tileStyle,
    required this.onTileStyleChanged,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final MapTileStyle tileStyle;
  final ValueChanged<MapTileStyle> onTileStyleChanged;
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
          PopupMenuButton<MapTileStyle>(
            tooltip: 'Map tiles',
            initialValue: tileStyle,
            onSelected: onTileStyleChanged,
            icon: const Icon(Icons.layers_outlined),
            itemBuilder: (context) {
              return [
                for (final style in MapTileStyle.values)
                  PopupMenuItem(
                    value: style,
                    child: Row(
                      children: [
                        Icon(style.icon, color: style.accentColor),
                        const SizedBox(width: 12),
                        Text(style.label),
                      ],
                    ),
                  ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

class _CompassControl extends StatelessWidget {
  const _CompassControl({required this.rotation});

  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      color: Colors.white,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Center(
          child: Transform.rotate(
            angle: rotation,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'N',
                  style: TextStyle(
                    color: Color(0xff0b4238),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Icon(Icons.navigation, color: Color(0xdd0b4238), size: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingMap extends StatelessWidget {
  const _LoadingMap();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(dimension: 46, child: CircularProgressIndicator()),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.isOffline});

  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final background = isOffline
        ? const Color(0xffffe0b2)
        : const Color(0xffd7f3e8);
    final foreground = isOffline
        ? const Color(0xff8a4200)
        : const Color(0xff075e4a);

    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        color: background,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOffline ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
              size: 17,
              color: foreground,
            ),
            const SizedBox(width: 7),
            Text(
              isOffline ? 'Offline — no internet connection' : 'Online',
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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

class RoutingNode {
  final String id;
  final double latitude;
  final double longitude;

  RoutingNode({
    required this.id,
    required this.latitude,
    required this.longitude,
  });

  factory RoutingNode.fromJson(Map<String, dynamic> json) {
    return RoutingNode(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class RoutingEdge {
  final String id;
  final String? sourceNodeId;
  final String? targetNodeId;
  final double distance;
  final bool bidirectional;

  RoutingEdge({
    required this.id,
    this.sourceNodeId,
    this.targetNodeId,
    required this.distance,
    required this.bidirectional,
  });

  factory RoutingEdge.fromJson(Map<String, dynamic> json) {
    return RoutingEdge(
      id: json['id'] as String,
      sourceNodeId: json['source_node_id'] as String?,
      targetNodeId: json['target_node_id'] as String?,
      distance: (json['distance'] as num).toDouble(),
      bidirectional: json['bidirectional'] as bool? ?? true,
    );
  }
}

class RouteResult {
  final List<String> nodeIds;
  final double distance;

  RouteResult({required this.nodeIds, required this.distance});
}

class RoutingLocation {
  final String id;
  final String label;
  final String description;
  final GeoPoint position;
  final String nodeId;

  RoutingLocation({
    required this.id,
    required this.label,
    required this.description,
    required this.position,
    required this.nodeId,
  });
}

RoutingNode nearestNode(GeoPoint position, List<RoutingNode> nodes) {
  var nearest = nodes.first;
  var nearestDistance = double.infinity;
  for (final node in nodes) {
    final lngDelta = node.longitude - position.lng;
    final latDelta = node.latitude - position.lat;
    final distance = lngDelta * lngDelta + latDelta * latDelta;
    if (distance < nearestDistance) {
      nearest = node;
      nearestDistance = distance;
    }
  }
  return nearest;
}

RouteResult? shortestPath(String startId, String endId, List<RoutingEdge> edges) {
  if (edges.isEmpty) return null;
  final graph = <String, List<MapEntry<String, double>>>{};
  
  void connect(String source, String target, double distance) {
    graph.putIfAbsent(source, () => []).add(MapEntry(target, distance));
  }
  
  for (final edge in edges) {
    final src = edge.sourceNodeId;
    final dst = edge.targetNodeId;
    if (src == null || dst == null) continue;
    connect(src, dst, edge.distance);
    if (edge.bidirectional) {
      connect(dst, src, edge.distance);
    }
  }

  final distances = <String, double>{startId: 0.0};
  final previous = <String, String>{};
  final pending = <String>{startId};

  while (pending.isNotEmpty) {
    String? current;
    var currentDistance = double.infinity;
    
    for (final nodeId in pending) {
      final d = distances[nodeId] ?? double.infinity;
      if (d < currentDistance) {
        current = nodeId;
        currentDistance = d;
      }
    }
    
    if (current == null) break;
    pending.remove(current);
    
    if (current == endId) break;
    
    final neighbors = graph[current] ?? const [];
    for (final neighbor in neighbors) {
      final neighborId = neighbor.key;
      final neighborDist = neighbor.value;
      final nextDistance = currentDistance + neighborDist;
      
      final currentNeighborDistance = distances[neighborId] ?? double.infinity;
      if (nextDistance < currentNeighborDistance) {
        distances[neighborId] = nextDistance;
        previous[neighborId] = current;
        pending.add(neighborId);
      }
    }
  }

  final distance = distances[endId];
  if (distance == null) return null;
  
  final nodeIds = <String>[endId];
  while (nodeIds.first != startId) {
    final predecessor = previous[nodeIds.first];
    if (predecessor == null) return null;
    nodeIds.insert(0, predecessor);
  }
  
  return RouteResult(nodeIds: nodeIds, distance: distance);
}

class ExhibitionMapData {
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
    final response = await http.get(
      _mapEndpoint,
      headers: const {'accept': 'application/json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Map API returned ${response.statusCode} ${response.reasonPhrase ?? ''}'
            .trim(),
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>?;
    final layers = data?['layers'] as List<dynamic>?;
    if (layers == null) {
      print('SabaSaba Map API Error: No layers found in payload: $payload');
      throw const FormatException('Map API response does not contain layers.');
    }

    print('SabaSaba Map API - Available Layers: ${layers.map((l) => l?['id']).toList()}');

    var buildings = <MapFeature>[];
    final List<MapFeature> roads;
    final List<MapFeature> trees;
    final List<MapFeature> boundaries;

    try {
      buildings = _loadFeatures(layers, 'booths', Layer.building);
      if (buildings.isEmpty) {
        buildings = _loadFeatures(layers, 'buildings', Layer.building);
      }
      roads = _loadFeatures(layers, 'roads', Layer.road);
      trees = _loadFeatures(layers, 'trees', Layer.tree);
      boundaries = _loadFeatures(layers, 'boundary', Layer.boundary);
    } catch (e, stackTrace) {
      print('SabaSaba Map Parsing Failed: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }

    // Fallback: If both booths and buildings layers have 0 features in the API response,
    // fetch features of the layer with editor_key = 'buildings' directly from Supabase REST API!
    if (buildings.isEmpty) {
      try {
        final headers = {
          'apikey': 'sb_publishable_AMEQ6X4TMeyGz1JlCledzg_9k2ojRkV',
          'Authorization': 'Bearer sb_publishable_AMEQ6X4TMeyGz1JlCledzg_9k2ojRkV',
          'Accept': 'application/json',
        };

        final mapResponse = await http.get(
          Uri.parse('https://iqmcidsxvbsbbukjloew.supabase.co/rest/v1/maps?is_active=eq.true&select=id'),
          headers: headers,
        ).timeout(const Duration(seconds: 5));

        if (mapResponse.statusCode == 200) {
          final mapsJson = jsonDecode(mapResponse.body) as List<dynamic>;
          if (mapsJson.isNotEmpty) {
            final mapId = mapsJson.first['id'] as String;

            final layerResponse = await http.get(
              Uri.parse('https://iqmcidsxvbsbbukjloew.supabase.co/rest/v1/layers?map_id=eq.$mapId&editor_key=in.(\"buildings\",\"booths\")&select=id,editor_key'),
              headers: headers,
            ).timeout(const Duration(seconds: 5));

            if (layerResponse.statusCode == 200) {
              final layersJson = jsonDecode(layerResponse.body) as List<dynamic>;
              
              var targetLayerId = '';
              final buildingsLayer = layersJson.firstWhere((l) => l['editor_key'] == 'buildings', orElse: () => null);
              final boothsLayer = layersJson.firstWhere((l) => l['editor_key'] == 'booths', orElse: () => null);
              
              if (buildingsLayer != null) {
                targetLayerId = buildingsLayer['id'] as String;
              } else if (boothsLayer != null) {
                targetLayerId = boothsLayer['id'] as String;
              }

              if (targetLayerId.isNotEmpty) {
                final featuresResponse = await http.get(
                  Uri.parse('https://iqmcidsxvbsbbukjloew.supabase.co/rest/v1/features?layer_id=eq.$targetLayerId&select=id,geometry,properties'),
                  headers: headers,
                ).timeout(const Duration(seconds: 5));

                if (featuresResponse.statusCode == 200) {
                  final featuresJson = jsonDecode(featuresResponse.body) as List<dynamic>;
                  buildings = [
                    for (var i = 0; i < featuresJson.length; i++)
                      MapFeature.fromJson(featuresJson[i] as Map<String, dynamic>, Layer.building, i)
                  ];
                  print('SabaSaba Map API - Fallback fetched ${buildings.length} building features from Supabase REST.');
                }
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
          'Authorization': 'Bearer sb_publishable_AMEQ6X4TMeyGz1JlCledzg_9k2ojRkV',
          'Accept': 'application/json',
        };

        // 1. Get active map ID
        final mapResponse = await http.get(
          Uri.parse('https://iqmcidsxvbsbbukjloew.supabase.co/rest/v1/maps?is_active=eq.true&select=id'),
          headers: headers,
        ).timeout(const Duration(seconds: 5));

        if (mapResponse.statusCode == 200) {
          final mapsJson = jsonDecode(mapResponse.body) as List<dynamic>;
          if (mapsJson.isNotEmpty) {
            final mapId = mapsJson.first['id'] as String;

            // 2. Fetch routing nodes
            final nodesResponse = await http.get(
              Uri.parse('https://iqmcidsxvbsbbukjloew.supabase.co/rest/v1/routing_nodes?map_id=eq.$mapId&select=id,latitude,longitude'),
              headers: headers,
            ).timeout(const Duration(seconds: 5));

            if (nodesResponse.statusCode == 200) {
              final nodesJson = jsonDecode(nodesResponse.body) as List<dynamic>;
              nodes = nodesJson.map((item) => RoutingNode.fromJson(item as Map<String, dynamic>)).toList();
            }

            // 3. Fetch routing edges
            final edgesResponse = await http.get(
              Uri.parse('https://iqmcidsxvbsbbukjloew.supabase.co/rest/v1/routing_edges?map_id=eq.$mapId&select=id,source_node_id,target_node_id,distance,bidirectional'),
              headers: headers,
            ).timeout(const Duration(seconds: 5));

            if (edgesResponse.statusCode == 200) {
              final edgesJson = jsonDecode(edgesResponse.body) as List<dynamic>;
              edges = edgesJson.map((item) => RoutingEdge.fromJson(item as Map<String, dynamic>)).toList();
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
        locations.add(RoutingLocation(
          id: building.key,
          label: building.title,
          description: 'Area',
          position: position,
          nodeId: node.id,
        ));
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

class UserAccount {
  const UserAccount({required this.name, required this.email});

  final String name;
  final String email;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return 'U';
    }
    final first = parts.first.substring(0, 1);
    final second = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return '$first$second'.toUpperCase();
  }
}

class VisitorInquiry {
  const VisitorInquiry({
    required this.visitor,
    required this.message,
    this.response,
  });

  final String visitor;
  final String message;
  final String? response;

  VisitorInquiry copyWith({String? response}) {
    return VisitorInquiry(
      visitor: visitor,
      message: message,
      response: response ?? this.response,
    );
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
    return GeoPoint((value[0] as num).toDouble(), (value[1] as num).toDouble());
  }
}

class VisitorService {
  const VisitorService({
    required this.title,
    required this.description,
    required this.icon,
    required this.tint,
    required this.area,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color tint;
  final MapFeature area;

  static List<VisitorService> forAreas(List<MapFeature> areas) {
    if (areas.isEmpty) {
      return const [];
    }

    return [
      VisitorService(
        title: 'Parking',
        description: 'Vehicle parking and drop-off access',
        icon: Icons.local_parking,
        tint: const Color(0xffe4f4ee),
        area: _areaAt(areas, 0.05),
      ),
      VisitorService(
        title: 'Toilets',
        description: 'Public washrooms for visitors',
        icon: Icons.wc,
        tint: const Color(0xffe7f0ff),
        area: _areaAt(areas, 0.22),
      ),
      VisitorService(
        title: 'Restaurants',
        description: 'Food, drinks, and seating',
        icon: Icons.restaurant,
        tint: const Color(0xffffefe1),
        area: _areaAt(areas, 0.38),
      ),
      VisitorService(
        title: 'Information desk',
        description: 'Help, directions, and exhibition guidance',
        icon: Icons.info_outline,
        tint: const Color(0xffe9f5f1),
        area: _areaAt(areas, 0.5),
      ),
      VisitorService(
        title: 'First aid',
        description: 'Medical assistance and emergency support',
        icon: Icons.medical_services_outlined,
        tint: const Color(0xffffe8e8),
        area: _areaAt(areas, 0.62),
      ),
      VisitorService(
        title: 'ATM and payments',
        description: 'Cash and payment support',
        icon: Icons.account_balance,
        tint: const Color(0xffeef0ff),
        area: _areaAt(areas, 0.74),
      ),
      VisitorService(
        title: 'Entrance gates',
        description: 'Main visitor entry and exit points',
        icon: Icons.login,
        tint: const Color(0xffedf7df),
        area: _areaAt(areas, 0.86),
      ),
      VisitorService(
        title: 'Security',
        description: 'Lost and found, safety, and visitor support',
        icon: Icons.security,
        tint: const Color(0xfff2edf8),
        area: _areaAt(areas, 0.96),
      ),
    ];
  }

  static MapFeature _areaAt(List<MapFeature> areas, double fraction) {
    final index = (areas.length * fraction)
        .floor()
        .clamp(0, areas.length - 1)
        .toInt();
    return areas[index];
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

  _ProjectionMetrics get _metrics {
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
    return _ProjectionMetrics(
      left: left,
      top: top,
      scale: scale,
      mapWidth: mapWidth,
      mapHeight: mapHeight,
    );
  }
}

class _ProjectionMetrics {
  const _ProjectionMetrics({
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
