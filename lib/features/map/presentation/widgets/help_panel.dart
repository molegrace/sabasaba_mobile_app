part of '../../../../main.dart';

/// Help panel — matches the web navigator's "help" panel content.
class HelpPanel extends StatelessWidget {
  const HelpPanel();

  static const _steps = [
    'Use the top search bar to look up specific exhibitors or booth numbers.',
    'Open the Route Finder to choose your current position and target booth.',
    'Tap Find Route to display the shortest walking path and estimated time.',
    'Use the right toolbar to toggle satellite imagery or recenter the map.',
    'Tap any area on the map to view its details and set it as a destination.',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'How to use Sabasaba Navigator',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xff1e293b),
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _steps.length; i++) ...[
          _HelpStep(number: i + 1, text: _steps[i]),
          if (i < _steps.length - 1) const SizedBox(height: 10),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xfff0fdf4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffa7f3d0)),
          ),
          child: Row(
            children: const [
              Icon(Icons.tips_and_updates_rounded,
                  color: Color(0xff059669), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pinch to zoom, drag to pan, and rotate with two fingers for better orientation.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xff065f46),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HelpStep extends StatelessWidget {
  const _HelpStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xff0284c7),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xff475569),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
