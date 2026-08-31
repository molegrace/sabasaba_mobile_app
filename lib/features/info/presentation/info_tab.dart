part of '../../../main.dart';

class InfoTab extends StatefulWidget {
  const InfoTab({
    super.key,
    required this.buildingCount,
    this.locations = const [],
    this.exhibition,
    this.onUnreadCountChanged,
    this.onSelectLocation,
  });

  final int buildingCount;
  final List<RoutingLocation> locations;
  final Exhibition? exhibition;
  final ValueChanged<int>? onUnreadCountChanged;
  final ValueChanged<RoutingLocation>? onSelectLocation;

  @override
  State<InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<InfoTab> {
  int _activeSubTab = 0; // 0 = Announcements, 1 = Grounds Guide
  List<VisitorAnnouncement> _announcements = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'critical', 'unread'
  String _selectedIndustryFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    final list = await VisitorAnnouncementManager.fetchAnnouncements();
    if (mounted) {
      setState(() {
        _announcements = list;
        _isLoading = false;
      });
      _notifyUnreadCount();
    }
  }

  void _notifyUnreadCount() {
    final unread = _announcements.where((a) => !a.isRead).length;
    widget.onUnreadCountChanged?.call(unread);
  }

  Future<void> _markRead(String id) async {
    await VisitorAnnouncementManager.markAsRead(id);
    if (!mounted) return;
    setState(() {
      _announcements =
          _announcements
              .map((a) => a.id == id ? a.copyWith(isRead: true) : a)
              .toList();
    });
    _notifyUnreadCount();
  }

  Future<void> _markAllRead() async {
    await VisitorAnnouncementManager.markAllAsRead(_announcements);
    if (!mounted) return;
    setState(() {
      _announcements =
          _announcements.map((a) => a.copyWith(isRead: true)).toList();
    });
    _notifyUnreadCount();
  }

  List<VisitorAnnouncement> get _filteredAnnouncements {
    if (_filter == 'critical') {
      return _announcements.where((a) => a.isCritical).toList();
    }
    if (_filter == 'unread') {
      return _announcements.where((a) => !a.isRead).toList();
    }
    return _announcements;
  }

  int get _unreadCount => _announcements.where((a) => !a.isRead).length;

  List<RoutingLocation> get _companyLocations {
    return widget.locations
        .where(
          (loc) => loc.companyName != null && loc.companyName!.trim().isNotEmpty,
        )
        .toList();
  }

  Map<String, int> get _industryCounts {
    final map = <String, int>{'all': _companyLocations.length};
    for (final loc in _companyLocations) {
      final inds =
          (loc.industries != null && loc.industries!.isNotEmpty)
              ? loc.industries!
              : (loc.industry != null ? [loc.industry!] : <String>[]);
      for (final ind in inds) {
        if (ind.trim().isNotEmpty) {
          map[ind] = (map[ind] ?? 0) + 1;
        }
      }
    }
    return map;
  }

