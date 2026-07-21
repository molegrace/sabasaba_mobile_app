part of '../../../../main.dart';

class RouteInputPanel extends StatelessWidget {
  const RouteInputPanel({
    required this.locations,
    required this.startId,
    required this.endId,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onFindRoute,
    required this.onSwap,
    required this.onBack,
    this.notice,
  });

  final List<RoutingLocation> locations;
  final String startId;
  final String endId;
  final ValueChanged<String> onStartChanged;
  final ValueChanged<String> onEndChanged;
  final VoidCallback onFindRoute;
  final VoidCallback onSwap;
  final VoidCallback onBack;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      shadowColor: Colors.black26,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xff0b4238)),
                  onPressed: onBack,
                  tooltip: 'Exit route finder',
                ),
                const SizedBox(width: 4),
                const Text(
                  'Route Finder',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xff0b4238),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.swap_vert, color: Color(0xff0b4238)),
                  onPressed: onSwap,
                  tooltip: 'Swap locations',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xfff2f5f3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: startId.isEmpty ? null : startId,
                  hint: const Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xff4CAF50), size: 12),
                      SizedBox(width: 8),
                      Text(
                        'Select starting point',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  items: locations.map((loc) {
                    return DropdownMenuItem<String>(
                      value: loc.id,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            color: Color(0xff4CAF50),
                            size: 12,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loc.label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) onStartChanged(val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xfff2f5f3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: endId.isEmpty ? null : endId,
                  hint: const Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xffF44336), size: 12),
                      SizedBox(width: 8),
                      Text(
                        'Select destination',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  items: locations.map((loc) {
                    return DropdownMenuItem<String>(
                      value: loc.id,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            color: Color(0xffF44336),
                            size: 12,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loc.label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) onEndChanged(val);
                  },
                ),
              ),
            ),
            if (notice != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xfffff3cd),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  notice!,
                  style: const TextStyle(
                    color: Color(0xff664d03),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff0b4238),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onFindRoute,
              icon: const Icon(Icons.directions, size: 20),
              label: const Text(
                'Find Route',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MinimizedRouteHeader extends StatelessWidget {
  const MinimizedRouteHeader({
    required this.startLabel,
    required this.endLabel,
    required this.distance,
    required this.onEdit,
    required this.onClose,
  });

  final String startLabel;
  final String endLabel;
  final double distance;
  final VoidCallback onEdit;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      shadowColor: Colors.black26,
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions, color: Color(0xff0b4238), size: 20),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$startLabel ? $endLabel',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xff0b4238),
                  ),
                ),
                Text(
                  'Distance: ${distance.toStringAsFixed(0)} meters',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(999),
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xffe4f4ee),
                child: Icon(Icons.edit, color: Color(0xff0b4238), size: 14),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(999),
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xffffebee),
                child: Icon(Icons.close, color: Color(0xffc62828), size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
