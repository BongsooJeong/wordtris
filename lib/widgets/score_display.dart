/// ScoreDisplay 위젯
///
/// 게임의 점수와 레벨을 표시하는 위젯입니다.
///
/// ## 레이아웃 구조
/// ```
/// Container (패딩: 12.0, 마진: 8.0)
/// ├─ 배경: 흰색
/// ├─ 테두리: 둥근 모서리 (8.0)
/// ├─ 그림자: 검은색 12% (블러: 4, y-오프셋: 2)
/// │
/// └─ Row (mainAxisAlignment: spaceAround)
///    ├─ Column (점수 섹션)
///    │  ├─ Text ("점수")
///    │  │  └─ 스타일: 파란색, 16pt, 굵게
///    │  └─ Text (점수 값)
///    │     └─ 스타일: 검은색, 24pt, 굵게
///    │
///    ├─ Container (구분선)
///    │  └─ 높이: 40, 너비: 1, 색상: 회색 30%
///    │
///    ├─ Column (최근 단어 섹션)
///    │  ├─ Text ("최근 단어")
///    │  │  └─ 스타일: 빨간색, 16pt, 굵게
///    │  ├─ Text (단어 값)
///    │  │  └─ 스타일: 검은색, 18pt, 굵게
///    │  └─ Text (단어 점수 값)
///    │     └─ 스타일: 검은색, 14pt, 굵게
///    │
///    ├─ Container (구분선)
///    │  └─ 높이: 40, 너비: 1, 색상: 회색 30%
///    │
///    └─ Column (레벨 섹션)
///       ├─ Text ("레벨")
///       │  └─ 스타일: 초록색, 16pt, 굵게
///       └─ Text (레벨 값)
///          └─ 스타일: 검은색, 24pt, 굵게
/// ```
///
/// ## 매개변수
/// - `score`: 표시할 점수 값
/// - `level`: 표시할 레벨 값
/// - `lastWord`: 최근 완성한 단어
/// - `lastWordPoints`: 최근 완성한 단어의 점수

import 'package:flutter/material.dart';

class ScoreDisplay extends StatelessWidget {
  final int score;
  final int level;
  final String lastWord;
  final int lastWordPoints;

  const ScoreDisplay({
    super.key,
    required this.score,
    required this.level,
    this.lastWord = '',
    this.lastWordPoints = 0,
  });

  @override
  Widget build(BuildContext context) {
    // 화면 크기에 따라 레이아웃 조정
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: isSmallScreen
          // 세로 레이아웃 (모바일)
          ? Column(
              children: [
                // 점수 섹션
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '점수: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // 구분선
                Divider(
                  height: 16,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),

                // 최근 완성 단어 섹션
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '최근 단어: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        lastWord.isEmpty ? '-' : lastWord,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (lastWordPoints > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(
                            '+$lastWordPoints',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 구분선
                Divider(
                  height: 16,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),

                // 레벨 섹션
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '레벨: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '$level',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          // 가로 레이아웃 (기존)
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 점수 섹션
                Column(
                  children: [
                    const Text(
                      '점수',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // 구분선
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.shade300,
                ),

                // 최근 완성 단어 섹션
                Column(
                  children: [
                    const Text(
                      '최근 단어',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      lastWord.isEmpty ? '-' : lastWord,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (lastWordPoints > 0)
                      Text(
                        '+$lastWordPoints',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                  ],
                ),

                // 구분선
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.shade300,
                ),

                // 레벨 섹션
                Column(
                  children: [
                    const Text(
                      '레벨',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '$level',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
