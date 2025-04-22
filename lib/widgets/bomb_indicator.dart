import 'package:flutter/material.dart';
import '../providers/game_provider.dart';

/// 폭탄 생성 상태를 표시하는 위젯
class BombIndicator extends StatelessWidget {
  final GameProvider gameProvider;
  final bool isCompactMode; // 모바일 뷰를 위한 컴팩트 모드

  const BombIndicator({
    Key? key,
    required this.gameProvider,
    this.isCompactMode = false, // 기본값은 일반 모드
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 폭탄 생성까지 남은 턴 수 계산 (3의 배수마다 생성)
    int clearedWords = gameProvider.wordClearCount;
    int remainingTurns = 3 - (clearedWords % 3);
    bool bombActive = remainingTurns == 0 || gameProvider.bombGenerated;

    // 화면 크기 확인
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isVerySmallScreen = screenWidth < 320;

    // 상태 텍스트 및 색상 설정 (화면 크기에 따라 다르게)
    String statusText = bombActive
        ? '💣 폭탄 준비!'
        : isCompactMode
            ? isVerySmallScreen
                ? '폭탄 준비중'
                : '단어 3개 후 폭탄'
            : isSmallScreen
                ? '단어 3개 완성 후 폭탄 등장'
                : '단어 3개 완성 후 폭탄이 나타납니다';

    Color borderColor = bombActive ? Colors.red : Colors.orange.shade300;
    Color bgColor = bombActive ? Colors.red.shade50 : Colors.white;
    Color textColor = bombActive ? Colors.red.shade700 : Colors.black87;

    // 가장 컴팩트한 디자인 (컴팩트 모드 + 매우 작은 화면)
    if (isCompactMode && isVerySmallScreen) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
        margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: borderColor,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              bombActive ? Icons.warning_amber : Icons.info_outline,
              color: bombActive ? Colors.red : Colors.orange.shade700,
              size: 12,
            ),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              '($clearedWords)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      );
    }

    // 컴팩트 모드 디자인 (일반 작은 화면)
    if (isCompactMode) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
        margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 6.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: borderColor,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              bombActive ? Icons.warning_amber : Icons.info_outline,
              color: bombActive ? Colors.red : Colors.orange.shade700,
              size: 14,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(color: Colors.blue.shade300, width: 0.8),
              ),
              child: Text(
                '$clearedWords',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 일반 모드에서 작은 화면 처리
    if (isSmallScreen) {
      // 일반 작은 화면 디자인
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              bombActive ? Icons.warning_amber : Icons.info_outline,
              color: bombActive ? Colors.red : Colors.orange.shade700,
              size: 18,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '($clearedWords)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      );
    }

    // 원래 디자인 (일반 화면)
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                bombActive ? Icons.warning_amber : Icons.info_outline,
                color: bombActive ? Colors.red : Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: Colors.blue.shade300, width: 1.0),
            ),
            child: Text(
              '총 완성 단어: $clearedWords',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
