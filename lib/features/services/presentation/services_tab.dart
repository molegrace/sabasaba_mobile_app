part of '../../../main.dart';

class ServicesTab extends StatefulWidget {
  const ServicesTab({
    super.key,
    required this.locations,
    required this.areas,
    required this.selectedService,
    required this.onSelectService,
    this.onSelectExhibitor,
    this.onNavigateToExhibitor,
  });

  final List<RoutingLocation> locations;
  final List<MapFeature> areas;
  final VisitorService? selectedService;
  final ValueChanged<VisitorService> onSelectService;
  final ValueChanged<RoutingLocation>? onSelectExhibitor;
  final ValueChanged<RoutingLocation>? onNavigateToExhibitor;

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  int _selectedSegment = 0; // 0: Exhibitors, 1: Visitor Facilities
  String _searchQuery = '';
  String _selectedIndustry = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── 1. Gather all Exhibitors / Companies ──────────────────────────────────
    final allExhibitors = widget.locations.where((loc) {
      final hasCompany =
          loc.companyName != null && loc.companyName!.trim().isNotEmpty;
      final isBooth = loc.properties['booth_number'] != null;
      return hasCompany || isBooth;
    }).toList();

    // Dynamically collect industries
    final industriesSet = <String>{};
    for (final loc in allExhibitors) {
      final inds =
          loc.industries ?? (loc.industry != null ? [loc.industry!] : <String>[]);
      for (final ind in inds) {
        if (ind.trim().isNotEmpty) {
          industriesSet.add(ind.trim());
        }
      }
    }
    final industriesList = ['All', ...industriesSet.toList()..sort()];

    // Filter exhibitors based on industry and search query
    final filteredExhibitors = allExhibitors.where((loc) {
      // Industry filter
      if (_selectedIndustry != 'All') {
        final locInds =
            loc.industries ?? (loc.industry != null ? [loc.industry!] : <String>[]);
        if (!locInds.contains(_selectedIndustry)) {
          return false;
        }
      }

      // Search query filter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchCompany =
            loc.companyName?.toLowerCase().contains(q) ?? false;
        final matchLabel = loc.label.toLowerCase().contains(q);
        final matchDesc = loc.description.toLowerCase().contains(q);
        final matchInd = loc.industry?.toLowerCase().contains(q) ?? false;
        final matchBooth = loc.properties['booth_number']
                ?.toString()
                .toLowerCase()
                .contains(q) ??
            false;
        final matchOfferings = loc.offerings?.any(
              (o) =>
                  (o.title?.toLowerCase().contains(q) ?? false) ||
                  (o.description?.toLowerCase().contains(q) ?? false),
            ) ??
            false;
        return matchCompany ||
            matchLabel ||
            matchDesc ||
            matchInd ||
            matchBooth ||
            matchOfferings;
      }
      return true;
    }).toList();

    final visitorServices = VisitorService.forAreas(widget.areas);

    return SafeArea(
      child: Column(
        children: [
          // ── Top Bar Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xffe0f2fe),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Color(0xff0284c7),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Services & Exhibitors',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xff0f172a),
                                ),
                          ),
                          const Text(
                            'Explore participating companies and fairground services.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xff64748b),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Segment Switcher (Exhibitors vs Visitor Facilities) ───────
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xffe2e8f0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SegmentTab(
                          label: 'Exhibitors (${allExhibitors.length})',
                          icon: Icons.business_rounded,
                          isSelected: _selectedSegment == 0,
                          onTap: () => setState(() => _selectedSegment = 0),
                        ),
                      ),
                      Expanded(
                        child: _SegmentTab(
                          label: 'Facilities (${visitorServices.length})',
                          icon: Icons.room_service_rounded,
                          isSelected: _selectedSegment == 1,
                          onTap: () => setState(() => _selectedSegment = 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Segment 0: Exhibitors Directory ──────────────────────────────────
          if (_selectedSegment == 0) ...[
            // Search Input Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffcbd5e1)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0a000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search company, booth, or product...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xff94a3b8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xff64748b),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              size: 18,
                              color: Color(0xff64748b),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Industry Chips Horizontal List
            if (industriesList.length > 1)
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: industriesList.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final ind = industriesList[index];
                    final isSelected = _selectedIndustry == ind;
                    return ChoiceChip(
                      label: Text(
                        ind,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xff334155),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xff0284c7),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xff0284c7)
                            : const Color(0xffcbd5e1),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedIndustry = ind);
                        }
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),

            // Exhibitors List View
            Expanded(
              child: filteredExhibitors.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.storefront_outlined,
                              size: 48,
                              color: Color(0xffcbd5e1),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No exhibitors found',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xff475569),
                                  ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Try adjusting your search terms or industry filter.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xff94a3b8),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedIndustry = 'All';
                                });
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Reset filters'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: filteredExhibitors.length,
                      itemBuilder: (context, index) {
                        final exhibitor = filteredExhibitors[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ExhibitorCard(
                            exhibitor: exhibitor,
                            onTap: () => _showExhibitorDetailsSheet(
                              context,
                              exhibitor,
                            ),
                            onViewOnMap: widget.onSelectExhibitor != null
                                ? () => widget.onSelectExhibitor!(exhibitor)
                                : null,
                            onDirections: widget.onNavigateToExhibitor != null
                                ? () => widget.onNavigateToExhibitor!(exhibitor)
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],

          // ── Segment 1: Visitor Facilities ────────────────────────────────────
          if (_selectedSegment == 1)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                children: [
                  for (final service in visitorServices) ...[
                    VisitorServiceTile(
                      service: service,
                      selected: widget.selectedService?.title == service.title,
                      onTap: () => widget.onSelectService(service),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Open Rich Exhibitor Details Bottom Sheet ────────────────────────────────
  void _showExhibitorDetailsSheet(
    BuildContext context,
    RoutingLocation exhibitor,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ExhibitorDetailSheet(
          exhibitor: exhibitor,
          onViewOnMap: () {
            Navigator.of(context).pop();
            if (widget.onSelectExhibitor != null) {
              widget.onSelectExhibitor!(exhibitor);
            }
          },
          onDirections: () {
            Navigator.of(context).pop();
            if (widget.onNavigateToExhibitor != null) {
              widget.onNavigateToExhibitor!(exhibitor);
            }
          },
        );
      },
    );
  }
}

// ── Segment Tab Helper Widget ────────────────────────────────────────────────
class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0f000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xff0284c7)
                  : const Color(0xff64748b),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xff0284c7)
                    : const Color(0xff64748b),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Exhibitor Card Widget ────────────────────────────────────────────────────
