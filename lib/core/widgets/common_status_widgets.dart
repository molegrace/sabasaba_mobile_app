part of '../../main.dart';

class LoadingMap extends StatelessWidget {
  const LoadingMap();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(dimension: 46, child: CircularProgressIndicator()),
    );
  }
}

class MapError extends StatelessWidget {
  const MapError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Could not load SabaSaba map.\n$message',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class EmptyResults extends StatelessWidget {
  const EmptyResults();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'No matching services found.',
          style: TextStyle(color: Color(0xff5f6f69)),
        ),
      ),
    );
  }
}
