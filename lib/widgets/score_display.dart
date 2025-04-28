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
/// └─ Row (mainAxisAlignment: spaceAround) 또는 Column (isCompactMode가 true인 경우)
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
/// - `isCompactMode`: 컴팩트 모드 여부 (세로 배치)

import 'package:flutter/material.dart';

class ScoreDisplay extends StatelessWidget {
  final int score;
  final int level;
  final String lastWord;
  final int lastWordPoints;
  final bool isCompactMode;

  const ScoreDisplay({
    super.key,
    required this.score,
    required this.level,
    this.lastWord = '',
    this.lastWordPoints = 0,
    this.isCompactMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // 스크린 크기에 따른 동적 설정
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isVerySmallScreen = screenWidth < 320;

    // 작은 화면일 경우 더 작은 글꼴 크기 적용
    final titleFontSize = isVerySmallScreen
        ? 12.0
        : (isSmallScreen ? 13.0 : (isCompactMode ? 14.0 : 16.0));
    final scoreFontSize = isVerySmallScreen
        ? 16.0
        : (isSmallScreen ? 18.0 : (isCompactMode ? 20.0 : 24.0));
    final wordFontSize = isVerySmallScreen
        ? 12.0
        : (isSmallScreen ? 14.0 : (isCompactMode ? 16.0 : 18.0));
    final pointsFontSize = isVerySmallScreen
        ? 10.0
        : (isSmallScreen ? 11.0 : (isCompactMode ? 12.0 : 14.0));

    // 모바일에서 더 작은 패딩 적용
    final containerPadding = isCompactMode
        ? EdgeInsets.symmetric(
            vertical: isVerySmallScreen ? 4.0 : 6.0,
            horizontal: isVerySmallScreen ? 6.0 : 10.0,
          )
        : const EdgeInsets.all(12.0);

    // 컴팩트 모드에서 마진 적용 (여백을 조금 추가)
    final containerMargin = isCompactMode
        ? const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0)
        : const EdgeInsets.all(8.0);

    // 구분선 높이 조정
    final dividerHeight = isVerySmallScreen ? 28.0 : 34.0;

    // 모든 모드에서 Row 레이아웃 사용
    return Container(
      padding: containerPadding,
      margin: containerMargin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: isCompactMode ? 3 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isCompactMode
          ? Row(
              // 모바일 가로 레이아웃 (컴팩트 모드)
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 점수 섹션
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '점수',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 1), // 최소 간격 추가
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: scoreFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // 구분선
                Container(
                  height: dividerHeight,
                  width: 1,
                  color: Colors.grey.shade300,
                ),

                // 최근 완성 단어 섹션
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '최근',
                            style: TextStyle(
                              fontSize: titleFontSize - 1,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          if (lastWordPoints > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Text(
                                '+$lastWordPoints',
                                style: TextStyle(
                                  fontSize: pointsFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 1), // 최소 간격 추가
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: isVerySmallScreen ? 80 : 90,
                        ),
                        child: Text(
                          lastWord.isEmpty ? '-' : lastWord,
                          style: TextStyle(
                            fontSize: wordFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                // 구분선
                Container(
                  height: dividerHeight,
                  width: 1,
                  color: Colors.grey.shade300,
                ),

                // 레벨 섹션
                FittedBox(
                  // FittedBox로 감싸서 내용이 공간에 맞게 조정되도록 함
                  fit: BoxFit.scaleDown,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '레벨',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 1), // 최소 간격 추가
                      Text(
                        '$level',
                        style: TextStyle(
                          fontSize: isVerySmallScreen
                              ? scoreFontSize - 2
                              : scoreFontSize, // 작은 화면에서는 글꼴 크기 축소
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          // 일반 레이아웃 (데스크톱)
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 점수 섹션
                Column(
                  mainAxisSize: MainAxisSize.min, // 최소 크기 사용
                  children: [
                    Text(
                      '점수',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 2), // 최소 간격
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: scoreFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // 구분선
                Container(
                  height: dividerHeight,
                  width: 1,
                  color: Colors.grey.shade300,
                ),

                // 최근 완성 단어 섹션
                Column(
                  mainAxisSize: MainAxisSize.min, // 최소 크기 사용
                  children: [
                    Text(
                      '최근 단어',
                      style: TextStyle(
                        fontSize: titleFontSize - 2,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 2), // 최소 간격
                    Text(
                      lastWord.isEmpty ? '-' : lastWord,
                      style: TextStyle(
                        fontSize: wordFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (lastWordPoints > 0) const SizedBox(height: 2), // 최소 간격
                    if (lastWordPoints > 0)
                      Text(
                        '+$lastWordPoints',
                        style: TextStyle(
                          fontSize: pointsFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                  ],
                ),

                // 구분선
                Container(
                  height: dividerHeight,
                  width: 1,
                  color: Colors.grey.shade300,
                ),

                // 레벨 섹션
                Column(
                  mainAxisSize: MainAxisSize.min, // 최소 크기 사용
                  children: [
                    Text(
                      '레벨',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 2), // 최소 간격
                    Text(
                      '$level',
                      style: TextStyle(
                        fontSize: scoreFontSize,
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
