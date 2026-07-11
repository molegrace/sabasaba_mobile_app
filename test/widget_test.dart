import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabasaba_mobile_app/main.dart';

void main() {
  testWidgets('search results appear while typing and hide on blur', (
    WidgetTester tester,
  ) async {
    final building = MapFeature(
      layer: Layer.building,
      index: 0,
      id: 1,
      code: 'j1',
      polygons: const [
        [
          GeoPoint(39.27, -6.86),
          GeoPoint(39.28, -6.86),
          GeoPoint(39.28, -6.87),
          GeoPoint(39.27, -6.87),
        ],
      ],
      lines: const [],
      points: const [],
    );
    final mapData = ExhibitionMapData(
      buildings: [building],
      roads: const [],
      trees: const [],
      boundaries: const [],
      bounds: const GeoBounds(
        minLng: 39.27,
        maxLng: 39.28,
        minLat: -6.87,
        maxLat: -6.86,
      ),
    );

    await tester.pumpWidget(SabaSabaApp(mapData: Future.value(mapData)));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Area J1'), findsNothing);

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'j1');
    await tester.pumpAndSettle();

    expect(find.text('Area J1'), findsWidgets);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(find.text('Area J1'), findsNothing);
  });
}
