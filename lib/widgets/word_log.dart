import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/grid.dart';
import '../providers/game_provider.dart';

/// 성공한 단어들의 로그를 보여주는 위젯
class WordLog extends StatelessWidget {
  final List<Word> words;
  final ScrollController? scrollController;

  const WordLog({
    super.key, 
    required this.words,
    this.scrollController,
  });

  // 네이버 사전 URL 생성
  String getNaverDictionaryWebUrl(String word) {
    return 'https://dict.naver.com/search.dict?dicQuery=$word';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Text(
            '완성된 단어',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          Expanded(
            child: words.isEmpty 
                ? const Center(
                    child: Text(
                      '아직 완성된 단어가 없습니다',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController ?? ScrollController(),
                    itemCount: words.length,
                    itemBuilder: (context, index) {
                      final reversedIndex = words.length - 1 - index;
                      final word = words[reversedIndex];
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Card(
                          elevation: 0,
                          color: Colors.grey.shade100,
                          child: ListTile(
                            title: Text(
                              word.text,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 점수 표시
                                Text(
                                  '+${word.score}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // 사전 링크 아이콘
                                IconButton(
                                  icon: const Icon(
                                    Icons.search,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    // 사전 웹사이트 열기
                                    final url = getNaverDictionaryWebUrl(word.text);
                                    try {
                                      await launch(url);
                                    } catch (e) {
                                      // 오류 처리
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('사전을 열 수 없습니다: $e')),
                                      );
                                    }
                                  },
                                ),
                              ],
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