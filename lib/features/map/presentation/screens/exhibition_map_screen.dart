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

  // Route & Saved state
  String _startLocationId = '';
  String _endLocationId = '';
  RouteResult? _currentRoute;
  CityRouteResult? _cityRoute;
  String? _routeNotice;
  String? _gpsMessage;
  List<String> _savedIds = [];

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
    _loadSavedIds();
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

  Future<void> _loadSavedIds() async {
    final ids = await SavedLocationsManager.getSavedIds();
    if (mounted) setState(() => _savedIds = ids);
  }

  Future<void> _toggleSaveLocation(String id) async {
    final ids = await SavedLocationsManager.toggleSave(id);
    if (mounted) setState(() => _savedIds = ids);
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
                  final errStr = snapshot.error.toString();
                  final displayMessage = errStr.contains('TimeoutException')
                      ? 'Map data download timed out due to slow network. Tap below to retry.'
                      : errStr.replaceAll('Exception: ', '');
                  return MapError(
                    message: displayMessage,
                    onRetry: () {
                      setState(() {
                        _mapFuture = ExhibitionMapData.load();
                      });
                    },
                  );
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
    // Compute category counts & filter list (exact parity with Next.js)
    final categoryCounts = <String, int>{
      'all': data.locations.length,
      'exhibitors': 0,
    };

    for (final loc in data.locations) {
      final isExhibitor = loc.companyName != null && loc.companyName!.trim().isNotEmpty;
      if (isExhibitor) {
        categoryCounts['exhibitors'] = (categoryCounts['exhibitors'] ?? 0) + 1;
      }

      final indList = (loc.industries != null && loc.industries!.isNotEmpty)
          ? loc.industries!
          : (loc.industry != null ? [loc.industry!] : <String>[]);

      for (final ind in indList) {
        if (ind.trim().isNotEmpty) {
          final indKey = 'ind:$ind';
          categoryCounts[indKey] = (categoryCounts[indKey] ?? 0) + 1;
        }
      }

      if (loc.layerName.isNotEmpty) {
        final layerKey = 'layer:${loc.layerName}';
        categoryCounts[layerKey] = (categoryCounts[layerKey] ?? 0) + 1;
      }
    }

    final availableCategories = <_CategoryItem>[
      _CategoryItem(id: 'all', label: 'All', count: categoryCounts['all'] ?? 0),
      _CategoryItem(
        id: 'exhibitors',
        label: 'Exhibitors',
        count: categoryCounts['exhibitors'] ?? 0,
      ),
    ];

    // Industry categories (sorted alphabetically)
    final indKeys = categoryCounts.keys
        .where((key) => key.startsWith('ind:') && (categoryCounts[key] ?? 0) > 0)
        .toList()
      ..sort();

    for (final key in indKeys) {
      final industryLabel = key.replaceFirst('ind:', '');
      availableCategories.add(
        _CategoryItem(
          id: key,
          label: industryLabel,
          count: categoryCounts[key]!,
        ),
      );
    }

    // Layer categories (sorted alphabetically)
    final layerKeys = categoryCounts.keys
        .where((key) => key.startsWith('layer:') && (categoryCounts[key] ?? 0) > 0)
        .toList()
      ..sort();

    for (final key in layerKeys) {
      final layerLabel = key.replaceFirst('layer:', '');
      availableCategories.add(
        _CategoryItem(
          id: key,
          label: layerLabel,
          count: categoryCounts[key]!,
        ),
      );
    }

    final displayedCategories = availableCategories.length <= 10
        ? availableCategories
        : [
            ...availableCategories.take(9),
            _CategoryItem(
              id: 'more',
              label: 'More',
              count: availableCategories.length - 9,
            ),
          ];

    final filteredLocations = data.locations.where((loc) {
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          loc.label.toLowerCase().contains(q) ||
          loc.description.toLowerCase().contains(q) ||
          (loc.companyName?.toLowerCase().contains(q) ?? false) ||
          (loc.industry?.toLowerCase().contains(q) ?? false) ||
          (loc.searchTerms?.any((t) => t.toLowerCase().contains(q)) ?? false);

      if (!matchesSearch) return false;

      if (_categoryFilter == 'all' || _categoryFilter == 'more') return true;
      if (_categoryFilter == 'exhibitors') {
        return loc.companyName != null && loc.companyName!.trim().isNotEmpty;
      }
      if (_categoryFilter.startsWith('ind:')) {
        final targetInd = _categoryFilter.replaceFirst('ind:', '');
        return (loc.industries != null && loc.industries!.contains(targetInd)) ||
            loc.industry == targetInd;
      }
      if (_categoryFilter.startsWith('layer:')) {
        final targetLayer = _categoryFilter.replaceFirst('layer:', '');
        return loc.layerName == targetLayer;
      }
      return loc.layerName == _categoryFilter || loc.industry == _categoryFilter;
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
                    categoryFilter: _categoryFilter,
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
                    displayedCategories,
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
              if (_cityRoute != null)
                Positioned(
                  bottom: 16,
                  left: isDesktop && _activePanel != null ? 416 : 12,
                  right: isDesktop ? null : 12,
                  width: isDesktop ? 380 : null,
                  child: RouteInfoBar(
                    distanceMeters: _cityRoute!.distance + _cityRoute!.walkingDistance,
                    walkingTime: travelTimeLabel(_cityRoute!.duration + _cityRoute!.walkingDuration),
                    startLabel: 'Live GPS Location',
                    endLabel: _cityRoute!.destinationLabel,
                    onEdit: () => setState(() => _activePanel = 'route'),
                    onClear: _clearRoute,
                  ),
                )
              else if (_currentRoute != null)
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
        return 'Navigation';
      case 'spaces':
        return 'Existing Things';
      case 'saved':
        return 'Saved Locations (${_savedIds.length})';
      case 'filters':
        return 'Filters & Categories';
      case 'legend':
        return 'Map Legend';
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
    List<_CategoryItem> displayedCategories,
    List<_CategoryItem> availableCategories,
    List<RoutingLocation> filteredLocations,
  ) {
    switch (_activePanel) {
      case 'spaces':
        return SpacesPanel(
          locations: data.locations,
          categories: displayedCategories,
          filteredLocations: filteredLocations,
          categoryFilter: _categoryFilter,
          onCategoryChanged: (cat) {
            if (cat == 'more') {
              setState(() => _activePanel = 'filters');
            } else {
              setState(() => _categoryFilter = cat);
            }
          },
          onSelectLocation: (loc) => _selectLocation(loc, data),
          onSetTarget: (loc) {
            setState(() {
              _startLocationId = gpsStartId;
              _endLocationId = loc.id;
              _activePanel = 'route';
            });
          },
        );

      case 'saved':
        return SavedPanel(
          locations: data.locations,
          savedIds: _savedIds,
          onSelectLocation: (loc) => _selectLocation(loc, data),
          onSetDestination: (loc) {
            setState(() {
              _startLocationId = gpsStartId;
              _endLocationId = loc.id;
              _activePanel = 'route';
            });
          },
          onToggleSave: (id) => _toggleSaveLocation(id),
        );

      case 'filters':
        return FiltersPanel(
          categories: availableCategories,
          activeCategory: _categoryFilter,
          onSelectCategory: (cat) => setState(() {
            _categoryFilter = cat;
            _activePanel = 'spaces';
          }),
        );



      case 'route':
        return RouteInputPanel(
          locations: data.locations,
          startId: _startLocationId,
          endId: _endLocationId,
          notice: _routeNotice,
          gpsMessage: _gpsMessage,
          cityRoute: _cityRoute,
          onStartChanged: (id) => setState(() {
            _startLocationId = id;
            _currentRoute = null;
            _cityRoute = null;
          }),
          onEndChanged: (id) => setState(() {
            _endLocationId = id;
            _currentRoute = null;
            _cityRoute = null;
          }),
          onFindRoute: () => _calculateRoute(data),
          onClearRoute: _clearRoute,
          onOpenTurnByTurn: _openTurnByTurnNavigation,
        );

      case 'details':
        final info = _selectedFeatureInfo;
        if (info == null) return const SizedBox();
        final locId = info.location?.id;
        final isSaved = locId != null && _savedIds.contains(locId);

        return FeatureDetailsPanel(
          info: info,
          isSaved: isSaved,
          onToggleSave: locId != null ? () => _toggleSaveLocation(locId) : null,
          onSetDestination: () {
            if (info.location != null) {
              setState(() {
                _startLocationId = gpsStartId;
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

      case 'legend':
        return const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: LegendOverlay(),
        );


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
        (math.max(currentScale, 4.5)).clamp(minMapScale, maxMapScale);


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
  Future<void> _calculateRoute(ExhibitionMapData data) async {
    setState(() => _routeNotice = null);

    if (_startLocationId.isEmpty || _endLocationId.isEmpty) {
      setState(() => _routeNotice =
          'Please select both start and destination points.');
      return;
    }

    if (_startLocationId == gpsStartId) {
      await _navigateFromGpsToDestination(data);
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

    final result = findNavigableRoute(start.nodeId, end.nodeId, data.nodes, data.edges);
    if (result == null) {
      setState(
        () => _routeNotice = 'No path was found between these locations.',
      );
      return;
    }

    setState(() {
      _cityRoute = null;
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

  Future<void> _navigateFromGpsToDestination(ExhibitionMapData data) async {
    final destination = _findLocation(data.locations, _endLocationId);
    if (destination == null) {
      setState(() => _routeNotice = 'Select the booth or place you want to navigate to.');
      return;
    }

    setState(() => _gpsMessage = 'Locating your current GPS position...');

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied || req == LocationPermission.deniedForever) {
          throw Exception('Location permission was denied.');
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() => _gpsMessage = 'Connecting city route to Gate 1...');

      const gateLat = -6.86392;
      const gateLng = 39.27701;

      final gateNode = nearestNode(GeoPoint(gateLng, gateLat), data.nodes);
      final fairgroundRoute = findNavigableRoute(gateNode.id, destination.nodeId, data.nodes, data.edges);
      if (fairgroundRoute == null) {
        throw Exception('No path found from Gate 1 to ${destination.label}.');
      }

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${position.longitude},${position.latitude};$gateLng,$gateLat'
        '?overview=full&geometries=geojson&steps=false',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('City driving route could not be calculated right now.');
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = payload['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        throw Exception('No driving route found to Sabasaba Gate 1.');
      }

      final firstRoute = routes.first as Map<String, dynamic>;
      final distance = (firstRoute['distance'] as num).toDouble();
      final duration = (firstRoute['duration'] as num).toDouble();
      final geometry = firstRoute['geometry'] as Map<String, dynamic>;
      final rawCoords = geometry['coordinates'] as List<dynamic>;

      final coords = rawCoords.map((c) {
        final pair = c as List<dynamic>;
        return GeoPoint((pair[0] as num).toDouble(), (pair[1] as num).toDouble());
      }).toList();

      final cityResult = CityRouteResult(
        distance: distance,
        duration: duration,
        coordinates: coords,
        walkingDistance: fairgroundRoute.distance,
        walkingDuration: fairgroundRoute.distance / (5000 / 3600),
        destinationId: destination.id,
        destinationLabel: destination.label,
      );

      setState(() {
        _cityRoute = cityResult;
        _currentRoute = fairgroundRoute;
        _gpsMessage = 'Route ready to ${destination.label}. Drive to Gate 1 then walk ${fairgroundRoute.distance.round()} m.';
        _activePanel = null;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && identical(_currentRoute, fairgroundRoute)) {
          _fitRouteToScreen(data, fairgroundRoute);
        }
      });
    } catch (e) {
      setState(() {
        _gpsMessage = null;
        _routeNotice = e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Could not calculate GPS route.';
      });
    }
  }

  Future<void> _openTurnByTurnNavigation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=${position.latitude},${position.longitude}'
        '&destination=-6.86392,39.27701&travelmode=driving',
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=-6.86392,39.27701&travelmode=driving');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _clearRoute() {
    setState(() {
      _startLocationId = '';
      _endLocationId = '';
      _currentRoute = null;
      _cityRoute = null;
      _gpsMessage = null;
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
