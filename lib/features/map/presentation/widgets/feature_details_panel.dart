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

/// Feature details panel — matches the web navigator's "details" panel.
/// Shows layer badge, feature ID, exhibitor card, properties table,
/// and Set Destination / Set Starting Point buttons.
class FeatureDetailsPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final props = info.properties;
    final loc = info.location;
    final hasLocation = loc != null;

    final logoUrl = loc?.logoUrl ?? props['logo_url']?.toString();
    final photos = loc?.photos ?? (props['photos'] is List ? props['photos'] as List : null);
    final team = loc?.team ?? (props['team'] is List ? props['team'] as List : null);
    final offerings = loc?.offerings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Feature header card with logo and bookmark toggle
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xffe0f2fe).withOpacity(0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xffbae6fd)),
          ),
          child: Column(
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
                      color: const Color(0xffbae6fd),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      info.layerName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff0369a1),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (onToggleSave != null)
                    IconButton(
                      onPressed: onToggleSave,
                      icon: Icon(
                        isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: isSaved ? const Color(0xff0284c7) : const Color(0xff64748b),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: isSaved ? 'Remove bookmark' : 'Bookmark location',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (logoUrl != null && logoUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        logoUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      info.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff1e293b),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _FeatureAction(
              icon: Icons.map_rounded,
              label: 'View on map',
              onTap: onViewOnMap,
            ),
            if (onToggleSave != null)
              _FeatureAction(
                icon: isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: isSaved ? 'Saved' : 'Save',
                onTap: onToggleSave!,
                active: isSaved,
              ),
            _FeatureAction(
              icon: Icons.share_rounded,
              label: 'Share',
              onTap: onShare,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Photos gallery
        if (photos != null && photos.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final photoUrl = _featureMediaUrl(photos[idx]);
                if (photoUrl == null) return const SizedBox.shrink();
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    photoUrl,
                    width: 140,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Exhibitor card
        if (info.companyName != null || props['company_name'] != null) ...[
          _ExhibitorCard(properties: props),
          const SizedBox(height: 12),
        ],

        // Offerings (Products & Services)
        if (offerings != null && offerings.isNotEmpty) ...[
          const Text(
            'OFFERINGS & PRODUCTS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xff64748b),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          for (final offering in offerings) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xffe2e8f0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: offering.type == 'service'
                          ? const Color(0xfffef3c7)
                          : const Color(0xffdbeafe),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      (offering.type ?? 'Product').toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: offering.type == 'service'
                            ? const Color(0xffd97706)
                            : const Color(0xff2563eb),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offering.title ?? 'Offering',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff1e293b),
                          ),
                        ),
                        if (offering.description != null && offering.description!.isNotEmpty)
                          Text(
                            offering.description!,
                            style: const TextStyle(fontSize: 11, color: Color(0xff64748b)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (offering.priceText != null && offering.priceText!.isNotEmpty)
                    Text(
                      offering.priceText!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff059669),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],

        // Team members section
        if (team != null && team.isNotEmpty) ...[
          const Text(
            'BOOTH TEAM MEMBERS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xff64748b),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: team.map((member) {
              final name = member is Map
                  ? (member['fullName'] ?? member['full_name'] ?? member['name'])
                      ?.toString()
                  : member.toString();
              return Chip(
                avatar: const Icon(Icons.person_rounded, size: 14, color: Color(0xff0284c7)),
                label: Text(name ?? 'Team Member', style: const TextStyle(fontSize: 11)),
                backgroundColor: const Color(0xfff1f5f9),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Properties table
        _PropertiesTable(properties: props),
        const SizedBox(height: 16),

        // Navigation buttons
        if (hasLocation) ...[
          ElevatedButton.icon(
            onPressed: onSetDestination,
            icon: const Icon(Icons.flag_rounded, color: Color(0xfffda4af), size: 18),
            label: const Text(
              'Set as Destination',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff0284c7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onSetStart,
            icon: const Icon(
              Icons.location_on_rounded,
              color: Color(0xff10b981),
              size: 18,
            ),
            label: const Text(
              'Set as Starting Point',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xff334155),
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ] else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'This spatial boundary cannot be navigated directly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xff94a3b8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
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

class _FeatureAction extends StatelessWidget {
  const _FeatureAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor:
                  active ? const Color(0xfff59e0b) : const Color(0xffe0f2fe),
              child: Icon(
                icon,
                size: 20,
                color: active ? Colors.white : const Color(0xff0369a1),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xff475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExhibitorCard extends StatelessWidget {
  const _ExhibitorCard({required this.properties});

  final Map<String, dynamic> properties;

  @override
  Widget build(BuildContext context) {
    final companyName = properties['company_name'] as String?;
    final allocationStatus =
        properties['allocation_status'] as String? ?? 'Active';
    final contactPerson = properties['contact_person'] as String?;
    final email = properties['email'] as String?;
    final phone = properties['phone']?.toString();
    final website = properties['website']?.toString();
    final description = properties['description']?.toString();

    if (companyName == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfff0fdf4).withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffa7f3d0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xffa7f3d0).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ASSIGNED EXHIBITOR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff065f46),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                allocationStatus.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff059669),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            companyName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xff0f172a),
            ),
          ),
          if (contactPerson != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.person_rounded,
                  size: 14,
                  color: Color(0xff059669),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    contactPerson,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff475569),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (email != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.email_rounded,
                  size: 14,
                  color: Color(0xff059669),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff475569),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: () => launchUrl(Uri.parse('tel:${Uri.encodeComponent(phone)}')),
              child: Row(
                children: [
                  const Icon(Icons.phone_rounded, size: 14, color: Color(0xff059669)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      phone,
                      style: const TextStyle(fontSize: 12, color: Color(0xff0369a1)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (website != null && website.isNotEmpty) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: () {
                final uri = Uri.tryParse(website);
                if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Row(
                children: [
                  const Icon(Icons.language_rounded, size: 14, color: Color(0xff059669)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      website,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Color(0xff0369a1)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xff475569)),
            ),
          ],
        ],
      ),
    );
  }
}

class _PropertiesTable extends StatelessWidget {
  const _PropertiesTable({required this.properties});

  final Map<String, dynamic> properties;

  @override
  Widget build(BuildContext context) {
    final entries = properties.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.info_outline_rounded, size: 14, color: Color(0xff0284c7)),
            SizedBox(width: 6),
            Text(
              'FEATURE PROPERTIES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xff64748b),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffe2e8f0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: entries.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'No extra properties provided for this space.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xff94a3b8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < entries.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          color: Colors.grey.shade100,
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                entries[i].key.replaceAll('_', ' '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff64748b),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: Text(
                                entries[i].value is Map || entries[i].value is List
                                    ? entries[i].value.toString()
                                    : '${entries[i].value}',
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff1e293b),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
