/// GameGridAnimations API 문서
///
/// 게임 그리드의 애니메이션을 관리하는 클래스입니다.
///
/// ## 주요 API 목록
///
/// ### 생성자
/// - `GameGridAnimations(dynamic state)`: 애니메이션 관리자 인스턴스 생성
///   - `state`: State<GameGrid> 및 TickerProviderStateMixin을 구현한 클래스
///
/// ### 애니메이션 제어 메서드
/// - `dispose()`: 리소스 해제
/// - `stopAllAnimations()`: 모든 애니메이션 중지 및 상태 초기화
/// - `startExplosionAnimation(Point center)`: 폭발 애니메이션 시작
/// - `startCellFadeAnimation(List<RemovedCell> cells)`: 셀 사라짐 애니메이션 시작
///
/// ### 위젯 생성 메서드
/// - `buildExplosionEffect(double totalCellSize, double gridPadding, double cellSize)`: 폭발 효과 위젯 생성
///   - 레이아웃: Positioned 위젯으로 폭발 중심점 기준 배치
///   - 효과: 원형 그라데이션과 그림자를 사용한 폭발 효과
///
/// - `buildFadingCells(double totalCellSize, double actualCellSize, double cellMargin, double gridPadding)`: 사라지는 셀 위젯 목록 생성
///   - 레이아웃: Stack 내부의 Positioned 위젯들로 구성
///   - 효과:
///     1. 메인 셀: 축소, 회전, 페이드아웃 효과
///     2. 파티클: 8개의 작은 원형 파티클이 방사형으로 퍼짐
///     3. 반짝임: 셀 중앙에서 퍼져나가는 원형 테두리
///
/// ### 상태 확인 게터
/// - `explosionAnimation`: 현재 폭발 애니메이션 상태
/// - `explosionCenter`: 폭발 중심점 위치
/// - `fadeAnimation`: 페이드 애니메이션 상태
/// - `fadingCells`: 현재 사라지는 중인 셀 목록
/// - `isAnimatingRemoval`: 셀 제거 애니메이션 진행 여부

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/grid.dart';
import '../utils/point.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

/// 게임 그리드의 애니메이션을 관리하는 클래스
class GameGridAnimations {
  final TickerProvider _tickerProvider;
  final Function(VoidCallback)? _setState;
  bool _disposed = false;

  // 폭발 애니메이션 관련 변수
  AnimationController? _explosionController;
  Animation<double>? _explosionAnimation;
  Point? _explosionCenter;

  // 블록 사라짐 애니메이션 관련 변수
  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;
  List<RemovedCell> _fadingCells = [];
  bool _animatingRemoval = false;

  // 게터
  Animation<double>? get explosionAnimation => _explosionAnimation;
  Point? get explosionCenter => _explosionCenter;
  Animation<double>? get fadeAnimation => _fadeAnimation;
  List<RemovedCell> get fadingCells => _fadingCells;
  bool get isAnimatingRemoval => _animatingRemoval;

  /// 생성자
  /// state 매개변수는 State<GameGrid> 및 TickerProviderStateMixin을 구현한 클래스여야 함
  GameGridAnimations(dynamic state)
      : _tickerProvider = state,
        _setState = state.setState;

  // 안전하게 setState 호출하는 메서드
  void _safeSetState(VoidCallback fn) {
    if (_disposed) return;
    try {
      _setState?.call(fn);
    } catch (e) {
      // 위젯이 이미 해제되었거나 상태를 업데이트할 수 없는 경우 무시
      print('Animation setState 실패: $e');
    }
  }

  /// 리소스 해제
  void dispose() {
    _disposed = true;
    stopAllAnimations();
  }

