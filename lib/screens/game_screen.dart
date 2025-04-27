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

        // 화면 크기 확인
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;

        // 게임 화면 구성
        return Scaffold(
          appBar: AppBar(
            title: AnimatedTitle(
              isCompactMode: isSmallScreen, // 작은 화면에서는 컴팩트 모드 활성화
            ),
            centerTitle: true,
            elevation: 4.0,
            backgroundColor: Colors.indigo.shade700,
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
          body: GameLayout(
            wordSuggestionsKey: _wordSuggestionsKey,
          ),
        );
      },
    );
  }
}
