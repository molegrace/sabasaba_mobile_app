part of '../../../../main.dart';

/// Search suggestion item model matching Next.js SearchSuggestion.
class SearchSuggestionItem {
  final String id;
  final String title;
  final String? subtitle;
  final String type; // 'exhibitor' | 'product' | 'service' | 'booth' | 'hall'
  final String? badge;
  final VoidCallback onSelect;

  SearchSuggestionItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.type = 'booth',
    this.badge,
    required this.onSelect,
  });
}

/// Navigator search box with hamburger menu & floating suggestions popover —
/// matches the web's SearchBox component from sabasaba_nextjs.
class NavigatorSearchBox extends StatefulWidget {
  const NavigatorSearchBox({
    required this.controller,
    required this.isLeftOpen,
    required this.onToggleSidebar,
    required this.onFocus,
    this.onSearchChange,
    this.onClear,
    this.placeholder = 'Search booths, exhibitors, products, or services...',
    this.suggestions = const [],
    this.onSelectPopularTag,
  });

  final TextEditingController controller;
  final bool isLeftOpen;
  final VoidCallback onToggleSidebar;
  final VoidCallback onFocus;
  final ValueChanged<String>? onSearchChange;
  final VoidCallback? onClear;
  final String placeholder;
  final List<SearchSuggestionItem> suggestions;
  final ValueChanged<String>? onSelectPopularTag;

  @override
  State<NavigatorSearchBox> createState() => _NavigatorSearchBoxState();
}

class _NavigatorSearchBoxState extends State<NavigatorSearchBox> {
  bool _isOpen = false;
  final FocusNode _focusNode = FocusNode();
  final List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        if (!_isOpen) setState(() => _isOpen = true);
        widget.onFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _addRecentSearch(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    _recentSearches.removeWhere(
      (item) => item.toLowerCase() == clean.toLowerCase(),
    );
    _recentSearches.insert(0, clean);
    if (_recentSearches.length > 5) {
      _recentSearches.removeLast();
    }
  }

  void _clearRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
  }

  void _closeDropdown() {
    if (_isOpen) {
      setState(() => _isOpen = false);
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.controller.text.trim();
    final hasQuery = query.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Input Bar
        Material(
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _isOpen ? const Color(0xff0284c7) : Colors.grey.shade200,
                width: _isOpen ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // Hamburger / Close toggle
                InkWell(
                  onTap: widget.onToggleSidebar,
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    width: 44,
                    height: 48,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          widget.isLeftOpen
                              ? Icons.close_rounded
                              : Icons.menu_rounded,
                          key: ValueKey(widget.isLeftOpen),
                          size: 20,
                          color: const Color(0xff334155),
                        ),
                      ),
                    ),
                  ),
                ),

                // Text field
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    onTap: () {
                      if (!_isOpen) setState(() => _isOpen = true);
                      widget.onFocus();
                    },
                    onChanged: (val) {
                      widget.onSearchChange?.call(val);
                      if (!_isOpen) setState(() => _isOpen = true);
                    },
                    onSubmitted: (val) {
                      _addRecentSearch(val);
                      _closeDropdown();
                    },
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xff1e293b),
                    ),
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      hintStyle: const TextStyle(
                        color: Color(0xff94a3b8),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),

                // Clear or search icon
                if (hasQuery)
                  IconButton(
                    icon: const Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: Color(0xff94a3b8),
                    ),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onClear?.call();
                      widget.onSearchChange?.call('');
                    },
                  )
                else
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
        ),

        // Dropdown popover:
        // Shows matching suggestions if typed, OR recent searches if query is empty and history exists.
        // If empty query & no history -> NO DROPDOWN pops up!
        if (_isOpen && (hasQuery || _recentSearches.isNotEmpty)) ...[
          const SizedBox(height: 6),
          Material(
            elevation: 12,
            shadowColor: Colors.black.withValues(alpha: 0.18),
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 320),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: hasQuery
                    ? _buildSuggestionsList(query)
                    : _buildRecentSearchesList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuggestionsList(String query) {
    if (widget.suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xfff1f5f9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 22,
                color: Color(0xff94a3b8),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'No matching item found',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xff334155),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try another product, service, exhibitor, booth, or hall name.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xff64748b)),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: const Color(0xfff8fafc),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MATCHING SUGGESTIONS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Color(0xff94a3b8),
                ),
              ),
              Text(
                '${widget.suggestions.length} found',
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Color(0xff94a3b8),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xffe2e8f0)),

        // Suggestions list
        Flexible(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: widget.suggestions.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xfff1f5f9)),
            itemBuilder: (context, index) {
              final item = widget.suggestions[index];
              return InkWell(
                onTap: () {
                  _addRecentSearch(item.title);
                  item.onSelect();
                  _closeDropdown();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Type Icon
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _typeBgColor(item.type),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _typeIcon(item.type),
                          size: 16,
                          color: _typeIconColor(item.type),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Text info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff1e293b),
                              ),
                            ),
                            if (item.subtitle != null &&
                                item.subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xff64748b),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Badge tag
                      if (item.badge != null && item.badge!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xfff1f5f9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.badge!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff475569),
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
      ],
    );
  }

  Widget _buildRecentSearchesList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: const Color(0xfff8fafc),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RECENT SEARCHES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Color(0xff94a3b8),
                ),
              ),
              GestureDetector(
                onTap: _clearRecentSearches,
                child: const Text(
                  'Clear All',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff0284c7),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xffe2e8f0)),

        // Recent items list
        Flexible(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: _recentSearches.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xfff1f5f9)),
            itemBuilder: (context, index) {
              final term = _recentSearches[index];
              return InkWell(
                onTap: () {
                  widget.controller.text = term;
                  widget.onSearchChange?.call(term);
                  widget.onSelectPopularTag?.call(term);
                  _closeDropdown();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: Color(0xff94a3b8),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          term,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff334155),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.north_west_rounded,
                        size: 14,
                        color: Color(0xffcbd5e1),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'exhibitor':
        return Icons.business_rounded;
      case 'product':
        return Icons.inventory_2_rounded;
      case 'service':
        return Icons.build_rounded;
      case 'hall':
        return Icons.meeting_room_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  Color _typeBgColor(String type) {
    switch (type) {
      case 'exhibitor':
        return const Color(0xffe0f2fe);
      case 'product':
        return const Color(0xfff3e8ff);
      case 'service':
        return const Color(0xffe0e7ff);
      case 'hall':
        return const Color(0xfffef3c7);
      default:
        return const Color(0xffdcfce7);
    }
  }

  Color _typeIconColor(String type) {
    switch (type) {
      case 'exhibitor':
        return const Color(0xff0284c7);
      case 'product':
        return const Color(0xff9333ea);
      case 'service':
        return const Color(0xff4f46e5);
      case 'hall':
        return const Color(0xffd97706);
      default:
        return const Color(0xff16a34a);
    }
  }
}
