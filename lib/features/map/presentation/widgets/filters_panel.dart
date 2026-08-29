part of '../../../../main.dart';

/// Matches the web navigator's FiltersPanel component.
class FiltersPanel extends StatelessWidget {
  const FiltersPanel({
    super.key,
    required this.categories,
    required this.activeCategory,
    required this.onSelectCategory,
  });

  final List<_CategoryItem> categories;
  final String activeCategory;
  final ValueChanged<String> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    final mainCategories = categories
        .where((cat) => cat.id == 'all' || cat.id == 'exhibitors')
        .toList();

    final industryCategories = categories
        .where((cat) => cat.id.startsWith('ind:'))
        .toList();

    final layerCategories = categories
        .where((cat) => cat.id.startsWith('layer:'))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select any category below to filter exhibitors, booths, buildings, and ground facilities on the map.',
            style: TextStyle(fontSize: 12, color: Color(0xff64748b), height: 1.4),
          ),
          const SizedBox(height: 18),

          // 1. Main Filters
          if (mainCategories.isNotEmpty) ...[
            _buildSectionHeader('Main Filters', Icons.star_rounded, const Color(0xfff59e0b)),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: mainCategories.length,
              itemBuilder: (context, index) {
                final cat = mainCategories[index];
                final isActive = activeCategory == cat.id;
                return _buildFilterButton(
                  cat: cat,
                  isActive: isActive,
                  icon: cat.id == 'all' ? Icons.grid_view_rounded : Icons.people_rounded,
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // 2. Exhibitor Industries
          if (industryCategories.isNotEmpty) ...[
            _buildSectionHeader('Exhibitor Industries', Icons.work_rounded, const Color(0xff0284c7)),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: industryCategories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final cat = industryCategories[index];
                final isActive = activeCategory == cat.id;
                return _buildFilterButton(
                  cat: cat,
                  isActive: isActive,
                  icon: Icons.sell_rounded,
                  iconColor: const Color(0xff0284c7),
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // 3. Facilities & Layers
          if (layerCategories.isNotEmpty) ...[
            _buildSectionHeader('Facilities & Layers', Icons.layers_rounded, const Color(0xff10b981)),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: layerCategories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final cat = layerCategories[index];
                final isActive = activeCategory == cat.id;
                return _buildFilterButton(
                  cat: cat,
                  isActive: isActive,
                  icon: Icons.apartment_rounded,
                  iconColor: const Color(0xff10b981),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xff94a3b8),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton({
    required _CategoryItem cat,
    required bool isActive,
    required IconData icon,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelectCategory(cat.id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xff0284c7) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? const Color(0xff0284c7) : const Color(0xffe2e8f0),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : (iconColor ?? const Color(0xff0284c7)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? Colors.white : const Color(0xff1e293b),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xff0369a1)
                      : const Color(0xfff1f5f9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${cat.count}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : const Color(0xff475569),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
