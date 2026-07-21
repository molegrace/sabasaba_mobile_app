part of '../../../../main.dart';

class SearchPanel extends StatelessWidget {
  const SearchPanel({
    required this.query,
    required this.controller,
    required this.focusNode,
    required this.areas,
    required this.selectedArea,
    required this.showResults,
    required this.onQueryChanged,
    required this.onSelectArea,
    required this.onClear,
  });

  final String query;
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<MapFeature> areas;
  final MapFeature? selectedArea;
  final bool showResults;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<MapFeature> onSelectArea;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          elevation: 12,
          shadowColor: Colors.black26,
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search area, pavilion, service...',
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 15,
              ),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: onClear,
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (showResults) ...[
          const SizedBox(height: 8),
          Material(
            elevation: 12,
            shadowColor: Colors.black26,
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: areas.isEmpty
                    ? const EmptyResults()
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: areas.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final area = areas[index];
                          final selected = area.key == selectedArea?.key;
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            selected: selected,
                            leading: CircleAvatar(
                              radius: 17,
                              backgroundColor: selected
                                  ? const Color(0xfff26430)
                                  : const Color(0xffe4f4ee),
                              child: Text(
                                area.shortCode,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xff0b4238),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            title: Text(
                              area.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              area.serviceLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => onSelectArea(area),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
