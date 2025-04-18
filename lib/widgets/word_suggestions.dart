import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 게임에서 추천 단어를 표시하는 위젯
class WordSuggestions extends StatelessWidget {
  final List<String> words;
  final Map<String, int> wordUsageCount;
  final Function? onRefresh;
  final Function(String)? onDictionaryLookup; // 사전 검색 콜백 함수 추가

  const WordSuggestions({
    super.key,
    required this.words,
    required this.wordUsageCount,
    this.onRefresh,
    this.onDictionaryLookup,
  });

  // 네이버 사전 URL 생성
  String getNaverDictionaryWebUrl(String word) {
    return 'https://dict.naver.com/search.dict?dicQuery=$word';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180, // 고정 너비
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
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '추천 단어',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () => onRefresh!(),
                  tooltip: '새로운 단어 세트',
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          Expanded(
            child: words.isEmpty
                ? const Center(
                    child: Text(
                      '추천 단어가 없습니다',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: words.length,
                    itemBuilder: (context, index) {
                      final word = words[index];
                      final isUsed = wordUsageCount.containsKey(word) &&
                          wordUsageCount[word]! > 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Card(
                          elevation: 0,
                          color: isUsed
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 0),
                            title: Text(
                              word,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isUsed
                                    ? Colors.green.shade800
                                    : Colors.black87,
                                decoration:
                                    isUsed ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.search,
                                color: Colors.blue,
                                size: 20,
                              ),
                              onPressed: () async {
                                // WordProcessor의 openDictionary 메서드 사용
                                if (onDictionaryLookup != null) {
                                  await onDictionaryLookup!(word);
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
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('사전을 열 수 없습니다: $e'),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              tooltip: '사전에서 검색',
                            ),
                          ),
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
