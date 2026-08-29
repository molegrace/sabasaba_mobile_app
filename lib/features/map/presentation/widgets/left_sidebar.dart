part of '../../../../main.dart';

/// Matches the web navigator's LeftSideBar component.
/// Slides in from the left with a backdrop overlay.
class LeftSidebar extends StatelessWidget {
  const LeftSidebar({
    super.key,
    required this.isOpen,
    required this.activePanel,
    required this.onClose,
    required this.onSelect,
  });

  final bool isOpen;
  final String? activePanel;
  final VoidCallback onClose;
  final ValueChanged<String> onSelect;

  static const _menuItems = [
    _SidebarItem(
      label: 'route',
      name: 'Navigation',
      icon: Icons.alt_route_rounded,
    ),
    _SidebarItem(
      label: 'spaces',
      name: 'Existing Things',
      icon: Icons.business_rounded,
    ),
    _SidebarItem(
      label: 'saved',
      name: 'Saved Locations',
      icon: Icons.bookmark_rounded,
    ),
    _SidebarItem(
      label: 'filters',
      name: 'Filters',
      icon: Icons.tune_rounded,
    ),
    _SidebarItem(
      label: 'legend',
      name: 'Map Legend',
      icon: Icons.info_rounded,
    ),
    _SidebarItem(
      label: 'help',
      name: 'Navigator Help',
      icon: Icons.help_rounded,
    ),
  ];



  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isOpen,
      child: Stack(
        children: [
          // Backdrop overlay
          if (isOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: Container(color: Colors.black.withValues(alpha: 0.18)),
              ),
            ),

          // Sidebar panel
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 260,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              offset: isOpen ? Offset.zero : const Offset(-1, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  border: Border(
                    right: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(4, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.map_rounded,
                              color: Color(0xfffbbf24),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Sabasaba',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff1e293b),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: onClose,
                              icon: const Icon(Icons.close_rounded, size: 20),
                              color: const Color(0xff64748b),
                              tooltip: 'Close sidebar',
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: Colors.grey.shade200),
                      const SizedBox(height: 8),

                      // Nav items
                      for (final item in _menuItems) ...[
                        _SidebarNavItem(
                          item: item,
                          isActive: activePanel == item.label,
                          onTap: () => onSelect(item.label),
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
  }
}

class _SidebarItem {
  final String label;
  final String name;
  final IconData icon;

  const _SidebarItem({
    required this.label,
    required this.name,
    required this.icon,
  });
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _SidebarItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isActive ? const Color(0xffe0f2fe) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isActive
                      ? const Color(0xff0284c7)
                      : const Color(0xff64748b),
                ),
                const SizedBox(width: 12),
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? const Color(0xff0369a1)
                        : const Color(0xff334155),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
