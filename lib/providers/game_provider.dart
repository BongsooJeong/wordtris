import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/block.dart';
import '../models/grid.dart';
import '../services/word_service.dart';
import '../utils/point.dart';
import 'package:url_launcher/url_launcher.dart';
import 'word_processor.dart';
import 'block_manager.dart';
import 'character_provider.dart';

/// WordTris 게임 상태 관리 Provider API 문서
///
/// [GameProvider] 클래스
/// 게임의 전체 상태와 로직을 관리하는 Provider 클래스
///
/// 주요 속성:
/// - grid: 게임 보드 그리드
/// - availableBlocks: 현재 사용 가능한 블록 목록
/// - score: 현재 게임 점수
/// - level: 현재 게임 레벨
/// - isGameOver: 게임 종료 여부
/// - isGamePaused: 게임 일시정지 여부
/// - formedWords: 완성된 단어 목록
/// - wordClearCount: 단어 제거 횟수
/// - bombGenerated: 폭탄 블록 생성 여부
///
/// 초기화 메서드:
/// - initialize(): Future<void>
///   게임 초기 상태 설정
///
/// - restartGame(): void
///   게임 재시작
///
/// 게임 조작 메서드:
/// - togglePause(): void
///   게임 일시정지 토글
///
/// - rotateBlockInTray(Block block): void
///   블록 회전
///
/// - placeBlock(Block block, List<Point> positions): Future<bool>
///   블록을 그리드에 배치
///
/// 단어 관련 메서드:
/// - getWordSuggestions(String pattern): Future<List<String>>
///   패턴에 맞는 단어 제안 가져오기
///
/// 내부 메서드:
/// - _generateBlocks(): void
///   새로운 블록 생성
///
/// - _createRandomBlock(): Block
///   랜덤 블록 생성
///
/// - _checkForWords(): Future<void>
///   형성된 단어 확인
///
/// - _checkGameOver(): void
///   게임 오버 상태 확인
///
/// 애니메이션 관련:
/// - resetAnimationState(): void
///   애니메이션 상태 초기화

/// 게임 상태를 관리하는 Provider 클래스
class GameProvider with ChangeNotifier {
  final Set<String> _validWords = {};
  final WordService _wordService = WordService();
  bool _isLoading = true;
  String _errorMessage = '';
  late Grid _grid;
  List<Block> _availableBlocks = [];
  int _score = 0;
  bool _isGameOver = false;
  bool _isGamePaused = false;
  int _level = 1;
  final bool _isInitialized = false;
  final Random _random = Random();
  final List<Word> _formedWords = [];
  final String _currentPattern = '';
  final List<String> _suggestedWords = [];
  final bool _isLoadingSuggestions = false;
  int _wordClearCount = 0; // 단어 제거 횟수 카운터
  bool _bombGenerated = false;

  // 사용된 글자를 추적하는 세트 추가
  final Set<String> _usedCharacters = {};

  late final WordProcessor _wordProcessor;
  late final BlockManager _blockManager;

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isGameOver => _isGameOver;
  bool get isGamePaused => _isGamePaused;
  int get level => _level;
  bool get isInitialized => _isInitialized;
  Grid get grid => _grid;
  List<Block> get availableBlocks => _availableBlocks;
  int get score => _score;
  List<Word> get formedWords => _formedWords;
  String get currentPattern => _currentPattern;
  List<String> get suggestedWords => _suggestedWords;
  bool get isLoadingSuggestions => _isLoadingSuggestions;
  int get wordClearCount => _wordClearCount;
  bool get bombGenerated => _bombGenerated;

  // 사용된 글자 목록 getter 추가
  Set<String> get usedCharacters => Set.unmodifiable(_usedCharacters);

  /// 현재 추천 단어 목록 가져오기
  List<String> get suggestedWordSet {
    final words = _wordProcessor.selectedWords;
    // print('📋 GameProvider.suggestedWordSet 접근: ${words.length}개 단어');
    return words;
  }

  /// 단어 사용 횟수 가져오기
  Map<String, int> get wordUsageCounts {
    final counts = _wordProcessor.wordUsageCount;
    // print('📋 GameProvider.wordUsageCounts 접근: ${counts.length}개 항목');
    return counts;
  }

