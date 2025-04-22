import 'package:flutter/material.dart';

/// 게임 앱바에 표시되는 애니메이션 타이틀 위젯
class AnimatedTitle extends StatelessWidget {
  final bool isCompactMode; // 모바일 화면용 컴팩트 모드

  const AnimatedTitle({
    Key? key,
    this.isCompactMode = false, // 기본값은 일반 모드
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 화면 크기에 따른 폰트 크기 조정
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = _calculateFontSize(screenWidth);
    final letterSpacing = screenWidth < 360
        ? (isCompactMode ? 0.5 : 0.8)
        : (isCompactMode ? 0.8 : 1.2);

    final shadowBlur = isCompactMode ? (screenWidth < 320 ? 2.0 : 3.0) : 4.0;

    final strokeWidth = isCompactMode
        ? (screenWidth < 320 ? 2.0 : 2.5)
        : (screenWidth < 360 ? 3 : 4);

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
          Text(
            '워드',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: letterSpacing,
              shadows: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: shadowBlur,
                  offset: const Offset(1.0, 1.0),
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
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = strokeWidth.toDouble()
                    ..color = Colors.indigo.shade900.withOpacity(0.3),
                  letterSpacing: letterSpacing,
                ),
              ),
              Text(
                '트리스',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: letterSpacing,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 화면 너비에 따른 폰트 크기 계산
  double _calculateFontSize(double screenWidth) {
    if (isCompactMode) {
      if (screenWidth < 320) {
        return 16.0; // 매우 작은 화면에서 컴팩트 모드
      } else if (screenWidth < 360) {
        return 18.0; // 작은 모바일 화면에서 컴팩트 모드
      } else {
        return 20.0; // 일반 모바일 화면에서 컴팩트 모드
      }
    } else {
      if (screenWidth < 320) {
        return 18.0; // 매우 작은 화면
      } else if (screenWidth < 360) {
        return 20.0; // 작은 모바일 화면
      } else if (screenWidth < 480) {
        return 22.0; // 일반 모바일 화면
      } else {
        return 24.0; // 태블릿 이상 크기
      }
    }
  }
}
