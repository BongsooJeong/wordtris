import 'package:flutter/material.dart';
import '../providers/game_provider.dart';

/// 폭탄 생성 상태를 표시하는 위젯
class BombIndicator extends StatelessWidget {
  final GameProvider gameProvider;

  const BombIndicator({
    Key? key,
    required this.gameProvider,
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

    // 상태 텍스트 및 색상 설정 (작은 화면에서는 더 짧은 텍스트)
    String statusText = bombActive
        ? '💣 폭탄 준비!'
        : isSmallScreen
            ? '단어 3개 완성 후 폭탄 등장'
            : '단어 3개 완성 후 폭탄이 나타납니다';

    Color borderColor = bombActive ? Colors.red : Colors.orange.shade300;
    Color bgColor = bombActive ? Colors.red.shade50 : Colors.white;
    Color textColor = bombActive ? Colors.red.shade700 : Colors.black87;

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
      child: isSmallScreen
          // 작은 화면에서는 단순화된 레이아웃
          ? Row(
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
            )
          // 일반 화면에서는 기존 레이아웃
          : Wrap(
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6.0, vertical: 2.0),
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
