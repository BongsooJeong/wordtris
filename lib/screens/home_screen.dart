import 'package:flutter/material.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildAnimatedTitle(),
        centerTitle: true,
        elevation: 4.0,
        backgroundColor: Colors.indigo.shade700,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.2),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 로고 또는 제목
                _buildLogo(),
                const SizedBox(height: 10),
                const Text(
                  '블록을 배치하여 단어를 만들어보세요!',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // 게임 시작 버튼
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GameScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    '게임 시작',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 설정 버튼
                OutlinedButton(
                  onPressed: () {
                    // TODO: 설정 화면 구현
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('설정 화면은 아직 구현되지 않았습니다.'),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    '설정',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 80),

                // 게임 설명
                const Text(
                  '게임 방법',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '1. 블록을 그리드로 드래그하여 배치합니다.\n'
                  '2. 가로나 세로로 한글 단어가 형성되면 해당 블록들이 사라집니다.\n'
                  '3. 가능한 많은 단어를 만들어 높은 점수를 획득하세요!',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 애니메이션 타이틀 위젯 생성
  Widget _buildAnimatedTitle() {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [
            Colors.purple,
            Colors.blue,
            Colors.lightBlueAccent,
            Colors.blue,
            Colors.purple,
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '워드',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
              shadows: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4.0,
                  offset: Offset(1.0, 1.0),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              // 그림자 효과
              Text(
                '트리스',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 4
                    ..color = Colors.indigo.shade900.withOpacity(0.3),
                  letterSpacing: 1.2,
                ),
              ),
              const Text(
                '트리스',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 큰 로고 위젯 생성
  Widget _buildLogo() {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [
            Colors.purple,
            Colors.blue,
            Colors.lightBlueAccent,
            Colors.blue,
            Colors.purple,
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          tileMode: TileMode.mirror,
        ).createShader(bounds);
      },
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '한국어',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  shadows: [
                    BoxShadow(
                      color: Colors.indigo.shade900.withOpacity(0.5),
                      blurRadius: 4.0,
                      offset: const Offset(1.0, 1.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '워드',
                style: TextStyle(
                  fontSize: 36.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                  shadows: [
                    BoxShadow(
                      color: Colors.indigo.shade900.withOpacity(0.5),
                      blurRadius: 4.0,
                      offset: const Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  // 그림자 효과
                  Text(
                    '트리스',
                    style: TextStyle(
                      fontSize: 36.0,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 6
                        ..color = Colors.indigo.shade900.withOpacity(0.3),
                      letterSpacing: 2.0,
                    ),
                  ),
                  Text(
                    '트리스',
                    style: TextStyle(
                      fontSize: 36.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2.0,
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4.0,
                          offset: const Offset(1.0, 1.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
