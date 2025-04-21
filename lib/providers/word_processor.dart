import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/position.dart';
import '../models/grid.dart';
import '../services/word_service.dart';
import '../utils/point.dart';
import 'character_provider.dart';

/// WordTris 게임의 한글 단어 처리를 담당하는 클래스 API 문서
///
/// [WordProcessor] 클래스
/// 한글 단어 검증, 점수 계산, 사전 검색 등을 담당하는 클래스
///
/// 주요 기능:
/// - 단어 검증 및 점수 계산
/// - 사전 검색 기능
/// - 그리드에서 단어 찾기
/// - 와일드카드 문자 지원
/// - CharacterProvider와 연동하여 문자 관리
///
/// 초기화 메서드:
/// - initialize(): Future<void>
///   한글 처리를 위한 초기 설정 수행
///
/// 게임 그리드 관리:
/// - initializeGrid(int rows, int cols): Future<void>
///   게임 그리드 초기화
///
/// - updateGridCharacter(int row, int col): Future<void>
///   그리드의 특정 위치 문자 업데이트
///
/// - isAdjacentOrSame(Position current, Position next): bool
///   두 위치가 인접한지 확인
///
/// - isPositionSelected(Position position): bool
///   위치가 이미 선택되었는지 확인
///
/// - selectPosition(Position position): void
///   위치 선택 처리
///
/// - resetSelection(): void
///   선택 초기화
///
/// - submitWord(): Future<bool>
///   선택한 단어 제출
///
/// 단어 처리 메서드:
/// - findWords(Grid grid): Future<List<Word>>
///   그리드에서 유효한 단어 찾기
///
/// - _checkAndAddWord(String word, List<Point> cells, List<Word> wordCandidates): Future<void>
///   단어가 유효한지 확인하고 결과에 추가
///
/// - calculateWordPoints(Word word, int level): int
///   단어 객체의 점수 계산
///
/// - calculateWordPointsForString(String word, {int level = 1}): int
///   문자열의 점수 계산
///
/// - _calculateWordPointsInternal(String word, int level): int
///   내부 단어 점수 계산 구현
///
/// - getWordSuggestions(String pattern): Future<List<String>>
///   패턴에 맞는 단어 제안 가져오기
///
/// 사전 기능:
/// - openDictionary(String word): Future<bool>
///   국립국어원 사전에서 단어 검색
///
/// 단어 세트 관리:
/// - selectNewWordSet({bool replaceAll = false}): Future<void>
///   CharacterProvider에 새 단어 세트 선택 요청
///
/// - syncWithCharacterProvider(): void
///   CharacterProvider와 상태 동기화
///
/// - reset(): void
///   WordProcessor 상태 초기화
///
/// 문자 생성 관련:
/// - getFrequencyBasedChar(): Future<String>
///   CharacterProvider를 통해 빈도 기반 문자 가져오기
///
/// - getRandomConsonantChar(): Future<String>
///   CharacterProvider를 통해 자음 기반 랜덤 문자 가져오기
///
/// - getRandomVowelChar(): Future<String>
///   CharacterProvider를 통해 모음 기반 랜덤 문자 가져오기
///
/// Getters:
/// - grid: List<List<String>>
///   현재 게임 그리드 상태
///
/// - selectedPositions: List<Position>
///   현재 선택된 위치 목록
///
/// - currentWord: String
///   현재 선택한 단어
///
/// - foundWords: List<String>
///   발견한 단어 목록
///
/// - wordUsageCount: Map<String, int>
///   CharacterProvider에서 관리하는 단어별 사용 횟수
///
/// - selectedWords: List<String>
///   CharacterProvider에서 관리하는 현재 선택된 단어 목록

/// WordTris 게임에서 한글 단어 처리를 담당하는 클래스
/// - 단어 검증, 점수 계산, 사전 검색 기능 제공
class WordProcessor with ChangeNotifier {
  final WordService _wordService;
  final CharacterProvider _characterProvider;

  List<List<String>> _grid = [];
  final List<Position> _selectedPositions = [];
  String _currentWord = '';
  final List<String> _foundWords = [];
  Map<String, int> _wordUsageCount = {};

  // 재귀 호출 방지 플래그
  bool _isSelectingWordSet = false;

  /// 서비스를 주입받는 생성자
  WordProcessor({
    required WordService wordService,
    required CharacterProvider characterProvider,
  })  : _wordService = wordService,
        _characterProvider = characterProvider {
    // CharacterProvider의 변경을 감지하는 리스너 추가
    _characterProvider.addListener(_onCharacterProviderChanged);
  }

