part of '../../../../main.dart';

class ExhibitionMapScreen extends StatefulWidget {
  const ExhibitionMapScreen({super.key, this.mapData});

  final Future<ExhibitionMapData>? mapData;

  @override
  State<ExhibitionMapScreen> createState() => _ExhibitionMapScreenState();
}

class _ExhibitionMapScreenState extends State<ExhibitionMapScreen>
    with SingleTickerProviderStateMixin {
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
  final TextEditingController _searchController = TextEditingController();
  final TransformationController _transformController =
      TransformationController();
  final GlobalKey _mapViewportKey = GlobalKey();
  late final AnimationController _mapAnimationController;
  Animation<Matrix4>? _mapAnimation;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _connectionBannerTimer;

  late Future<ExhibitionMapData> _mapFuture;
  bool _isOffline = false;
  bool _showConnectionBanner = false;
  int _tileRefreshGeneration = 0;

  // ─── Navigator state ────────────────────────────────────────────────────────
  String _searchQuery = '';
  String _categoryFilter = 'all';
  bool _isLeftOpen = false;
  String? _activePanel; // null | 'spaces' | 'route' | 'details' | 'help'
  bool _showLegend = false;
  SelectedFeatureInfo? _selectedFeatureInfo;
  MapFeature? _selectedAreaForCanvas;

  // Route state
  String _startLocationId = '';
  String _endLocationId = '';
  RouteResult? _currentRoute;
  String? _routeNotice;

  // ─── Other tab state ────────────────────────────────────────────────────────
  int _selectedNavIndex = 2; // default to map (index 2)
  bool _exhibitorRegisterMode = false;
  bool _locationAllowed = false;
  MapTileStyle _tileStyle = MapTileStyle.openStreetMap;
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
  VisitorService? _selectedService;
  double _mapRotation = 0;
  double _gestureRotationStart = 0;

  @override
  void initState() {
    super.initState();
    _mapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addListener(() {
        final animation = _mapAnimation;
        if (animation != null) {
          _transformController.value = animation.value;
        }
      });
    _mapFuture = widget.mapData ?? ExhibitionMapData.load();
    if (widget.mapData == null) {
      _monitorConnectivity();
    }
    _boothNameController.text = _boothName;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionBannerTimer?.cancel();
    _authNameController.dispose();
    _authEmailController.dispose();
    _authPasswordController.dispose();
    _exhibitorNameController.dispose();
    _exhibitorEmailController.dispose();
    _boothNameController.dispose();
    _productController.dispose();
    _replyController.dispose();
    _searchController.dispose();
    _mapAnimationController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedNavIndex = index);
        },
        destinations: const [
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
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Navigator',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge),
            label: 'Exhibitor',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Tickets',
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showConnectionBanner
                ? ConnectionBanner(
                    key: ValueKey(_isOffline),
                    isOffline: _isOffline,
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: FutureBuilder<ExhibitionMapData>(
              future: _mapFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return MapError(message: snapshot.error.toString());
                }
                if (!snapshot.hasData) {
                  return const LoadingMap();
                }

                final data = snapshot.data!;

                // ── Non-map tabs ──────────────────────────────────────────────
                if (_selectedNavIndex == 0) {
                  return ServicesTab(
                    areas: data.buildings,
                    selectedService: _selectedService,
                    onSelectService: _openService,
                  );
                }
                if (_selectedNavIndex == 1) {
                  return InfoTab(
                    buildingCount: data.buildings.length,
                    roadCount: data.roads.length,
                    treeCount: data.trees.length,
                    exhibition: data.exhibition,
                  );
                }
                if (_selectedNavIndex == 3) {
                  return ExhibitorTab(
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
                    onToggleMode: () => setState(
                      () => _exhibitorRegisterMode = !_exhibitorRegisterMode,
                    ),
                    onSubmit: () {
                      final email = _exhibitorEmailController.text.trim();
                      final fallbackName =
                          email.isEmpty ? 'Exhibitor' : email.split('@').first;
                      setState(() {
                        _exhibitorAccount = UserAccount(
                          name: _exhibitorRegisterMode &&
                                  _exhibitorNameController.text.trim().isNotEmpty
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
                      if (value.isEmpty) return;
                      setState(() => _boothName = value);
                    },
                    onAddProduct: () {
                      final value = _productController.text.trim();
                      if (value.isEmpty) return;
                      setState(() {
                        _exhibitorProducts.add(value);
                        _productController.clear();
                      });
                    },
                    onReply: (index) {
                      final reply = _replyController.text.trim();
                      if (reply.isEmpty) return;
                      setState(() {
                        _visitorInquiries[index] =
                            _visitorInquiries[index].copyWith(response: reply);
                        _replyController.clear();
                      });
                    },
                    onLogout: () => setState(() => _exhibitorAccount = null),
                  );
                }
                if (_selectedNavIndex == 4) {
                  return const TicketsTab();
                }

                // ── Navigator Map View (index 2) ─────────────────────────────
                return _buildMapView(data);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build the full navigator map view ────────────────────────────────────
  Widget _buildMapView(ExhibitionMapData data) {
    // Compute category data for SpacesPanel
    final categoryCounts = <String, int>{
      'all': data.locations.length,
      'exhibitors': 0,
    };
    for (final loc in data.locations) {
      if (loc.companyName != null) {
        categoryCounts['exhibitors'] =
            (categoryCounts['exhibitors'] ?? 0) + 1;
      }
      if (loc.layerName.isNotEmpty) {
        categoryCounts[loc.layerName] =
            (categoryCounts[loc.layerName] ?? 0) + 1;
      }
    }

    final availableCategories = <_CategoryItem>[
      _CategoryItem(id: 'all', label: 'All', count: categoryCounts['all'] ?? 0),
      if ((categoryCounts['exhibitors'] ?? 0) > 0)
        _CategoryItem(
          id: 'exhibitors',
          label: 'Exhibitors',
          count: categoryCounts['exhibitors']!,
        ),
      ...categoryCounts.entries
          .where(
            (e) => e.key != 'all' && e.key != 'exhibitors' && e.value > 0,
          )
          .map((e) => _CategoryItem(id: e.key, label: e.key, count: e.value)),
    ];

    final filteredLocations = data.locations.where((loc) {
      final matchesSearch = _searchQuery.trim().isEmpty ||
          loc.label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          loc.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (loc.companyName?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
      if (!matchesSearch) return false;
      if (_categoryFilter == 'all') return true;
      if (_categoryFilter == 'exhibitors') return loc.companyName != null;
      return loc.layerName == _categoryFilter;
    }).toList();

    // Start/end labels for info bar
    final startLoc = _findLocation(data.locations, _startLocationId);
    final endLoc = _findLocation(data.locations, _endLocationId);

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 600;
          final searchShowingResults =
              _searchQuery.trim().isNotEmpty && _activePanel == 'spaces';

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── 1. Map canvas (fills full viewport) ─────────────────────────
              Positioned.fill(
                child: SizedBox(
                  key: _mapViewportKey,
                  child: MapCanvas(
                    data: data,
                    filteredAreas: searchShowingResults
                        ? data.searchBuildings(_searchQuery)
                        : data.buildings,
                    selectedArea: _selectedAreaForCanvas,
                    selectedService: _selectedService,
                    tileStyle: _tileStyle,
                    tileRefreshGeneration: _tileRefreshGeneration,
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
                    onDoubleTap: () => _zoom(0.82),
                    onSelectArea: (area) => _onCanvasTap(area, data),
                    route: _currentRoute,
                    startPoint: (_currentRoute != null &&
                            _startLocationId.isNotEmpty)
                        ? _findLocation(data.locations, _startLocationId)
                              ?.position
                        : null,
                    endPoint: (_currentRoute != null &&
                            _endLocationId.isNotEmpty)
                        ? _findLocation(data.locations, _endLocationId)
                              ?.position
                        : null,
                  ),
                ),
              ),

              // ── 2. Main panel overlay (when active) ─────────────────────────
              if (_activePanel != null)
                NavigatorMainPanel(
                  title: _panelTitle(data),
                  onClose: () => setState(() => _activePanel = null),
                  child: _buildPanelContent(
                    data,
                    availableCategories,
                    filteredLocations,
                  ),
                ),

              // ── 3. Right toolbar (always on desktop, hidden on mobile when panel open)
              if (isDesktop || _activePanel == null)
                Positioned(
                  right: 14,
                  top: 14,
                  child: NavigatorRightToolbar(
                    tileStyle: _tileStyle,
                    onTileStyleChanged: (s) => setState(() => _tileStyle = s),
                    showLegend: _showLegend,
                    onToggleLegend: () =>
                        setState(() => _showLegend = !_showLegend),
                    onLocateMe: _locateMe,
                    onResetView: () => _resetMapView(data),
                  ),
                ),

              // ── 4. Bottom route info bar ─────────────────────────────────────
              if (_currentRoute != null)
                Positioned(
                  bottom: 16,
                  left: isDesktop && _activePanel != null ? 416 : 12,
                  right: isDesktop ? null : 12,
                  width: isDesktop ? 380 : null,
                  child: RouteInfoBar(
                    distanceMeters: _currentRoute!.distance,
                    walkingTime: walkingTimeLabel(_currentRoute!.distance),
                    startLabel: startLoc?.label,
                    endLabel: endLoc?.label,
                    onEdit: () => setState(() => _activePanel = 'route'),
                    onClear: _clearRoute,
                  ),
                ),

              // ── 5. Legend overlay (bottom-right) ────────────────────────────
              if (_showLegend)
                Positioned(
                  bottom: _currentRoute != null ? 150 : 20,
                  right: 14,
                  child: const LegendOverlay(),
                ),

              // ── 6. Left sidebar drawer ──────────────────────────────────────
              Positioned.fill(
                child: LeftSidebar(
                  isOpen: _isLeftOpen,
                  activePanel: _activePanel,
                  onClose: () => setState(() => _isLeftOpen = false),
                  onSelect: (panel) {
                    if (panel == 'legend') {
                      setState(() {
                        _showLegend = !_showLegend;
                        _isLeftOpen = false;
                      });
                      return;
                    }
                    setState(() {
                      _activePanel = panel;
                      _isLeftOpen = false;
                    });
                  },
                ),
              ),

              // ── 7. Search box (topmost, responsive width) ───────────────────
              Positioned(
                top: 14,
                left: 14,
                width: isDesktop
                    ? 372
                    : (constraints.maxWidth -
                        (_activePanel == null ? 68.0 : 28.0)),
                child: NavigatorSearchBox(
                  controller: _searchController,
                  isLeftOpen: _isLeftOpen,
                  onToggleSidebar: () =>
                      setState(() => _isLeftOpen = !_isLeftOpen),
                  onSearchChange: (value) {
                    setState(() {
                      _searchQuery = value;
                      if (_activePanel != 'spaces') {
                        _activePanel = 'spaces';
                      }
                    });
                  },
                  onFocus: () {
                    if (_activePanel == null) {
                      setState(() => _activePanel = 'spaces');
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Panel title ──────────────────────────────────────────────────────────
  String _panelTitle(ExhibitionMapData data) {
    switch (_activePanel) {
      case 'route':
        return 'Route Finder';
      case 'spaces':
        return 'Exhibition Grounds & Exhibitors';
      case 'help':
        return 'Navigator Guide';
      case 'details':
        return _selectedFeatureInfo?.label ?? 'Feature Details';
      default:
        return '';
    }
  }

  // ─── Panel content ────────────────────────────────────────────────────────
  Widget _buildPanelContent(
    ExhibitionMapData data,
    List<_CategoryItem> categories,
    List<RoutingLocation> filteredLocations,
  ) {
    switch (_activePanel) {
      case 'spaces':
        return SpacesPanel(
          locations: data.locations,
          categories: categories,
          filteredLocations: filteredLocations,
          categoryFilter: _categoryFilter,
          onCategoryChanged: (cat) =>
              setState(() => _categoryFilter = cat),
          onSelectLocation: (loc) => _selectLocation(loc, data),
          onSetTarget: (loc) {
            setState(() {
              _endLocationId = loc.id;
              _activePanel = 'route';
            });
          },
        );

      case 'route':
        return RouteInputPanel(
          locations: data.locations,
          startId: _startLocationId,
          endId: _endLocationId,
          notice: _routeNotice,
          onStartChanged: (id) => setState(() {
            _startLocationId = id;
            _currentRoute = null;
          }),
          onEndChanged: (id) => setState(() {
            _endLocationId = id;
            _currentRoute = null;
          }),
          onFindRoute: () => _calculateRoute(data),
          onClearRoute: _clearRoute,
        );

      case 'details':
        final info = _selectedFeatureInfo;
        if (info == null) return const SizedBox();
        return FeatureDetailsPanel(
          info: info,
          onSetDestination: () {
            if (info.location != null) {
              setState(() {
                _endLocationId = info.location!.id;
                _activePanel = 'route';
              });
            }
          },
          onSetStart: () {
            if (info.location != null) {
              setState(() {
                _startLocationId = info.location!.id;
                _activePanel = 'route';
              });
            }
          },
        );

      case 'help':
        return const HelpPanel();

      default:
        return const SizedBox();
    }
  }

  // ─── Canvas tap handler ───────────────────────────────────────────────────
  void _onCanvasTap(MapFeature area, ExhibitionMapData data) {
    final loc = area.featureId != null
        ? _findLocation(data.locations, area.featureId!)
        : null;

    setState(() {
      _selectedAreaForCanvas = area;
      _selectedFeatureInfo = SelectedFeatureInfo(
        id: area.featureId ?? area.key,
        label: area.title,
        layerName: area.layer.label,
        companyName: area.rawProperties['company_name'] as String?,
        properties: area.rawProperties,
        location: loc,
      );
      _activePanel = 'details';
    });
  }

  // ─── Select a location from the spaces list ───────────────────────────────
  void _selectLocation(RoutingLocation loc, ExhibitionMapData data) {
    // Find the corresponding canvas feature for highlighting
    final mapFeature = data.buildings
        .where((b) => b.featureId == loc.id)
        .firstOrNull;
    if (mapFeature != null) {
      setState(() => _selectedAreaForCanvas = mapFeature);
    }

    // Focus the map on the location
    _focusLocation(loc, data);

    setState(() {
      _selectedFeatureInfo = SelectedFeatureInfo(
        id: loc.id,
        label: loc.label,
        layerName: loc.layerName,
        companyName: loc.companyName,
        properties: loc.properties,
        location: loc,
      );
      _activePanel = 'details';
    });
  }

  // ─── Focus map on a location ──────────────────────────────────────────────
  void _focusLocation(RoutingLocation loc, ExhibitionMapData data) {
    final renderBox =
        _mapViewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final size = renderBox.size;
    final projection = data.projectionFor(size);
    final point = projection.project(loc.position);

    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final targetScale =
        (math.max(currentScale, 2.5)).clamp(minMapScale, maxMapScale);

    final target = Matrix4.identity()
      ..translate(
        size.width / 2 - point.dx * targetScale,
        size.height / 2 - point.dy * targetScale,
      )
      ..scale(targetScale);

    _mapAnimationController.stop();
    _mapAnimation = Matrix4Tween(
      begin: _transformController.value.clone(),
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _mapAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );
    _mapAnimationController.forward(from: 0);
  }

  // ─── Reset map to show all features ──────────────────────────────────────
  void _resetMapView(ExhibitionMapData data) {
    setState(() {
      _selectedAreaForCanvas = null;
    });

    final renderBox =
        _mapViewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final size = renderBox.size;
    final projection = data.projectionFor(size);

    // Fit all building features in view
    final allPoints = data.buildings
        .expand((b) => b.allPoints)
        .toList();

    if (allPoints.isEmpty) {
      _transformController.value = Matrix4.identity();
      return;
    }

    final projected =
        allPoints.map((p) => projection.project(p)).toList();
    final left =
        projected.map((o) => o.dx).reduce(math.min);
    final right =
        projected.map((o) => o.dx).reduce(math.max);
    final top = projected.map((o) => o.dy).reduce(math.min);
    final bottom =
        projected.map((o) => o.dy).reduce(math.max);

    const padding = 40.0;
    final routeW = math.max(1.0, right - left);
    final routeH = math.max(1.0, bottom - top);
    final scale = math
        .min(
          (size.width - padding * 2) / routeW,
          (size.height - padding * 2) / routeH,
        )
        .clamp(minMapScale, maxMapScale);

    final cx = (left + right) / 2;
    final cy = (top + bottom) / 2;
    final target = Matrix4.identity()
      ..translate(size.width / 2 - cx * scale, size.height / 2 - cy * scale)
      ..scale(scale);

    _mapAnimationController.stop();
    _mapAnimation = Matrix4Tween(
      begin: _transformController.value.clone(),
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _mapAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );
    _mapAnimationController.forward(from: 0);
  }

  // ─── Route calculation ────────────────────────────────────────────────────
  void _calculateRoute(ExhibitionMapData data) {
    setState(() => _routeNotice = null);

    if (_startLocationId.isEmpty || _endLocationId.isEmpty) {
      setState(() => _routeNotice =
          'Please select both start and destination points.');
      return;
    }
    if (_startLocationId == _endLocationId) {
      setState(
        () => _routeNotice = 'Start and destination points must be different.',
      );
      return;
    }

    final start = _findLocation(data.locations, _startLocationId);
    final end = _findLocation(data.locations, _endLocationId);
    if (start == null || end == null) {
      setState(() => _routeNotice = 'Location not found.');
      return;
    }

    final result = shortestPath(start.nodeId, end.nodeId, data.edges);
    if (result == null) {
      setState(
        () => _routeNotice = 'No path was found between these locations.',
      );
      return;
    }

    setState(() {
      _currentRoute = result;
      _mapRotation = 0;
      _activePanel = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(_currentRoute, result)) {
        _fitRouteToScreen(data, result);
      }
    });
  }

  void _clearRoute() {
    setState(() {
      _startLocationId = '';
      _endLocationId = '';
      _currentRoute = null;
      _routeNotice = null;
    });
  }

  // ─── Fit route to screen ──────────────────────────────────────────────────
  void _fitRouteToScreen(ExhibitionMapData data, RouteResult route) {
    final renderBox =
        _mapViewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final size = renderBox.size;
    final projection = data.projectionFor(size);
    final nodeById = {for (final node in data.nodes) node.id: node};
    final points = route.nodeIds
        .map((id) => nodeById[id])
        .whereType<RoutingNode>()
        .map(
          (node) => projection.project(GeoPoint(node.longitude, node.latitude)),
        )
        .toList();
    if (points.isEmpty) return;

    final left = points.map((p) => p.dx).reduce(math.min);
    final right = points.map((p) => p.dx).reduce(math.max);
    final top = points.map((p) => p.dy).reduce(math.min);
    final bottom = points.map((p) => p.dy).reduce(math.max);
    const padding = 72.0;
    final routeWidth = math.max(1.0, right - left);
    final routeHeight = math.max(1.0, bottom - top);
    final scale = math
        .min(
          (size.width - padding * 2) / routeWidth,
          (size.height - padding * 2) / routeHeight,
        )
        .clamp(minMapScale, maxMapScale);
    final routeCenter = Offset((left + right) / 2, (top + bottom) / 2);
    final target = Matrix4.identity()
      ..translate(
        size.width / 2 - routeCenter.dx * scale,
        size.height / 2 - routeCenter.dy * scale,
      )
      ..scale(scale);

    _mapAnimationController.stop();
    _mapAnimation = Matrix4Tween(
      begin: _transformController.value.clone(),
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _mapAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );
    _mapAnimationController.forward(from: 0);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  RoutingLocation? _findLocation(List<RoutingLocation> locations, String id) {
    if (id.isEmpty) return null;
    for (final l in locations) {
      if (l.id == id) return l;
    }
    return null;
  }

  void _zoom(double factor) {
    final current = _transformController.value;
    final currentScale = current.getMaxScaleOnAxis();
    final nextScale = (currentScale * factor).clamp(minMapScale, maxMapScale);
    if (currentScale == nextScale) return;
    final adjustedFactor = nextScale / currentScale;
    _transformController.value =
        current.scaled(adjustedFactor, adjustedFactor);
  }

  Future<void> _locateMe() async {
    if (!_locationAllowed) {
      final allowed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Allow location access?'),
            content: const Text(
              'SabaSaba needs your device location to locate you on the map.',
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
      if (allowed != true || !mounted) return;
      setState(() => _locationAllowed = true);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Location access enabled.')));
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
      if (allowed != true || !mounted) return;
      _locationAllowed = true;
    }
    setState(() {
      _selectedService = service;
      _selectedNavIndex = 0;
    });
  }

  Future<void> _monitorConnectivity() async {
    final connectivity = Connectivity();
    _connectivitySubscription =
        connectivity.onConnectivityChanged.listen(_updateConnectivity);
    _updateConnectivity(await connectivity.checkConnectivity());
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    if (!mounted) return;
    final isOffline =
        results.isEmpty || results.contains(ConnectivityResult.none);
    final reconnected = _isOffline && !isOffline;
    _connectionBannerTimer?.cancel();
    setState(() {
      _isOffline = isOffline;
      _showConnectionBanner = true;
      if (reconnected) {
        _mapFuture = ExhibitionMapData.load();
        _tileRefreshGeneration++;
      }
    });
    _connectionBannerTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showConnectionBanner = false);
    });
  }
}
