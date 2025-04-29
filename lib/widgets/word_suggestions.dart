import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 게임에서 추천 단어를 표시하는 위젯
class WordSuggestions extends StatefulWidget {
  final List<String>? words;
  final Map<String, int>? wordUsageCount;
  final Function(String)? onDictionaryLookup; // 사전 검색 콜백 함수 추가
  final Set<String>? usedCharacters; // 사용된 글자 목록 추가
  final bool isCompactMode; // 모바일 뷰를 위한 컴팩트 모드 추가
  final bool initiallyExpanded; // 초기에 펼쳐진 상태인지 여부

  const WordSuggestions({
    super.key,
    required this.words,
    required this.wordUsageCount,
    this.onDictionaryLookup,
    this.usedCharacters,
    this.isCompactMode = false, // 기본값은 false
    this.initiallyExpanded = false, // 기본값은 접힌 상태
  });

  @override
  State<WordSuggestions> createState() => WordSuggestionsState();
}

class WordSuggestionsState extends State<WordSuggestions> {
  // 현재 하이라이트할 글자 목록
  Set<String> _highlightedCharacters = {};
  // 위젯 확장/축소 상태
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

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

  // 확장/축소 상태 전환
  void toggleExpanded() {
    if (!mounted) return;

    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 표시할 필터링된 단어 목록 가져오기
    final filteredWords = _getFilteredWords();

    // 화면 크기 확인
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isVerySmallScreen = screenWidth < 320;
    final isDesktopMode = screenWidth >= 900;

    // 데스크톱 모드에서 확장된 경우 오버레이 스타일 적용
    final desktopExpandedStyle = isDesktopMode && _isExpanded;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(desktopExpandedStyle ? 0.3 : 0.1),
            blurRadius: desktopExpandedStyle ? 10 : 3,
            spreadRadius: desktopExpandedStyle ? 3 : 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: desktopExpandedStyle
            ? Border.all(color: Colors.blue.shade300, width: 1.5)
            : null,
      ),
      margin: widget.isCompactMode
          ? const EdgeInsets.symmetric(vertical: 2.0)
          : const EdgeInsets.all(8),
      padding: widget.isCompactMode
          ? const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0)
          : const EdgeInsets.all(8),
      child: Material(
        color: desktopExpandedStyle
            ? Colors.blue.shade50.withOpacity(0.8) // 확장 시 배경색 변경
            : Colors.transparent,
        elevation: desktopExpandedStyle ? 8 : 0,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 데스크톱에서는 최소 크기 사용
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.isCompactMode && isVerySmallScreen
              ? [
                  // 매우 작은 화면에서는 최소한의 요소만 표시
                  InkWell(
                    onTap: toggleExpanded,
                    child: Row(
                      children: [
                        const Text(
                          '추천 단어',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),

                  // 확장/축소 가능한 내용 부분
                  if (_isExpanded)
                    SizedBox(
                      height: 120,
                      child: filteredWords.isEmpty
                          ? const Center(
                              child: Text(
                                '표시할 단어가 없습니다',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : _buildCompactWordList(
                              filteredWords, isSmallScreen, isVerySmallScreen),
                    ),
                ]
              : [
                  // 헤더 부분 (제목 + 확장/축소 버튼)
                  InkWell(
                    onTap: toggleExpanded,
                    child: Row(
                      children: [
                        Text(
                          '추천 단어',
                          style: TextStyle(
                            fontSize: isVerySmallScreen
                                ? 12
                                : (isSmallScreen ? 13 : 14),
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: isVerySmallScreen ? 16 : 18,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),

                  // 작은 화면에서는 구분선 제거
                  if (!isVerySmallScreen) const SizedBox(height: 2),

                  if (!isVerySmallScreen)
                    const Divider(height: 4, thickness: 0.5),

                  // 확장/축소 가능한 내용 부분
                  if (_isExpanded)
                    GestureDetector(
                      // 추천 단어 목록 내부 클릭 시 이벤트 버블링 방지
                      onTap: () {
                        // 이벤트 소비
                      },
                      child: Container(
                        // 데스크톱 모드에서는 더 큰 높이 제공
                        height: widget.isCompactMode
                            ? (isVerySmallScreen ? 120 : 160)
                            : (isDesktopMode ? 300 : 240),
                        decoration: desktopExpandedStyle
                            ? BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              )
                            : null,
                        child: filteredWords.isEmpty
                            ? Center(
                                child: Text(
                                  '표시할 단어가 없습니다',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: isVerySmallScreen ? 12 : 14,
                                  ),
                                ),
                              )
                            : widget.isCompactMode
                                ? _buildCompactWordList(filteredWords,
                                    isSmallScreen, isVerySmallScreen)
                                : _buildNormalWordList(filteredWords),
                      ),
                    ),
                ],
        ),
      ),
    );
  }

  // 일반 모드의 단어 목록 (세로 스크롤)
  Widget _buildNormalWordList(List<String> filteredWords) {
    return ScrollConfiguration(
      // 스크롤바 항상 보이게 설정
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: true,
        overscroll: true,
        physics: const ClampingScrollPhysics(),
      ),
      child: ListView.builder(
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
      ),
    );
  }

  // 컴팩트 모드의 단어 목록 (가로 스크롤)
  Widget _buildCompactWordList(
      List<String> filteredWords, bool isSmallScreen, bool isVerySmallScreen) {
    return ScrollConfiguration(
      // 스크롤바 항상 보이게 설정
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: true,
        overscroll: true,
        physics: const ClampingScrollPhysics(),
      ),
      child: ListView.builder(
        key: ValueKey('compact_word_list_${filteredWords.hashCode}'),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          vertical: isVerySmallScreen ? 1 : 2,
          horizontal: isVerySmallScreen ? 1 : 2,
        ),
        itemCount: filteredWords.length,
        itemBuilder: (context, index) {
          final word = filteredWords[index];
          final isHighlighted = _wordContainsHighlightedChar(word);

          // 작은 화면에서는 더 작은 카드 크기 사용
          final verticalPadding =
              isVerySmallScreen ? 2.0 : (isSmallScreen ? 3.0 : 4.0);
          final horizontalPadding =
              isVerySmallScreen ? 3.0 : (isSmallScreen ? 5.0 : 8.0);
          final wordFontSize =
              isVerySmallScreen ? 10.0 : (isSmallScreen ? 11.0 : 12.0);
          final iconSize =
              isVerySmallScreen ? 8.0 : (isSmallScreen ? 9.0 : 10.0);

          return Card(
            color: isHighlighted ? Colors.blue.shade50 : Colors.grey.shade50,
            elevation: isVerySmallScreen ? 0 : 1,
            margin: EdgeInsets.symmetric(horizontal: isVerySmallScreen ? 1 : 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: isHighlighted
                  ? BorderSide(color: Colors.blue.shade300, width: 1.0)
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: () async {
                if (widget.onDictionaryLookup != null) {
                  await widget.onDictionaryLookup!(word);
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: verticalPadding),
                // SizedBox 높이를 더 작게 조정
                child: SizedBox(
                  height: isVerySmallScreen ? 24 : (isSmallScreen ? 28 : 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: RichText(
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              for (int i = 0; i < word.length; i++)
                                TextSpan(
                                  text: word[i],
                                  style: TextStyle(
                                    fontSize: wordFontSize,
                                    fontWeight: widget.usedCharacters
                                                ?.contains(word[i]) ==
                                            true
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                    color: isHighlighted
                                        ? Colors.blue.shade700
                                        : (widget.usedCharacters
                                                    ?.contains(word[i]) ==
                                                true
                                            ? Colors.red.shade300
                                            : Colors.black),
                                    decoration: widget.usedCharacters
                                                ?.contains(word[i]) ==
                                            true
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isVerySmallScreen ? 1 : 2),
                      Icon(Icons.search, size: iconSize, color: Colors.blue),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
