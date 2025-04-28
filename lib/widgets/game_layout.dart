import 'package:flutter/material.dart';
import 'mobile_game_layout.dart';
import 'desktop_game_layout.dart';
import 'word_suggestions.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        // 화면 크기에 따라 레이아웃 조정
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // 목표 가로세로 비율 설정 (9:16)
        const aspectRatio = 9 / 16;

        // 실제 화면에 맞는 게임 영역 크기 계산
        double gameWidth = screenWidth;
        double gameHeight = screenWidth / aspectRatio;

        // 세로가 화면을 벗어나면 높이 기준으로 다시 계산
        if (gameHeight > screenHeight) {
          gameHeight = screenHeight;
          gameWidth = screenHeight * aspectRatio;
        }

        // 게임 영역을 화면 중앙에 배치하는 컨테이너
        return Center(
          child: Container(
            width: gameWidth,
            height: gameHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: screenWidth < 900
                ? MobileGameLayout(
                    wordSuggestionsKey: wordSuggestionsKey,
                  )
                : DesktopGameLayout(
                    wordSuggestionsKey: wordSuggestionsKey,
                  ),
          ),
        );
      },
    );
  }
}
