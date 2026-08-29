part of '../../../../main.dart';

/// Helper for managing saved/bookmarked location IDs using SharedPreferences.
class SavedLocationsManager {
  static const _key = 'sabasaba_saved_locations_v1';

  static Future<List<String>> getSavedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<bool> isSaved(String id) async {
    final ids = await getSavedIds();
    return ids.contains(id);
  }

  static Future<List<String>> toggleSave(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    await prefs.setStringList(_key, ids);
    return ids;
  }
}

/// Saved places panel — matches the web navigator's "saved" panel.
class SavedPanel extends StatefulWidget {
  const SavedPanel({
    super.key,
    required this.locations,
    required this.savedIds,
    required this.onSelectLocation,
    required this.onSetDestination,
    required this.onToggleSave,
  });

  final List<RoutingLocation> locations;
  final List<String> savedIds;
  final ValueChanged<RoutingLocation> onSelectLocation;
  final ValueChanged<RoutingLocation> onSetDestination;
  final ValueChanged<String> onToggleSave;

  @override
  State<SavedPanel> createState() => _SavedPanelState();
}

class _SavedPanelState extends State<SavedPanel> {
  @override
  Widget build(BuildContext context) {
    final savedLocations = widget.locations
        .where((loc) => widget.savedIds.contains(loc.id))
        .toList();

    if (savedLocations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Column(
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 48,
              color: Color(0xffcbd5e1),
            ),
            SizedBox(height: 12),
            Text(
              'No Saved Places Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xff334155),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Bookmark your favorite booths or spaces to quickly access them later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xff94a3b8),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final loc in savedLocations) ...[
          _SavedLocationCard(
            location: loc,
            onTap: () => widget.onSelectLocation(loc),
            onSetDestination: () => widget.onSetDestination(loc),
            onUnsave: () => widget.onToggleSave(loc.id),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SavedLocationCard extends StatelessWidget {
  const _SavedLocationCard({
    required this.location,
    required this.onTap,
    required this.onSetDestination,
    required this.onUnsave,
  });

  final RoutingLocation location;
  final VoidCallback onTap;
  final VoidCallback onSetDestination;
  final VoidCallback onUnsave;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe2e8f0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        location.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff0f172a),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onUnsave,
                      icon: const Icon(
                        Icons.bookmark_rounded,
                        color: Color(0xff0284c7),
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Remove from saved',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  location.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff64748b),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.remove_red_eye_rounded, size: 14),
                      label: const Text('View', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: onSetDestination,
                      icon: const Icon(Icons.navigation_rounded, size: 14),
                      label: const Text('Directions', style: TextStyle(fontSize: 12)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff0284c7),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
