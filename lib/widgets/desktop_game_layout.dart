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
        // 타이틀은 이미 AppBar에 있으므로 제거
        // 상단 여백만 유지
        const SizedBox(height: 8.0),

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
                    Column(
                      children: [
                        // 점수 디스플레이와 폭탄 인디케이터 & 추천 단어를 가로로 배치
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 왼쪽 영역: 점수 디스플레이 + 추천 단어
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 점수 디스플레이
                                    ScoreDisplay(
                                      score: gameProvider.score,
                                      level: gameProvider.level,
                                      lastWord: gameProvider.lastCompletedWord,
                                      lastWordPoints:
                                          gameProvider.lastWordPoints,
                                      isCompactMode: false, // 데스크톱에서는 가로 배치 유지
                                    ),

                                    // 추천 단어 패널 (접힌 상태)
                                    const SizedBox(height: 8),
                                    WordSuggestions(
                                      key: wordSuggestionsKey,
                                      words: gameProvider.suggestedWordSet,
                                      wordUsageCount:
                                          gameProvider.wordUsageCounts,
                                      usedCharacters:
                                          gameProvider.usedCharacters,
                                      onDictionaryLookup:
                                          gameProvider.openDictionary,
                                      isCompactMode: false,
                                      initiallyExpanded: false, // 접힌 상태로 시작
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // 게임 그리드
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GameGrid(
                              cellSize: cellSize,
                              gridPadding: 6.0,
                              autoSize: true, // 자동 크기 조정 활성화
                            ),
                          ),
                        ),

                        // 블록 트레이를 위한 공간 확보
                        SizedBox(height: cellSize * 3.5),
                      ],
                    ),

                    // 블록 트레이 (화면 하단에 고정)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: BlockTray(
                        cellSize: cellSize - 4.0,
                        spacing: 8.0,
                        wordSuggestionsKey: wordSuggestionsKey,
                        isCompactMode: false, // 데스크톱에서는 일반 모드 유지
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