  /// 새 단어 세트 선택
  Future<void> selectNewWordSet({bool replaceAll = false}) async {
    print(
        '🎮 GameProvider.selectNewWordSet(replaceAll: $replaceAll) 호출 - 호출 스택: ${StackTrace.current}');
    print('📝 WordProcessor에 새 단어 세트 선택 요청');
    print('📋 선택 전 단어 수: ${_wordProcessor.selectedWords.length}');
    print('📋 선택 전 단어 목록: ${_wordProcessor.selectedWords}');

    try {
      await _wordProcessor.selectNewWordSet(replaceAll: replaceAll);

      print('✅ GameProvider에서 새 단어 세트 선택 완료');
      print('📋 선택 후 단어 수: ${_wordProcessor.selectedWords.length}');
      print('📋 선택 후 단어 목록: ${_wordProcessor.selectedWords}');

      // 상태 변경을 위젯에 알림
      print('📢 GameProvider.notifyListeners() 호출 - selectNewWordSet');
      notifyListeners();
      print('📢 GameProvider.notifyListeners() 완료 - selectNewWordSet');
    } catch (e) {
      print('❌ 단어 세트 선택 중 오류 발생: $e');
      // 오류가 발생해도 UI 갱신
      notifyListeners();
    }
  }

  // 생성자에서 초기화
  GameProvider() {
    final wordService = WordService();
    final characterProvider = CharacterProvider(wordService);
    _wordProcessor = WordProcessor(
      wordService: wordService,
      characterProvider: characterProvider,
    );
    // WordProcessor의 변경을 감지하는 리스너 추가
    _wordProcessor.addListener(_onWordProcessorChanged);
    _blockManager = BlockManager(_wordProcessor);
    _initializeGame();
  }

  /// WordProcessor 변경 시 호출되는 콜백
  void _onWordProcessorChanged() {
    print('📣 WordProcessor 변경 감지됨, GameProvider 상태 업데이트 중...');
    print('📋 GameProvider 단어 세트 수: ${_wordProcessor.selectedWords.length}');

    // 여기서 단어 세트와 관련된 상태 업데이트
    print('📢 GameProvider.notifyListeners() 호출 - _onWordProcessorChanged');
    // 명시적으로 상태 변경을 알림
    notifyListeners();
    print('📢 GameProvider.notifyListeners() 완료 - _onWordProcessorChanged');
  }

  @override
  void dispose() {
    // 리스너 제거
    _wordProcessor.removeListener(_onWordProcessorChanged);
    super.dispose();
  }

