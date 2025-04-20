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
///                      └─ BlockDraggable
/// ```

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'word_suggestions.dart';
import 'block_draggable.dart';
import 'block_highlight_handler.dart';

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

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final blocks = gameProvider.availableBlocks;
    final screenSize = MediaQuery.of(context).size;

    // 하이라이트 핸들러 생성
    final highlightHandler =
        BlockHighlightHandler(wordSuggestionsKey: wordSuggestionsKey);

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
                          return BlockDraggable(
                            block: block,
                            cellSize: cellSize,
                            highlightHandler: highlightHandler,
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
}
