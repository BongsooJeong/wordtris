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
        // 반응형 브레이크포인트 구분을 더 상세하게 설정
        final screenWidth = constraints.maxWidth;

        // 모바일/태블릿: 0-899px, 데스크톱: 900px+
        if (screenWidth < 900) {
          // MobileGameLayout 위젯 반환
          return MobileGameLayout(
            wordSuggestionsKey: wordSuggestionsKey,
          );
        } else {
          // DesktopGameLayout 위젯 반환
          return DesktopGameLayout(
            wordSuggestionsKey: wordSuggestionsKey,
          );
        }
      },
    );
  }
}
