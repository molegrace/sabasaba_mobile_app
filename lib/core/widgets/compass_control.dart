part of '../../main.dart';

class CompassControl extends StatelessWidget {
  const CompassControl({required this.rotation});

  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      color: Colors.white,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Center(
          child: Transform.rotate(
            angle: rotation,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'N',
                  style: TextStyle(
                    color: Color(0xff0b4238),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Icon(Icons.navigation, color: Color(0xdd0b4238), size: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
