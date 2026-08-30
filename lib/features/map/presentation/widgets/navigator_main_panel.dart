part of '../../../../main.dart';

/// Responsive sliding main panel that overlays the map — matches web navigator's MainPanel.
/// On mobile (width < 600) it occupies ~82% width (max 340px) so the visitor
/// can clearly see the map canvas, selected features, pins, and controls on the right.
/// On desktop/tablet (width >= 600) it occupies a fixed width of 400px on the left.
class NavigatorMainPanel extends StatelessWidget {
  const NavigatorMainPanel({
    super.key,
    required this.title,
    required this.onClose,
    required this.child,
  });

  final String title;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDesktop = media.size.width >= 600;
    final statusBarHeight = media.padding.top;
    final topClearance = statusBarHeight + 68.0;

    final panelWidth = isDesktop
        ? 400.0
        : math.min(media.size.width * 0.82, 340.0);

    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: panelWidth,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: isDesktop
              ? null
              : const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
          border: isDesktop
              ? Border(right: BorderSide(color: Colors.grey.shade200))
              : Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 20,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Clear space for search box
            SizedBox(height: topClearance),

            // Title bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.explore_rounded,
                    color: Color(0xfffbbf24),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1e293b),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: const Color(0xff64748b),
                    tooltip: 'Close panel',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
