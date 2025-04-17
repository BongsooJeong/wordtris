import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/block.dart';
import '../providers/game_provider.dart';
import '../utils/point.dart';
import 'dart:math' as Math;

/// 게임에서 사용 가능한 블록들을 표시하는 트레이 위젯
class BlockTray extends StatelessWidget {
  final double cellSize;
  final double spacing;

  const BlockTray({
    super.key,
    this.cellSize = 40.0,
    this.spacing = 16.0,
  });

  /// 블록의 회전 처리
  void _handleTap(BuildContext context, Block block) {
    try {
      // print("블록 회전 시도: ${block.shape}, ID: ${block.id}");
      // 블록 회전 실행
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      gameProvider.rotateBlockInTray(block);
    } catch (e) {
      print("블록 회전 중 오류 발생: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final blocks = gameProvider.availableBlocks;
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        width: screenSize.width,
        height: cellSize * 6,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -3),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 블록 트레이 제목
            Text(
              '블록 트레이 (클릭하여 회전)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // 블록 목록
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: blocks.length,
                itemBuilder: (context, index) {
                  final block = blocks[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Draggable<Block>(
                      data: block,
                      onDragStarted: () {
                        // 드래그 시작 시 처리
                      },
                      feedback: Material(
                        color: Colors.transparent,
                        child: buildBlockWidget(block, 0.7),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: buildBlockWidget(block, 0.3),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          _handleTap(context, block);
                        },
                        child: buildBlockWidget(block, 1.0),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 블록 위젯 생성 (2차원 레이아웃 적용)
  Widget buildBlockWidget(Block block, double opacity) {
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

    return Container(
      width: gridWidth <= 2 ? cellSize * 3.5 : (gridWidth <= 3 ? cellSize * 4.5 : cellSize * 5.5),
      height: gridHeight <= 2 ? cellSize * 3.5 : (gridHeight <= 3 ? cellSize * 4.5 : cellSize * 5.5),
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
                  final cellPadding = 2.0;
                  
                  // 셀 크기 - 정사각형으로 유지
                  // 작은 grid일수록 더 큰 셀로, 큰 grid일수록 조금 작은 셀로 조정
                  final maxCellSize = gridWidth <= 2 ? 60.0 : 
                                     (gridWidth == 3 ? 50.0 : 45.0);
                  
                  double cellSize = Math.min(
                    (availableWidth - (gridWidth - 1) * cellPadding) / gridWidth,
                    (availableHeight - (gridHeight - 1) * cellPadding) / gridHeight
                  );
                  
                  // 최대 크기 제한
                  cellSize = Math.min(cellSize, maxCellSize);
                  
                  // 그리드 전체 크기 계산
                  final gridRealWidth = (cellSize + cellPadding) * gridWidth - cellPadding;
                  final gridRealHeight = (cellSize + cellPadding) * gridHeight - cellPadding;
                  
                  return Center(
                    child: SizedBox(
                      width: gridRealWidth,
                      height: gridRealHeight,
                      child: Stack(
                        children: [
                          for (int i = 0; i < relativePoints.length; i++)
                            Positioned(
                              left: relativePoints[i].x * (cellSize + cellPadding),
                              top: relativePoints[i].y * (cellSize + cellPadding),
                              child: Container(
                                width: cellSize,
                                height: cellSize,
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
                                      ? _buildBombWidget(opacity)
                                      : FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Padding(
                                            padding: const EdgeInsets.all(2.0),
                                            child: Text(
                                              _getCharacterForPosition(block, i),
                                              style: TextStyle(
                                                fontSize: Math.min(cellSize * 0.6, 20),
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

  /// 폭탄 위젯 생성
  Widget _buildBombWidget(double opacity) {
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
        // 펄스 애니메이션 효과
        if (opacity > 0.5)
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.8, end: 1.2),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Container(
                width: cellSize * value,
                height: cellSize * value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withOpacity((1.2 - value) * 0.5),
                    width: 2,
                  ),
                ),
              );
            },
            onEnd: () {
              // 애니메이션은 자동으로 반복되게 설정
            },
          ),
      ],
    );
  }

  /// 블록의 위치에 맞는 문자를 반환합니다
  String _getCharacterForPosition(Block block, int positionIndex) {
    // 현재 위치의 좌표점 가져오기
    List<Point> points = block.getRelativePoints();
    if (positionIndex >= points.length || positionIndex >= block.characters.length) {
      return '';
    }
    
    Point currentPoint = points[positionIndex];
    
    // 행렬에서 해당 위치의 문자 가져오기
    String? character = block.getCharacterAt(currentPoint.x, currentPoint.y);
    return character ?? '';
  }
}
