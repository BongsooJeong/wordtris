import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/block.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/game_grid.dart';
import '../widgets/block_tray.dart';
import '../widgets/score_display.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// 게임 화면 위젯
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // 검색 패턴
  String _searchPattern = '';
  // 단어 제안 목록
  List<String> _wordSuggestions = [];
  // 디바운스 타이머
  Timer? _debounceTimer;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 게임 초기화
    Future.microtask(() {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      gameProvider.initialize();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // 검색 패턴 변경시 호출
  void _onSearchChanged(String value) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    setState(() {
      _searchPattern = value;
    });

    if (value.length < 2) {
      setState(() {
        _wordSuggestions = [];
      });
      return;
    }

    // 디바운싱 적용 (타이핑 중단 후 검색)
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _getWordSuggestions(value);
    });
  }

  // 단어 제안 가져오기
  Future<void> _getWordSuggestions(String pattern) async {
    if (pattern.length < 2) return;

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final suggestions = await gameProvider.getWordSuggestions(pattern);

    setState(() {
      _wordSuggestions = suggestions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          if (gameProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (gameProvider.errorMessage.isNotEmpty) {
            return Center(child: Text(gameProvider.errorMessage));
          }

        // 게임 화면 구성
        return Scaffold(
          appBar: AppBar(
            title: const Text('워드트리스'),
            centerTitle: true,
            actions: [
              // 새로고침 버튼
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  Provider.of<GameProvider>(context, listen: false).restartGame();
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                  children: [
                    // 점수 디스플레이
                    ScoreDisplay(
                      score: gameProvider.score,
                      level: gameProvider.level,
                    ),
                    
                    // 폭탄 인디케이터 추가
                    _buildBombIndicator(gameProvider),
                    
                    // 게임 그리드
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GameGrid(
                          cellSize: 32.0,
                          gridPadding: 4.0,
                        ),
                      ),
                    ),
                    
                  // 블록 트레이를 위한 공간 확보
                  SizedBox(height: 150),
                      ],
                    ),
              
              // 블록 트레이 (화면 하단에 고정)
              BlockTray(
                cellSize: 40.0,
                spacing: 8.0,
                        ),
                      ],
                    ),
          );
        },
    );
  }

  // 폭탄 인디케이터 위젯
  Widget _buildBombIndicator(GameProvider gameProvider) {
    // 폭탄 생성까지 남은 턴 수 계산 (5의 배수마다 생성)
    int clearedWords = gameProvider.wordClearCount;
    int remainingTurns = 5 - (clearedWords % 5);
    if (remainingTurns == 5 && clearedWords > 0 && gameProvider.bombGenerated) {
      remainingTurns = 0;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
      margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: remainingTurns == 0 ? Colors.red : Colors.orange.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 현재 클리어 턴 수
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
              const SizedBox(width: 4),
              Text(
                '클리어 턴: $clearedWords',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          // 폭탄 생성 정보
          Row(
            children: [
              Icon(Icons.fireplace, 
                color: remainingTurns == 0 ? Colors.red : Colors.grey, 
                size: 20
              ),
              const SizedBox(width: 4),
              remainingTurns == 0
                ? const Text(
                    '폭탄 생성됨!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  )
                : Text(
                    '폭탄까지 $remainingTurns턴',
                    style: const TextStyle(
                      fontSize: 14,
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
