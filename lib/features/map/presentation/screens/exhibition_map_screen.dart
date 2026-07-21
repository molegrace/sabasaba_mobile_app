part of '../../../../main.dart';

class ExhibitionMapScreen extends StatefulWidget {
  const ExhibitionMapScreen({super.key, this.mapData});

  final Future<ExhibitionMapData>? mapData;

  @override
  State<ExhibitionMapScreen> createState() => _ExhibitionMapScreenState();
}

class _ExhibitionMapScreenState extends State<ExhibitionMapScreen>
    with SingleTickerProviderStateMixin {
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
  final GlobalKey _mapViewportKey = GlobalKey();
  late final AnimationController _mapAnimationController;
  Animation<Matrix4>? _mapAnimation;
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
    _mapAnimationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1400),
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
          ConnectionBanner(isOffline: _isOffline),
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
                  return ServicesTab(
                    areas: data.buildings,
                    selectedService: _selectedService,
                    onSelectService: _openService,
                  );
                }

                if (_selectedNavIndex == 2) {
                  return InfoTab(
                    buildingCount: data.buildings.length,
                    roadCount: data.roads.length,
                    treeCount: data.trees.length,
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
                  return YouTab(
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
                      final panel = SearchPanel(
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
                            child: SizedBox(
                              key: _mapViewportKey,
                              child: MapCanvas(
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
                                    _mapRotation =
                                        _gestureRotationStart + angle;
                                  });
                                },
                                onDoubleTap: () => _zoom(0.82),
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
                                startPoint:
                                    _currentRoute == null ||
                                        _startLocationId.isEmpty
                                    ? null
                                    : data.locations
                                          .firstWhere(
                                            (loc) => loc.id == _startLocationId,
                                            orElse: () => data.locations.first,
                                          )
                                          .position,
                                endPoint:
                                    _currentRoute == null ||
                                        _endLocationId.isEmpty
                                    ? null
                                    : data.locations
                                          .firstWhere(
                                            (loc) => loc.id == _endLocationId,
                                            orElse: () => data.locations.first,
                                          )
                                          .position,
                              ),
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
                                      ? MinimizedRouteHeader(
                                          startLabel: data.locations
                                              .firstWhere(
                                                (loc) =>
                                                    loc.id == _startLocationId,
                                                orElse: () =>
                                                    data.locations.first,
                                              )
                                              .label,
                                          endLabel: data.locations
                                              .firstWhere(
                                                (loc) =>
                                                    loc.id == _endLocationId,
                                                orElse: () =>
                                                    data.locations.first,
                                              )
                                              .label,
                                          distance:
                                              _currentRoute?.distance ?? 0.0,
                                          onEdit: () {
                                            setState(
                                              () => _routeMinimized = false,
                                            );
                                          },
                                          onClose: () {
                                            _clearRoute();
                                          },
                                        )
                                      : RouteInputPanel(
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
                                          onFindRoute: () =>
                                              _calculateRoute(data),
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
                              child: SelectedAreaModal(
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
                              child: SelectedAreaModal(
                                area: modalArea,
                                onClose: () {
                                  setState(() => _selectedArea = null);
                                },
                              ),
                            ),
                          if (_selectedService != null &&
                              !wide &&
                              !_routingMode)
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 14,
                              child: SelectedServiceNavigationCard(
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
                              child: SelectedServiceNavigationCard(
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
                                  : (_routingMode && !_routeMinimized
                                        ? 260.0
                                        : 98.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MapControls(
                                    tileStyle: _tileStyle,
                                    onTileStyleChanged: (style) {
                                      setState(() => _tileStyle = style);
                                    },
                                    onLocateMe: _locateMe,
                                  ),
                                  const SizedBox(height: 12),
                                  CompassControl(rotation: _mapRotation),
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
    final nextScale = (currentScale * factor).clamp(minMapScale, maxMapScale);
    if (currentScale == nextScale) {
      return;
    }

    final adjustedFactor = nextScale / currentScale;
    _transformController.value = current.scaled(adjustedFactor, adjustedFactor);
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

      if (allowed != true || !mounted) {
        return;
      }
      setState(() => _locationAllowed = true);
    }

    if (!mounted) {
      return;
    }
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

  void _fitRouteToScreen(ExhibitionMapData data, RouteResult route) {
    final renderBox =
        _mapViewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return;
    }

    final size = renderBox.size;
    final projection = data.projectionFor(size);
    final nodeById = {for (final node in data.nodes) node.id: node};
    final points = route.nodeIds
        .map((nodeId) => nodeById[nodeId])
        .whereType<RoutingNode>()
        .map(
          (node) => projection.project(GeoPoint(node.longitude, node.latitude)),
        )
        .toList();
    if (points.isEmpty) {
      return;
    }

    final left = points.map((point) => point.dx).reduce(math.min);
    final right = points.map((point) => point.dx).reduce(math.max);
    final top = points.map((point) => point.dy).reduce(math.min);
    final bottom = points.map((point) => point.dy).reduce(math.max);
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

  void _calculateRoute(ExhibitionMapData data) {
    setState(() => _routeNotice = null);
    if (_startLocationId.isEmpty || _endLocationId.isEmpty) {
      setState(
        () => _routeNotice = 'Please select both start and end locations.',
      );
      return;
    }
    if (_startLocationId == _endLocationId) {
      setState(
        () => _routeNotice = 'Start and end locations must be different.',
      );
      return;
    }

    final start = data.locations.firstWhere(
      (loc) => loc.id == _startLocationId,
    );
    final end = data.locations.firstWhere((loc) => loc.id == _endLocationId);
    final result = shortestPath(start.nodeId, end.nodeId, data.edges);
    if (result == null) {
      setState(
        () => _routeNotice = 'No path was found between these locations.',
      );
      return;
    }

    setState(() {
      _currentRoute = result;
      _routeMinimized = true;
      _mapRotation = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(_currentRoute, result)) {
        _fitRouteToScreen(data, result);
      }
    });
  }
}
