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
    final isVerySmallScreen = screenWidth < 320;

    // 모바일에서 더 작은 셀 크기 사용 - 많은 블록이 보이도록 조정
    final dynamicCellSize = isCompactMode
        ? (isVerySmallScreen ? 24.0 : (isSmallScreen ? 26.0 : 30.0))
        : (isSmallScreen ? 34.0 : cellSize);

    // 모바일에서 더 작은 패딩 적용
    final dynamicPadding = isCompactMode
        ? (isVerySmallScreen ? 2.0 : (isSmallScreen ? 4.0 : 6.0))
        : (isSmallScreen ? 8.0 : 16.0);

    // 트레이 높이를 약간 증가시키고 모바일에서 더 잘 보이게 함
    final trayHeight = isCompactMode
        ? dynamicCellSize * (isVerySmallScreen ? 5.0 : 5.2)
        : dynamicCellSize * 5.5;

    // 하이라이트 핸들러 생성
    final highlightHandler =
        BlockHighlightHandler(wordSuggestionsKey: wordSuggestionsKey);

    return Container(
      width: screenSize.width,
      height: trayHeight,
      padding: EdgeInsets.symmetric(
        vertical: isCompactMode ? (isVerySmallScreen ? 2.0 : 3.0) : 8.0,
        horizontal: dynamicPadding,
      ),
      decoration: BoxDecoration(
        // 배경색을 더 눈에 띄게 변경 (약간 파란 색조가 있는 밝은 회색)
        color: isCompactMode ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isCompactMode ? 12.0 : 20.0),
          topRight: Radius.circular(isCompactMode ? 12.0 : 20.0),
        ),
        // 테두리를 추가하여 경계를 명확하게 함
        border: isCompactMode
            ? Border(top: BorderSide(color: Colors.blue.shade200, width: 1.5))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isCompactMode ? 0.25 : 0.2),
            blurRadius: isCompactMode ? 8.0 : 8.0,
            offset: Offset(0, isCompactMode ? -3.0 : -3.0),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Container(
            width: 40,
            height: isCompactMode ? (isVerySmallScreen ? 2.0 : 3.0) : 4.0,
            margin: EdgeInsets.only(
                bottom: isCompactMode ? (isVerySmallScreen ? 2.0 : 3.0) : 8.0),
            decoration: BoxDecoration(
              color: isCompactMode
                  ? Colors.blue.shade300
                  : Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 트레이 제목 텍스트 (컴팩트 모드에서 작게 표시)
          if ((!isCompactMode || screenWidth > 360) && !isVerySmallScreen)
            Padding(
              padding: EdgeInsets.only(bottom: isCompactMode ? 2.0 : 4.0),
              child: Text(
                isCompactMode || isSmallScreen ? '블록 트레이' : '블록 트레이 (클릭하여 회전)',
                style: TextStyle(
                  fontSize: isCompactMode
                      ? (isSmallScreen ? 11.0 : 12.0)
                      : (isSmallScreen ? 13.0 : 14.0),
                  fontWeight: FontWeight.w500,
                  color: isCompactMode ? Colors.blue.shade800 : Colors.black87,
                ),
              ),
            ),

          // 블록 목록
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 블록 간격 동적 조정 - 매우 작게 설정하여 더 많은 블록이 보이도록 함
                final blockPadding =
                    isCompactMode ? (isVerySmallScreen ? 0.5 : 1.0) : 4.0;

                // 모바일에서는 블록을 스크롤 없이 모두 보이도록 조정
                return Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 첫 번째 블록 앞에 작은 여백 추가
                        SizedBox(width: isCompactMode ? 2.0 : 4.0),

                        // 블록들 나열
                        for (int i = 0; i < blocks.length; i++)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: blockPadding,
                            ),
                            child: BlockDraggable(
                              block: blocks[i],
                              cellSize: dynamicCellSize,
                              highlightHandler: highlightHandler,
                              isCompactMode: isCompactMode,
                            ),
                          ),

                        // 마지막 블록 뒤에 작은 여백 추가
                        SizedBox(width: isCompactMode ? 2.0 : 4.0),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
