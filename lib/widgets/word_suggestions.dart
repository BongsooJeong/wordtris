import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 게임에서 추천 단어를 표시하는 위젯
class WordSuggestions extends StatefulWidget {
  final List<String>? words;
  final Map<String, int>? wordUsageCount;
  final Function(String)? onDictionaryLookup; // 사전 검색 콜백 함수 추가
  final Set<String>? usedCharacters; // 사용된 글자 목록 추가
  final bool isCompactMode; // 모바일 뷰를 위한 컴팩트 모드 추가

  const WordSuggestions({
    super.key,
    required this.words,
    required this.wordUsageCount,
    this.onDictionaryLookup,
    this.usedCharacters,
    this.isCompactMode = false, // 기본값은 false
  });

  @override
  State<WordSuggestions> createState() => WordSuggestionsState();
}

class WordSuggestionsState extends State<WordSuggestions> {
  // 현재 하이라이트할 글자 목록
  Set<String> _highlightedCharacters = {};

  // 단어가 완전히 사용되었는지 확인하는 헬퍼 메서드
  bool _isWordFullyUsed(String word) {
    if (widget.usedCharacters == null) return false;

    // 단어의 모든 글자가 사용되었는지 확인
    for (int i = 0; i < word.length; i++) {
      if (!widget.usedCharacters!.contains(word[i])) {
        return false; // 한 글자라도 사용되지 않았다면 false 반환
      }
    }
    return true; // 모든 글자가 사용되었다면 true 반환
  }

  // 표시할 단어 목록을 필터링하는 메서드
  List<String> _getFilteredWords() {
    if (widget.words == null) return [];

    // 모든 글자가 사용된 단어를 필터링하여 제외
    return widget.words!.where((word) => !_isWordFullyUsed(word)).toList();
  }

  // 네이버 사전 URL 생성
  String getNaverDictionaryWebUrl(String word) {
    return 'https://dict.naver.com/search.dict?dicQuery=$word';
  }

  // 단어에 하이라이트할 글자가 포함되어 있는지 확인
  bool _wordContainsHighlightedChar(String word) {
    if (_highlightedCharacters.isEmpty) return false;

    for (var char in _highlightedCharacters) {
      if (word.contains(char)) {
        return true;
      }
    }
    return false;
  }

  // 외부에서 호출할 하이라이트 설정 메서드
  void setHighlightedCharacters(Set<String> characters) {
    if (!mounted) return;

    setState(() {
      _highlightedCharacters = Set.from(characters);
    });
  }

  // 하이라이트 제거 메서드
  void clearHighlights() {
    if (!mounted) return;

    setState(() {
      _highlightedCharacters.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 표시할 필터링된 단어 목록 가져오기
    final filteredWords = _getFilteredWords();

    return Container(
      width:
          widget.isCompactMode ? double.infinity : 170, // 컴팩트 모드에서는 가로 전체 너비 사용
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '추천 단어',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 4),
          const Divider(),
          Expanded(
            child: filteredWords.isEmpty
                ? const Center(
                    child: Text(
                      '표시할 단어가 없습니다',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  )
                : widget.isCompactMode
                    ? _buildCompactWordList(filteredWords)
                    : _buildNormalWordList(filteredWords),
          ),
        ],
      ),
    );
  }

  // 일반 모드의 단어 목록 (세로 스크롤)
  Widget _buildNormalWordList(List<String> filteredWords) {
    return ListView.builder(
      key: ValueKey('word_list_${filteredWords.hashCode}'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: filteredWords.length,
      itemBuilder: (context, index) {
        final word = filteredWords[index];
        final isHighlighted = _wordContainsHighlightedChar(word);

        return ListTile(
          key: ValueKey('word_tile_$word'),
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          tileColor: isHighlighted ? Colors.blue.shade50 : null,
          shape: isHighlighted
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: Colors.blue.shade300, width: 1.5),
                )
              : null,
          title: RichText(
            text: TextSpan(
              children: [
                for (int i = 0; i < word.length; i++)
                  TextSpan(
                    text: word[i],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          widget.usedCharacters?.contains(word[i]) == true
                              ? FontWeight.normal
                              : FontWeight.bold,
                      color: isHighlighted
                          ? Colors.blue.shade700
                          : (widget.usedCharacters?.contains(word[i]) == true
                              ? Colors.red.shade300
                              : Colors.black),
                      decoration:
                          widget.usedCharacters?.contains(word[i]) == true
                              ? TextDecoration.lineThrough
                              : null,
                      decorationColor: Colors.red.shade700,
                      decorationThickness: 2.0,
                      backgroundColor:
                          widget.usedCharacters?.contains(word[i]) == true
                              ? Colors.yellow.shade100
                              : null,
                    ),
                  ),
              ],
            ),
          ),
          trailing: IconButton(
            icon: const Icon(
              Icons.search,
              color: Colors.blue,
              size: 16,
            ),
            onPressed: () async {
              if (widget.onDictionaryLookup != null) {
                await widget.onDictionaryLookup!(word);
              }
            },
            tooltip: '사전 검색',
          ),
        );
      },
    );
  }

  // 컴팩트 모드의 단어 목록 (가로 스크롤)
  Widget _buildCompactWordList(List<String> filteredWords) {
    return ListView.builder(
      key: ValueKey('compact_word_list_${filteredWords.hashCode}'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      itemCount: filteredWords.length,
      itemBuilder: (context, index) {
        final word = filteredWords[index];
        final isHighlighted = _wordContainsHighlightedChar(word);

        return Card(
          color: isHighlighted ? Colors.blue.shade50 : Colors.grey.shade50,
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isHighlighted
                ? BorderSide(color: Colors.blue.shade300, width: 1.5)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: () async {
              if (widget.onDictionaryLookup != null) {
                await widget.onDictionaryLookup!(word);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        for (int i = 0; i < word.length; i++)
                          TextSpan(
                            text: word[i],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  widget.usedCharacters?.contains(word[i]) ==
                                          true
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                              color: isHighlighted
                                  ? Colors.blue.shade700
                                  : (widget.usedCharacters?.contains(word[i]) ==
                                          true
                                      ? Colors.red.shade300
                                      : Colors.black),
                              decoration:
                                  widget.usedCharacters?.contains(word[i]) ==
                                          true
                                      ? TextDecoration.lineThrough
                                      : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.search, size: 14, color: Colors.blue),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
