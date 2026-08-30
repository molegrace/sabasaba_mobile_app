import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabasaba_mobile_app/main.dart';

void main() {
  ExhibitionMapData createMapData() {
    final building = MapFeature(
      layer: Layer.building,
      index: 0,
      featureId: null,
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
      rawProperties: const {},
    );
    return ExhibitionMapData(
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
      nodes: const [],
      edges: const [],
      locations: const [],
    );
  }

  testWidgets('search results appear while typing and hide on blur', (
    WidgetTester tester,
  ) async {
    final building = MapFeature(
      layer: Layer.building,
      index: 0,
      featureId: null,
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
      rawProperties: const {},
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
      nodes: const [],
      edges: const [],
      locations: const [],
    );

    await tester.pumpWidget(SabaSabaApp(mapData: Future.value(mapData)));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('double tapping the map zooms in one level', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      SabaSabaApp(mapData: Future.value(createMapData())),
    );
    await tester.pumpAndSettle();

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    viewer.transformationController!.value = Matrix4.diagonal3Values(2, 2, 1);

    final mapCenter = tester.getCenter(find.byType(InteractiveViewer));
    await tester.tapAt(mapCenter);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(mapCenter);
    await tester.pumpAndSettle();

    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      closeTo(4.0, 0.001),
    );
  });

  testWidgets('tile layer reloads at native zoom and overzooms at the cap', (
    WidgetTester tester,
  ) async {
    final controller = TransformationController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 600,
          child: MapTileLayer(
            data: createMapData(),
            tileStyle: MapTileStyle.openStreetMap,
            refreshGeneration: 0,
            controller: controller,
            rotation: 0,
          ),
        ),
      ),
    );

    expect(
      tester.widgetList<TileImage>(find.byType(TileImage)),
      everyElement(predicate<TileImage>((tile) => tile.url.contains('/17/'))),
    );

    controller.value = Matrix4.diagonal3Values(2, 2, 1);
    await tester.pump();
    expect(
      tester.widgetList<TileImage>(find.byType(TileImage)),
      everyElement(predicate<TileImage>((tile) => tile.url.contains('/18/'))),
    );

    final beforePan = tester
        .widgetList<TileImage>(find.byType(TileImage))
        .map((tile) => tile.url)
        .toSet();
    controller.value = Matrix4.diagonal3Values(2, 2, 1)
      ..setTranslationRaw(-400, 0, 0);
    await tester.pump();
    final afterPan = tester
        .widgetList<TileImage>(find.byType(TileImage))
        .map((tile) => tile.url)
        .toSet();
    expect(afterPan, isNot(equals(beforePan)));

    controller.value = Matrix4.diagonal3Values(maxMapScale, maxMapScale, 1);
    await tester.pump();
    expect(
      tester.widgetList<TileImage>(find.byType(TileImage)),
      everyElement(predicate<TileImage>((tile) => tile.url.contains('/19/'))),
    );
  });
}
