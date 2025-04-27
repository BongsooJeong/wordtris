import 'package:flutter/material.dart';
import '../models/block.dart';
import 'word_suggestions.dart';

/// 블록 문자 하이라이트 기능을 관리하는 클래스
class BlockHighlightHandler {
  final GlobalKey<WordSuggestionsState>? wordSuggestionsKey;

  BlockHighlightHandler({this.wordSuggestionsKey});

  /// 블록 문자를 하이라이트 (기능 비활성화)
  void highlightBlockCharacters(Block block, {bool clear = false}) {
    // 하이라이트 기능을 비활성화
    // 호환성을 위해 메서드는 유지
  }
}