  /// 게임 초기화
  Future<void> _initializeGame() async {
    print('🎮 GameProvider._initializeGame() 시작');
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // WordProcessor 초기화 - 이 과정에서 이미 CharacterProvider에서 단어 세트가 선택됨
      print('📝 WordProcessor 초기화 시작 (via GameProvider)');
      await _wordProcessor.initialize();
      print('✅ WordProcessor 초기화 완료 (via GameProvider)');

      // 게임 그리드 생성 (10x10)
      _grid = Grid(rows: 10, columns: 10);

      // 게임 상태 초기화
      _score = 0;
      _level = 1;
      _isGameOver = false;
      _isGamePaused = false;
      _wordClearCount = 0;
      _bombGenerated = false;
      _availableBlocks.clear();
      _usedCharacters.clear(); // 사용된 글자 목록 초기화

      // 초기 블록 생성
      print('🧩 초기 블록 생성');
      _generateInitialBlocks();

      _isLoading = false;
      notifyListeners();
      print('✅ GameProvider 초기화 완료');
    } catch (e) {
      _isLoading = false;
      _errorMessage = '게임 초기화 오류: $e';
      print('❌ 게임 초기화 오류: $e');
      notifyListeners();
    }
  }

  /// 게임 초기화
  Future<void> initialize() async {
    await _initializeGame();
  }

  /// 게임 재시작
  void restartGame() {
    _usedCharacters.clear(); // 사용된 글자 목록 초기화
    _initializeGame();
  }

  /// 게임 일시정지 토글
  void togglePause() {
    _isGamePaused = !_isGamePaused;
    notifyListeners();
  }

  /// 초기 블록 생성
  void _generateInitialBlocks() {
    _availableBlocks = _blockManager.generateBlocks(4);
    notifyListeners();
  }

  /// 새로운 블록 생성
  void _generateNewBlock() {
    if (_blockManager.isBlockCountExceeded(_availableBlocks)) return;

    // 5번마다 폭탄 블록 생성 (5, 10, 15, 20, ...)
    if (_wordClearCount > 0 && _wordClearCount % 5 == 0 && !_bombGenerated) {
      _bombGenerated = true;
      _availableBlocks.add(_blockManager.generateBombBlock());
    } else {
      _availableBlocks.add(_blockManager.createRandomBlock());
    }
    notifyListeners();
  }

  /// 블록 회전 - 블록 트레이에 있는 블록
  void rotateBlockInTray(Block block) {
    int index = _availableBlocks.indexWhere((b) => b.id == block.id);
    if (index != -1) {
      _availableBlocks[index] = block.rotate();
      notifyListeners();
    }
  }

  /// 블록을 그리드에 배치할 수 있는지 확인
  bool _canPlaceBlock(List<Point> points) {
    // 모든 위치가 그리드 내에 있고 비어있는지 확인
    for (Point point in points) {
      if (point.x < 0 ||
          point.x >= _grid.columns ||
          point.y < 0 ||
          point.y >= _grid.rows) {
        return false;
      }

      if (!_grid.cells[point.y][point.x].isEmpty) {
        return false;
      }
    }
    return true;
  }

  /// 블록을 그리드에 배치
  Future<bool> placeBlock(Block block, List<Point> positions) async {
    // 배치 가능 여부 확인
    if (!_grid.isValidPlacement(positions)) {
      return false;
    }

    // 블록 배치
    _grid = _grid.placeBlock(block, positions);

    // 활성 블록에서 제거
    _availableBlocks.removeWhere((b) => b.id == block.id);

    // 배치된 블록의 모든 글자를 사용된 글자 목록에 추가
    for (String character in block.characters) {
      _usedCharacters.add(character);
    }

    // print('🧩 블록 배치 - 사용된 글자 추가: ${block.characters}');
    // print('📊 현재 사용된 글자: $_usedCharacters');

    // 새 블록 생성 (최대 5개까지)
    if (_availableBlocks.length < 5) {
      _generateNewBlock();
    }

    // 단어 확인
    await _checkForWords();

    // 게임 오버 체크
    _checkGameOver();

    notifyListeners();
    return true;
  }

  /// 단어 확인
  Future<void> _checkForWords() async {
    List<Word> words = await _wordProcessor.findWords(_grid);
    if (words.isEmpty) return;

    // 단어 제거 및 점수 계산
    int totalPoints = 0;
    for (Word word in words) {
      totalPoints += _wordProcessor.calculateWordPoints(word, _level);
    }

    // 점수 추가
    _score += totalPoints;

    // 단어 제거 카운트 증가
    _wordClearCount++;

    // 레벨 업 체크 (100점마다)
    _level = (_score ~/ 100) + 1;
    if (_level > 10) _level = 10;

    // 단어 제거
    _grid = _grid.removeWords(words);

    notifyListeners();
  }

  /// 게임 오버 체크
  void _checkGameOver() {
    // 사용 가능한 블록이 없거나 그리드가 가득 찬 경우
    if (_availableBlocks.isEmpty || _grid.isFull()) {
      _isGameOver = true;
      notifyListeners();
    }
  }

  /// 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = '';
    }
    notifyListeners();
  }

  /// 오류 메시지 설정
  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    print(message); // 디버깅용
    notifyListeners();
  }

  /// 패턴에 맞는 단어 제안 가져오기
  Future<List<String>> getWordSuggestions(String pattern) async {
    if (pattern.isEmpty || pattern.length < 3) {
      return [];
    }

    return await _wordProcessor.getWordSuggestions(pattern);
  }

  // 블록 최대 개수
  static const int _maxAvailableBlocks = 5;

  // 색상 팔레트
  static const List<Color> _blockColors = [
    Color(0xFFFFC107), // 노랑
    Color(0xFF4CAF50), // 초록
    Color(0xFF2196F3), // 파랑
    Color(0xFFE91E63), // 분홍
    Color(0xFF9C27B0), // 보라
    Color(0xFFFF5722), // 주황
  ];

  // 애니메이션 상태 초기화
  void resetAnimationState() {
    _grid = _grid.copyWith();
    _grid.lastRemovedCells = [];
    notifyListeners();
  }

  set availableBlocks(List<Block> blocks) {
    _availableBlocks = blocks;
    notifyListeners();
  }

  /// 단어 사전 검색
  Future<bool> openDictionary(String word) async {
    return await _wordProcessor.openDictionary(word);
  }
}
