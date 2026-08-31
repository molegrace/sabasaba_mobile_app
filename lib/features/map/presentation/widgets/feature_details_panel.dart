part of '../../../../main.dart';

/// Selected feature info passed to the details panel.
class SelectedFeatureInfo {
  final String id;
  final String label;
  final String layerName;
  final String? companyName;
  final Map<String, dynamic> properties;
  final RoutingLocation? location;

  const SelectedFeatureInfo({
    required this.id,
    required this.label,
    required this.layerName,
    this.companyName,
    this.properties = const {},
    this.location,
  });
}

/// Feature details panel — exact structural & visual parity with Next.js Navigator.
class FeatureDetailsPanel extends StatefulWidget {
  const FeatureDetailsPanel({
    super.key,
    required this.info,
    required this.onSetDestination,
    required this.onSetStart,
    this.onToggleSave,
    this.isSaved = false,
    required this.onViewOnMap,
    required this.onShare,
  });

  final SelectedFeatureInfo info;
  final VoidCallback onSetDestination;
  final VoidCallback onSetStart;
  final VoidCallback? onToggleSave;
  final bool isSaved;
  final VoidCallback onViewOnMap;
  final VoidCallback onShare;

  @override
  State<FeatureDetailsPanel> createState() => _FeatureDetailsPanelState();
}

class _FeatureDetailsPanelState extends State<FeatureDetailsPanel> {
  String _activeTab = 'overview'; // 'overview' | 'offerings' | 'team' | 'about'
  Offering? _selectedOfferingModal;

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final props = info.properties;
    final loc = info.location;

    final companyName = loc?.companyName ?? props['company_name']?.toString() ?? info.companyName;
    final logoUrl = loc?.logoUrl ?? props['logo_url']?.toString();
    final rawPhotos = loc?.photos ?? (props['photos'] is List ? props['photos'] as List : null);
    final rawTeam = loc?.team ?? (props['team'] is List ? props['team'] as List : null);
    final offerings = loc?.offerings;

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
    final description = props['description']?.toString() ?? loc?.description;

    final industries = loc?.industries ??
        (loc?.industry != null
            ? [loc!.industry!]
            : (props['industries'] is List
                ? (props['industries'] as List).map((e) => e.toString()).toList()
                : (props['industry'] != null ? [props['industry'].toString()] : <String>[])));

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 1. Hero Cover Banner ──────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (heroImage != null && heroImage.isNotEmpty)
                      Image.network(
                        heroImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDefaultBannerGradient(info.layerName),
                      )
                    else
                      _buildDefaultBannerGradient(info.layerName),

