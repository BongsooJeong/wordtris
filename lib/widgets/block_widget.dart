import 'package:flutter/material.dart';
import 'dart:math' as Math;
import '../models/block.dart';
import '../utils/point.dart';
import 'bomb_widget.dart';
import 'wildcard_star_widget.dart';

/// 블록 위젯 생성 클래스
class BlockWidget extends StatelessWidget {
  final Block block;
  final double opacity;
  final double cellSize;
  final bool isCompactMode;

  const BlockWidget({
    super.key,
    required this.block,
    this.opacity = 1.0,
    this.cellSize = 40.0,
    this.isCompactMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // 블록의 상대적 위치 가져오기
    List<Point> relativePoints = block.getRelativePoints();

    // 블록의 레이아웃 크기 계산
    int maxX = 0;
    int maxY = 0;

    for (var point in relativePoints) {
      if (point.x > maxX) maxX = point.x;
      if (point.y > maxY) maxY = point.y;
    }

    // 그리드의 폭과 높이 (0부터 시작하므로 +1)
    int gridWidth = maxX + 1;
    int gridHeight = maxY + 1;

    // 폭탄 블록 여부 확인
    bool isBombBlock = block.isBomb;
    // 와일드카드 블록 여부 확인
    bool isWildcardBlock = block.isWildcard;

    // 컴팩트 모드에서는 더 작은 여백 사용
    final containerPadding = isCompactMode ? 2.0 : 8.0;
    final borderRadius = isCompactMode ? 6.0 : 12.0;

    // 컴팩트 모드에서는 더 작은 너비/높이 계산
    // 모바일에서 더 많은 블록이 보이도록 크기 축소
    final widthFactor = isCompactMode ? 2.6 : 3.5;
    final heightFactor = isCompactMode ? 2.6 : 3.5;

    // 모바일 화면에서 더 눈에 띄는 배경색 사용
    final bgColor = isCompactMode
        ? const Color.fromARGB(255, 250, 253, 255) // 약간 파란 색조가 있는 밝은 색
        : Colors.grey.withOpacity(0.1);

    // 모바일 화면에서 더 강조된 테두리 사용
    final borderWidth = isCompactMode ? 1.5 : 1.5;
    final borderColor = block.color.withOpacity(isCompactMode ? 0.7 : 0.5);

    // 화면 크기에 따른 동적 설정
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    // 블록 크기 계산 - 모바일에서 더 작게 조정
    final dynamicWidth = gridWidth <= 2
        ? cellSize * widthFactor
        : (gridWidth <= 3 ? cellSize * 3.8 : cellSize * 4.5);

    final dynamicHeight = gridHeight <= 2
        ? cellSize * heightFactor
        : (gridHeight <= 3 ? cellSize * 3.8 : cellSize * 4.5);

    return Container(
      width: dynamicWidth,
      height: dynamicHeight,
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        // 약간의 그림자를 추가하여 입체감 부여
        boxShadow: isCompactMode
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 3.0,
                  offset: const Offset(0, 1.0),
                )
              ]
            : null,
      ),
      child: Column(
        children: [
          // 형태 정보 표시 제거
          SizedBox(height: isCompactMode ? 2.0 : 4.0),
          // 블록 셀 그리드
          Expanded(
            child: Container(
              padding: EdgeInsets.all(isCompactMode ? 2.0 : 4.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 사용 가능한 공간 계산
                  final availableWidth = constraints.maxWidth;
                  final availableHeight = constraints.maxHeight;

                  // 셀 사이의 간격 (모바일에서 더 작게)
                  final cellPadding = isCompactMode ? 1.0 : 2.0;

                  // 셀 크기 - 정사각형으로 유지
                  // 작은 grid일수록 더 큰 셀로, 큰 grid일수록 조금 작은 셀로 조정
                  final maxCellSize = isCompactMode
                      ? (gridWidth <= 2 ? 32.0 : (gridWidth == 3 ? 28.0 : 24.0))
                      : (gridWidth <= 2
                          ? 60.0
                          : (gridWidth == 3 ? 50.0 : 45.0));

                  double actualCellSize = Math.min(
                      (availableWidth - (gridWidth - 1) * cellPadding) /
                          gridWidth,
                      (availableHeight - (gridHeight - 1) * cellPadding) /
                          gridHeight);

                  // 최대 크기 제한
                  actualCellSize = Math.min(actualCellSize, maxCellSize);

                  // 그리드 전체 크기 계산
                  final gridRealWidth =
                      (actualCellSize + cellPadding) * gridWidth - cellPadding;
                  final gridRealHeight =
                      (actualCellSize + cellPadding) * gridHeight - cellPadding;

                  return Center(
                    child: SizedBox(
                      width: gridRealWidth,
                      height: gridRealHeight,
                      child: Stack(
                        children: [
                          for (int i = 0; i < relativePoints.length; i++)
                            Positioned(
                              left: relativePoints[i].x *
                                  (actualCellSize + cellPadding),
                              top: relativePoints[i].y *
                                  (actualCellSize + cellPadding),
                              child: Container(
                                width: actualCellSize,
                                height: actualCellSize,
                                decoration: BoxDecoration(
                                  // 모바일에서는 더 진한 색상을 사용하여 가시성 개선
                                  color: block.color
                                      .withOpacity(isCompactMode ? 0.95 : 0.8),
                                  borderRadius: BorderRadius.circular(
                                      isCompactMode ? 4.0 : 8.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: block.color.withOpacity(
                                          isCompactMode ? 0.5 : 0.4),
                                      blurRadius: isCompactMode ? 2 : 3,
                                      offset: const Offset(0, 1),
                                    )
                                  ],
                                ),
                                child: Center(
                                  child: isBombBlock
                                      ? BombWidget(opacity: opacity)
                                      : isWildcardBlock
                                          ? WildcardStarWidget(
                                              size: Math.min(
                                                  actualCellSize * 0.8, 28),
                                              opacity: opacity,
                                            )
                                          : FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Padding(
                                                padding: EdgeInsets.all(
                                                    isCompactMode ? 1.0 : 2.0),
                                                child: Text(
                                                  _getCharacterForPosition(i),
                                                  style: TextStyle(
                                                    fontSize: Math.min(
                                                        actualCellSize * 0.65,
                                                        isCompactMode
                                                            ? 22
                                                            : 20),
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 위치에 따른 문자 반환
  String _getCharacterForPosition(int position) {
    // 상대적 위치 목록에서 현재 위치 가져오기
    List<Point> relativePoints = block.getRelativePoints();
    if (position < relativePoints.length) {
      Point point = relativePoints[position];
      // 해당 위치의 문자 가져오기
      String? character = block.getCharacterAt(point.x, point.y);
      if (character != null) {
        return character;
      }
    }

    // 폴백: 기존 방식으로 처리 (문제가 있을 경우 대비)
    if (position < block.characters.length) {
      return block.characters[position];
    }

    return '';
  }
}
