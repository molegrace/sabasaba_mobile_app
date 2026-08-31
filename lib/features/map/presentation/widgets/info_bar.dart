part of '../../../../main.dart';

/// Bottom floating route info bar — matches the web navigator's InfoPanel.
/// Shows route summary with From/To labels, distance, walking time,
/// and Edit/Clear buttons.
class RouteInfoBar extends StatelessWidget {
  const RouteInfoBar({
    required this.distanceMeters,
    required this.walkingTime,
    this.timeMetricLabel = 'Walking Time',
    this.startLabel,
    this.endLabel,
    required this.onEdit,
    required this.onClear,
    this.clearLabel = 'Clear',
  });

  final double distanceMeters;
  final String walkingTime;
  final String timeMetricLabel;
  final String? startLabel;
  final String? endLabel;
  final VoidCallback onEdit;
  final VoidCallback onClear;
  final String clearLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffe2e8f0).withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Row(
            children: [
              const Icon(
                Icons.signpost_rounded,
                color: Color(0xff0284c7),
                size: 16,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Route Summary',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1e293b),
                  ),
                ),
              ),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff0284c7),
                  ),
                ),
              ),
              TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  clearLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff94a3b8),
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 12, color: Colors.grey.shade100),

          // From / To labels
          if (startLabel != null || endLabel != null) ...[
            if (startLabel != null)
              _RouteEndpoint(
                color: const Color(0xff10b981),
                prefix: 'From',
                label: startLabel!,
              ),
            if (endLabel != null) ...[
              const SizedBox(height: 4),
              _RouteEndpoint(
                color: const Color(0xfff43f5e),
                prefix: 'To',
                label: endLabel!,
              ),
            ],
            const SizedBox(height: 10),
          ],

          // Distance + walking time grid
          Row(
            children: [
              Expanded(
                child: _InfoMetric(
                  label: 'Distance',
                  value: distanceMeters >= 1000
                      ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
                      : '${distanceMeters.round()} m',
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Expanded(
                child: _InfoMetric(label: timeMetricLabel, value: walkingTime),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NavigationWarningBanner extends StatelessWidget {
  const NavigationWarningBanner({
    super.key,
    required this.status,
    required this.message,
  });

  final NavigationStatus status;
  final String message;

  @override
  Widget build(BuildContext context) {
    final arrived = status == NavigationStatus.arrived;
    final offRoute = status == NavigationStatus.offRoute;
    final color = arrived
        ? const Color(0xff047857)
        : offRoute
        ? const Color(0xffbe123c)
        : const Color(0xffb45309);
    final background = arrived
        ? const Color(0xffecfdf5)
        : offRoute
        ? const Color(0xfffff1f2)
        : const Color(0xfffffbeb);
    final icon = arrived
        ? Icons.check_circle_rounded
        : offRoute
        ? Icons.warning_rounded
        : Icons.wrong_location_rounded;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteEndpoint extends StatelessWidget {
  const _RouteEndpoint({
    required this.color,
    required this.prefix,
    required this.label,
  });

  final Color color;
  final String prefix;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$prefix: ',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff475569),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _InfoMetric extends StatelessWidget {
  const _InfoMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xff94a3b8),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xff1e293b),
            ),
          ),
        ],
      ),
    );
  }
}
