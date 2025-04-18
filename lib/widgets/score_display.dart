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

import 'package:flutter/material.dart';

class ScoreDisplay extends StatelessWidget {
  final int score;
  final int level;

  const ScoreDisplay({
    super.key,
    required this.score,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
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
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.shade300,
          ),
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
