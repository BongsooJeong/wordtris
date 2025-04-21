import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 폭탄 위젯 생성 클래스
class BombWidget extends StatefulWidget {
  final double opacity;

  const BombWidget({
    super.key,
    this.opacity = 1.0,
  });

  @override
  State<BombWidget> createState() => _BombWidgetState();
}

class _BombWidgetState extends State<BombWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_controller);

    _rotationAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
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
        // 퓨즈 깜빡임 효과
        final fuseFlicker = _controller.value > 0.7
            ? math.sin(_controller.value * 40) > 0
                ? 1.0
                : 0.5
            : 1.0;

        // 색상 변화
        final glowColor = _controller.value < 0.3
            ? Colors.orange.withOpacity(0.7)
            : Colors.red.withOpacity(
                0.7 + 0.3 * math.sin(_controller.value * math.pi * 2));

        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Stack(
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

                // 폭탄 퓨즈 불꽃 효과
                Positioned(
                  top: -7,
                  right: -3,
                  child: Opacity(
                    opacity: fuseFlicker * widget.opacity,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange,
                            blurRadius: 4,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 반짝임 효과
                Positioned.fill(
                  child: Opacity(
                    opacity: widget.opacity * 0.5,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [glowColor, Colors.transparent],
                          stops: const [0.1, 1.0],
                          center: Alignment.center,
                          radius: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
