part of '../../main.dart';

class MapControls extends StatelessWidget {
  const MapControls({
    required this.tileStyle,
    required this.onTileStyleChanged,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final MapTileStyle tileStyle;
  final ValueChanged<MapTileStyle> onTileStyleChanged;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Zoom in',
            onPressed: onZoomIn,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Zoom out',
            onPressed: onZoomOut,
            icon: const Icon(Icons.remove),
          ),
          IconButton(
            tooltip: 'Reset map',
            onPressed: onReset,
            icon: const Icon(Icons.my_location),
          ),
          PopupMenuButton<MapTileStyle>(
            tooltip: 'Map tiles',
            initialValue: tileStyle,
            onSelected: onTileStyleChanged,
            icon: const Icon(Icons.layers_outlined),
            itemBuilder: (context) {
              return [
                for (final style in MapTileStyle.values)
                  PopupMenuItem(
                    value: style,
                    child: Row(
                      children: [
                        Icon(style.icon, color: style.accentColor),
                        const SizedBox(width: 12),
                        Text(style.label),
                      ],
                    ),
                  ),
              ];
            },
          ),
        ],
      ),
    );
  }
}
