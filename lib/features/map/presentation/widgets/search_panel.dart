part of '../../../../main.dart';

/// Navigator search box with hamburger menu — matches the web's SearchBox component.
/// Accepts a persistent [TextEditingController] from the parent to avoid
/// recreating the controller on every rebuild (which loses focus and caret).
class NavigatorSearchBox extends StatelessWidget {
  const NavigatorSearchBox({
    required this.controller,
    required this.isLeftOpen,
    required this.onToggleSidebar,
    required this.onFocus,
    this.onSearchChange,
    this.placeholder = 'Search exhibitors, booths, spaces...',
  });

  final TextEditingController controller;
  final bool isLeftOpen;
  final VoidCallback onToggleSidebar;
  final VoidCallback onFocus;
  final ValueChanged<String>? onSearchChange;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Hamburger / X toggle
            GestureDetector(
              onTap: onToggleSidebar,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isLeftOpen ? Icons.close_rounded : Icons.menu_rounded,
                      key: ValueKey(isLeftOpen),
                      size: 20,
                      color: const Color(0xff334155),
                    ),
                  ),
                ),
              ),
            ),

            // Search input
            Expanded(
              child: TextField(
                controller: controller,
                onTap: onFocus,
                onChanged: onSearchChange,
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 14, color: Color(0xff1e293b)),
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: const TextStyle(
                    color: Color(0xff94a3b8),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            // Search icon
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Icon(
                Icons.search_rounded,
                size: 18,
                color: Color(0xff94a3b8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
