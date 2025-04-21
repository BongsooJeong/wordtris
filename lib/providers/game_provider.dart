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
/// - lastCompletedWord: 가장 최근에 완성한 단어
/// - lastWordPoints: 최근 완성한 단어의 점수
/// - usedCharacters: 게임에서 사용된 글자 목록
/// - wildcardGenerated: 와일드카드 블록 생성 여부
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
/// - moveBlock(Direction direction): bool
///   그리드에서 블록 이동하기
///
/// 단어 관련 메서드:
/// - getWordSuggestions(String pattern): Future<List<String>>
///   패턴에 맞는 단어 제안 가져오기
///
/// - selectNewWordSet({bool replaceAll = false}): Future<void>
///   새 단어 세트 선택하기
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
/// - _validateWord(String word): Future<bool>
///   단어 유효성 검증
///
/// 애니메이션 관련:
/// - resetAnimationState(): void
///   애니메이션 상태 초기화

/// 게임 상태를 관리하는 Provider 클래스
class GameProvider with ChangeNotifier {
  final WordService _wordService = WordService();
  bool _isLoading = true;
  String _errorMessage = '';
  late Grid _grid;
  List<Block> _availableBlocks = [];
  int _score = 0;
  bool _isGameOver = false;
  bool _isGamePaused = false;
  int _level = 1;
  final List<Word> _formedWords = [];
  int _wordClearCount = 0;                   // 단어 제거 횟수 카운터
  bool _bombGenerated = false;               // 폭탄 생성 플래그
  bool _wildcardGenerated = false;           // 와일드카드 생성 플래그
  int _blockCount = 0;                       // 총 블록 생성 카운트
  int _wildcardFrequency = 3;                // 와일드카드 생성 빈도 (기본값: 3)

  // 사용된 글자를 추적하는 세트 추가
  final Set<String> _usedCharacters = {};

  // 가장 최근에 완성한 단어를 저장하는 변수 추가
  String _lastCompletedWord = '';
  int _lastWordPoints = 0;

  late final WordProcessor _wordProcessor;
  late final BlockManager _blockManager;

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isGameOver => _isGameOver;
  bool get isGamePaused => _isGamePaused;
  int get level => _level;
  Grid get grid => _grid;
  List<Block> get availableBlocks => _availableBlocks;
  int get score => _score;
  List<Word> get formedWords => _formedWords;
  int get wordClearCount => _wordClearCount;
  bool get bombGenerated => _bombGenerated;

  // 가장 최근에 완성한 단어 getter 추가
  String get lastCompletedWord => _lastCompletedWord;
  int get lastWordPoints => _lastWordPoints;

  // 사용된 글자 목록 getter 추가
  Set<String> get usedCharacters => Set.unmodifiable(_usedCharacters);

  // 단어 세트 선택 중 플래그
  bool _isSelectingWordSet = false;

  /// 현재 추천 단어 목록 가져오기
  List<String> get suggestedWordSet {
    final words = _wordProcessor.selectedWords;
    return words;
  }

  /// 단어 사용 횟수 가져오기
  Map<String, int> get wordUsageCounts {
    final counts = _wordProcessor.wordUsageCount;
    return counts;
  }

