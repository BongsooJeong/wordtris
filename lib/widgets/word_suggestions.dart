import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 게임에서 추천 단어를 표시하는 위젯
class WordSuggestions extends StatefulWidget {
  final List<String>? words;
  final Map<String, int>? wordUsageCount;
  final Function(String)? onDictionaryLookup; // 사전 검색 콜백 함수 추가
  final Set<String>? usedCharacters; // 사용된 글자 목록 추가

  const WordSuggestions({
    super.key,
    required this.words,
    required this.wordUsageCount,
    this.onDictionaryLookup,
    this.usedCharacters, // 새 파라미터 추가
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
      width: 170, // 고정 너비를 180에서 170으로 줄임
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
      margin: const EdgeInsets.all(8), // 마진을 10에서 8로 줄임
      padding: const EdgeInsets.all(8), // 패딩을 12에서 8로 줄임
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
                : ListView.builder(
                    key: ValueKey(
                        'word_list_${filteredWords.hashCode}'), // 고유 키로 변경하여 목록 변경 시 강제 재구성
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filteredWords.length,
                    itemBuilder: (context, index) {
                      final word = filteredWords[index];
                      final isHighlighted = _wordContainsHighlightedChar(word);

                      return ListTile(
                        key: ValueKey('word_tile_$word'), // 개별 타일에도 키 추가
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        tileColor: isHighlighted ? Colors.blue.shade50 : null,
                        shape: isHighlighted
                            ? RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: BorderSide(
                                    color: Colors.blue.shade300, width: 1.5),
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
                                    fontWeight: widget.usedCharacters
                                                ?.contains(word[i]) ==
                                            true
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                    color: isHighlighted
                                        ? Colors.blue
                                            .shade700 // 하이라이트된 단어는 모든 글자가 파란색
                                        : (widget.usedCharacters
                                                    ?.contains(word[i]) ==
                                                true
                                            ? Colors
                                                .red.shade300 // 사용된 글자는 빨간색으로
                                            : Colors.black), // 미사용 글자는 검정색으로
                                    decoration: widget.usedCharacters
                                                ?.contains(word[i]) ==
                                            true
                                        ? TextDecoration
                                            .lineThrough // 사용된 글자는 취소선 추가
                                        : null,
                                    decorationColor: Colors.red.shade700,
                                    decorationThickness: 2.0,
                                    backgroundColor: widget.usedCharacters
                                                ?.contains(word[i]) ==
                                            true
                                        ? Colors
                                            .yellow.shade100 // 사용된 글자만 배경색 추가
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
                            // WordProcessor의 openDictionary 메서드 사용
                            if (widget.onDictionaryLookup != null) {
                              await widget.onDictionaryLookup!(word);
                            } else {
                              // 기본 구현(fallback): 네이버 사전 페이지 직접 호출
                              final url = getNaverDictionaryWebUrl(word);
                              try {
                                await launchUrl(
                                  Uri.parse(url),
                                  mode: LaunchMode.externalApplication,
                                );
                              } catch (e) {
                                // 오류 처리
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('사전을 열 수 없습니다: $e'),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          tooltip: '사전에서 검색',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
