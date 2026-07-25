part of '../../../../main.dart';

/// Category item for the spaces filter.
class _CategoryItem {
  final String id;
  final String label;
  final int count;

  const _CategoryItem({
    required this.id,
    required this.label,
    required this.count,
  });
}

/// Spaces panel — matches the web navigator's "spaces" panel content.
/// Shows horizontal category filter chips and a scrollable list of location cards.
class SpacesPanel extends StatefulWidget {
  const SpacesPanel({
    required this.locations,
    required this.categories,
    required this.filteredLocations,
    required this.categoryFilter,
    required this.onCategoryChanged,
    required this.onSelectLocation,
    required this.onSetTarget,
  });

  final List<RoutingLocation> locations;
  final List<_CategoryItem> categories;
  final List<RoutingLocation> filteredLocations;
  final String categoryFilter;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<RoutingLocation> onSelectLocation;
  final ValueChanged<RoutingLocation> onSetTarget;

  @override
  State<SpacesPanel> createState() => _SpacesPanelState();
}

class _SpacesPanelState extends State<SpacesPanel> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollFilters(bool left) {
    final scrollAmount = left ? -180.0 : 180.0;
    _scrollController.animateTo(
      (_scrollController.offset + scrollAmount).clamp(
        0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Category filter row
        Row(
          children: [
            // Scroll left
            _FilterScrollButton(
              icon: Icons.chevron_left_rounded,
              onTap: () => _scrollFilters(true),
            ),
            const SizedBox(width: 4),

            // Scrollable filter chips
            Expanded(
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final cat = widget.categories[index];
                    final isActive = widget.categoryFilter == cat.id;
                    return GestureDetector(
                      onTap: () => widget.onCategoryChanged(cat.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xff0284c7)
                              : const Color(0xfff1f5f9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xff0284c7)
                                : const Color(0xffe2e8f0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? Colors.white
                                    : const Color(0xff475569),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xff0369a1)
                                    : const Color(0xffe2e8f0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${cat.count}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? const Color(0xffbae6fd)
                                      : const Color(0xff64748b),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Scroll right
            _FilterScrollButton(
              icon: Icons.chevron_right_rounded,
              onTap: () => _scrollFilters(false),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Location cards
        if (widget.filteredLocations.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No locations match the selected filter.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xff94a3b8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          for (final loc in widget.filteredLocations) ...[
            _LocationCard(
              location: loc,
              onTap: () => widget.onSelectLocation(loc),
              onSetTarget: () => widget.onSetTarget(loc),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _FilterScrollButton extends StatelessWidget {
  const _FilterScrollButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xffe2e8f0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 16, color: const Color(0xff64748b)),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.onTap,
    required this.onSetTarget,
  });

  final RoutingLocation location;
  final VoidCallback onTap;
  final VoidCallback onSetTarget;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xfff1f5f9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1e293b),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff64748b),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSetTarget,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xffe0f2fe),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Set Target',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff0284c7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