  /// 기본 생성자 - 내부에서 서비스 초기화
  WordProcessor.create()
      : _wordService = WordService(),
        _characterProvider = CharacterProvider(WordService()) {
    // 나중에 초기화 필요
    // CharacterProvider의 변경을 감지하는 리스너 추가
    _characterProvider.addListener(_onCharacterProviderChanged);
  }

  /// CharacterProvider 변경 시 호출되는 콜백
  void _onCharacterProviderChanged() {
    print('📣 CharacterProvider 변경 감지됨, WordProcessor 상태 동기화 중...');
    print('📋 변경 전 선택된 단어 수: ${_characterProvider.selectedWords.length}');
    syncWithCharacterProvider();
    print('📋 변경 후 동기화 완료');
  }

  @override
  void dispose() {
    // 리스너 제거
    _characterProvider.removeListener(_onCharacterProviderChanged);
    super.dispose();
  }

  /// 초기화
  Future<void> initialize() async {
    print('🔄 WordProcessor 초기화 시작');
    await _wordService.initialize();
    print('📚 WordService 초기화 완료');

    print('🔄 CharacterProvider 초기화 시작 (via WordProcessor)');
    await _characterProvider.initialize();
    print('📚 CharacterProvider 초기화 완료 (via WordProcessor)');

    // CharacterProvider에서 이미 selectNewWordSet을 호출하므로 여기서는 호출하지 않음
    // 단어 목록 변경 감지를 위한 동기화만 수행
    print('🔄 CharacterProvider와 상태 동기화');
    syncWithCharacterProvider();
    notifyListeners();
    print('✅ WordProcessor 초기화 완료');
  }

  // Getters
  List<List<String>> get grid => _grid;
  List<Position> get selectedPositions => _selectedPositions;
  String get currentWord => _currentWord;
  List<String> get foundWords => _foundWords;
  Map<String, int> get wordUsageCount => _characterProvider.wordUsageCount;
  List<String> get selectedWords => _characterProvider.selectedWords;

