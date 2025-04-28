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

    // 게임 영역의 실제 크기 계산
    final gameWidth = screenWidth;
    final gameHeight = screenHeight;

    // 그리드와 트레이의 크기 비율 설정
    final gridHeight = gameHeight * 0.6; // 전체 높이의 60%
    final trayHeight = gameHeight * 0.2; // 전체 높이의 20%

    // 셀 크기 계산
    final dynamicCellSize = (gridHeight - 16) / 10; // 10x10 그리드 기준
    final isVerySmallScreen = screenWidth < 320;

    return Column(
      children: [
        // 상단 여백
        SizedBox(height: isVerySmallScreen ? 2.0 : 4.0),

        // 점수 디스플레이 및 추천 단어 (상단 영역)
        Container(
          height: gameHeight * 0.15, // 전체 높이의 15%
          margin: EdgeInsets.symmetric(
            horizontal: isVerySmallScreen ? 4.0 : 8.0,
            vertical: isVerySmallScreen ? 2.0 : 4.0,
          ),
          child: Column(
            children: [
              // 점수 정보
              Expanded(
                flex: 2,
                child: ScoreDisplay(
                  score: gameProvider.score,
                  level: gameProvider.level,
                  lastWord: gameProvider.lastCompletedWord,
                  lastWordPoints: gameProvider.lastWordPoints,
                  isCompactMode: true,
                ),
              ),

              // 추천 단어 패널
              Expanded(
                flex: 3,
                child: WordSuggestions(
                  key: wordSuggestionsKey,
                  words: gameProvider.suggestedWordSet,
                  wordUsageCount: gameProvider.wordUsageCounts,
                  usedCharacters: gameProvider.usedCharacters,
                  onDictionaryLookup: gameProvider.openDictionary,
                  isCompactMode: true,
                  initiallyExpanded: false,
                ),
              ),
            ],
          ),
        ),

        // 게임 그리드
        Container(
          height: gridHeight,
          padding: EdgeInsets.symmetric(
            horizontal: isVerySmallScreen ? 2.0 : 4.0,
          ),
          child: Center(
            child: GameGrid(
              cellSize: dynamicCellSize,
              gridPadding: screenWidth < 360 ? 2.0 : 4.0,
              autoSize: true,
            ),
          ),
        ),

        // 블록 트레이
        SizedBox(
          height: trayHeight,
          child: BlockTray(
            cellSize: dynamicCellSize * 0.9,
            spacing: screenWidth < 360 ? 2.0 : 4.0,
            wordSuggestionsKey: wordSuggestionsKey,
            isCompactMode: true,
          ),
        ),
      ],
    );
  }

  /// 태블릿 화면용 혼합 레이아웃 구성 (600px <= 화면 너비 < 900px)
  Widget _buildTabletLayout(
      BuildContext context, GameProvider gameProvider, double screenWidth) {
    // 셀 크기를 더 작게 조정하여 5개 블록이 모두 표시되도록 함
    final cellSize = screenWidth < 720 ? 36.0 : 40.0;
    // 트레이 높이를 더 크게 조정하여 모든 블록이 보이도록 함
    final trayHeight = cellSize * 5.2;

    // 화면 높이 가져오기
    final screenHeight = MediaQuery.of(context).size.height;
    // 그리드에 사용할 수 있는 최대 높이 계산 (화면 높이의 65%)
    final maxGridHeight = screenHeight * 0.65;

    return Column(
      children: [
        // 타이틀은 이미 AppBar에 있으므로 제거
        // 상단 여백만 유지
        const SizedBox(height: 6.0),

        // 상단 정보 영역 (세로 배치로 변경)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 점수와 레벨 정보 (왼쪽)
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
                      lastWordPoints: gameProvider.lastWordPoints,
                      isCompactMode: true, // 태블릿에서도 컴팩트 모드 사용
                    ),

                    // 추천 단어 패널 (접힌 상태)
                    const SizedBox(height: 8),
                    WordSuggestions(
                      key: wordSuggestionsKey,
                      words: gameProvider.suggestedWordSet,
                      wordUsageCount: gameProvider.wordUsageCounts,
                      usedCharacters: gameProvider.usedCharacters,
                      onDictionaryLookup: gameProvider.openDictionary,
                      isCompactMode: true, // 작은 태블릿에서는 컴팩트 모드
                      initiallyExpanded: false, // 접힌 상태로 시작
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // 게임 영역 (중앙)
        Expanded(
          child: Column(
            children: [
              // 게임 그리드
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 8.0,
                      right: 8.0,
                      top: 8.0,
                      bottom: 8.0, // 트레이와의 간격 확보
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // 사용 가능한 공간에 맞춰 그리드 표시
                        final availableHeight = constraints.maxHeight - 8.0;
                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: math.min(
                                availableHeight, maxGridHeight - trayHeight),
                            maxWidth: constraints.maxWidth,
                          ),
                          child: GameGrid(
                            cellSize: cellSize,
                            gridPadding: 6.0,
                            autoSize: true, // 자동 크기 조정 활성화
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // 블록 트레이 (화면 하단에 고정)
              SizedBox(
                height: trayHeight,
                child: BlockTray(
                  cellSize:
                      cellSize - (screenWidth < 720 ? 2.0 : 4.0), // 셀 크기 조정
                  spacing: screenWidth < 720 ? 2.0 : 4.0, // 공간 조정
                  wordSuggestionsKey: wordSuggestionsKey,
                  isCompactMode: true, // 태블릿에서도 컴팩트 모드 사용
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
