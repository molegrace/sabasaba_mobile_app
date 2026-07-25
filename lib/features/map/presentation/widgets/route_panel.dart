part of '../../../../main.dart';

/// Route input panel — matches the web navigator's route panel content.
/// Uses dropdowns with emerald/rose icons for start/end locations.
class RouteInputPanel extends StatelessWidget {
  const RouteInputPanel({
    required this.locations,
    required this.startId,
    required this.endId,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onFindRoute,
    required this.onClearRoute,
    this.notice,
  });

  final List<RoutingLocation> locations;
  final String startId;
  final String endId;
  final ValueChanged<String> onStartChanged;
  final ValueChanged<String> onEndChanged;
  final VoidCallback onFindRoute;
  final VoidCallback onClearRoute;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Start location
        _RouteLocationLabel(
          icon: Icons.location_on_rounded,
          iconColor: const Color(0xff10b981),
          label: 'Start Location',
        ),
        const SizedBox(height: 6),
        _RouteDropdown(
          value: startId.isEmpty ? null : startId,
          hint: 'Select starting point',
          locations: locations,
          onChanged: (val) {
            if (val != null) onStartChanged(val);
          },
        ),
        const SizedBox(height: 14),

        // Destination
        _RouteLocationLabel(
          icon: Icons.flag_rounded,
          iconColor: const Color(0xfff43f5e),
          label: 'Destination',
        ),
        const SizedBox(height: 6),
        _RouteDropdown(
          value: endId.isEmpty ? null : endId,
          hint: 'Select destination',
          locations: locations,
          onChanged: (val) {
            if (val != null) onEndChanged(val);
          },
        ),

        // Notice
        if (notice != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xfffffbeb),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xfffde68a)),
            ),
            child: Text(
              notice!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xff92400e),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Find Route button
        ElevatedButton.icon(
          onPressed: onFindRoute,
          icon: const Icon(Icons.signpost_rounded, size: 18),
          label: const Text(
            'Find Route',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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

        // Clear Route button
        OutlinedButton.icon(
          onPressed: onClearRoute,
          icon: const Icon(Icons.close_rounded, size: 16),
          label: const Text(
            'Clear Route',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xff64748b),
            padding: const EdgeInsets.symmetric(vertical: 11),
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteLocationLabel extends StatelessWidget {
  const _RouteLocationLabel({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xff64748b),
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _RouteDropdown extends StatelessWidget {
  const _RouteDropdown({
    required this.value,
    required this.hint,
    required this.locations,
    required this.onChanged,
  });

  final String? value;
  final String hint;
  final List<RoutingLocation> locations;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe2e8f0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xff94a3b8),
            ),
          ),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xff1e293b),
            fontWeight: FontWeight.w500,
          ),
          items: locations.map((loc) {
            return DropdownMenuItem<String>(
              value: loc.id,
              child: Text(
                '${loc.label} — ${loc.description}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
