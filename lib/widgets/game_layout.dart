import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/game_grid.dart';
import '../widgets/block_tray.dart';
import '../widgets/score_display.dart';
import '../widgets/word_suggestions.dart';
import '../widgets/bomb_indicator.dart';
import '../widgets/animated_title.dart';

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
        // 반응형 브레이크포인트 구분을 더 상세하게 설정
        final screenWidth = constraints.maxWidth;

        // 모바일: 0-599px, 태블릿: 600-899px, 데스크톱: 900px+
        if (screenWidth < 600) {
          return _buildMobileLayout(context, gameProvider, screenWidth);
        } else if (screenWidth < 900) {
          return _buildTabletLayout(context, gameProvider, screenWidth);
        } else {
          return _buildDesktopLayout(context, gameProvider, screenWidth);
        }
      },
    );
  }

  /// 모바일 화면용 세로 레이아웃 구성 (화면 너비 < 600px)
  Widget _buildMobileLayout(
      BuildContext context, GameProvider gameProvider, double screenWidth) {
    // 화면 크기에 따른 동적 셀 크기 조정
    final dynamicCellSize = screenWidth < 360 ? 36.0 : 42.0;
    final trayHeight = dynamicCellSize * 4.2; // 트레이 높이 최적화
    final isVerySmallScreen = screenWidth < 320;

    return Column(
      children: [
        // 애니메이션 타이틀은 이미 AppBar에 있으므로 제거
        // 상단 여백만 유지
        SizedBox(height: isVerySmallScreen ? 2.0 : 4.0),

        // 점수 디스플레이 (세로 모드로 변경)
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: isVerySmallScreen ? 4.0 : 8.0,
            vertical: isVerySmallScreen ? 2.0 : 4.0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 점수 및 레벨 정보 (왼쪽 세로 배치)
              Expanded(
                flex: 3,
                child: ScoreDisplay(
                  score: gameProvider.score,
                  level: gameProvider.level,
                  lastWord: gameProvider.lastCompletedWord,
                  lastWordPoints: gameProvider.lastWordPoints,
                  isCompactMode: true, // 세로 배치 모드 활성화
                ),
              ),

              // 폭탄 인디케이터 (오른쪽 세로 배치)
              Expanded(
                flex: 2,
                child: BombIndicator(
                  gameProvider: gameProvider,
                  isCompactMode: true, // 컴팩트 모드 활성화
                ),
              ),
            ],
          ),
        ),

        // 게임 그리드와 블록 트레이 영역
        Expanded(
          child: Stack(
            children: [
              // 게임 그리드 (화면 크기에 맞게 조정)
              Positioned.fill(
                bottom: trayHeight, // 트레이 높이만큼 공간 확보
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isVerySmallScreen ? 2.0 : 4.0,
                    vertical: isVerySmallScreen ? 0.0 : 2.0,
                  ),
                  child: GameGrid(
                    cellSize: dynamicCellSize,
                    gridPadding: screenWidth < 360 ? 2.0 : 4.0,
                    autoSize: true, // 자동 크기 조정 활성화
                  ),
                ),
              ),

              // 블록 트레이 (화면 하단에 고정, 컴팩트하게)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BlockTray(
                  cellSize: dynamicCellSize - 8.0, // 더 작은 셀 크기로 설정
                  spacing: screenWidth < 360 ? 2.0 : 4.0, // 공간 절약
                  wordSuggestionsKey: wordSuggestionsKey,
                  isCompactMode: true, // 컴팩트 모드 활성화
                ),
              ),
            ],
          ),
        ),

        // 하단 단어 추천 영역 (최소 크기로 표시)
        SizedBox(
          height: screenWidth < 360 ? 70 : 80,
          child: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: isVerySmallScreen ? 2.0 : 4.0),
            child: WordSuggestions(
              words: gameProvider.suggestedWordSet,
              wordUsageCount: gameProvider.wordUsageCounts,
              usedCharacters: gameProvider.usedCharacters,
              onDictionaryLookup: gameProvider.openDictionary,
              isCompactMode: true, // 컴팩트 모드 활성화
            ),
          ),
        ),
      ],
    );
  }

  /// 태블릿 화면용 혼합 레이아웃 구성 (600px <= 화면 너비 < 900px)
  Widget _buildTabletLayout(
      BuildContext context, GameProvider gameProvider, double screenWidth) {
    final cellSize = screenWidth < 720 ? 42.0 : 46.0;
    final trayHeight = cellSize * 4.5;

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
                child: ScoreDisplay(
                  score: gameProvider.score,
                  level: gameProvider.level,
                  lastWord: gameProvider.lastCompletedWord,
                  lastWordPoints: gameProvider.lastWordPoints,
                  isCompactMode: true, // 태블릿에서도 세로 배치로 변경
                ),
              ),
            ),

            // 폭탄 인디케이터 (오른쪽)
            Expanded(
              flex: 2,
              child: BombIndicator(
                gameProvider: gameProvider,
                isCompactMode: screenWidth < 720, // 작은 태블릿에서만 컴팩트 모드
              ),
            ),
          ],
        ),

        // 게임 영역 (중앙)
        Expanded(
          child: Row(
            children: [
              // 게임 그리드 (왼쪽)
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    // 게임 그리드
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GameGrid(
                        cellSize: cellSize,
                        gridPadding: 6.0,
                        autoSize: true, // 자동 크기 조정 활성화
                      ),
                    ),

                    // 블록 트레이 (화면 하단에 고정)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: BlockTray(
                        cellSize: cellSize - 4.0,
                        spacing: 6.0,
                        wordSuggestionsKey: wordSuggestionsKey,
                        isCompactMode: screenWidth < 720, // 작은 태블릿에서만 컴팩트 모드
                      ),
                    ),
                  ],
                ),
              ),

              // 추천 단어 영역 (오른쪽) - GlobalKey 사용하지 않음
              Expanded(
                flex: 1,
                child: WordSuggestions(
                  words: gameProvider.suggestedWordSet,
                  wordUsageCount: gameProvider.wordUsageCounts,
                  usedCharacters: gameProvider.usedCharacters,
                  onDictionaryLookup: gameProvider.openDictionary,
                  isCompactMode: false,
                ),
              ),
            ],
          ),
        ),
      ],
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
                        // 점수 디스플레이와 폭탄 인디케이터를 가로로 배치
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 점수 디스플레이 (왼쪽)
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ScoreDisplay(
                                  score: gameProvider.score,
                                  level: gameProvider.level,
                                  lastWord: gameProvider.lastCompletedWord,
                                  lastWordPoints: gameProvider.lastWordPoints,
                                  isCompactMode: false, // 데스크톱에서는 가로 배치 유지
                                ),
                              ),
                            ),

                            // 폭탄 인디케이터 (오른쪽)
                            Expanded(
                              flex: 1,
                              child: BombIndicator(gameProvider: gameProvider),
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

              // 추천 단어 영역 - GlobalKey 사용하지 않음
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: WordSuggestions(
                    words: gameProvider.suggestedWordSet,
                    wordUsageCount: gameProvider.wordUsageCounts,
                    usedCharacters: gameProvider.usedCharacters,
                    onDictionaryLookup: gameProvider.openDictionary,
                    isCompactMode: false,
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