  /// 모든 애니메이션 멈추기
  void stopAllAnimations() {
    // 폭발 애니메이션 멈추기
    if (_explosionController != null) {
      if (_explosionController!.isAnimating) {
        _explosionController!.stop();
      }
      _explosionController!.dispose();
      _explosionController = null;
    }

    // 페이드 애니메이션 멈추기
    if (_fadeController != null) {
      if (_fadeController!.isAnimating) {
        _fadeController!.stop();
      }
      _fadeController!.dispose();
      _fadeController = null;
    }

    // 직접 상태 업데이트 (setState는 호출하지 않음)
    _explosionCenter = null;
    _fadingCells = [];
    _animatingRemoval = false;
  }

  /// 폭발 애니메이션 시작
  void startExplosionAnimation(Point center) {
    if (_disposed) return;

    // 이전 애니메이션 컨트롤러 해제
    if (_explosionController != null) {
      if (_explosionController!.isAnimating) {
        _explosionController!.stop();
      }
      _explosionController!.dispose();
    }

    // 애니메이션 컨트롤러 초기화
    _explosionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: _tickerProvider,
    );

    // 애니메이션 설정
    _explosionAnimation = CurvedAnimation(
      parent: _explosionController!,
      curve: Curves.easeOut,
    );

    // 상태 변수 직접 업데이트
    _explosionCenter = center;

    // 상태 업데이트로 UI에 알림
    _safeSetState(() {});

