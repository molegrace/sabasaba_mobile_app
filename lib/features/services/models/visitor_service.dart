part of '../../../main.dart';

class FacilityPoint {
  const FacilityPoint({
    required this.label,
    required this.position,
    required this.icon,
  });

  final String label;
  final GeoPoint position;
  final IconData icon;
}

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

  static List<FacilityPoint> resolveFacilityPoints(
    VisitorService service,
    List<MapFeature> areas,
  ) {
    if (areas.isEmpty) return const [];

    final titleLower = service.title.toLowerCase();
    final points = <FacilityPoint>[];

    if (titleLower.contains('toilet') || titleLower.contains('washroom')) {
      points.addAll([
        FacilityPoint(
          label: 'Main Gate Restrooms',
          position: _areaAt(areas, 0.08).center,
          icon: Icons.wc,
        ),
        FacilityPoint(
          label: 'Hall 1 & 2 Washrooms',
          position: _areaAt(areas, 0.22).center,
          icon: Icons.wc,
        ),
        FacilityPoint(
          label: 'Food Court Washrooms',
          position: _areaAt(areas, 0.42).center,
          icon: Icons.wc,
        ),
        FacilityPoint(
          label: 'Hall 4 Public Restrooms',
          position: _areaAt(areas, 0.68).center,
          icon: Icons.wc,
        ),
        FacilityPoint(
          label: 'North Pavilion Washrooms',
          position: _areaAt(areas, 0.88).center,
          icon: Icons.wc,
        ),
      ]);
    } else if (titleLower.contains('parking')) {
      points.addAll([
        FacilityPoint(
          label: 'Gate 1 Visitor Parking',
          position: _areaAt(areas, 0.05).center,
          icon: Icons.local_parking,
        ),
        FacilityPoint(
          label: 'VIP & Staff Parking',
          position: _areaAt(areas, 0.35).center,
          icon: Icons.local_parking,
        ),
        FacilityPoint(
          label: 'Gate 3 Public Parking',
          position: _areaAt(areas, 0.82).center,
          icon: Icons.local_parking,
        ),
      ]);
    } else if (titleLower.contains('restaurant') || titleLower.contains('food')) {
      points.addAll([
        FacilityPoint(
          label: 'Main Food Court & Cafes',
          position: _areaAt(areas, 0.38).center,
          icon: Icons.restaurant,
        ),
        FacilityPoint(
          label: 'Hall 2 Refreshment Station',
          position: _areaAt(areas, 0.25).center,
          icon: Icons.restaurant,
        ),
        FacilityPoint(
          label: 'Outdoor Dining Area',
          position: _areaAt(areas, 0.60).center,
          icon: Icons.restaurant,
        ),
        FacilityPoint(
          label: 'South Gate Snack Bar',
          position: _areaAt(areas, 0.90).center,
          icon: Icons.restaurant,
        ),
      ]);
    } else if (titleLower.contains('info') || titleLower.contains('desk')) {
      points.addAll([
        FacilityPoint(
          label: 'Main Entrance Info Desk',
          position: _areaAt(areas, 0.12).center,
          icon: Icons.info_outline,
        ),
        FacilityPoint(
          label: 'Central Pavilion Help Desk',
          position: _areaAt(areas, 0.50).center,
          icon: Icons.info_outline,
        ),
        FacilityPoint(
          label: 'Exhibitor Support Center',
          position: _areaAt(areas, 0.75).center,
          icon: Icons.info_outline,
        ),
      ]);
    } else if (titleLower.contains('first aid') || titleLower.contains('medical')) {
      points.addAll([
        FacilityPoint(
          label: 'Main Medical Emergency Post',
          position: _areaAt(areas, 0.62).center,
          icon: Icons.medical_services_outlined,
        ),
        FacilityPoint(
          label: 'Red Cross First Aid Hub',
          position: _areaAt(areas, 0.20).center,
          icon: Icons.medical_services_outlined,
        ),
      ]);
    } else if (titleLower.contains('atm') || titleLower.contains('payment')) {
      points.addAll([
        FacilityPoint(
          label: 'CRDB & NMB Banking Hub',
          position: _areaAt(areas, 0.74).center,
          icon: Icons.account_balance,
        ),
        FacilityPoint(
          label: 'Main Gate ATM & Mobile Pay',
          position: _areaAt(areas, 0.10).center,
          icon: Icons.account_balance,
        ),
        FacilityPoint(
          label: 'Hall 3 Cash Station',
          position: _areaAt(areas, 0.45).center,
          icon: Icons.account_balance,
        ),
      ]);
    } else if (titleLower.contains('gate') || titleLower.contains('entrance')) {
      points.addAll([
        FacilityPoint(
          label: 'Gate 1 (Main Entrance)',
          position: _areaAt(areas, 0.02).center,
          icon: Icons.login,
        ),
        FacilityPoint(
          label: 'Gate 2 (VIP Entry)',
          position: _areaAt(areas, 0.48).center,
          icon: Icons.login,
        ),
        FacilityPoint(
          label: 'Gate 3 (North Exit)',
          position: _areaAt(areas, 0.94).center,
          icon: Icons.login,
        ),
      ]);
    } else if (titleLower.contains('security')) {
      points.addAll([
        FacilityPoint(
          label: 'Central Police & Security Command',
          position: _areaAt(areas, 0.96).center,
          icon: Icons.security,
        ),
        FacilityPoint(
          label: 'Main Gate Security Station',
          position: _areaAt(areas, 0.06).center,
          icon: Icons.security,
        ),
        FacilityPoint(
          label: 'Lost & Found Booth',
          position: _areaAt(areas, 0.52).center,
          icon: Icons.security,
        ),
      ]);
    } else {
      points.add(
        FacilityPoint(
          label: service.title,
          position: service.area.center,
          icon: service.icon,
        ),
      );
    }

    return points;
  }

  static MapFeature _areaAt(List<MapFeature> areas, double fraction) {
    final index = (areas.length * fraction)
        .floor()
        .clamp(0, areas.length - 1)
        .toInt();
    return areas[index];
  }
}
