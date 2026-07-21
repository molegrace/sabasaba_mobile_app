part of '../../../main.dart';

class VisitorService {
  const VisitorService({
    required this.title,
    required this.description,
    required this.icon,
    required this.tint,
    required this.area,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color tint;
  final MapFeature area;

  static List<VisitorService> forAreas(List<MapFeature> areas) {
    if (areas.isEmpty) {
      return const [];
    }

    return [
      VisitorService(
        title: 'Parking',
        description: 'Vehicle parking and drop-off access',
        icon: Icons.local_parking,
        tint: const Color(0xffe4f4ee),
        area: _areaAt(areas, 0.05),
      ),
      VisitorService(
        title: 'Toilets',
        description: 'Public washrooms for visitors',
        icon: Icons.wc,
        tint: const Color(0xffe7f0ff),
        area: _areaAt(areas, 0.22),
      ),
      VisitorService(
        title: 'Restaurants',
        description: 'Food, drinks, and seating',
        icon: Icons.restaurant,
        tint: const Color(0xffffefe1),
        area: _areaAt(areas, 0.38),
      ),
      VisitorService(
        title: 'Information desk',
        description: 'Help, directions, and exhibition guidance',
        icon: Icons.info_outline,
        tint: const Color(0xffe9f5f1),
        area: _areaAt(areas, 0.5),
      ),
      VisitorService(
        title: 'First aid',
        description: 'Medical assistance and emergency support',
        icon: Icons.medical_services_outlined,
        tint: const Color(0xffffe8e8),
        area: _areaAt(areas, 0.62),
      ),
      VisitorService(
        title: 'ATM and payments',
        description: 'Cash and payment support',
        icon: Icons.account_balance,
        tint: const Color(0xffeef0ff),
        area: _areaAt(areas, 0.74),
      ),
      VisitorService(
        title: 'Entrance gates',
        description: 'Main visitor entry and exit points',
        icon: Icons.login,
        tint: const Color(0xffedf7df),
        area: _areaAt(areas, 0.86),
      ),
      VisitorService(
        title: 'Security',
        description: 'Lost and found, safety, and visitor support',
        icon: Icons.security,
        tint: const Color(0xfff2edf8),
        area: _areaAt(areas, 0.96),
      ),
    ];
  }

  static MapFeature _areaAt(List<MapFeature> areas, double fraction) {
    final index = (areas.length * fraction)
        .floor()
        .clamp(0, areas.length - 1)
        .toInt();
    return areas[index];
  }
}
