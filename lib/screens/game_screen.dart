import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/block.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/game_grid.dart';
import '../widgets/block_tray.dart';
import '../widgets/score_display.dart';
import '../widgets/word_suggestions.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// WordTris 게임의 메인 화면을 구성하는 위젯 API 문서
///
/// [GameScreen] 클래스
/// 게임의 주요 화면 구성과 상태 관리를 담당하는 StatefulWidget
///
/// 주요 기능:
/// - 게임 화면 UI 구성
/// - 게임 상태 관리
/// - 단어 검색 및 제안 기능
/// - 폭탄 생성 및 표시
///
/// 상태 관리:
/// - initState(): void
///   게임 초기화 및 상태 설정
///
/// - dispose(): void
///   리소스 정리 및 타이머 취소
///
/// 검색 관련 메서드:
/// - _onSearchChanged(String value): void
///   검색어 변경 시 디바운싱 처리
///
/// - _getWordSuggestions(String pattern): Future<void>
///   입력된 패턴에 맞는 단어 제안 가져오기
///
/// UI 구성 메서드:
/// - build(BuildContext context): Widget
///   전체 게임 화면 구성
///
/// - _buildBombIndicator(GameProvider gameProvider): Widget
///   폭탄 생성 상태 표시 위젯 구성

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

  // WordSuggestions 위젯의 GlobalKey 추가
  final GlobalKey<WordSuggestionsState> _wordSuggestionsKey =
      GlobalKey<WordSuggestionsState>();

  @override
  void initState() {
    super.initState();
    // 게임 초기화는 앱 시작 시 한 번만 실행
    print('🎮 GameScreen.initState() - 게임 초기화 시작');

    // 초기화가 이미 진행 중일 수 있으므로 microtask 사용하지 않음
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    // initState에서는 GameProvider.initialize()를 직접 호출하지 않음
    // GameProvider 생성자에서 이미 _initializeGame()이 호출됨
    print('📱 GameScreen 초기화 완료 - GameProvider는 자동 초기화됨');
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
                  Provider.of<GameProvider>(context, listen: false)
                      .restartGame();
                },
              ),
            ],
          ),
          body: Row(
            children: [
              // 메인 게임 영역
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // 점수 디스플레이
                        ScoreDisplay(
                          score: gameProvider.score,
                          level: gameProvider.level,
                          lastWord: gameProvider.lastCompletedWord,
                          lastWordPoints: gameProvider.lastWordPoints,
                        ),

                        // 폭탄 인디케이터 추가
                        _buildBombIndicator(gameProvider),

                        // 게임 그리드
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: GameGrid(
                              cellSize: 48.0,
                              gridPadding: 4.0,
                            ),
                          ),
                        ),

                        // 블록 트레이를 위한 공간 확보
                        const SizedBox(height: 150),
                      ],
                    ),

                    // 블록 트레이 (화면 하단에 고정)
                    BlockTray(
                      cellSize: 40.0,
                      spacing: 8.0,
                      wordSuggestionsKey: _wordSuggestionsKey,
                    ),
                  ],
                ),
              ),

              // 추천 단어 영역
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: WordSuggestions(
                    key: _wordSuggestionsKey,
                    words: gameProvider.suggestedWordSet,
                    wordUsageCount: gameProvider.wordUsageCounts,
                    usedCharacters: gameProvider.usedCharacters,
                    onDictionaryLookup: gameProvider.openDictionary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 폭탄 인디케이터 위젯
  Widget _buildBombIndicator(GameProvider gameProvider) {
    // 폭탄 생성까지 남은 턴 수 계산 (3의 배수마다 생성)
    int clearedWords = gameProvider.wordClearCount;
    int remainingTurns = 3 - (clearedWords % 3);
    bool bombActive = remainingTurns == 0 || gameProvider.bombGenerated;

    // 상태 텍스트 및 색상 설정
    String statusText = bombActive ? '💣 폭탄이 준비되었습니다!' : '단어 3개 완성 후 폭탄이 나타납니다';

    Color borderColor = bombActive ? Colors.red : Colors.orange.shade300;
    Color bgColor = bombActive ? Colors.red.shade50 : Colors.white;
    Color textColor = bombActive ? Colors.red.shade700 : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            bombActive ? Icons.warning_amber : Icons.info_outline,
            color: bombActive ? Colors.red : Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            margin: const EdgeInsets.only(left: 8.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: Colors.blue.shade300, width: 1.0),
            ),
            child: Text(
              '총 완성 단어: $clearedWords',
              style: TextStyle(
                fontSize: 14,
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