  // Grid 초기화 메서드
  Future<void> initializeGrid(int rows, int cols) async {
    // 빈 그리드 먼저 생성
    _grid = List.generate(
      rows,
      (_) => List.generate(
        cols,
        (_) => '', // 빈 문자열로 초기화
      ),
    );

    // 그리드의 각 셀을 비동기적으로 채우기
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        _grid[i][j] = await _characterProvider.getRandomCharacter();
      }
    }

    notifyListeners();
  }

  // Grid의 특정 위치 문자 업데이트
  Future<void> updateGridCharacter(int row, int col) async {
    _grid[row][col] = await _characterProvider.getRandomCharacter();
    notifyListeners();
  }

  // 현재 위치의 인접한 위치인지 확인
  bool isAdjacentOrSame(Position current, Position next) {
    return (current.row - next.row).abs() <= 1 &&
        (current.col - next.col).abs() <= 1;
  }

  // 위치가 이미 선택되었는지 확인
  bool isPositionSelected(Position position) {
    return _selectedPositions.contains(position);
  }

  // 위치 선택 처리
  void selectPosition(Position position) {
    if (_selectedPositions.isEmpty ||
        (isAdjacentOrSame(_selectedPositions.last, position) &&
            !isPositionSelected(position))) {
      _selectedPositions.add(position);
      _currentWord += _grid[position.row][position.col];
      notifyListeners();
    }
  }

  // 선택 초기화
  void resetSelection() {
    _selectedPositions.clear();
    _currentWord = '';
    notifyListeners();
  }

  // 선택한 단어 제출
  Future<bool> submitWord() async {
    print('🔤 단어 제출 시도: "$_currentWord", 길이: ${_currentWord.length}');

    if (_currentWord.length < 2) {
      print('❌ 단어가 너무 짧음 (${_currentWord.length} < 2)');
      resetSelection();
      return false;
    }

    if (_wordService.isValidWord(_currentWord) &&
        !_foundWords.contains(_currentWord)) {
      print('✅ 유효한 단어 확인: "$_currentWord"');
      _foundWords.add(_currentWord);

      // 점수 계산 로그
      int score = calculateWordPointsForString(_currentWord);
      print('💯 단어 점수: $score (레벨: 1)');

      // CharacterProvider에 단어 사용 횟수 업데이트
      if (_characterProvider.selectedWords.contains(_currentWord)) {
        print('📊 단어 사용 횟수 업데이트: "$_currentWord"');
        _characterProvider.updateWordUsage(_currentWord);
      }

      // 선택된 위치의 문자 교체
      print('🔄 선택된 위치의 문자 교체 (${_selectedPositions.length}개)');
      for (var position in _selectedPositions) {
        await updateGridCharacter(position.row, position.col);
      }

      resetSelection();
      return true;
    } else {
      print('❌ 유효하지 않은 단어이거나 이미 발견한 단어: "$_currentWord"');
      resetSelection();
      return false;
    }
  }

  /// 그리드에서 단어 찾기
  Future<List<Word>> findWords(Grid grid) async {
    // print('🔍 단어 검색 시작: 그리드 크기 ${grid.rows}x${grid.columns}');
    List<Word> wordCandidates = [];

    // 가로 단어 검색
    // print('🔍 가로 방향 단어 검색 시작');
    for (int y = 0; y < grid.rows; y++) {
      for (int startX = 0; startX < grid.columns - 1; startX++) {
        if (grid.cells[y][startX].isEmpty) continue;

        String word = grid.cells[y][startX].character!;
        List<Point> cells = [Point(startX, y)];

        for (int x = startX + 1; x < grid.columns; x++) {
          if (grid.cells[y][x].isEmpty) break;

          word += grid.cells[y][x].character!;
          cells.add(Point(x, y));

          if (word.length >= 3) {
            await _checkAndAddWord(word, cells, wordCandidates);
          }
        }
      }
    }

    // 세로 단어 검색
    // print('🔍 세로 방향 단어 검색 시작');
    for (int x = 0; x < grid.columns; x++) {
      for (int startY = 0; startY < grid.rows - 1; startY++) {
        if (grid.cells[startY][x].isEmpty) continue;

        String word = grid.cells[startY][x].character!;
        List<Point> cells = [Point(x, startY)];

        for (int y = startY + 1; y < grid.rows; y++) {
          if (grid.cells[y][x].isEmpty) break;

          word += grid.cells[y][x].character!;
          cells.add(Point(x, y));

          if (word.length >= 3) {
            await _checkAndAddWord(word, cells, wordCandidates);
          }
        }
      }
    }

    // print('🔍 단어 검색 완료: ${wordCandidates.length}개의 단어 발견');
    return wordCandidates;
  }

  /// 단어가 유효한지 확인하고 결과에 추가
  Future<void> _checkAndAddWord(
      String word, List<Point> cells, List<Word> wordCandidates) async {
    bool isValid = await _wordService.isValidWordAsync(word);
    if (isValid) {
      // print('✓ 유효한 단어 발견: "$word" (길이: ${word.length})');
      wordCandidates.add(Word(text: word, cells: List.from(cells)));

      // CharacterProvider에 단어 사용 횟수 증가 요청
      _characterProvider.updateWordUsage(word);
    } else {
      // print('✗ 유효하지 않은 단어: "$word"');
    }
  }

  /// 단어 점수 계산 (Word 객체 버전)
  int calculateWordPoints(Word word, int level) {
    print('💯 단어 점수 계산 시작: "${word.text}" (레벨: $level)');
    int score = _calculateWordPointsInternal(word.text, level);
    print('💯 계산된 최종 점수: $score');
    return score;
  }

  /// 단어 점수 계산 (문자열 버전)
  int calculateWordPointsForString(String word, {int level = 1}) {
    print('💯 단어 점수 계산 시작: "$word" (레벨: $level)');
    int score = _calculateWordPointsInternal(word, level);
    print('💯 계산된 최종 점수: $score');
    return score;
  }

  /// 내부 단어 점수 계산 구현
  int _calculateWordPointsInternal(String word, int level) {
    if (word.isEmpty) {
      print('💯 빈 단어: 0점');
      return 0;
    }

    // 기본 점수: 글자당 10점
    int basePoints = word.length * 10;
    print('💯 기본 점수: $basePoints (글자 수: ${word.length})');

    // 보너스 점수: 특수 문자나 덜 사용되는 문자에 대한 추가 점수
    int bonusPoints = 0;
    for (int i = 0; i < word.length; i++) {
      String char = word[i];
      // 덜 사용되는 문자에 대한 추가 점수
      if (_characterProvider.isRareCharacter(char)) {
        bonusPoints += 5;
        print('💯 희귀 문자 보너스: +5 (문자: "$char")');
      }
    }
    print('💯 총 보너스 점수: $bonusPoints');

    // 레벨에 따른 보너스 (레벨당 10% 증가)
    double levelMultiplier = 1 + (level - 1) * 0.1;
    print('💯 레벨 보너스 승수: x$levelMultiplier (레벨: $level)');

    int finalScore = ((basePoints + bonusPoints) * levelMultiplier).round();
    print(
        '💯 최종 점수: $finalScore = ($basePoints + $bonusPoints) x $levelMultiplier');
    return finalScore;
  }

  /// 패턴에 맞는 단어 제안 가져오기
  Future<List<String>> getWordSuggestions(String pattern) async {
    print('🔍 단어 제안 검색: "$pattern"');
    if (pattern.isEmpty || pattern.length < 2) {
      print('🔍 패턴이 너무 짧음: "$pattern"');
      return [];
    }
    List<String> suggestions = await _wordService.getWordAsync(pattern);
    print('🔍 ${suggestions.length}개의 단어 제안 발견');
    return suggestions;
  }

  /// 국립국어원 사전 URL 열기
  Future<bool> openDictionary(String word) async {
    print('📖 사전 열기 시도: "$word"');
    final encodedWord = Uri.encodeComponent(word);
    final uri = Uri.parse(
        'https://stdict.korean.go.kr/search/searchResult.do?searchKeyword=$encodedWord');

    try {
      print('📖 URL 실행 가능 여부 확인: $uri');
      if (await canLaunchUrl(uri)) {
        print('📖 URL 실행 중...');
        bool result =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('📖 URL 실행 결과: $result');
        return result;
      }
      print('📖 URL을 실행할 수 없음');
      return false;
    } catch (e) {
      print('📖 URL 열기 오류: $e');
      debugPrint('URL 열기 오류: $e');
      return false;
    }
  }

  /// 새 단어 세트 선택 요청
  Future<void> selectNewWordSet({bool replaceAll = false}) async {
    // 이미 단어 세트 선택 중이면 중복 호출 방지
    if (_isSelectingWordSet) {
      print('⚠️ WordProcessor - 이미 단어 세트 선택 중입니다. 중복 호출 무시.');
      return;
    }

    _isSelectingWordSet = true;

    try {
      print('🔄 WordProcessor.selectNewWordSet(replaceAll: $replaceAll) 호출');
      print(
          '📋 WordProcessor - 선택 전 단어 수: ${_characterProvider.selectedWords.length}');

      // CharacterProvider에 단어 세트 선택 요청
      await _characterProvider.selectNewWordSet(replaceAll: replaceAll);

      print('📋 CharacterProvider에서 단어 세트 선택 완료');
      print(
          '📋 WordProcessor - 선택 후 단어 수: ${_characterProvider.selectedWords.length}');

      // 상태 동기화
      syncWithCharacterProvider();

      // UI에 변경 알림
      print('📢 WordProcessor에서 notifyListeners() 호출 - selectNewWordSet');
      notifyListeners();
      print('✅ WordProcessor에서 새 단어 세트 선택 완료');
    } catch (e) {
      print('❌ WordProcessor에서 단어 세트 선택 중 오류 발생: $e');
      // 오류가 발생해도 상태를 동기화하고 UI에 알림
      syncWithCharacterProvider();
      notifyListeners();
    } finally {
      _isSelectingWordSet = false;
    }
  }

  /// WordProcessor 초기화
  void reset() {
    _selectedPositions.clear();
    _currentWord = '';
    _foundWords.clear();
    notifyListeners();
  }

  /// 선택된 단어 목록 동기화
  void syncWithCharacterProvider() {
    print('🔄 WordProcessor.syncWithCharacterProvider() 호출');
    print(
        '📋 CharacterProvider 단어 수: ${_characterProvider.selectedWords.length}');

    // 로컬 단어 사용 횟수 맵 업데이트
    final providerUsageCount = _characterProvider.wordUsageCount;
    _wordUsageCount = Map.from(providerUsageCount);

    print('📢 WordProcessor.notifyListeners() 호출 - syncWithCharacterProvider');
    notifyListeners();
    print('📢 WordProcessor.notifyListeners() 완료 - syncWithCharacterProvider');
  }

  /// 빈도 기반 문자 가져오기
  Future<String> getFrequencyBasedChar() async {
    return await _characterProvider.getFrequencyBasedChar();
  }

  /// 자음 기반 랜덤 문자 가져오기
  Future<String> getRandomConsonantChar() async {
    return await _characterProvider.getRandomConsonantChar();
  }

  /// 모음 기반 랜덤 문자 가져오기
  Future<String> getRandomVowelChar() async {
    return await _characterProvider.getRandomVowelChar();
  }
}
