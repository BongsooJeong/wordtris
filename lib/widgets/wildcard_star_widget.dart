import 'package:flutter/material.dart';
import 'dart:math';

/// 반짝이는 와일드카드 별을 표시하는 위젯
class WildcardStarWidget extends StatefulWidget {
  final double size;
  final double opacity;

  const WildcardStarWidget({
    Key? key,
    this.size = 24.0,
    this.opacity = 1.0,
  }) : super(key: key);

  @override
  State<WildcardStarWidget> createState() => _WildcardStarWidgetState();
}

class _WildcardStarWidgetState extends State<WildcardStarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: false);

    // 색상 애니메이션
    _colorAnimation = ColorTween(
      begin: Colors.yellow,
      end: Colors.purpleAccent,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 무지개 색상 배열
        final List<Color> rainbowColors = [
          Colors.red,
          Colors.orange,
          Colors.yellow,
          Colors.green,
          Colors.blue,
          Colors.indigo,
          Colors.purple,
        ];

        // 현재 색상 계산 (무지개 효과)
        final int colorIndex =
            (_controller.value * rainbowColors.length).floor() %
                rainbowColors.length;
        final int nextColorIndex = (colorIndex + 1) % rainbowColors.length;
        final double colorPosition =
            (_controller.value * rainbowColors.length) % 1.0;

        // 두 색상 사이를 자연스럽게 전환
        final Color currentColor = Color.lerp(rainbowColors[colorIndex],
                rainbowColors[nextColorIndex], colorPosition) ??
            rainbowColors[colorIndex];

        // 밝기 변화 효과 (반짝임 효과)
        final double brightness = 0.8 + 0.2 * sin(_controller.value * 2 * pi);
        final Color color = HSLColor.fromColor(currentColor)
            .withLightness(brightness)
            .withSaturation(0.9)
            .toColor();

        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [color, Colors.white.withOpacity(0.8), color],
              stops: const [0.2, 0.5, 0.8],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: Text(
            '★',
            style: TextStyle(
              fontSize: widget.size,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(widget.opacity),
              shadows: [
                BoxShadow(
                  color: color.withOpacity(0.8),
                  blurRadius: 12,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
