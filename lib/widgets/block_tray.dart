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
/// - isCompactMode: bool
///   컴팩트 모드 여부 (기본값: false)
///   모바일 화면에서 더 작고 간결한 레이아웃 사용
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
  final bool isCompactMode;

  const BlockTray({
    super.key,
    this.cellSize = 40.0,
    this.spacing = 16.0,
    this.wordSuggestionsKey,
    this.isCompactMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final blocks = gameProvider.availableBlocks;
    final screenSize = MediaQuery.of(context).size;

    // 화면 크기와 모드에 따른 동적 설정
    final screenWidth = screenSize.width;
    final isSmallScreen = screenWidth < 360;

    // 컴팩트 모드에서 더 작은 셀과 패딩 크기 사용
    final dynamicCellSize = isCompactMode
        ? (isSmallScreen ? 32.0 : 36.0)
        : (isSmallScreen ? 34.0 : cellSize);

    final dynamicPadding = isCompactMode
        ? (isSmallScreen ? 6.0 : 10.0)
        : (isSmallScreen ? 8.0 : 16.0);

    final trayHeight =
        isCompactMode ? dynamicCellSize * 4.0 : dynamicCellSize * 5.5;

    // 하이라이트 핸들러 생성
    final highlightHandler =
        BlockHighlightHandler(wordSuggestionsKey: wordSuggestionsKey);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        width: screenSize.width,
        height: trayHeight,
        padding: EdgeInsets.symmetric(
          vertical: isCompactMode ? 4.0 : 8.0,
          horizontal: dynamicPadding,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isCompactMode ? 16.0 : 20.0),
            topRight: Radius.circular(isCompactMode ? 16.0 : 20.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isCompactMode ? 0.15 : 0.2),
              blurRadius: isCompactMode ? 6.0 : 8.0,
              offset: Offset(0, isCompactMode ? -2.0 : -3.0),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Container(
              width: 40,
              height: isCompactMode ? 3.0 : 4.0,
              margin: EdgeInsets.only(bottom: isCompactMode ? 4.0 : 8.0),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 트레이 제목 텍스트 (컴팩트 모드에서는 작게)
            if (!isCompactMode || screenWidth > 360)
              Text(
                isCompactMode || isSmallScreen ? '블록 트레이' : '블록 트레이 (클릭하여 회전)',
                style: TextStyle(
                  fontSize: isCompactMode
                      ? (isSmallScreen ? 12.0 : 13.0)
                      : (isSmallScreen ? 13.0 : 14.0),
                  fontWeight: FontWeight.w500,
                ),
              ),

            const SizedBox(height: 4),

            // 블록 목록
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < blocks.length; i++)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompactMode ? 2.0 : 4.0,
                              ),
                              child: BlockDraggable(
                                block: blocks[i],
                                cellSize: dynamicCellSize,
                                highlightHandler: highlightHandler,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
