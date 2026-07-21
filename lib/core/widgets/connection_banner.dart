part of '../../main.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({required this.isOffline});

  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final background = isOffline
        ? const Color(0xffffe0b2)
        : const Color(0xffd7f3e8);
    final foreground = isOffline
        ? const Color(0xff8a4200)
        : const Color(0xff075e4a);

    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        color: background,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOffline ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
              size: 17,
              color: foreground,
            ),
            const SizedBox(width: 7),
            Text(
              isOffline ? 'Offline — no internet connection' : 'Online',
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
