part of '../../../main.dart';

class InfoTab extends StatelessWidget {
  const InfoTab({
    required this.buildingCount,
    required this.roadCount,
    required this.treeCount,
    this.exhibition,
  });

  final int buildingCount;
  final int roadCount;
  final int treeCount;
  final Exhibition? exhibition;

  @override
  Widget build(BuildContext context) {
    final ex = exhibition;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        children: [
          Text(
            ex?.title ?? 'SabaSaba Exhibition',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xff0b4238),
            ),
          ),
          const SizedBox(height: 6),
          if (ex != null) ...[
            _ExhibitionStatusBadge(exhibition: ex),
            const SizedBox(height: 6),
          ],
          const Text(
            'Use the map to find areas, services, routes, and nearby landmarks.',
            style: TextStyle(color: Color(0xff40534d)),
          ),
          const SizedBox(height: 18),
          InfoTile(
            icon: Icons.storefront,
            title: '$buildingCount exhibition areas',
            subtitle: 'Tap any building on the map to view services.',
          ),
          InfoTile(
            icon: Icons.alt_route,
            title: '$roadCount routes',
            subtitle: 'Zoom, pan, and rotate the map for easier navigation.',
          ),
          InfoTile(
            icon: Icons.park,
            title: '$treeCount mapped trees',
            subtitle: 'Green markers help orient visitors around the grounds.',
          ),
          const SizedBox(height: 10),
          const LegendRow(color: Color(0xff1aa987), label: 'Exhibition area'),
          const LegendRow(color: Color(0xfff26430), label: 'Selected area'),
          const LegendRow(color: Color(0xffd89b48), label: 'Road and boundary'),
        ],
      ),
    );
  }
}

class _ExhibitionStatusBadge extends StatelessWidget {
  const _ExhibitionStatusBadge({required this.exhibition});

  final Exhibition exhibition;

  @override
  Widget build(BuildContext context) {
    final isOngoing = exhibition.status == 'ongoing';
    final statusColor = isOngoing ? const Color(0xff1aa987) : const Color(0xff6b7280);
    final statusLabel = isOngoing ? 'Ongoing' : exhibition.status[0].toUpperCase() + exhibition.status.substring(1);

    String? dateRange;
    if (exhibition.startDate != null || exhibition.endDate != null) {
      final parts = <String>[];
      if (exhibition.startDate != null) parts.add(_formatDate(exhibition.startDate!));
      if (exhibition.endDate != null) parts.add(_formatDate(exhibition.endDate!));
      dateRange = parts.join(' – ');
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.5)),
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
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (dateRange != null) ...[
          const SizedBox(width: 8),
          Text(
            dateRange,
            style: const TextStyle(
              color: Color(0xff40534d),
              fontSize: 12,
            ),
          ),
        ],
        if (exhibition.year != null) ...[
          const SizedBox(width: 8),
          Text(
            '${exhibition.year}',
            style: const TextStyle(
              color: Color(0xff40534d),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]}';
    } catch (_) {
      return isoDate;
    }
  }
}

class InfoTile extends StatelessWidget {
  const InfoTile({
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

class LegendRow extends StatelessWidget {
  const LegendRow({required this.color, required this.label});

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
