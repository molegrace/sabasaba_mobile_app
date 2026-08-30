part of '../../../../main.dart';

class ExhibitionMapScreen extends StatefulWidget {
  const ExhibitionMapScreen({super.key, this.mapData});

  final Future<ExhibitionMapData>? mapData;

  @override
  State<ExhibitionMapScreen> createState() => _ExhibitionMapScreenState();
}

class _ExhibitionMapScreenState extends State<ExhibitionMapScreen>
    with SingleTickerProviderStateMixin {
  static const GeoPoint _sabasabaGate = GeoPoint(39.27701, -6.86392);

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
  bool _isMapFullscreen = false;
  SelectedFeatureInfo? _selectedFeatureInfo;
  MapFeature? _selectedAreaForCanvas;

  // Route & Saved state
  String _startLocationId = '';
  String _endLocationId = '';
  RouteResult? _currentRoute;
  CityRouteResult? _cityRoute;
  String? _routeNotice;
  String? _gpsMessage;
  int _cityRouteRequestId = 0;
  List<String> _savedIds = [];

  // ─── Other tab state ────────────────────────────────────────────────────────
  int _selectedNavIndex = 2; // default to map (index 2)
  bool _exhibitorRegisterMode = false;
  bool _locationAllowed = false;
  GeoPoint? _userLocation;
  double? _userLocationAccuracy;
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
    _mapAnimationController =
        AnimationController(
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

  StreamSubscription<Position>? _positionSubscription;

  void _startLiveLocationStream() {
    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 2,
          ),
        ).listen((position) {
          if (!mounted) return;
          setState(() {
            _locationAllowed = true;
            _userLocation = GeoPoint(position.longitude, position.latitude);
            _userLocationAccuracy = position.accuracy;
          });
        }, onError: (_) {});
  }

  @override
  void dispose() {
    if (_isMapFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _positionSubscription?.cancel();
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
      bottomNavigationBar: _isMapFullscreen
          ? null
          : NavigationBar(
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
      final isExhibitor =
          loc.companyName != null && loc.companyName!.trim().isNotEmpty;
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
    final indKeys =
        categoryCounts.keys
            .where(
              (key) => key.startsWith('ind:') && (categoryCounts[key] ?? 0) > 0,
            )
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
    final layerKeys =
        categoryCounts.keys
            .where(
              (key) =>
                  key.startsWith('layer:') && (categoryCounts[key] ?? 0) > 0,
            )
            .toList()
          ..sort();

    for (final key in layerKeys) {
      final layerLabel = key.replaceFirst('layer:', '');
      availableCategories.add(
        _CategoryItem(id: key, label: layerLabel, count: categoryCounts[key]!),
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
      final matchesSearch =
          q.isEmpty ||
          loc.label.toLowerCase().contains(q) ||
          loc.description.toLowerCase().contains(q) ||
          (loc.companyName?.toLowerCase().contains(q) ?? false) ||
          (loc.industry?.toLowerCase().contains(q) ?? false) ||
          (loc.industries?.any((item) => item.toLowerCase().contains(q)) ??
              false) ||
          (loc.offerings?.any(
                (item) =>
                    [item.type, item.title, item.description, item.priceText]
                        .whereType<String>()
                        .any((value) => value.toLowerCase().contains(q)),
              ) ??
              false) ||
          (loc.searchTerms?.any((t) => t.toLowerCase().contains(q)) ?? false);

      if (!matchesSearch) return false;

      if (_categoryFilter == 'all' || _categoryFilter == 'more') return true;
      if (_categoryFilter == 'exhibitors') {
        return loc.companyName != null && loc.companyName!.trim().isNotEmpty;
      }
      if (_categoryFilter.startsWith('ind:')) {
        final targetInd = _categoryFilter.replaceFirst('ind:', '');
        return (loc.industries != null &&
                loc.industries!.contains(targetInd)) ||
            loc.industry == targetInd;
      }
      if (_categoryFilter.startsWith('layer:')) {
        final targetLayer = _categoryFilter.replaceFirst('layer:', '');
        return loc.layerName == targetLayer;
      }
      return loc.layerName == _categoryFilter ||
          loc.industry == _categoryFilter;
    }).toList();

    final searchSuggestions = <SearchSuggestionItem>[];
    final sq = _searchQuery.trim().toLowerCase();
    if (sq.isNotEmpty) {
      for (final loc in data.locations) {
        final matchesLabel = loc.label.toLowerCase().contains(sq);
        final matchesComp =
            loc.companyName?.toLowerCase().contains(sq) ?? false;
        final matchesDesc = loc.description.toLowerCase().contains(sq);
        final matchesInd = loc.industry?.toLowerCase().contains(sq) ?? false;

        if (matchesLabel || matchesComp || matchesDesc || matchesInd) {
          final isExhibitor =
              loc.companyName != null && loc.companyName!.trim().isNotEmpty;
          searchSuggestions.add(
            SearchSuggestionItem(
              id: loc.id,
              title: isExhibitor ? loc.companyName! : loc.label,
              subtitle: isExhibitor
                  ? '${loc.label} • ${loc.description}'
                  : loc.description,
              type: isExhibitor
                  ? 'exhibitor'
                  : (loc.layerName.contains('Hall') ? 'hall' : 'booth'),
              badge: isExhibitor ? 'Company' : loc.layerName,

              onSelect: () => _selectLocationFromSearch(loc, data),
            ),
          );
        }

        if (loc.offerings != null) {
          for (final offering in loc.offerings!) {
            final oTitle = offering.title ?? '';
            final oDesc = offering.description ?? '';
            if (oTitle.toLowerCase().contains(sq) ||
                oDesc.toLowerCase().contains(sq)) {
              searchSuggestions.add(
                SearchSuggestionItem(
                  id: '${loc.id}_${offering.id ?? oTitle}',
                  title: oTitle.isNotEmpty ? oTitle : loc.label,
                  subtitle:
                      '${loc.companyName ?? loc.label} • ${offering.priceText ?? offering.type ?? 'Offering'}',
                  type: offering.type == 'service' ? 'service' : 'product',
                  badge: offering.type ?? 'Product',
                  onSelect: () => _selectLocationFromSearch(loc, data),
                ),
              );
            }
          }
        }

        if (searchSuggestions.length >= 10) break;
      }
    }

    // Start/end labels for info bar
    final startLoc = _findLocation(data.locations, _startLocationId);
    final endLoc = _findLocation(data.locations, _endLocationId);

    return SafeArea(
      bottom: false,

      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 600;
          final isFiltering =
              _searchQuery.trim().isNotEmpty ||
              (_categoryFilter != 'all' && _categoryFilter != 'more');
          final matchingFeatureIds = filteredLocations
              .expand((location) => [location.id, location.featureId])
              .whereType<String>()
              .toSet();
          final filteredFeatures = isFiltering
              ? data.buildings
                    .where(
                      (feature) =>
                          feature.featureId != null &&
                          matchingFeatureIds.contains(feature.featureId),
                    )
                    .toList()
              : data.buildings;

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── 1. Map canvas (fills full viewport) ─────────────────────────
              Positioned.fill(
                child: SizedBox(
                  key: _mapViewportKey,
                  child: MapCanvas(
                    data: data,
                    filteredAreas: filteredFeatures,
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
                    onDoubleTap: (position) => _zoom(2, focalPoint: position),

                    onSelectArea: (area) => _onCanvasTap(area, data),
                    route: _currentRoute,
                    cityRoute: _cityRoute,
                    startPoint:
                        ((_currentRoute != null || _cityRoute != null) &&
                            _startLocationId.isNotEmpty)
                        ? _resolvePoint(_startLocationId, data)
                        : null,
                    endPoint:
                        ((_currentRoute != null || _cityRoute != null) &&
                            _endLocationId.isNotEmpty)
                        ? _resolvePoint(_endLocationId, data)
                        : null,
                    userLocation: _userLocation,
                    userLocationAccuracy: _userLocationAccuracy,
                  ),
                ),
              ),

              // ── 2. Main panel overlay (when active) ─────────────────────────
              if (isDesktop || _activePanel == null)
                Positioned(
                  top: isDesktop ? 14 : 68,
                  left: isDesktop ? 400 : 12,
                  right: isDesktop ? 66 : 12,
                  child: NavigatorCategoryBar(
                    categories: displayedCategories,
                    activeCategory: _categoryFilter,
                    onSelect: (category) {
                      setState(() {
                        if (category == 'more') {
                          _activePanel = 'filters';
                        } else {
                          _categoryFilter = category;
                          _activePanel = 'spaces';
                        }
                      });
                    },
                  ),
                ),

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

              // ── 3. Right toolbar (always visible for map navigation controls)
              Positioned(
                right: 14,
                top: 14,
                child: NavigatorRightToolbar(
                  tileStyle: _tileStyle,
                  onTileStyleChanged: (s) => setState(() => _tileStyle = s),
                  showLegend: _showLegend,
                  onToggleLegend: () =>
                      setState(() => _showLegend = !_showLegend),
                  onLocateMe: () => _locateMe(data),
                  onResetView: () => _resetMapView(data),
                  onDirections: () => setState(() {
                    _startLocationId = gpsStartId;
                    _activePanel = 'route';
                  }),
                  isFullscreen: _isMapFullscreen,
                  onToggleFullscreen: _toggleMapFullscreen,
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
                    distanceMeters: _cityRoute != null
                        ? _cityRoute!.distance + _cityRoute!.walkingDistance
                        : _currentRoute!.distance,
                    walkingTime: _cityRoute != null
                        ? travelTimeLabel(
                            _cityRoute!.duration + _cityRoute!.walkingDuration,
                          )
                        : walkingTimeLabel(_currentRoute!.distance),
                    timeMetricLabel: _cityRoute != null
                        ? 'Estimated Trip'
                        : 'Walking Time',
                    startLabel: _startLocationId == gpsStartId
                        ? 'Live GPS Location'
                        : (startLoc?.label ?? 'Start Location'),
                    endLabel:
                        endLoc?.label ??
                        _selectedFeatureInfo?.label ??
                        'Destination',
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
                width: isDesktop ? 372 : (constraints.maxWidth - 68.0),
                child: NavigatorSearchBox(
                  controller: _searchController,
                  isLeftOpen: _isLeftOpen,
                  onToggleSidebar: () =>
                      setState(() => _isLeftOpen = !_isLeftOpen),
                  onSearchChange: (value) {
                    setState(() {
                      _searchQuery = value;
                      if (value.trim().isNotEmpty && _activePanel != 'spaces') {
                        _activePanel = 'spaces';
                      }
                    });
                  },
                  onClear: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                  onFocus: () {},

                  suggestions: searchSuggestions,
                  onSelectPopularTag: (tagQuery) {
                    setState(() {
                      _searchQuery = tagQuery;
                      _searchController.text = tagQuery;
                      if (_activePanel != 'spaces') {
                        _activePanel = 'spaces';
                      }
                    });
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
          onResetFilters: () {
            setState(() {
              _categoryFilter = 'all';
              _searchQuery = '';
              _searchController.clear();
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
            _cityRouteRequestId += 1;
            _startLocationId = id;
            _currentRoute = null;
            _cityRoute = null;
          }),
          onEndChanged: (id) => setState(() {
            _cityRouteRequestId += 1;
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
          onViewOnMap: () {
            if (info.location != null) {
              _focusLocation(info.location!, data);
            }
            setState(() => _activePanel = null);
          },
          onShare: () => _shareFeature(info),
          onToggleSave: locId != null ? () => _toggleSaveLocation(locId) : null,
          onSetDestination: () {
            final loc =
                info.location ?? _findLocation(data.locations, info.id, data);
            if (loc != null) {
              setState(() {
                _startLocationId = gpsStartId;
                _endLocationId = loc.id;
                _activePanel = 'route';
              });
              _calculateRoute(data);
            }
          },
          onSetStart: () {
            final loc =
                info.location ?? _findLocation(data.locations, info.id, data);
            if (loc != null) {
              setState(() {
                _startLocationId = loc.id;
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
        : _findLocation(data.locations, area.key, data);

    final targetLoc =
        loc ??
        RoutingLocation(
          id: area.featureId ?? area.key,
          label: area.title,
          description: area.layer.label,
          layerName: area.layer.label,
          position: area.center,
          nodeId: nearestNode(area.center, data.nodes).id,
          companyName: area.rawProperties['company_name'] as String?,
          properties: area.rawProperties,
        );

    setState(() {
      _selectedAreaForCanvas = area;
      _selectedFeatureInfo = SelectedFeatureInfo(
        id: area.featureId ?? area.key,
        label: area.title,
        layerName: area.layer.label,
        companyName: area.rawProperties['company_name'] as String?,
        properties: area.rawProperties,
        location: targetLoc,
      );
      _startLocationId = gpsStartId;
      _endLocationId = targetLoc.id;
    });

    _calculateRoute(data);
  }

  // ─── Select a location from the spaces list ───────────────────────────────
  void _selectLocation(RoutingLocation loc, ExhibitionMapData data) {
    // Find the corresponding canvas feature for highlighting
    final mapFeature = data.buildings
        .where((b) => b.featureId == loc.id || b.key == loc.id)
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
      _startLocationId = gpsStartId;
      _endLocationId = loc.id;
    });

    _calculateRoute(data);
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
    final targetScale = (math.max(
      currentScale,
      4.5,
    )).clamp(minMapScale, maxMapScale);

    final target = Matrix4.identity()
      ..translate(
        size.width / 2 - point.dx * targetScale,
        size.height / 2 - point.dy * targetScale,
      )
      ..scale(targetScale);

    _mapAnimationController.stop();
    _mapAnimation =
        Matrix4Tween(
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
    final allPoints = data.buildings.expand((b) => b.allPoints).toList();

    if (allPoints.isEmpty) {
      _transformController.value = Matrix4.identity();
      return;
    }

    final projected = allPoints.map((p) => projection.project(p)).toList();
    final left = projected.map((o) => o.dx).reduce(math.min);
    final right = projected.map((o) => o.dx).reduce(math.max);
    final top = projected.map((o) => o.dy).reduce(math.min);
    final bottom = projected.map((o) => o.dy).reduce(math.max);

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
    _mapAnimation =
        Matrix4Tween(
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
      setState(
        () => _routeNotice = 'Please select both start and destination points.',
      );
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

    final start = _findLocation(data.locations, _startLocationId, data);
    final end = _findLocation(data.locations, _endLocationId, data);
    if (start == null || end == null) {
      setState(() => _routeNotice = 'Location not found.');
      return;
    }

    final result = findNavigableRoute(
      start.nodeId,
      end.nodeId,
      data.nodes,
      data.edges,
    );
    if (result == null) {
      setState(() {
        _routeNotice =
            'The selected locations do not have usable navigation nodes.';
      });
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
    final requestId = ++_cityRouteRequestId;
    final destination = _findLocation(data.locations, _endLocationId, data);
    if (destination == null) {
      setState(
        () =>
            _routeNotice = 'Select the booth or place you want to navigate to.',
      );
      return;
    }

    if (data.nodes.isEmpty || destination.nodeId == 'no_node') {
      setState(() {
        _routeNotice =
            'This destination is not connected to a mapped fairground path yet.';
      });
      return;
    }

    final gateLocation = data.locations.where((location) {
      return location.label.trim().toLowerCase() == 'gate 1';
    }).firstOrNull;
    final gateNodeId = gateLocation != null && gateLocation.nodeId != 'no_node'
        ? gateLocation.nodeId
        : nearestNode(_sabasabaGate, data.nodes).id;
    final routeResult = findNavigableRoute(
      gateNodeId,
      destination.nodeId,
      data.nodes,
      data.edges,
    );
    if (routeResult == null || routeResult.nodeIds.length < 2) {
      setState(() {
        _routeNotice =
            'No usable navigation path was found from Gate 1 to ${destination.label}.';
      });
      return;
    }

    setState(() {
      _routeNotice = null;
      _gpsMessage =
          'Finding your GPS position and building the route to ${destination.label}...';
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception(
          'Location services are disabled. Turn on GPS and try again.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. Enable it in device settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted || requestId != _cityRouteRequestId) return;

      final userPoint = GeoPoint(position.longitude, position.latitude);
      setState(() {
        _locationAllowed = true;
        _userLocation = userPoint;
        _userLocationAccuracy = position.accuracy;
        _gpsMessage =
            'GPS found. Connecting the road route to the fairground paths...';
      });
      _startLiveLocationStream();

      final coordinates =
          '${position.longitude},${position.latitude};'
          '${_sabasabaGate.lng},${_sabasabaGate.lat}';
      final uri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/$coordinates',
        const {'overview': 'full', 'geometries': 'geojson', 'steps': 'false'},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (!mounted || requestId != _cityRouteRequestId) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'The road routing service returned an invalid response.',
        );
      }
      final routes = decoded['routes'];
      final firstRoute = routes is List && routes.isNotEmpty
          ? routes.first
          : null;
      final geometry = firstRoute is Map ? firstRoute['geometry'] : null;
      final rawCoordinates = geometry is Map ? geometry['coordinates'] : null;
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['code'] != 'Ok' ||
          firstRoute is! Map ||
          rawCoordinates is! List) {
        throw Exception(
          'The road section could not be calculated right now. Please try again.',
        );
      }

      final roadCoordinates = <GeoPoint>[];
      for (final rawCoordinate in rawCoordinates) {
        if (rawCoordinate is! List || rawCoordinate.length < 2) continue;
        final longitude = rawCoordinate[0];
        final latitude = rawCoordinate[1];
        if (longitude is! num || latitude is! num) continue;
        roadCoordinates.add(
          GeoPoint(longitude.toDouble(), latitude.toDouble()),
        );
      }
      if (roadCoordinates.length < 2) {
        throw Exception(
          'The road routing service did not return a usable route line.',
        );
      }

      final cityRoute = CityRouteResult(
        distance: (firstRoute['distance'] as num).toDouble(),
        duration: (firstRoute['duration'] as num).toDouble(),
        coordinates: roadCoordinates,
        walkingDistance: routeResult.distance,
        walkingDuration: routeResult.distance / (5000 / 3600),
        destinationId: destination.id,
        destinationLabel: destination.label,
      );

      setState(() {
        _cityRoute = cityRoute;
        _currentRoute = routeResult;
        _gpsMessage =
            'Complete route ready to ${destination.label} · GPS accuracy about ${position.accuracy.round()} m.';
        _mapRotation = 0;
        _activePanel = null;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            requestId == _cityRouteRequestId &&
            identical(_cityRoute, cityRoute)) {
          _fitCityRouteToScreen(data, cityRoute, routeResult);
        }
      });
    } catch (error) {
      if (!mounted || requestId != _cityRouteRequestId) return;
      setState(() {
        _cityRoute = null;
        _currentRoute = null;
        _gpsMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openTurnByTurnNavigation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
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
      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=-6.86392,39.27701&travelmode=driving',
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _clearRoute() {
    _cityRouteRequestId += 1;
    setState(() {
      _startLocationId = '';
      _endLocationId = '';
      _currentRoute = null;
      _cityRoute = null;
      _gpsMessage = null;
      _routeNotice = null;
    });
  }

  Future<void> _toggleMapFullscreen() async {
    final next = !_isMapFullscreen;
    await SystemChrome.setEnabledSystemUIMode(
      next ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
    if (mounted) setState(() => _isMapFullscreen = next);
  }

  Future<void> _shareFeature(SelectedFeatureInfo info) async {
    final baseUrl = ExhibitionMapData.navigatorApiUrl.replaceFirst(
      RegExp(r'/api/map/?$'),
      '/navigator',
    );
    final shareUrl = Uri.parse(
      baseUrl,
    ).replace(queryParameters: {'fid': info.id}).toString();
    final message =
        'View ${info.companyName ?? info.label} at Sabasaba\n$shareUrl';
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Share this place',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.chat_rounded,
                  color: Color(0xff16a34a),
                ),
                title: const Text('WhatsApp'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await launchUrl(
                    Uri.parse(
                      'https://wa.me/?text=${Uri.encodeComponent(message)}',
                    ),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.sms_rounded,
                  color: Color(0xff0284c7),
                ),
                title: const Text('Message'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await launchUrl(
                    Uri.parse('sms:?body=${Uri.encodeComponent(message)}'),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_rounded),
                title: const Text('Copy link'),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: shareUrl));
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Navigator link copied.')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
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
    _mapAnimation =
        Matrix4Tween(
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

  void _fitCityRouteToScreen(
    ExhibitionMapData data,
    CityRouteResult cityRoute,
    RouteResult fairgroundRoute,
  ) {
    final renderBox =
        _mapViewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final size = renderBox.size;
    final projection = data.projectionFor(size);
    final nodeById = {for (final node in data.nodes) node.id: node};
    final points = <Offset>[
      ...cityRoute.coordinates.map(projection.project),
      ...fairgroundRoute.nodeIds
          .map((id) => nodeById[id])
          .whereType<RoutingNode>()
          .map(
            (node) =>
                projection.project(GeoPoint(node.longitude, node.latitude)),
          ),
    ];
    if (points.length < 2) return;

    final left = points.map((point) => point.dx).reduce(math.min);
    final right = points.map((point) => point.dx).reduce(math.max);
    final top = points.map((point) => point.dy).reduce(math.min);
    final bottom = points.map((point) => point.dy).reduce(math.max);
    const padding = 48.0;
    final routeWidth = math.max(1.0, right - left);
    final routeHeight = math.max(1.0, bottom - top);
    final availableWidth = math.max(1.0, size.width - padding * 2);
    final availableHeight = math.max(1.0, size.height - padding * 2);
    final scale = math
        .min(availableWidth / routeWidth, availableHeight / routeHeight)
        .clamp(minMapScale, maxMapScale);
    final routeCenter = Offset((left + right) / 2, (top + bottom) / 2);
    final target = Matrix4.identity()
      ..translate(
        size.width / 2 - routeCenter.dx * scale,
        size.height / 2 - routeCenter.dy * scale,
      )
      ..scale(scale);

    _mapAnimationController.stop();
    _mapAnimation =
        Matrix4Tween(
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

  void _selectLocationFromSearch(RoutingLocation loc, ExhibitionMapData data) {
    final building = data.buildings
        .where((b) => b.featureId == loc.id || b.key == loc.id)
        .firstOrNull;
    setState(() {
      _selectedAreaForCanvas = building;
      _selectedFeatureInfo = SelectedFeatureInfo(
        id: loc.id,
        label: loc.label,
        layerName: loc.layerName,
        companyName: loc.companyName,
        properties: loc.properties,
        location: loc,
      );
      _startLocationId = gpsStartId;
      _endLocationId = loc.id;
    });
    if (building != null) {
      _fitMapToArea(building, data);
    }
    _calculateRoute(data);
  }

  void _fitMapToArea(MapFeature building, ExhibitionMapData data) {
    final renderBox =
        _mapViewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final size = renderBox.size;
    final projection = data.projectionFor(size);
    final points = building.allPoints
        .map((p) => projection.project(p))
        .toList();
    if (points.isEmpty) return;

    final left = points.map((p) => p.dx).reduce(math.min);
    final right = points.map((p) => p.dx).reduce(math.max);
    final top = points.map((p) => p.dy).reduce(math.min);
    final bottom = points.map((p) => p.dy).reduce(math.max);
    const padding = 80.0;
    final areaWidth = math.max(1.0, right - left);
    final areaHeight = math.max(1.0, bottom - top);
    final scale = math
        .min(
          (size.width - padding * 2) / areaWidth,
          (size.height - padding * 2) / areaHeight,
        )
        .clamp(minMapScale, maxMapScale);
    final center = Offset((left + right) / 2, (top + bottom) / 2);
    final target = Matrix4.identity()
      ..translate(
        size.width / 2 - center.dx * scale,
        size.height / 2 - center.dy * scale,
      )
      ..scale(scale);

    _mapAnimationController.stop();
    _mapAnimation =
        Matrix4Tween(
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

  RoutingLocation? _findLocation(
    List<RoutingLocation> locations,
    String id, [
    ExhibitionMapData? data,
  ]) {
    if (id.isEmpty) return null;
    for (final l in locations) {
      if (l.id == id) return l;
    }
    if (data != null) {
      final building = data.buildings
          .where((b) => b.featureId == id || b.key == id)
          .firstOrNull;
      if (building != null) {
        final node = nearestNode(building.center, data.nodes);
        return RoutingLocation(
          id: building.featureId ?? building.key,
          label: building.title,
          description: building.layer.label,
          layerName: building.layer.label,
          position: building.center,
          nodeId: node.id,
          companyName: building.rawProperties['company_name'] as String?,
          properties: building.rawProperties,
        );
      }
    }
    return null;
  }

  GeoPoint? _resolvePoint(String id, ExhibitionMapData data) {
    if (id.isEmpty) return null;
    if (id == gpsStartId) {
      return _userLocation ?? const GeoPoint(39.27701, -6.86392);
    }
    final loc = _findLocation(data.locations, id, data);
    return loc?.position;
  }

  void _zoom(double factor, {Offset? focalPoint}) {
    final current = _transformController.value;
    final currentScale = current.getMaxScaleOnAxis();
    final nextScale = (currentScale * factor).clamp(minMapScale, maxMapScale);
    if (currentScale == nextScale) return;

    final renderBox =
        _mapViewportKey.currentContext?.findRenderObject() as RenderBox?;
    final focal =
        focalPoint ??
        (renderBox != null && renderBox.hasSize
            ? renderBox.size.center(Offset.zero)
            : Offset.zero);
    final scenePoint = _transformController.toScene(focal);

    // Preserve the geographic point below the tap, matching Leaflet's
    // double-click zoom-around-cursor behaviour.
    _transformController.value =
        Matrix4.diagonal3Values(nextScale, nextScale, 1)..setTranslationRaw(
          focal.dx - scenePoint.dx * nextScale,
          focal.dy - scenePoint.dy * nextScale,
          0,
        );
  }

  Future<void> _locateMe(ExhibitionMapData data) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception(
          'Location services are disabled. Turn on GPS and try again.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. Enable it in device settings.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final point = GeoPoint(position.longitude, position.latitude);
      if (!mounted) return;
      setState(() {
        _locationAllowed = true;
        _userLocation = point;
        _userLocationAccuracy = position.accuracy;
      });
      _startLiveLocationStream();
      _focusGeoPoint(point, data, targetScale: 6);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _focusGeoPoint(
    GeoPoint location,
    ExhibitionMapData data, {
    double targetScale = 4.5,
  }) {
    final renderBox =
        _mapViewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    final size = renderBox.size;
    final point = data.projectionFor(size).project(location);
    final scale = targetScale.clamp(minMapScale, maxMapScale);
    final target = Matrix4.identity()
      ..translate(
        size.width / 2 - point.dx * scale,
        size.height / 2 - point.dy * scale,
      )
      ..scale(scale);
    _mapAnimationController.stop();
    _mapAnimation =
        Matrix4Tween(
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
    _connectivitySubscription = connectivity.onConnectivityChanged.listen(
      _updateConnectivity,
    );
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
