part of '../../../../main.dart';

class SelectedAreaModal extends StatelessWidget {
  const SelectedAreaModal({required this.area, required this.onClose});

  final MapFeature area;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      shadowColor: Colors.black26,
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place, color: Color(0xfff26430)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    area.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              area.serviceLine,
              style: const TextStyle(color: Color(0xff40534d)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: area.services
                  .map(
                    (service) => Chip(
                      side: BorderSide.none,
                      backgroundColor: const Color(0xffe4f4ee),
                      label: Text(service),
                      avatar: const Icon(Icons.storefront, size: 18),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectedServiceNavigationCard extends StatelessWidget {
  const SelectedServiceNavigationCard({
    required this.service,
    required this.onClose,
  });

  final VisitorService service;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      shadowColor: Colors.black26,
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xffffeee7),
                  child: Icon(service.icon, color: const Color(0xfff26430)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    service.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              service.description,
              style: const TextStyle(color: Color(0xff40534d)),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Follow the highlighted marker to ${service.title}.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.near_me),
              label: const Text('Navigate'),
            ),
          ],
        ),
      ),
    );
  }
}
