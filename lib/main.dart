import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

part 'features/map/presentation/screens/exhibition_map_screen.dart';
part 'features/map/presentation/widgets/map_canvas.dart';
part 'features/map/presentation/widgets/map_tile_layer.dart';
part 'features/map/presentation/widgets/route_panel.dart';
part 'features/map/presentation/widgets/search_panel.dart';
part 'features/map/presentation/widgets/area_modal.dart';
part 'features/map/presentation/widgets/left_sidebar.dart';
part 'features/map/presentation/widgets/navigator_main_panel.dart';
part 'features/map/presentation/widgets/spaces_panel.dart';
part 'features/map/presentation/widgets/saved_panel.dart';
part 'features/map/presentation/widgets/filters_panel.dart';

part 'features/map/presentation/widgets/feature_details_panel.dart';
part 'features/map/presentation/widgets/help_panel.dart';
part 'features/map/presentation/widgets/legend_overlay.dart';
part 'features/map/presentation/widgets/info_bar.dart';
part 'features/map/presentation/widgets/right_toolbar.dart';

part 'features/services/presentation/services_tab.dart';
part 'features/info/presentation/info_tab.dart';
part 'features/info/models/visitor_announcement.dart';
part 'features/exhibitor/presentation/exhibitor_tab.dart';
part 'features/profile/presentation/you_tab.dart';
part 'core/widgets/map_controls.dart';
part 'core/widgets/compass_control.dart';
part 'core/widgets/common_status_widgets.dart';
part 'core/widgets/connection_banner.dart';
part 'features/map/data/routing_engine.dart';
part 'features/map/data/navigation_progress.dart';
part 'features/map/data/polyline_matcher.dart';
part 'features/map/data/off_route_detector.dart';
part 'features/map/data/route_progress.dart';
part 'features/map/data/navigation_session.dart';
part 'features/map/data/exhibition_map_data.dart';
part 'features/profile/models/user_account.dart';
part 'features/exhibitor/models/visitor_inquiry.dart';
part 'core/models/map_feature.dart';
part 'features/services/models/visitor_service.dart';
part 'core/models/geo_point.dart';
part 'core/constants/map_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const SabaSabaApp());
}

class SabaSabaApp extends StatelessWidget {
  const SabaSabaApp({super.key, this.mapData});

  final Future<ExhibitionMapData>? mapData;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xff0284c7);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SabaSaba Exhibition Map',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          primary: const Color(0xff0284c7),
        ),
        scaffoldBackgroundColor: const Color(0xfff3f6f1),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w800),
          titleMedium: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      home: ExhibitionMapScreen(mapData: mapData),
    );
  }
}
