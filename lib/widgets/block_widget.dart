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

  const BlockWidget({
    super.key,
    required this.block,
    this.opacity = 1.0,
    this.cellSize = 40.0,
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

    return Container(
      width: gridWidth <= 2
          ? cellSize * 3.5
          : (gridWidth <= 3 ? cellSize * 4.5 : cellSize * 5.5),
      height: gridHeight <= 2
          ? cellSize * 3.5
          : (gridHeight <= 3 ? cellSize * 4.5 : cellSize * 5.5),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: block.color.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // 형태 정보 표시 제거
          const SizedBox(height: 4),
          // 블록 셀 그리드
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 사용 가능한 공간 계산
                  final availableWidth = constraints.maxWidth;
                  final availableHeight = constraints.maxHeight;

                  // 셀 사이의 간격
                  const cellPadding = 2.0;

                  // 셀 크기 - 정사각형으로 유지
                  // 작은 grid일수록 더 큰 셀로, 큰 grid일수록 조금 작은 셀로 조정
                  final maxCellSize =
                      gridWidth <= 2 ? 60.0 : (gridWidth == 3 ? 50.0 : 45.0);

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
                                  color: block.color.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(8.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: block.color.withOpacity(0.3),
                                      blurRadius: 3,
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
                                                padding:
                                                    const EdgeInsets.all(2.0),
                                                child: Text(
                                                  _getCharacterForPosition(i),
                                                  style: TextStyle(
                                                    fontSize: Math.min(
                                                        actualCellSize * 0.6,
                                                        20),
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
