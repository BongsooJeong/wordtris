import 'package:flutter/material.dart';

/// 폭탄 위젯 생성 클래스
class BombWidget extends StatelessWidget {
  final double opacity;

  const BombWidget({
    super.key,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 폭탄 이모지
        const Text(
          '💣',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        // 반짝임 효과
        Positioned.fill(
          child: Opacity(
            opacity: opacity * 0.3,
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.white, Colors.transparent],
                  stops: [0.1, 1.0],
                  center: Alignment.center,
                  radius: 0.8,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
