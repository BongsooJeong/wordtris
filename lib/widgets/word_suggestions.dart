import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 게임에서 추천 단어를 표시하는 위젯
class WordSuggestions extends StatefulWidget {
  final List<String>? words;
  final Map<String, int>? wordUsageCount;
  final void Function(bool replaceAll)? onRefresh;
  final Function(String)? onDictionaryLookup; // 사전 검색 콜백 함수 추가

  const WordSuggestions({
    super.key,
    required this.words,
    required this.wordUsageCount,
    this.onRefresh,
    this.onDictionaryLookup,
  });

  @override
  State<WordSuggestions> createState() => _WordSuggestionsState();
}

class _WordSuggestionsState extends State<WordSuggestions> {
  // 네이버 사전 URL 생성
  String getNaverDictionaryWebUrl(String word) {
    return 'https://dict.naver.com/search.dict?dicQuery=$word';
  }

  void _showRefreshMenu(BuildContext context, Offset position) {
    print('📱 WordSuggestions 새로고침 메뉴 표시');
    final Future<String?> resultFuture = showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: const [
        PopupMenuItem<String>(
          value: 'add',
          child: Row(
            children: [
              Icon(Icons.add, size: 16),
              SizedBox(width: 8),
              Text('새 단어 추가'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'replace',
          child: Row(
            children: [
              Icon(Icons.refresh, size: 16),
              SizedBox(width: 8),
              Text('단어 전체 교체'),
            ],
          ),
        ),
      ],
    );

    resultFuture.then((result) {
      // 컨텍스트 메뉴 항목을 표시합니다.
      if (result != null && widget.onRefresh != null) {
        print('📱 선택된 메뉴: $result');
        if (result == 'add') {
          print('📱 새 단어 추가 요청');
          widget.onRefresh!(false); // false는 단어 추가
        } else if (result == 'replace') {
          print('📱 단어 전체 교체 요청');
          widget.onRefresh!(true); // true는 전체 단어 교체
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // print('📱 WordSuggestions.build() 호출');
    // print('📋 단어 목록 수: ${widget.words?.length ?? 0}개');
    // print('📋 단어 사용 횟수 항목: ${widget.wordUsageCount?.length ?? 0}개');
    // print('📋 단어 목록: ${widget.words}');

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '추천 단어',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              if (widget.onRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: '단어 갱신',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    // 현재 버튼의 위치를 기준으로 메뉴 표시
                    final RenderBox button =
                        context.findRenderObject() as RenderBox;
                    final Offset position = button.localToGlobal(Offset.zero);
                    _showRefreshMenu(context, position);
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(),
          Expanded(
            child: widget.words == null || widget.words!.isEmpty
                ? const Center(
                    child: Text(
                      '추천 단어가 없습니다',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    key: ValueKey(
                        'word_list_${widget.words.hashCode}'), // 고유 키로 변경하여 목록 변경 시 강제 재구성
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: widget.words!.length,
                    itemBuilder: (context, index) {
                      final word = widget.words![index];
                      final isUsed =
                          widget.wordUsageCount?.containsKey(word) == true &&
                              widget.wordUsageCount![word]! > 0;

                      return ListTile(
                        key: ValueKey('word_tile_$word'), // 개별 타일에도 키 추가
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        leading: Icon(
                          isUsed ? Icons.check_circle : Icons.circle_outlined,
                          size: 16,
                          color: isUsed ? Colors.green : Colors.grey,
                        ),
                        title: Text(
                          word,
                          style: TextStyle(
                            fontWeight:
                                isUsed ? FontWeight.normal : FontWeight.bold,
                            fontSize: 14,
                            color:
                                isUsed ? Colors.green.shade800 : Colors.black87,
                            decoration:
                                isUsed ? TextDecoration.lineThrough : null,
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