    // 애니메이션 시작 및 완료 이벤트 핸들러
    _explosionController!.forward().then((_) {
      if (_disposed) return;

      // 애니메이션 종료 후 상태 초기화 (직접 업데이트)
      _explosionCenter = null;

      // 상태 업데이트로 UI에 알림
      _safeSetState(() {});
    });
  }

  /// 셀 사라짐 애니메이션 시작
  void startCellFadeAnimation(List<RemovedCell> cells) {
    if (_disposed || cells.isEmpty) return;

    // 이전 애니메이션 컨트롤러 해제
    if (_fadeController != null) {
      if (_fadeController!.isAnimating) {
        _fadeController!.stop();
      }
      _fadeController!.dispose();
    }

    // 애니메이션 컨트롤러 초기화
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: _tickerProvider,
    );

    // 애니메이션 설정
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController!,
      curve: Curves.easeInOut,
    );

    // 상태 변수 직접 업데이트
    _fadingCells = List.from(cells); // 복사본 생성
    _animatingRemoval = true;

    // 상태 업데이트로 UI에 알림
    _safeSetState(() {});

    // 애니메이션 시작 및 완료 이벤트 핸들러
    _fadeController!.forward().then((_) {
      if (_disposed) return;

      // 애니메이션 종료 후 상태 초기화 (직접 업데이트)
      _fadingCells = [];
      _animatingRemoval = false;

      // 상태 업데이트로 UI에 알림
      _safeSetState(() {});
    });
  }

  /// 폭발 효과 위젯 생성
  Widget buildExplosionEffect(
      double totalCellSize, double gridPadding, double cellSize) {
    if (_explosionCenter == null || _explosionAnimation == null) {
      return Container();
    }

    final centerX =
        gridPadding + _explosionCenter!.x * totalCellSize + cellSize / 2;
    final centerY =
        gridPadding + _explosionCenter!.y * totalCellSize + cellSize / 2;

    return Positioned(
      left: centerX - cellSize * 1.5,
      top: centerY - cellSize * 1.5,
      child: AnimatedBuilder(
        animation: _explosionAnimation!,
        builder: (context, child) {
          final size = cellSize * 3 * _explosionAnimation!.value;
          return Opacity(
            opacity: (1 - _explosionAnimation!.value) * 0.8,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.3),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.8),
                    blurRadius: size * 0.5,
                    spreadRadius: size * 0.2,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: size * 0.6,
                  height: size * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 사라지는 셀 위젯 목록 생성
  List<Widget> buildFadingCells(double totalCellSize, double actualCellSize,
      double cellMargin, double gridPadding) {
    if (_fadeAnimation == null || _fadingCells.isEmpty) return [];

    final List<Widget> widgets = [];

    // 각 사라지는 셀마다 애니메이션 추가
    for (final cell in _fadingCells) {
      // 메인 셀 애니메이션
      widgets.add(Positioned(
        left: gridPadding + cell.position.x * totalCellSize + cellMargin,
        top: gridPadding + cell.position.y * totalCellSize + cellMargin,
        child: AnimatedBuilder(
          animation: _fadeAnimation!,
          builder: (context, child) {
            // 축소되면서 회전하고 페이드아웃되는 효과
            double scale = 1.0 - _fadeAnimation!.value * 0.5;
            double angle = _fadeAnimation!.value * math.pi * 0.5; // 최대 90도 회전

            // 색상 변화 효과 (원래 색상 -> 밝은 색상)
            Color startColor = cell.color;
            Color endColor = Color.lerp(startColor, Colors.white, 0.7)!;
            Color currentColor =
                Color.lerp(startColor, endColor, _fadeAnimation!.value)!;

            return Transform.scale(
              scale: scale,
              child: Transform.rotate(
                angle: angle,
                child: Opacity(
                  opacity: 1.0 - _fadeAnimation!.value,
                  child: Container(
                    width: actualCellSize,
                    height: actualCellSize,
                    decoration: BoxDecoration(
                      color: currentColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(6.0),
                      boxShadow: [
                        BoxShadow(
                          color: currentColor.withOpacity(0.3),
                          blurRadius: 3.0 + _fadeAnimation!.value * 5.0,
                          spreadRadius: 1.0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        cell.character,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18 + _fadeAnimation!.value * 5, // 약간 커지는 효과
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ));

      // 파티클 효과 (작은 점들이 튀어나가는 효과)
      const int particleCount = 8; // 파티클 개수
      final random = math.Random(cell.position.x * 1000 + cell.position.y);

      for (int i = 0; i < particleCount; i++) {
        final double angle = 2 * math.pi * i / particleCount;
        // 수정된 거리 계산 - 애니메이션 값에 실제 거리 배율을 적용
        final double animationValue = _fadeAnimation?.value ?? 0;
        final double distance = animationValue * actualCellSize * 1.5;

        // 파티클 위치 계산
        final double particleX = math.cos(angle) * distance;
        final double particleY = math.sin(angle) * distance;

        widgets.add(Positioned(
          left: gridPadding +
              cell.position.x * totalCellSize +
              cellMargin +
              actualCellSize / 2 +
              particleX,
          top: gridPadding +
              cell.position.y * totalCellSize +
              cellMargin +
              actualCellSize / 2 +
              particleY,
          child: AnimatedBuilder(
            animation: _fadeAnimation!,
            builder: (context, child) {
              // 랜덤한 초기 지연 적용
              final double delay = random.nextDouble() * 0.3;
              double progress = math.max(
                  0.0, (_fadeAnimation!.value - delay) / (1.0 - delay));
              if (progress <= 0) return const SizedBox();

              final double size = 4.0 * (1.0 - progress);
              final double opacity = (1.0 - progress);

              return Opacity(
                opacity: opacity,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: cell.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: cell.color.withOpacity(0.3),
                        blurRadius: 2,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ));
      }

      // 반짝이는 효과 (셀 중앙에서 퍼져나가는 원)
      widgets.add(Positioned(
        left: gridPadding + cell.position.x * totalCellSize + cellMargin,
        top: gridPadding + cell.position.y * totalCellSize + cellMargin,
        child: AnimatedBuilder(
          animation: _fadeAnimation!,
          builder: (context, child) {
            final double progress = _fadeAnimation!.value;
            final double size = actualCellSize * (1.0 + progress * 1.5);
            final double opacity = math.max(0, 0.5 - progress * 0.5);

            return Opacity(
              opacity: opacity,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 2.0 * (1.0 - progress),
                  ),
                ),
              ),
            );
          },
        ),
      ));
    }

    return widgets;
  }
}
