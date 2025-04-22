import 'package:flutter/material.dart';

/// 게임 앱바에 표시되는 애니메이션 타이틀 위젯
class AnimatedTitle extends StatelessWidget {
  const AnimatedTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [
            Colors.purple,
            Colors.blue,
            Colors.lightBlueAccent,
            Colors.blue,
            Colors.purple,
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '워드',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
              shadows: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4.0,
                  offset: Offset(1.0, 1.0),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              // 그림자 효과
              Text(
                '트리스',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 4
                    ..color = Colors.indigo.shade900.withOpacity(0.3),
                  letterSpacing: 1.2,
                ),
              ),
              const Text(
                '트리스',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
