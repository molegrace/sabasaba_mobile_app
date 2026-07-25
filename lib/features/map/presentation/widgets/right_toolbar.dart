part of '../../../../main.dart';

/// Right floating toolbar — matches the web navigator's RightSideBar.
/// Has locate button, layer picker popover, reset view, and legend toggle.
class NavigatorRightToolbar extends StatefulWidget {
  const NavigatorRightToolbar({
    required this.tileStyle,
    required this.onTileStyleChanged,
    required this.showLegend,
    required this.onToggleLegend,
    required this.onLocateMe,
    required this.onResetView,
  });

  final MapTileStyle tileStyle;
  final ValueChanged<MapTileStyle> onTileStyleChanged;
  final bool showLegend;
  final VoidCallback onToggleLegend;
  final VoidCallback onLocateMe;
  final VoidCallback onResetView;

  @override
  State<NavigatorRightToolbar> createState() => _NavigatorRightToolbarState();
}

class _NavigatorRightToolbarState extends State<NavigatorRightToolbar> {
  bool _layersOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Locate me
        _ToolbarButton(
          icon: Icons.my_location_rounded,
          iconColor: const Color(0xff0284c7),
          tooltip: 'Show My Location',
          onTap: widget.onLocateMe,
        ),
        const SizedBox(height: 8),

        // Layer picker
        Stack(
          clipBehavior: Clip.none,
          children: [
            _ToolbarButton(
              icon: Icons.layers_rounded,
              tooltip: 'Map Layers',
              isActive: _layersOpen,
              onTap: () => setState(() => _layersOpen = !_layersOpen),
            ),
            if (_layersOpen)
              Positioned(
                right: 50,
                top: 0,
                child: Material(
                  elevation: 8,
                  color: Colors.white.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(12),
                  shadowColor: Colors.black26,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 4,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final style in MapTileStyle.values)
                          _LayerPickerItem(
                            style: style,
                            isActive: widget.tileStyle == style,
                            onTap: () {
                              widget.onTileStyleChanged(style);
                              setState(() => _layersOpen = false);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Reset view / center map
        _ToolbarButton(
          icon: Icons.adjust_rounded,
          tooltip: 'Center Map / Reset View',
          onTap: widget.onResetView,
        ),
        const SizedBox(height: 8),

        // Legend toggle
        _ToolbarButton(
          icon: Icons.info_outline_rounded,
          tooltip: 'Toggle Legend',
          isActive: widget.showLegend,
          activeColor: const Color(0xffe0f2fe),
          activeIconColor: const Color(0xff0284c7),
          onTap: widget.onToggleLegend,
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.iconColor,
    this.isActive = false,
    this.activeColor,
    this.activeIconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? iconColor;
  final bool isActive;
  final Color? activeColor;
  final Color? activeIconColor;

  @override
  Widget build(BuildContext context) {
    final bg = isActive ? (activeColor ?? const Color(0xffe0f2fe)) : Colors.white;
    final fg = isActive
        ? (activeIconColor ?? const Color(0xff0284c7))
        : (iconColor ?? const Color(0xff1e293b));

    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: fg),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

class _LayerPickerItem extends StatelessWidget {
  const _LayerPickerItem({
    required this.style,
    required this.isActive,
    required this.onTap,
  });

  final MapTileStyle style;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xffe0f2fe) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              style.icon,
              size: 16,
              color: isActive
                  ? const Color(0xff0284c7)
                  : const Color(0xff64748b),
            ),
            const SizedBox(width: 8),
            Text(
              style.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? const Color(0xff0369a1)
                    : const Color(0xff334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
