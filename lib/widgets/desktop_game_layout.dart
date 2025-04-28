import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/game_grid.dart';
import '../widgets/block_tray.dart';
import '../widgets/score_display.dart';
import '../widgets/word_suggestions.dart';

/// 데스크톱 화면용 게임 레이아웃을 관리하는 위젯
class DesktopGameLayout extends StatelessWidget {
  final GlobalKey<WordSuggestionsState> wordSuggestionsKey;

  const DesktopGameLayout({
    Key? key,
    required this.wordSuggestionsKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        return _buildDesktopLayout(context, gameProvider, screenWidth);
      },
    );
  }

  /// 데스크톱 화면용 가로 레이아웃 구성 (화면 너비 >= 900px)
  Widget _buildDesktopLayout(
      BuildContext context, GameProvider gameProvider, double screenWidth) {
    // 화면 크기에 따른 동적 셀 크기 조정
    final cellSize = screenWidth > 1200 ? 52.0 : 48.0;

    return Column(
      children: [
        // 상단 여백 감소
        const SizedBox(height: 4.0),

        // 메인 게임 영역
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 게임 그리드 및 관련 요소
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    // 배경 GestureDetector - 화면의 아무 곳이나 터치하면 추천 단어 패널 닫기
                    Positioned.fill(
                      child: GestureDetector(
                        behavior:
                            HitTestBehavior.translucent, // 투명 영역도 터치 이벤트 감지
                        onTap: () {
                          // 추천 단어 패널이 열려있으면 닫기
                          if (wordSuggestionsKey.currentState != null) {
                            wordSuggestionsKey.currentState!.toggleExpanded();
                          }
                        },
                      ),
                    ),

                    Column(
                      children: [
                        // 점수 디스플레이
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: ScoreDisplay(
                            score: gameProvider.score,
                            level: gameProvider.level,
                            lastWord: gameProvider.lastCompletedWord,
                            lastWordPoints: gameProvider.lastWordPoints,
                            isCompactMode: false,
                          ),
                        ),

                        // 게임 그리드
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 8.0,
                              right: 8.0,
                              top: 8.0,
                              bottom: 8.0,
                            ),
                            child: GameGrid(
                              cellSize: cellSize,
                              gridPadding: 6.0,
                              autoSize: true,
                            ),
                          ),
                        ),

                        // 블록 트레이를 위한 공간 확보
                        SizedBox(height: cellSize * 3.0),
                      ],
                    ),

                    // 추천 단어 패널 - 그리드 위에 겹치는 형태로 배치
                    Positioned(
                      top: 120.0, // 점수 디스플레이 아래에 위치
                      left: 6.0,
                      right: 6.0,
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: WordSuggestions(
                          key: wordSuggestionsKey,
                          words: gameProvider.suggestedWordSet,
                          wordUsageCount: gameProvider.wordUsageCounts,
                          usedCharacters: gameProvider.usedCharacters,
                          onDictionaryLookup: gameProvider.openDictionary,
                          isCompactMode: false,
                          initiallyExpanded: false,
                        ),
                      ),
                    ),

                    // 보드 아래 블록 트레이
                    Positioned(
                      left: 0.0,
                      right: 0.0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16.0),
                            topRight: Radius.circular(16.0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: BlockTray(
                          cellSize: 30.0,
                          spacing: 4.0,
                          wordSuggestionsKey: wordSuggestionsKey,
                          isCompactMode: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
