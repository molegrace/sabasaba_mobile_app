part of '../../../../main.dart';

/// Legend overlay — matches the web navigator's Legend component.
/// Shows color swatches for Start Point, Destination, Route, Selected Space.
class LegendOverlay extends StatelessWidget {
  const LegendOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe2e8f0).withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.layers_rounded, size: 14, color: Color(0xff0284c7)),
              SizedBox(width: 6),
              Text(
                'Map Legend',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1e293b),
                ),
              ),
            ],
          ),
          Divider(height: 14, color: Colors.grey.shade200),

          const _LegendRow(color: Color(0xff10b981), label: 'Start Point'),
          const SizedBox(height: 6),
          const _LegendRow(color: Color(0xfff43f5e), label: 'Destination'),
          const SizedBox(height: 6),
          const _LegendRow(color: Color(0xff0284c7), label: 'Calculated Route'),
          const SizedBox(height: 6),
          const _LegendRow(
            color: Color(0xff0d9488),
            label: 'Selected Space',
            isRounded: false,
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    this.isRounded = true,
  });

  final Color color;
  final String label;
  final bool isRounded;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: isRounded ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isRounded ? null : BorderRadius.circular(3),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xff475569),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