  List<RoutingLocation> get _filteredCompanyLocations {
    if (_selectedIndustryFilter == 'all') {
      return _companyLocations;
    }
    return _companyLocations.where((loc) {
      final inds =
          (loc.industries != null && loc.industries!.isNotEmpty)
              ? loc.industries!
              : (loc.industry != null ? [loc.industry!] : <String>[]);
      return inds.contains(_selectedIndustryFilter) ||
          loc.industry == _selectedIndustryFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exhibition;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadAnnouncements,
        color: const Color(0xff0284c7),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            // Top Header Hero Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff0369a1), Color(0xff0b4238)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff0b4238).withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          ex?.title ?? 'SabaSaba Exhibition',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xff4ade80),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Live Broadcast',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (ex != null) ...[
                    _ExhibitionStatusBadge(exhibition: ex),
                    const SizedBox(height: 10),
                  ],
                  const Text(
                    'Stay informed with official admin announcements & explore present companies & ground facilities.',
                    style: TextStyle(
                      color: Color(0xffe0f2fe),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Segmented Sub-Tab Bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xffe2e8f0),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeSubTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              _activeSubTab == 0
                                  ? Colors.white
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow:
                              _activeSubTab == 0
                                  ? [
                                    const BoxShadow(
                                      color: Colors.black12,
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
                              Icons.campaign_rounded,
                              size: 18,
                              color:
                                  _activeSubTab == 0
                                      ? const Color(0xff0284c7)
                                      : const Color(0xff64748b),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Announcements',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color:
                                    _activeSubTab == 0
                                        ? const Color(0xff0284c7)
                                        : const Color(0xff64748b),
                              ),
                            ),
                            if (_unreadCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xffef4444),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$_unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeSubTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              _activeSubTab == 1
                                  ? Colors.white
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow:
                              _activeSubTab == 1
                                  ? [
                                    const BoxShadow(
                                      color: Colors.black12,
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
                              Icons.storefront_rounded,
                              size: 18,
                              color:
                                  _activeSubTab == 1
                                      ? const Color(0xff0284c7)
                                      : const Color(0xff64748b),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Grounds Guide',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color:
                                    _activeSubTab == 1
                                        ? const Color(0xff0284c7)
                                        : const Color(0xff64748b),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab 0: Announcements Section
            if (_activeSubTab == 0) ...[
              // Filters and Quick Actions Header
              Row(
                children: [
                  Wrap(
                    spacing: 6,
                    children: [
                      _buildFilterChip('all', 'All (${_announcements.length})'),
                      _buildFilterChip(
                        'critical',
                        'Critical (${_announcements.where((a) => a.isCritical).length})',
                      ),
                      _buildFilterChip('unread', 'Unread ($_unreadCount)'),
                    ],
                  ),
                  const Spacer(),
                  if (_unreadCount > 0)
                    TextButton(
                      onPressed: _markAllRead,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff0284c7),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xff0284c7)),
                  ),
                )
              else if (_filteredAnnouncements.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 36,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffe2e8f0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.notifications_off_outlined,
                        size: 44,
                        color: Color(0xff94a3b8),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No announcements found',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xff1e293b),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _filter == 'all'
                            ? 'Admin announcements sent to visitors will appear here live.'
                            : 'No announcements match the selected filter.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff64748b),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadAnnouncements,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0284c7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredAnnouncements.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _filteredAnnouncements[index];
                    return _AnnouncementCard(
                      announcement: item,
                      onTap: () {
                        _markRead(item.id);
                        _showAnnouncementDetail(context, item);
                      },
                    );
                  },
                ),
            ] else ...[
              // ── Tab 1: Redesigned Grounds Guide (Companies Present & Facilities) ──
              _buildRedesignedGroundsGuide(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRedesignedGroundsGuide() {
    final companyCount = _companyLocations.length;
    final indCounts = _industryCounts;
    final filteredCompanies = _filteredCompanyLocations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Key Statistics Banner (Grid Cards)
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.domain_rounded,
                count: '${widget.buildingCount}',
                label: 'Exhibition Halls',
                accentColor: const Color(0xff0284c7),
                backgroundColor: const Color(0xfff0f9ff),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.business_center_rounded,
                count: '$companyCount',
                label: 'Exhibiting Companies',
                accentColor: const Color(0xff059669),
                backgroundColor: const Color(0xffecfdf5),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.room_service_rounded,
                count: '8',
                label: 'Ground Facilities',
                accentColor: const Color(0xff7c3aed),
                backgroundColor: const Color(0xfff5f3ff),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // 2. Companies Present Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Exhibiting Companies & Brands',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Color(0xff0b4238),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$companyCount registered companies operating booths',
                  style: const TextStyle(
                    color: Color(0xff64748b),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xffecfdf5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xffa7f3d0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xff10b981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Total Companies',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff047857),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Industry Filter Pills
        if (indCounts.length > 1) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  indCounts.entries.map((entry) {
                    final key = entry.key;
                    final count = entry.value;
                    final isSelected = _selectedIndustryFilter == key;
                    final label = key == 'all' ? 'All Industries' : key;

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedIndustryFilter = key);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? const Color(0xff047857)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? const Color(0xff047857)
                                      : const Color(0xffcbd5e1),
                            ),
                          ),
                          child: Text(
                            '$label ($count)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : const Color(0xff334155),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Company List Cards
        if (filteredCompanies.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffe2e8f0)),
            ),
            child: const Text(
              'No exhibiting companies match this industry filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xff64748b), fontSize: 12),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: math.min(5, filteredCompanies.length),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final comp = filteredCompanies[index];
              return _CompanyTile(
                location: comp,
                onTap: () => widget.onSelectLocation?.call(comp),
              );
            },
          ),

        if (filteredCompanies.length > 5) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              '+ ${filteredCompanies.length - 5} more exhibiting companies available on Navigator tab',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xff0284c7),
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // 3. Ground Facilities & Services Section
        const Text(
          'Ground Facilities & Visitor Services',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Color(0xff0b4238),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Essential amenities and support stations located throughout the grounds',
          style: TextStyle(color: Color(0xff64748b), fontSize: 12),
        ),

        const SizedBox(height: 14),

        // Facilities Grid (8 Items)
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.1,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: const [
            _FacilityGridTile(
              icon: Icons.local_parking_rounded,
              title: 'Parking & Access',
              subtitle: 'Vehicle & VIP entry',
              color: Color(0xff0284c7),
              bgColor: Color(0xfff0f9ff),
            ),
            _FacilityGridTile(
              icon: Icons.wc_rounded,
              title: 'Public Restrooms',
              subtitle: 'Clean washrooms',
              color: Color(0xff2563eb),
              bgColor: Color(0xffeff6ff),
            ),
            _FacilityGridTile(
              icon: Icons.restaurant_rounded,
              title: 'Food & Dining',
              subtitle: 'Restaurants & drinks',
              color: Color(0xffd97706),
              bgColor: Color(0xfffffbeb),
            ),
            _FacilityGridTile(
              icon: Icons.info_outline_rounded,
              title: 'Information Desks',
              subtitle: 'Help & map guides',
              color: Color(0xff059669),
              bgColor: Color(0xffecfdf5),
            ),
            _FacilityGridTile(
              icon: Icons.medical_services_outlined,
              title: 'First Aid & Medical',
              subtitle: 'Emergency response',
              color: Color(0xffdc2626),
              bgColor: Color(0xfffef2f2),
            ),
            _FacilityGridTile(
              icon: Icons.account_balance_rounded,
              title: 'ATMs & Banking',
              subtitle: 'Cash & mobile pay',
              color: Color(0xff4f46e5),
              bgColor: Color(0xffeeefed),
            ),
            _FacilityGridTile(
              icon: Icons.login_rounded,
              title: 'Entrance Gates',
              subtitle: 'Main entry gates',
              color: Color(0xff16a34a),
              bgColor: Color(0xfff0fdf4),
            ),
            _FacilityGridTile(
              icon: Icons.security_rounded,
              title: 'Ground Security',
              subtitle: 'Lost & found, safety',
              color: Color(0xff7c3aed),
              bgColor: Color(0xfff5f3ff),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 4. Ground Map Legend
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffe2e8f0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Grounds Map Color Legend',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xff0b4238),
                ),
              ),
              const SizedBox(height: 10),
              const LegendRow(
                color: Color(0xff1aa987),
                label: 'Exhibition Pavilions & Booths',
              ),
              const LegendRow(
                color: Color(0xfff26430),
                label: 'Selected Building / Booth Area',
              ),
              const LegendRow(
                color: Color(0xffd89b48),
                label: 'Ground Boundaries & Access Walkways',
              ),
              const LegendRow(
                color: Color(0xff0284c7),
                label: 'Visitor Service & Facility Station',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff0284c7) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xff0284c7) : const Color(0xffcbd5e1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xff334155),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showAnnouncementDetail(
    BuildContext context,
    VisitorAnnouncement announcement,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (announcement.isCritical)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xfffef2f2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xfffca5a5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 13,
                            color: Color(0xffdc2626),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Critical Alert',
                            style: TextStyle(
                              color: Color(0xffdc2626),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xfff0f9ff),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xffbae6fd)),
                      ),
                      child: const Text(
                        'Official Broadcast',
                        style: TextStyle(
                          color: Color(0xff0284c7),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    _formatTime(announcement.createdAt),
                    style: const TextStyle(
                      color: Color(0xff64748b),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                announcement.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xff0f172a),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xfff8fafc),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xffe2e8f0)),
                ),
                child: Text(
                  announcement.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xff334155),
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0284c7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close Announcement',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.count,
    required this.label,
    required this.accentColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final String count;
  final String label;
  final Color accentColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: accentColor),
          const SizedBox(height: 6),
          Text(
            count,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xff475569),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyTile extends StatelessWidget {
  const _CompanyTile({required this.location, this.onTap});

  final RoutingLocation location;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final companyName = location.companyName ?? location.label;
    final industry = location.industry ?? 'Exhibitor';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xffecfdf5),
                child: Text(
                  companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xff047857),
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xff0f172a),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xfff1f5f9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            industry,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff475569),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            location.label,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xff64748b),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xff94a3b8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FacilityGridTile extends StatelessWidget {
  const _FacilityGridTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xff64748b),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement, required this.onTap});

  final VisitorAnnouncement announcement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCritical = announcement.isCritical;
    final isUnread = !announcement.isRead;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isUnread
                    ? (isCritical
                        ? const Color(0xfffff1f2)
                        : const Color(0xfff0f9ff))
                    : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isUnread
                      ? (isCritical
                          ? const Color(0xfffca5a5)
                          : const Color(0xffbae6fd))
                      : const Color(0xffe2e8f0),
              width: isUnread ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUnread) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 4, right: 8),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color:
                            isCritical
                                ? const Color(0xffef4444)
                                : const Color(0xff0284c7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: TextStyle(
                        fontWeight:
                            isUnread ? FontWeight.w900 : FontWeight.w700,
                        fontSize: 15,
                        color: const Color(0xff0f172a),
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isCritical)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xfffee2e2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'CRITICAL',
                        style: TextStyle(
                          color: Color(0xffdc2626),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffe0f2fe),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'UPDATE',
                        style: TextStyle(
                          color: Color(0xff0369a1),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                announcement.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xff475569),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: Color(0xff94a3b8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(announcement.createdAt),
                        style: const TextStyle(
                          color: Color(0xff64748b),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Text(
                        'Read full',
                        style: TextStyle(
                          color: Color(0xff0284c7),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xff0284c7),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _ExhibitionStatusBadge extends StatelessWidget {
  const _ExhibitionStatusBadge({required this.exhibition});

  final Exhibition exhibition;

  @override
  Widget build(BuildContext context) {
    final isOngoing = exhibition.status == 'ongoing';
    final statusColor =
        isOngoing ? const Color(0xff4ade80) : const Color(0xffcbd5e1);
    final statusLabel =
        isOngoing
            ? 'Ongoing Exhibition'
            : exhibition.status[0].toUpperCase() +
                exhibition.status.substring(1);

    String? dateRange;
    if (exhibition.startDate != null || exhibition.endDate != null) {
      final parts = <String>[];
      if (exhibition.startDate != null) {
        parts.add(_formatDate(exhibition.startDate!));
      }
      if (exhibition.endDate != null) {
        parts.add(_formatDate(exhibition.endDate!));
      }
      dateRange = parts.join(' – ');
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                statusLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (dateRange != null) ...[
          const SizedBox(width: 8),
          Text(
            dateRange,
            style: const TextStyle(color: Color(0xffe0f2fe), fontSize: 11),
          ),
        ],
        if (exhibition.year != null) ...[
          const SizedBox(width: 8),
          Text(
            '${exhibition.year}',
            style: const TextStyle(
              color: Color(0xffe0f2fe),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${months[date.month - 1]}';
    } catch (_) {
      return isoDate;
    }
  }
}

class LegendRow extends StatelessWidget {
  const LegendRow({super.key, required this.color, required this.label});

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
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  const InfoTile({
    super.key,
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
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xffe4f4ee),
            child: Icon(icon, color: const Color(0xff0b4238)),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}
