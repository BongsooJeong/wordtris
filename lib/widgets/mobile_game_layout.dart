import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/game_grid.dart';
import '../widgets/block_tray.dart';
import '../widgets/score_display.dart';
import '../widgets/word_suggestions.dart';
import 'dart:math' as math;

/// 모바일 및 태블릿 화면용 게임 레이아웃을 관리하는 위젯
class MobileGameLayout extends StatelessWidget {
  final GlobalKey<WordSuggestionsState> wordSuggestionsKey;

  const MobileGameLayout({
    Key? key,
    required this.wordSuggestionsKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 화면 크기에 따라 레이아웃 조정
        final screenWidth = constraints.maxWidth;

        // 모바일: 0-599px, 태블릿: 600-899px
        if (screenWidth < 600) {
          return _buildMobileLayout(context, gameProvider, screenWidth);
        } else {
          return _buildTabletLayout(context, gameProvider, screenWidth);
        }
      },
    );
  }

  /// 모바일 화면용 세로 레이아웃 구성 (화면 너비 < 600px)
  Widget _buildMobileLayout(
      BuildContext context, GameProvider gameProvider, double screenWidth) {
    // 화면 크기에 따른 동적 셀 크기 조정
    final screenHeight = MediaQuery.of(context).size.height;

    // 셀 크기 계산 - 더 큰 셀 크기로 조정
    final availableHeight =
        screenHeight - MediaQuery.of(context).padding.vertical;
    final dynamicCellSize = math.min(
        (availableHeight * 0.55) / 10, (screenWidth - 12) / 10); // 셀 크기 증가
    final isVerySmallScreen = screenWidth < 320;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 점수 디스플레이 - 더 큰 높이 할당
            Container(
              height: isVerySmallScreen ? 70 : 80, // 높이 더 증가
              padding: const EdgeInsets.symmetric(
                vertical: 4.0,
                horizontal: 4.0,
              ),
              child: ScoreDisplay(
                score: gameProvider.score,
                level: gameProvider.level,
                lastWord: gameProvider.lastCompletedWord,
                lastWordPoints: gameProvider.lastWordPoints,
                isCompactMode: true,
              ),
            ),

            // 게임 그리드와 추천 단어 패널을 포함하는 Stack
            Expanded(
              flex: 8,
              child: Stack(
                children: [
                  // 배경 GestureDetector - 화면의 아무 곳이나 터치하면 추천 단어 패널 닫기
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        // 추천 단어 패널이 열려있으면 닫기
                        if (wordSuggestionsKey.currentState != null) {
                          wordSuggestionsKey.currentState!.toggleExpanded();
                        }
                      },
                    ),
                  ),

                  // 게임 그리드
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Center(
                      child: GameGrid(
                        cellSize: dynamicCellSize,
                        gridPadding: isVerySmallScreen ? 2.0 : 4.0,
                        autoSize: true,
                      ),
                    ),
                  ),

                  // 추천 단어 패널 - 그리드 위에 겹치는 형태로 배치
                  Positioned(
                    top: 10.0,
                    left: 4.0,
                    right: 4.0,
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
                ],
              ),
            ),

            // 블록 트레이 - 비율 감소
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: BlockTray(
                  cellSize: dynamicCellSize * 0.8, // 0.9에서 0.8로 셀 크기 더 감소
                  spacing: isVerySmallScreen ? 2.0 : 3.0, // 간격도 약간 조정
                  wordSuggestionsKey: wordSuggestionsKey,
                  isCompactMode: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 태블릿 화면용 혼합 레이아웃 구성 (600px <= 화면 너비 < 900px)
  Widget _buildTabletLayout(
      BuildContext context, GameProvider gameProvider, double screenWidth) {
    // 셀 크기를 더 작게 조정하여 5개 블록이 모두 표시되도록 함
    final cellSize = screenWidth < 720 ? 36.0 : 40.0;
    // 트레이 높이를 더 크게 조정하여 모든 블록이 보이도록 함
    final trayHeight = cellSize * 4.5; // 5.2에서 4.5로 감소

    // 화면 높이 가져오기
    final screenHeight = MediaQuery.of(context).size.height;
    // 그리드에 사용할 수 있는 최대 높이 계산 (화면 높이의 70%)
    final maxGridHeight = screenHeight * 0.7; // 65%에서 70%로 증가

    return Column(
      children: [
        // 상단 여백 축소
        const SizedBox(height: 2.0), // 6.0에서 2.0으로 감소

        // 상단 정보 영역 (세로 배치로 변경)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 점수와 레벨 정보 (왼쪽)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(4.0), // 8.0에서 4.0으로 감소
                child: ScoreDisplay(
                  score: gameProvider.score,
                  level: gameProvider.level,
                  lastWord: gameProvider.lastCompletedWord,
                  lastWordPoints: gameProvider.lastWordPoints,
                  isCompactMode: true,
                ),
              ),
            ),
          ],
        ),

        // 게임 영역 (중앙)
        Expanded(
          child: Stack(
            children: [
              // 배경 GestureDetector - 화면의 아무 곳이나 터치하면 추천 단어 패널 닫기
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
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
                  // 게임 그리드
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 8.0,
                          right: 8.0,
                          top: 4.0, // 8.0에서 4.0으로 감소
                          bottom: 4.0, // 8.0에서 4.0으로 감소
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // 사용 가능한 공간에 맞춰 그리드 표시
                            final availableHeight =
                                constraints.maxHeight - 4.0; // 8.0에서 4.0으로 감소
                            return ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: math.min(availableHeight,
                                    maxGridHeight - trayHeight),
                                maxWidth: constraints.maxWidth,
                              ),
                              child: GameGrid(
                                cellSize: cellSize,
                                gridPadding: 6.0,
                                autoSize: true,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // 그리드와 트레이 사이 간격 추가
                  const SizedBox(height: 4.0),

                  // 블록 트레이 (화면 하단에 고정)
                  SizedBox(
                    height: trayHeight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: BlockTray(
                        cellSize: cellSize - (screenWidth < 720 ? 2.0 : 4.0),
                        spacing: screenWidth < 720 ? 2.0 : 4.0,
                        wordSuggestionsKey: wordSuggestionsKey,
                        isCompactMode: true,
                      ),
                    ),
                  ),
                ],
              ),

              // 추천 단어 패널 - 그리드 위에 겹치는 형태로 배치
              Positioned(
                top: 10.0,
                left: 8.0,
                right: 8.0,
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
            ],
          ),
        ),
      ],
    );
  }
}
