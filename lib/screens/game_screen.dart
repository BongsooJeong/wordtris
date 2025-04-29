import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/block.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../widgets/animated_title.dart';
import '../widgets/game_layout.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../widgets/word_suggestions.dart';

/// WordTris 게임의 메인 화면을 구성하는 위젯 API 문서
///
/// [GameScreen] 클래스
/// 게임의 주요 화면 구성과 상태 관리를 담당하는 StatefulWidget
///
/// 주요 기능:
/// - 게임 화면 UI 구성
/// - 게임 상태 관리
/// - 단어 검색 및 제안 기능
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

  // 게임 종료 대화상자가 표시 중인지 여부를 추적
  bool _isShowingEndDialog = false;

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

  // 게임 종료 대화상자 표시 - 완전히 새로 구현
  void _showEndGameDialog() {
    // 이미 대화상자가 표시 중이면 무시
    if (_isShowingEndDialog) {
      print('🚫 이미 게임 종료 대화상자가 표시 중입니다.');
      return;
    }

    print('🟥 게임 종료 대화상자 표시 시작');
    _isShowingEndDialog = true;

    try {
      if (!mounted) {
        print('🟥 컨텍스트가 유효하지 않습니다.');
        _isShowingEndDialog = false;
        return;
      }

      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      final currentScore = gameProvider.score;
      print('🟥 현재 점수: $currentScore');

      // 동기식으로 대화상자 표시 (Future나 지연 없이)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          print('🟥 대화상자 빌더 호출됨');
          return AlertDialog(
            title: const Text('게임 종료'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('게임이 종료되었습니다.'),
                const SizedBox(height: 16),
                Text(
                  '최종 점수: $currentScore',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  print('🟥 닫기 버튼 클릭됨');
                  Navigator.of(context).pop();
                  _isShowingEndDialog = false;
                },
                child: const Text('닫기'),
              ),
              TextButton(
                onPressed: () {
                  print('🟥 다시 시작 버튼 클릭됨');
                  Navigator.of(context).pop();
                  _isShowingEndDialog = false;

                  // 지연 없이 직접 재시작
                  try {
                    print('🟥 게임 재시작 시도');
                    final provider =
                        Provider.of<GameProvider>(context, listen: false);
                    provider.restartGame();
                    print('🟥 게임 재시작 완료');
                  } catch (e) {
                    print('🟥 게임 재시작 중 오류: $e');
                  }
                },
                child: const Text('다시 시작'),
              ),
            ],
          );
        },
      ).then((_) {
        print('🟥 대화상자 닫힘');
        _isShowingEndDialog = false;
      });
    } catch (e) {
      print('🟥 대화상자 표시 중 오류 발생: $e');
      _isShowingEndDialog = false;
    }
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

        // 화면 크기 확인
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;

        // 게임 내용의 최대 너비
        const double maxContentWidth = 500;

        // 게임 화면 구성
        return Scaffold(
          backgroundColor: Colors.indigo.shade50, // 배경색 밝게 변경
          body: Column(
            children: [
              // 커스텀 헤더 영역
              Container(
                width: double.infinity,
                color: Colors.indigo.shade700, // 헤더 전체 배경색을 남색으로
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SafeArea(
                  child: Center(
                    child: SizedBox(
                      width: maxContentWidth, // 게임 영역과 동일한 너비
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 게임 제목 (왼쪽 정렬)
                          Expanded(
                            child: AnimatedTitle(
                              isCompactMode: isSmallScreen,
                            ),
                          ),
                          // 버튼 영역 (오른쪽 정렬)
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.exit_to_app,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: const Text(
                              '종료',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onPressed: () {
                              print('🟥 게임 종료 버튼 클릭됨');
                              _showEndGameDialog();
                              print('🟥 _showEndGameDialog 호출 완료');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 게임 화면
              Expanded(
                child: Center(
                  child: GameLayout(
                    wordSuggestionsKey: _wordSuggestionsKey,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
