/// WordTris 게임의 블록 트레이 위젯 API 문서
///
/// [BlockTray] 클래스
/// 게임에서 사용 가능한 블록들을 표시하고 관리하는 StatelessWidget
///
/// 주요 기능:
/// - 사용 가능한 블록 표시 (기본 4개)
/// - 블록 회전 처리
/// - 드래그 앤 드롭 기능
/// - 블록 레이아웃 관리
/// - 블록들의 가운데 정렬
///
/// 생성자 매개변수:
/// - cellSize: double
///   블록 셀의 크기 (기본값: 40.0)
///
/// - spacing: double
///   블록 간의 간격 (기본값: 16.0)
///
/// - wordSuggestionsKey: GlobalKey<WordSuggestionsState>?
///   단어 제안 위젯의 키 (기본값: null)
///
/// 이벤트 처리:
/// - _handleTap(BuildContext context, Block block): void
///   블록 회전 이벤트 처리
///
/// UI 구성:
/// - build(BuildContext context): Widget
///   전체 트레이 UI 구성
///
/// - buildBlockWidget(Block block, double opacity): Widget
///   개별 블록 위젯 생성 및 2차원 레이아웃 적용
///
/// 레이아웃 구조:
/// ```
/// Positioned (화면 하단에 고정)
/// └─ Container (트레이 메인 컨테이너)
///    └─ Column
///       ├─ Container (드래그 핸들)
///       ├─ Text (트레이 제목)
///       └─ Expanded
///          └─ Center (X축 가운데 정렬)
///             └─ Row (가운데 정렬)
///                └─ SizedBox (고정 높이)
///                   └─ ListView.builder (가로 스크롤)
///                      └─ Draggable<Block>
///                         ├─ Material (드래그 중 표시)
///                         │  └─ BlockWidget
///                         └─ GestureDetector (탭 처리)
///                            └─ BlockWidget
///
/// BlockWidget 구조:
/// Container (블록 컨테이너)
/// └─ Column
///    ├─ SizedBox (여백)
///    └─ Expanded
///       └─ LayoutBuilder
///          └─ Stack
///             └─ Positioned[] (블록 셀들)
///                └─ Container (개별 셀)
///                   └─ Text/BombWidget (문자 또는 폭탄)
/// ```

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/block.dart';
import '../providers/game_provider.dart';
import '../utils/point.dart';
import 'dart:math' as Math;
import '../widgets/word_suggestions.dart';

/// 게임에서 사용 가능한 블록들을 표시하는 트레이 위젯
class BlockTray extends StatelessWidget {
  final double cellSize;
  final double spacing;
  final GlobalKey<WordSuggestionsState>? wordSuggestionsKey;

  const BlockTray({
    super.key,
    this.cellSize = 40.0,
    this.spacing = 16.0,
    this.wordSuggestionsKey,
  });

  /// 블록 문자를 하이라이트
  void _highlightBlockCharacters(Block block, {bool clear = false}) {
    if (wordSuggestionsKey?.currentState == null) return;

    if (clear) {
      wordSuggestionsKey!.currentState!.clearHighlights();
    } else {
      final characters = Set<String>.from(block.characters);
      wordSuggestionsKey!.currentState!.setHighlightedCharacters(characters);
    }
  }

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
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: cellSize * 4,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        itemCount: blocks.length,
                        itemBuilder: (context, index) {
                          final block = blocks[index];
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Draggable<Block>(
                              data: block,
                              onDragStarted: () {
                                // 드래그 시작 시 처리
                                _highlightBlockCharacters(block);
                              },
                              onDragEnd: (details) {
                                // 드래그 종료 시 처리
                                _highlightBlockCharacters(block, clear: true);
                              },
                              onDraggableCanceled: (velocity, offset) {
                                // 드래그 취소 시 처리
                                _highlightBlockCharacters(block, clear: true);
                              },
                              // 드래그 중일 때 보여줄 위젯
                              feedback: Material(
                                color: Colors.transparent,
                                elevation: 4.0,
                                child: buildBlockWidget(block, 0.7),
                              ),
                              // 드래그 앵커 전략 - 블록의 중앙점이 마우스 포인터에 위치하도록 설정
                              dragAnchorStrategy:
                                  (draggable, context, position) {
                                // 블록 위젯의 중앙점을 계산
                                final RenderBox renderBox =
                                    context.findRenderObject() as RenderBox;
                                final size = renderBox.size;
                                return Offset(size.width / 2, size.height / 2);
                              },
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: buildBlockWidget(block, 0.3),
                              ),
                              child: MouseRegion(
                                onEnter: (_) {
                                  // 마우스가 블록에 들어왔을 때
                                  _highlightBlockCharacters(block);
                                },
                                onExit: (_) {
                                  // 마우스가 블록에서 나갔을 때
                                  _highlightBlockCharacters(block, clear: true);
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    _handleTap(context, block);
                                  },
                                  child: buildBlockWidget(block, 1.0),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
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

                  double cellSize = Math.min(
                      (availableWidth - (gridWidth - 1) * cellPadding) /
                          gridWidth,
                      (availableHeight - (gridHeight - 1) * cellPadding) /
                          gridHeight);

                  // 최대 크기 제한
                  cellSize = Math.min(cellSize, maxCellSize);

                  // 그리드 전체 크기 계산
                  final gridRealWidth =
                      (cellSize + cellPadding) * gridWidth - cellPadding;
                  final gridRealHeight =
                      (cellSize + cellPadding) * gridHeight - cellPadding;

                  return Center(
                    child: SizedBox(
                      width: gridRealWidth,
                      height: gridRealHeight,
                      child: Stack(
                        children: [
                          for (int i = 0; i < relativePoints.length; i++)
                            Positioned(
                              left: relativePoints[i].x *
                                  (cellSize + cellPadding),
                              top: relativePoints[i].y *
                                  (cellSize + cellPadding),
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
                                              _getCharacterForPosition(
                                                  block, i),
                                              style: TextStyle(
                                                fontSize: Math.min(
                                                    cellSize * 0.6, 20),
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

  /// 위치에 따른 문자 반환
  String _getCharacterForPosition(Block block, int position) {
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