class _ExhibitorCard extends StatelessWidget {
  const _ExhibitorCard({
    required this.exhibitor,
    required this.onTap,
    this.onViewOnMap,
    this.onDirections,
  });

  final RoutingLocation exhibitor;
  final VoidCallback onTap;
  final VoidCallback? onViewOnMap;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    final companyName = exhibitor.companyName ?? exhibitor.label;
    final props = exhibitor.properties;
    final boothNumber = props['booth_number']?.toString();
    final layerName = exhibitor.layerName;
    final logoUrl = exhibitor.logoUrl ?? props['logo_url']?.toString();

    final industries = exhibitor.industries ??
        (exhibitor.industry != null ? [exhibitor.industry!] : <String>[]);
    final offeringsCount = exhibitor.offerings?.length ?? 0;

    final locationTag = boothNumber != null && boothNumber.isNotEmpty
        ? (boothNumber.startsWith('Booth')
            ? '$boothNumber • $layerName'
            : 'Booth $boothNumber • $layerName')
        : layerName;

    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo / Initial Avatar
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xfff8fafc),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffe2e8f0)),
                    ),
                    child: logoUrl != null && logoUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              logoUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  _buildInitialAvatar(companyName),
                            ),
                          )
                        : _buildInitialAvatar(companyName),
                  ),
                  const SizedBox(width: 12),

                  // Info Stack
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff0f172a),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: Color(0xff0284c7),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                locationTag,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (industries.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              for (final ind in industries.take(2))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffe0f2fe),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    ind,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xff0369a1),
                                    ),
                                  ),
                                ),
                              if (offeringsCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xfffef3c7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$offeringsCount Items',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xffb45309),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xff94a3b8),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xfff1f5f9)),
              const SizedBox(height: 8),

              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Color(0xff0284c7),
                    ),
                    label: const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff0284c7),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  if (onViewOnMap != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onViewOnMap,
                      icon: const Icon(
                        Icons.map_rounded,
                        size: 15,
                        color: Color(0xff0f172a),
                      ),
                      label: const Text(
                        'Map',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff0f172a),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: Color(0xffcbd5e1)),
                      ),
                    ),
                  ],
                  if (onDirections != null) ...[
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: onDirections,
                      icon: const Icon(Icons.near_me_rounded, size: 15),
                      label: const Text(
                        'Route',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff0284c7),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(String name) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'CO';
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff0284c7), Color(0xff0369a1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Exhibitor Detail Bottom Sheet Widget ─────────────────────────────────────
class _ExhibitorDetailSheet extends StatefulWidget {
  const _ExhibitorDetailSheet({
    required this.exhibitor,
    required this.onViewOnMap,
    required this.onDirections,
  });

  final RoutingLocation exhibitor;
  final VoidCallback onViewOnMap;
  final VoidCallback onDirections;

  @override
  State<_ExhibitorDetailSheet> createState() => _ExhibitorDetailSheetState();
}

class _ExhibitorDetailSheetState extends State<_ExhibitorDetailSheet> {
  String _activeTab = 'overview'; // 'overview' | 'offerings' | 'team' | 'about'
  Offering? _selectedOfferingModal;

  @override
  Widget build(BuildContext context) {
    final exhibitor = widget.exhibitor;
    final props = exhibitor.properties;

    final companyName = exhibitor.companyName ?? exhibitor.label;
    final logoUrl = exhibitor.logoUrl ?? props['logo_url']?.toString();
    final rawPhotos = exhibitor.photos ??
        (props['photos'] is List ? props['photos'] as List : null);
    final rawTeam = exhibitor.team ??
        (props['team'] is List ? props['team'] as List : null);
    final offerings = exhibitor.offerings;

    final photos = <String>[];
    if (rawPhotos != null) {
      for (final p in rawPhotos) {
        final url = _featureMediaUrl(p);
        if (url != null) photos.add(url);
      }
    }

    final heroImage = photos.isNotEmpty ? photos.first : logoUrl;
    final contactPerson = props['contact_person']?.toString();
    final email = props['email']?.toString();
    final phone = props['phone']?.toString();
    final website = props['website']?.toString();
    final description = props['description']?.toString() ?? exhibitor.description;

    final industries = exhibitor.industries ??
        (exhibitor.industry != null
            ? [exhibitor.industry!]
            : (props['industries'] is List
                ? (props['industries'] as List)
                    .map((e) => e.toString())
                    .toList()
                : (props['industry'] != null
                    ? [props['industry'].toString()]
                    : <String>[])));

    final boothNumber = props['booth_number']?.toString();
    final locationTag = boothNumber != null && boothNumber.isNotEmpty
        ? (boothNumber.startsWith('Booth')
            ? '$boothNumber • ${exhibitor.layerName}'
            : 'Booth $boothNumber • ${exhibitor.layerName}')
        : exhibitor.layerName;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  // Drag Handle Indicator
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xffcbd5e1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Cover Hero Image / Gradient
                  SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (heroImage != null && heroImage.isNotEmpty)
                          Image.network(
                            heroImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _buildCoverGradient(exhibitor.layerName),
                          )
                        else
                          _buildCoverGradient(exhibitor.layerName),

                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0x990f172a)],
                            ),
                          ),
                        ),

                        // Close Button
                        Positioned(
                          top: 10,
                          right: 12,
                          child: CircleAvatar(
                            backgroundColor: Colors.black45,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Company Title Bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                companyName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xff0f172a),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 15,
                                    color: Color(0xff0284c7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    locationTag,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xff475569),
                                    ),
                                  ),
                                ],
                              ),
                              if (industries.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final ind in industries)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xffe0f2fe),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xffbae6fd),
                                          ),
                                        ),
                                        child: Text(
                                          ind,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xff0369a1),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (logoUrl != null && logoUrl.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Container(
                            width: 56,
                            height: 56,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xffe2e8f0)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0f000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                logoUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Actions bar (View on Map & Directions)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xfff8fafc),
                      border: Border.symmetric(
                        horizontal: BorderSide(color: Color(0xffe2e8f0)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: widget.onDirections,
                            icon: const Icon(Icons.turn_right_rounded),
                            label: const Text('Get Directions'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xff0284c7),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onViewOnMap,
                            icon: const Icon(
                              Icons.map_rounded,
                              color: Color(0xff0f172a),
                            ),
                            label: const Text(
                              'View on Map',
                              style: TextStyle(color: Color(0xff0f172a)),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xffcbd5e1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Navigation Tabs Bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        _TabButton(
                          label: 'Overview',
                          active: _activeTab == 'overview',
                          onTap: () => setState(() => _activeTab = 'overview'),
                        ),
                        _TabButton(
                          label: 'Products & Offers',
                          count: offerings?.length,
                          active: _activeTab == 'offerings',
                          onTap: () => setState(() => _activeTab = 'offerings'),
                        ),
                        _TabButton(
                          label: 'Team',
                          count: rawTeam?.length,
                          active: _activeTab == 'team',
                          onTap: () => setState(() => _activeTab = 'team'),
                        ),
                        _TabButton(
                          label: 'About',
                          active: _activeTab == 'about',
                          onTap: () => setState(() => _activeTab = 'about'),
                        ),
                      ],
                    ),
                  ),

                  // Tab Content Area
                  Container(
                    color: const Color(0xfff8fafc),
                    padding: const EdgeInsets.all(16),
                    child: _buildTabContent(
                      contactPerson: contactPerson,
                      email: email,
                      phone: phone,
                      website: website,
                      description: description,
                      offerings: offerings,
                      rawTeam: rawTeam,
                      props: props,
                    ),
                  ),
                ],
              ),

              // Product Detail Modal Popup Overlay
              if (_selectedOfferingModal != null)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffe0f2fe),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    (
                                      _selectedOfferingModal!.type ?? 'PRODUCT'
                                    ).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xff0369a1),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => setState(
                                    () => _selectedOfferingModal = null,
                                  ),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_selectedOfferingModal!.imageUrl != null &&
                                _selectedOfferingModal!
                                    .imageUrl!
                                    .isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _selectedOfferingModal!.imageUrl!,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Text(
                              _selectedOfferingModal!.title ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff0f172a),
                              ),
                            ),
                            if (_selectedOfferingModal!.priceText != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _selectedOfferingModal!.priceText!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff059669),
                                ),
                              ),
                            ],
                            if (_selectedOfferingModal!.description != null &&
                                _selectedOfferingModal!
                                    .description!
                                    .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _selectedOfferingModal!.description!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xff475569),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoverGradient(String layerName) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff0284c7), Color(0xff1e3a8a), Color(0xff0f172a)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.storefront_rounded,
              size: 44,
              color: Color(0xff38bdf8),
            ),
            const SizedBox(height: 6),
            Text(
              layerName.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xffbae6fd),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent({
    required String? contactPerson,
    required String? email,
    required String? phone,
    required String? website,
    required String? description,
    required List<Offering>? offerings,
    required List<dynamic>? rawTeam,
    required Map<String, dynamic> props,
  }) {
    switch (_activeTab) {
      case 'offerings':
        return _buildOfferingsTab(offerings);
      case 'team':
        return _buildTeamTab(rawTeam);
      case 'about':
        return _buildAboutTab(description, props);
      case 'overview':
      default:
        return _buildOverviewTab(
          contactPerson: contactPerson,
          email: email,
          phone: phone,
          website: website,
          description: description,
          offerings: offerings,
        );
    }
  }

  Widget _buildOverviewTab({
    required String? contactPerson,
    required String? email,
    required String? phone,
    required String? website,
    required String? description,
    required List<Offering>? offerings,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description != null && description.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xffe2e8f0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ABOUT COMPANY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff94a3b8),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xff334155),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Key Contact Information Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xffe2e8f0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CONTACT DETAILS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff94a3b8),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              if (contactPerson != null && contactPerson.isNotEmpty)
                _InfoRow(
                  icon: Icons.person_rounded,
                  iconColor: const Color(0xff0284c7),
                  child: Text(
                    contactPerson,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff334155),
                    ),
                  ),
                ),
              if (email != null && email.isNotEmpty)
                _InfoRow(
                  icon: Icons.email_rounded,
                  iconColor: const Color(0xff0284c7),
                  child: InkWell(
                    onTap: () => launchUrl(Uri.parse('mailto:$email')),
                    child: Text(
                      email,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff0284c7),
                      ),
                    ),
                  ),
                ),
              if (phone != null && phone.isNotEmpty)
                _InfoRow(
                  icon: Icons.phone_rounded,
                  iconColor: const Color(0xff0284c7),
                  child: InkWell(
                    onTap: () => launchUrl(Uri.parse('tel:$phone')),
                    child: Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff0284c7),
                      ),
                    ),
                  ),
                ),
              if (website != null && website.isNotEmpty)
                _InfoRow(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xff0284c7),
                  child: InkWell(
                    onTap: () {
                      final uri = Uri.tryParse(website);
                      if (uri != null) {
                        launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: Text(
                      website,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff0284c7),
                      ),
                    ),
                  ),
                ),
              const Divider(height: 20, color: Color(0xfff1f5f9)),
              const Row(
                children: [
                  Icon(
                    Icons.access_time_filled_rounded,
                    size: 16,
                    color: Color(0xff10b981),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Active Exhibitor at SabaSaba Fair',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff065f46),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Showcase Teaser
        if (offerings != null && offerings.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xfff5f3ff), Color(0xfffaf5ff)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xffddd6fe)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.card_giftcard_rounded,
                          size: 16,
                          color: Color(0xff7c3aed),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'PRODUCTS SHOWCASE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff5b21b6),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => setState(() => _activeTab = 'offerings'),
                      child: Text(
                        'View All (${offerings.length})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff7c3aed),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final item in offerings.take(3)) ...[
                  InkWell(
                    onTap: () => setState(() => _selectedOfferingModal = item),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xffede9fe)),
                      ),
                      child: Row(
                        children: [
                          if (item.imageUrl != null &&
                              item.imageUrl!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                item.imageUrl!,
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title ?? 'Item',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff1e293b),
                                  ),
                                ),
                                if (item.priceText != null)
                                  Text(
                                    item.priceText!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xff059669),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOfferingsTab(List<Offering>? offerings) {
    if (offerings == null || offerings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xffe2e8f0)),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 36,
              color: Color(0xffcbd5e1),
            ),
            SizedBox(height: 8),
            Text(
              'No products or special offers listed for this exhibitor.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xff94a3b8)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: offerings.map((item) {
        return InkWell(
          onTap: () => setState(() => _selectedOfferingModal = item),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xffe2e8f0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffe0f2fe),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              (item.type ?? 'PRODUCT').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff0369a1),
                              ),
                            ),
                          ),
                          if (item.priceText != null) ...[
                            const Spacer(),
                            Text(
                              item.priceText!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff059669),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff0f172a),
                        ),
                      ),
                      if (item.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xff64748b),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTeamTab(List<dynamic>? rawTeam) {
    if (rawTeam == null || rawTeam.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xffe2e8f0)),
        ),
        child: const Column(
          children: [
            Icon(Icons.people_outline_rounded, size: 36, color: Color(0xffcbd5e1)),
            SizedBox(height: 8),
            Text(
              'No team members registered for this booth.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xff94a3b8)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: rawTeam.map((member) {
        final m = member is Map ? member : <String, dynamic>{};
        final name = m['name']?.toString() ?? 'Representative';
        final role = m['role']?.toString() ?? 'Booth Staff';
        final photo = m['photo']?.toString() ?? m['avatar']?.toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xffe2e8f0)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xffe0f2fe),
                backgroundImage: photo != null ? NetworkImage(photo) : null,
                child: photo == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'T',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xff0369a1),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff0f172a),
                      ),
                    ),
                    Text(
                      role,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xff64748b),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAboutTab(String? description, Map<String, dynamic> props) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EXHIBITION DETAILS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xff94a3b8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          if (props['booth_number'] != null)
            _AboutRow(
              label: 'Booth Number',
              value: props['booth_number'].toString(),
            ),
          if (widget.exhibitor.layerName.isNotEmpty)
            _AboutRow(label: 'Hall / Zone', value: widget.exhibitor.layerName),
          if (widget.exhibitor.industry != null)
            _AboutRow(
              label: 'Primary Sector',
              value: widget.exhibitor.industry!,
            ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xff334155),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xff64748b),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xff64748b)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xff0f172a),
            ),
          ),
        ],
      ),
    );
  }
}

class VisitorServiceTile extends StatelessWidget {
  const VisitorServiceTile({
    super.key,
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
      borderRadius: BorderRadius.circular(10),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
