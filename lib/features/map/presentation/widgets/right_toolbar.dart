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
    required this.onDirections,
    required this.isFullscreen,
    required this.onToggleFullscreen,
  });

  final MapTileStyle tileStyle;
  final ValueChanged<MapTileStyle> onTileStyleChanged;
  final bool showLegend;
  final VoidCallback onToggleLegend;
  final VoidCallback onLocateMe;
  final VoidCallback onResetView;
  final VoidCallback onDirections;
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;

  @override
  State<NavigatorRightToolbar> createState() => _NavigatorRightToolbarState();
}

class _NavigatorRightToolbarState extends State<NavigatorRightToolbar> {
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

        // Layer picker (using PopupMenuButton so hit testing works 100% on touch screens)
        Theme(
          data: Theme.of(context).copyWith(
            hoverColor: const Color(0xfff0f9ff),
            highlightColor: const Color(0xffe0f2fe),
          ),
          child: PopupMenuButton<MapTileStyle>(
            tooltip: 'Map Layers / Appearance',
            offset: const Offset(-180, 0),
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xffe2e8f0)),
            ),
            color: Colors.white,
            onSelected: (style) {
              widget.onTileStyleChanged(style);
            },
            itemBuilder: (context) {
              return MapTileStyle.values.map((style) {
                final isActive = widget.tileStyle == style;
                return PopupMenuItem<MapTileStyle>(
                  value: style,
                  height: 44,
                  child: Row(
                    children: [
                      Icon(
                        style.icon,
                        size: 18,
                        color: isActive
                            ? const Color(0xff0284c7)
                            : const Color(0xff64748b),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        style.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.w500,
                          color: isActive
                              ? const Color(0xff0284c7)
                              : const Color(0xff334155),
                        ),
                      ),
                      if (isActive) ...[
                        const Spacer(),
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Color(0xff0284c7),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList();
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.layers_rounded,
                size: 20,
                color: Color(0xff1e293b),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Reset view / center map
        _ToolbarButton(
          icon: Icons.adjust_rounded,
          tooltip: 'Center Map / Reset View',
          onTap: widget.onResetView,
        ),
        const SizedBox(height: 8),

        _ToolbarButton(
          icon: Icons.turn_right_rounded,
          iconColor: const Color(0xff0284c7),
          tooltip: 'Directions',
          onTap: widget.onDirections,
        ),
        const SizedBox(height: 8),

        _ToolbarButton(
          icon: widget.isFullscreen
              ? Icons.fullscreen_exit_rounded
              : Icons.fullscreen_rounded,
          tooltip: widget.isFullscreen ? 'Exit Full Screen' : 'Full Screen',
          onTap: widget.onToggleFullscreen,
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
              color: Colors.black.withValues(alpha: 0.1),
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