  /// 새 단어 세트 선택
  Future<void> selectNewWordSet({bool replaceAll = false}) async {
    // 이미 진행 중이면 무시
    if (_isSelectingWordSet) {
      print('⚠️ GameProvider - 이미 단어 세트 선택 중입니다. 중복 호출 무시.');
      return;
    }

    _isSelectingWordSet = true;

    try {
      await _wordProcessor.selectNewWordSet(replaceAll: replaceAll);

      // 상태 변경을 위젯에 알림
      notifyListeners();
    } catch (e) {
      // 오류가 발생해도 UI 갱신
      notifyListeners();
    } finally {
      _isSelectingWordSet = false;
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
    // 여기서 단어 세트와 관련된 상태 업데이트
    // 명시적으로 상태 변경을 알림
    notifyListeners();
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
      _wildcardGenerated = false;
      _blockCount = 0;                       // 블록 카운트 초기화
      _wildcardFrequency = 3;                // 와일드카드 생성 빈도 초기화
      _availableBlocks.clear();
      _usedCharacters.clear(); // 사용된 글자 목록 초기화
      _lastCompletedWord = ''; // 최근 완성 단어 초기화
      _lastWordPoints = 0; // 최근 단어 점수 초기화

      // 초기 블록 생성
      print('🧩 초기 블록 생성');
      await _generateInitialBlocks();

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

  /// 게임 재시작
  void restartGame() {
    _usedCharacters.clear(); // 사용된 글자 목록 초기화
    _lastCompletedWord = ''; // 최근 완성 단어 초기화
    _lastWordPoints = 0; // 최근 단어 점수 초기화
    _initializeGame();
  }

  /// 게임 일시정지 토글
  void togglePause() {
    _isGamePaused = !_isGamePaused;
    notifyListeners();
  }

  /// 초기 블록 생성
  Future<void> _generateInitialBlocks() async {
    _availableBlocks = await _blockManager.generateBlocks(4);
    // 초기 블록 4개 생성했으므로 카운트 증가
    _blockCount += 4;
    print('🧩 초기 블록 생성 완료 - 블록 카운트: $_blockCount');
    notifyListeners();
  }

  /// 새 블록 생성
  Future<void> generateNewBlock() async {
    // 최대 블록 수 확인
    if (_availableBlocks.length >= 5) {
      print('❌ 최대 블록 수(5개)에 도달했습니다.');
      return;
    }

    print('🔄 새 블록 생성 시작 - 현재 블록 수: ${_availableBlocks.length}');
    
    // 3번마다 와일드카드 블록 생성
    if (_availableBlocks.length == 2) {
      print('🎲 와일드카드 블록 생성 (3번째 블록)');
      _availableBlocks.add(await _blockManager.generateWildcardBlock());
    } else {
      print('📦 일반 블록 생성 (${_availableBlocks.length + 1}번째 블록)');
      _availableBlocks.add(await _blockManager.createRandomBlock());
    }
    
    print('✅ 블록 생성 완료 - 현재 블록 수: ${_availableBlocks.length}');
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

    // 폭탄 블록인 경우 폭발 효과 적용
    if (block.isBomb && positions.isNotEmpty) {
      // 폭발의 중심점은 첫 번째 위치 (폭탄은 1칸이므로)
      _grid = _grid.explodeBomb(positions[0]);
    }

    // 블록 카운트 증가 (총 몇 번째 블록인지 추적)
    _blockCount++;
    
    // 새 블록 생성 (최대 5개까지)
    if (_availableBlocks.length < 5) {
      // 설정된 빈도에 따라 와일드카드 블록 생성
      if (_blockCount % _wildcardFrequency == 0) {
        print('🎲 ${_blockCount}번째 블록: 와일드카드 블록 생성 (빈도: $_wildcardFrequency)');
        _availableBlocks.add(await _blockManager.generateWildcardBlock());
      } else {
        print('📦 ${_blockCount}번째 블록: 일반 블록 생성');
        _availableBlocks.add(await _blockManager.createRandomBlock());
      }
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
    _lastCompletedWord = ''; // 단어 목록 초기화

    for (Word word in words) {
      int wordPoints = _wordProcessor.calculateWordPoints(word, _level);
      totalPoints += wordPoints;

      // 와일드카드가 포함된 단어인 경우 실제 단어 찾기
      String actualWord = word.text;
      if (word.text.contains('?')) {
        String? matchingWord = await _wordService.findMatchingWord(word.text);
        if (matchingWord != null) {
          actualWord = matchingWord;
        }
      }

      // 가장 긴 단어를 최근 완성 단어로 저장
      if (actualWord.length > _lastCompletedWord.length) {
        _lastCompletedWord = actualWord;
        _lastWordPoints = wordPoints;
      }
    }

    // 단어가 여러 개면 첫 번째 단어 저장 (이미 저장되지 않은 경우)
    if (_lastCompletedWord.isEmpty && words.isNotEmpty) {
      String firstWord = words[0].text;
      if (firstWord.contains('?')) {
        String? matchingWord = await _wordService.findMatchingWord(firstWord);
        if (matchingWord != null) {
          firstWord = matchingWord;
        }
      }
      _lastCompletedWord = firstWord;
      _lastWordPoints = _wordProcessor.calculateWordPoints(words[0], _level);
    }

    // 점수 추가
    _score += totalPoints;

    // 단어 제거 카운트 증가
    _wordClearCount++;

    // 폭탄 생성 플래그 리셋 - 매 단어 클리어마다 초기화하여 3의 배수 확인이 제대로 동작하도록 함
    _bombGenerated = false;
    _wildcardGenerated = false;

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

  /// 폭탄 블록 폭발 효과 적용
  void explodeBomb(Point center) {
    _grid = _grid.explodeBomb(center);
    notifyListeners();
  }

  // 와일드카드 생성 빈도 getter 및 setter
  int get wildcardFrequency => _wildcardFrequency;
  
  /// 와일드카드 생성 빈도 설정
  /// [frequency]: 와일드카드가 생성되는 블록 간격 (예: 3이면 매 3번째 블록마다 생성)
  void setWildcardFrequency(int frequency) {
    if (frequency < 1) {
      print('⚠️ 와일드카드 빈도는 1 이상이어야 합니다. 기본값 3으로 설정합니다.');
      _wildcardFrequency = 3;
    } else {
      _wildcardFrequency = frequency;
      print('🎮 와일드카드 생성 빈도 설정: $_wildcardFrequency');
    }
    notifyListeners();
  }
}
