part of '../../../main.dart';

class ServicesTab extends StatelessWidget {
  const ServicesTab({
    required this.areas,
    required this.selectedService,
    required this.onSelectService,
  });

  final List<MapFeature> areas;
  final VisitorService? selectedService;
  final ValueChanged<VisitorService> onSelectService;

  @override
  Widget build(BuildContext context) {
    final services = VisitorService.forAreas(areas);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        children: [
          Text(
            'Services',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xff0b4238),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Find essential visitor facilities and open their location on the map.',
            style: TextStyle(color: Color(0xff40534d)),
          ),
          const SizedBox(height: 16),
          for (final service in services) ...[
            VisitorServiceTile(
              service: service,
              selected: selectedService?.title == service.title,
              onTap: () => onSelectService(service),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class VisitorServiceTile extends StatelessWidget {
  const VisitorServiceTile({
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final VisitorService service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xffffeee7) : Colors.white,
      elevation: selected ? 4 : 1,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: CircleAvatar(
          backgroundColor: selected ? const Color(0xfff26430) : service.tint,
          child: Icon(
            service.icon,
            color: selected ? Colors.white : const Color(0xff0b4238),
          ),
        ),
        title: Text(
          service.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          service.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.near_me_outlined),
        onTap: onTap,
      ),
    );
  }
}
