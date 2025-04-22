import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/game_grid.dart';
import '../widgets/block_tray.dart';
import '../widgets/score_display.dart';
import '../widgets/word_suggestions.dart';
import '../widgets/bomb_indicator.dart';

/// 게임 화면의 레이아웃을 관리하는 위젯
/// 화면 크기에 따라 모바일용(세로) 또는 데스크톱용(가로) 레이아웃을 제공
class GameLayout extends StatelessWidget {
  final GlobalKey<WordSuggestionsState> wordSuggestionsKey;

  const GameLayout({
    Key? key,
    required this.wordSuggestionsKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 화면 크기에 따라 레이아웃 조정
        final isSmallScreen = constraints.maxWidth < 600;

        if (isSmallScreen) {
          return _buildMobileLayout(context, gameProvider);
        } else {
          return _buildDesktopLayout(context, gameProvider);
        }
      },
    );
  }

  /// 모바일 화면용 세로 레이아웃 구성
  Widget _buildMobileLayout(BuildContext context, GameProvider gameProvider) {
    return Column(
      children: [
        // 점수 디스플레이
        ScoreDisplay(
          score: gameProvider.score,
          level: gameProvider.level,
          lastWord: gameProvider.lastCompletedWord,
          lastWordPoints: gameProvider.lastWordPoints,
        ),

        // 폭탄 인디케이터
        BombIndicator(gameProvider: gameProvider),

        // 게임 그리드와 블록 트레이 영역
        Expanded(
          child: Stack(
            children: [
              // 게임 그리드
              const Positioned.fill(
                bottom: 150, // 트레이 높이만큼 공간 확보
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: GameGrid(
                    cellSize: 48.0,
                    gridPadding: 4.0,
                  ),
                ),
              ),

              // 블록 트레이 (화면 하단에 고정)
              BlockTray(
                cellSize: 40.0,
                spacing: 8.0,
                wordSuggestionsKey: wordSuggestionsKey,
              ),
            ],
          ),
        ),

        // 하단 단어 추천 영역 (작은 영역으로 표시)
        SizedBox(
          height: 100,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: WordSuggestions(
              key: wordSuggestionsKey,
              words: gameProvider.suggestedWordSet,
              wordUsageCount: gameProvider.wordUsageCounts,
              usedCharacters: gameProvider.usedCharacters,
              onDictionaryLookup: gameProvider.openDictionary,
              isCompactMode: true,
            ),
          ),
        ),
      ],
    );
  }

  /// 데스크톱 화면용 가로 레이아웃 구성
  Widget _buildDesktopLayout(BuildContext context, GameProvider gameProvider) {
    return Row(
      children: [
        // 메인 게임 영역
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              Column(
                children: [
                  // 점수 디스플레이
                  ScoreDisplay(
                    score: gameProvider.score,
                    level: gameProvider.level,
                    lastWord: gameProvider.lastCompletedWord,
                    lastWordPoints: gameProvider.lastWordPoints,
                  ),

                  // 폭탄 인디케이터
                  BombIndicator(gameProvider: gameProvider),

                  // 게임 그리드
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: GameGrid(
                        cellSize: 48.0,
                        gridPadding: 4.0,
                      ),
                    ),
                  ),

                  // 블록 트레이를 위한 공간 확보
                  const SizedBox(height: 150),
                ],
              ),

              // 블록 트레이 (화면 하단에 고정)
              BlockTray(
                cellSize: 40.0,
                spacing: 8.0,
                wordSuggestionsKey: wordSuggestionsKey,
              ),
            ],
          ),
        ),

        // 추천 단어 영역
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: WordSuggestions(
              key: wordSuggestionsKey,
              words: gameProvider.suggestedWordSet,
              wordUsageCount: gameProvider.wordUsageCounts,
              usedCharacters: gameProvider.usedCharacters,
              onDictionaryLookup: gameProvider.openDictionary,
            ),
          ),
        ),
      ],
    );
  }
}
