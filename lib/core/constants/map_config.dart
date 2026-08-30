part of '../../main.dart';

// Keep the InteractiveViewer scale in sync with the Leaflet zoom range used by
// the web navigator. A scale of 1 is zoom 17, and every doubling is one zoom
// level.
const int minMapZoom = 0;
const int initialMapZoom = 17;
const int maxMapZoom = 25;
const double minMapScale = 0.00000762939453125; // 2 ^ (0 - 17)
const double maxMapScale = 256.0; // 2 ^ (25 - 17)
