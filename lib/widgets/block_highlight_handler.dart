import 'package:flutter/material.dart';
import '../models/block.dart';
import 'word_suggestions.dart';

/// 블록 문자 하이라이트 기능을 관리하는 클래스
class BlockHighlightHandler {
  final GlobalKey<WordSuggestionsState>? wordSuggestionsKey;

  BlockHighlightHandler({this.wordSuggestionsKey});

  /// 블록 문자를 하이라이트
  void highlightBlockCharacters(Block block, {bool clear = false}) {
    if (wordSuggestionsKey?.currentState == null) return;

    if (clear) {
      wordSuggestionsKey!.currentState!.clearHighlights();
    } else {
      final characters = Set<String>.from(block.characters);
      wordSuggestionsKey!.currentState!.setHighlightedCharacters(characters);
    }
  }
}