                    // Gradient overlay
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0x990f172a),
                          ],
                        ),
                      ),
                    ),

                    // Floating Category Badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xcc0f172a),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xff34d399),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              info.layerName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 2. Main Title Section ──────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              companyName ?? info.label,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xff0f172a),
                                height: 1.2,
                              ),
                            ),
                            if (companyName != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                'Feature: ${info.label}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff64748b),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (logoUrl != null && logoUrl.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xffe2e8f0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0a000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              logoUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xffecfdf5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xffa7f3d0)),
                        ),
                        child: Text(
                          companyName != null ? 'Company' : 'Spatial Feature',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff047857),
                          ),
                        ),


                      ),
                      if (industries.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '• ${industries.join(", ")}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff64748b),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── 3. Action Circular Buttons Row ─────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xfff1f5f9)),
                  bottom: BorderSide(color: Color(0xffe2e8f0)),
                ),
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _CircularActionButton(
                    icon: Icons.turn_right_rounded,
                    label: 'Directions',
                    backgroundColor: const Color(0xff0284c7),
                    iconColor: Colors.white,
                    onTap: widget.onSetDestination,
                  ),
                  _CircularActionButton(
                    icon: Icons.location_on_rounded,
                    label: 'Start Point',
                    backgroundColor: const Color(0xffe0f2fe),
                    iconColor: const Color(0xff0369a1),
                    onTap: widget.onSetStart,
                  ),
                  _CircularActionButton(
                    icon: Icons.map_rounded,
                    label: 'View on map',
                    backgroundColor: const Color(0xffe0f2fe),
                    iconColor: const Color(0xff0369a1),
                    onTap: widget.onViewOnMap,
                  ),
                  if (widget.onToggleSave != null)
                    _CircularActionButton(
                      icon: widget.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      label: widget.isSaved ? 'Saved' : 'Save',
                      backgroundColor: widget.isSaved ? const Color(0xfff59e0b) : const Color(0xffe0f2fe),
                      iconColor: widget.isSaved ? Colors.white : const Color(0xff0369a1),
                      onTap: widget.onToggleSave!,
                    ),
                  _CircularActionButton(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    backgroundColor: const Color(0xffe0f2fe),
                    iconColor: const Color(0xff0369a1),
                    onTap: widget.onShare,
                  ),
                ],
              ),
            ),

            // ── 4. Navigation Tabs Bar ─────────────────────────────────────────
            Container(
              color: Colors.white,
              child: SingleChildScrollView(
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
            ),

            // ── 5. Tab Content Sections ────────────────────────────────────────
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

        // Product Details Modal Overlay
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xffe0f2fe),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (_selectedOfferingModal!.type ?? 'PRODUCT').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff0369a1),
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => setState(() => _selectedOfferingModal = null),
                            icon: const Icon(Icons.close_rounded, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_selectedOfferingModal!.imageUrl != null &&
                          _selectedOfferingModal!.imageUrl!.isNotEmpty) ...[
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
                          _selectedOfferingModal!.description!.isNotEmpty) ...[
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
    );
  }

  Widget _buildDefaultBannerGradient(String layerName) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff075985),
            Color(0xff312e81),
            Color(0xff0f172a),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_rounded, size: 40, color: Color(0xff38bdf8)),
            const SizedBox(height: 6),
            Text(
              layerName.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
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
          offerings: offerings,
        );
    }
  }

  // ── Tab 1: Overview ────────────────────────────────────────────────────────
  Widget _buildOverviewTab({
    required String? contactPerson,
    required String? email,
    required String? phone,
    required String? website,
    required List<Offering>? offerings,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Key Information Card
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
                'KEY INFORMATION',
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
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xff334155)),
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
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xff0284c7)),
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
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xff0284c7)),
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
                      if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: Text(
                      website,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xff0284c7)),
                    ),
                  ),
                ),
              const Divider(height: 20, color: Color(0xfff1f5f9)),
              Row(
                children: const [
                  Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xff10b981)),
                  SizedBox(width: 8),
                  Text(
                    'Open for Sabasaba Fair Exhibition',
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

        // Products & Offers Showcase Teaser
        if (offerings != null && offerings.isNotEmpty) ...[
          const SizedBox(height: 16),
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
                    Row(
                      children: const [
                        Icon(Icons.card_giftcard_rounded, size: 16, color: Color(0xff7c3aed)),
                        SizedBox(width: 6),
                        Text(
                          'PRODUCTS & OFFERS SHOWCASE',
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
                          if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
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

  // ── Tab 2: Products & Offers ───────────────────────────────────────────────
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
        child: Column(
          children: const [
            Icon(Icons.inventory_2_outlined, size: 36, color: Color(0xffcbd5e1)),
            SizedBox(height: 8),
            Text(
              'No products or special offers listed for this space.',
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
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
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
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                          const Spacer(),
                          if (item.priceText != null)
                            Text(
                              item.priceText!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff059669),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff0f172a),
                        ),
                      ),
                      if (item.description != null && item.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Color(0xff64748b)),
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

  // ── Tab 3: Team ────────────────────────────────────────────────────────────
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
        child: Column(
          children: const [
            Icon(Icons.people_outline_rounded, size: 36, color: Color(0xffcbd5e1)),
            SizedBox(height: 8),
            Text(
              'No team members listed for this company.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xff94a3b8)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: rawTeam.map((member) {
        final m = member is Map ? member : {};
        final name = (m['fullName'] ?? m['full_name'] ?? m['name'])?.toString() ?? 'Team Member';
        final jobTitle = (m['jobTitle'] ?? m['job_title'] ?? m['title'])?.toString() ?? 'Exhibitor Team';
        final bio = (m['bio'] ?? m['description'])?.toString();
        final photoUrl = (m['photoUrl'] ?? m['photo_url'] ?? m['avatar'])?.toString();

        return Container(
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
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xffe0f2fe),
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl == null || photoUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'T',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xff0369a1)),
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
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xff0f172a)),
                    ),
                    Text(
                      jobTitle,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xff0284c7)),
                    ),
                    if (bio != null && bio.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        bio,
                        style: const TextStyle(fontSize: 11, color: Color(0xff64748b), height: 1.3),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Tab 4: About ───────────────────────────────────────────────────────────
  Widget _buildAboutTab(String? description, Map<String, dynamic> props) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                description != null && description.isNotEmpty
                    ? description
                    : 'No company description has been provided.',
                style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xff334155)),
              ),
            ],
          ),
        ),
      ],
    );
  }

}

class _CircularActionButton extends StatelessWidget {
  const _CircularActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0f000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xff334155),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? const Color(0xff0284c7) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? const Color(0xff0284c7) : const Color(0xff64748b),
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: active ? const Color(0xffe0f2fe) : const Color(0xfff1f5f9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: active ? const Color(0xff0369a1) : const Color(0xff64748b),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

String? _featureMediaUrl(dynamic item) {
  if (item is String && item.trim().isNotEmpty) return item;
  if (item is Map) {
    final value = item['url'] ?? item['imageUrl'] ?? item['image_url'];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return null;
}
