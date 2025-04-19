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
///
/// 초기화 메서드:
/// - initialize(): Future<void>
///   한글 처리를 위한 초기 설정 수행
///
/// 게임 그리드 관리:
/// - initializeGrid(int rows, int cols): void
///   게임 그리드 초기화
///
/// - updateGridCharacter(int row, int col): void
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
/// - submitWord(): bool
///   선택한 단어 제출
///
/// 단어 처리 메서드:
/// - findWords(Grid grid): Future<List<Word>>
///   그리드에서 유효한 단어 찾기
///
/// - calculateWordPoints(Word word, int level): int
///   단어 객체의 점수 계산
///
/// - calculateWordPointsForString(String word, {int level}): int
///   문자열의 점수 계산
///
/// - getWordSuggestions(String pattern): Future<List<String>>
///   패턴에 맞는 단어 제안 가져오기
///
/// 사전 기능:
/// - openDictionary(String word): Future<bool>
///   국립국어원 사전에서 단어 검색
///
/// 단어 세트 관리:
/// - selectNewWordSet(): Future<void>
///   새 단어 세트 선택
///
/// - syncWithCharacterProvider(): void
///   CharacterProvider와 상태 동기화
///
/// - reset(): void
///   WordProcessor 상태 초기화
///
/// 문자 생성 관련:
/// - getFrequencyBasedChar(): String
///   빈도 기반 문자 가져오기 (CharacterProvider 위임)
///
/// - getRandomConsonantChar(): String
///   자음 기반 랜덤 문자 가져오기
///
/// - getRandomVowelChar(): String
///   모음 기반 랜덤 문자 가져오기
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
///   단어별 사용 횟수
///
/// - selectedWords: List<String>
///   현재 선택된 단어 목록

/// 한글 단어 처리를 담당하는 클래스
class WordProcessor with ChangeNotifier {
  final WordService _wordService;
  final CharacterProvider _characterProvider;

  List<List<String>> _grid = [];
  final List<Position> _selectedPositions = [];
  String _currentWord = '';
  final List<String> _foundWords = [];
  Map<String, int> _wordUsageCount = {};

  /// 서비스를 주입받는 생성자
  WordProcessor({
    required WordService wordService,
    required CharacterProvider characterProvider,
  })  : _wordService = wordService,
        _characterProvider = characterProvider;

  /// 기본 생성자 - 내부에서 서비스 초기화
  WordProcessor.create()
      : _wordService = WordService(),
        _characterProvider = CharacterProvider(WordService()) {
    // 나중에 초기화 필요
  }

  /// 초기화
  Future<void> initialize() async {
    await _wordService.initialize();
    await _characterProvider.initialize();
    notifyListeners();
  }

  // Getters
  List<List<String>> get grid => _grid;
  List<Position> get selectedPositions => _selectedPositions;
  String get currentWord => _currentWord;
  List<String> get foundWords => _foundWords;
  Map<String, int> get wordUsageCount => _characterProvider.wordUsageCount;
  List<String> get selectedWords => _characterProvider.selectedWords;

  // Grid 초기화 메서드
  void initializeGrid(int rows, int cols) {
    _grid = List.generate(
      rows,
      (_) => List.generate(
        cols,
        (_) => _characterProvider.getRandomCharacter(),
      ),
    );
    notifyListeners();
  }

  // Grid의 특정 위치 문자 업데이트
  void updateGridCharacter(int row, int col) {
    _grid[row][col] = _characterProvider.getRandomCharacter();
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
  bool submitWord() {
    if (_currentWord.length < 2) {
      resetSelection();
      return false;
    }

    if (_wordService.isValidWord(_currentWord) &&
        !_foundWords.contains(_currentWord)) {
      _foundWords.add(_currentWord);

      // CharacterProvider에 단어 사용 횟수 업데이트
      if (_characterProvider.selectedWords.contains(_currentWord)) {
        _characterProvider.updateWordUsage(_currentWord);
      }

      // 선택된 위치의 문자 교체
      for (var position in _selectedPositions) {
        updateGridCharacter(position.row, position.col);
      }

      resetSelection();
      return true;
    } else {
      resetSelection();
      return false;
    }
  }

  /// 그리드에서 단어 찾기
  Future<List<Word>> findWords(Grid grid) async {
    List<Word> wordCandidates = [];

    // 가로 단어 검색
    for (int y = 0; y < grid.rows; y++) {
      for (int startX = 0; startX < grid.columns - 1; startX++) {
        if (grid.cells[y][startX].isEmpty) continue;

        String word = grid.cells[y][startX].character!;
        List<Point> cells = [Point(startX, y)];

        for (int x = startX + 1; x < grid.columns; x++) {
          if (grid.cells[y][x].isEmpty) break;

          word += grid.cells[y][x].character!;
          cells.add(Point(x, y));

          if (word.length >= 2) {
            bool isValid = await _wordService.isValidWordAsync(word);
            if (isValid) {
              wordCandidates.add(Word(text: word, cells: List.from(cells)));

              // CharacterProvider에 단어 사용 횟수 증가 요청
              _characterProvider.updateWordUsage(word);
            }
          }
        }
      }
    }

    // 세로 단어 검색
    for (int x = 0; x < grid.columns; x++) {
      for (int startY = 0; startY < grid.rows - 1; startY++) {
        if (grid.cells[startY][x].isEmpty) continue;

        String word = grid.cells[startY][x].character!;
        List<Point> cells = [Point(x, startY)];

        for (int y = startY + 1; y < grid.rows; y++) {
          if (grid.cells[y][x].isEmpty) break;

          word += grid.cells[y][x].character!;
          cells.add(Point(x, y));

          if (word.length >= 2) {
            bool isValid = await _wordService.isValidWordAsync(word);
            if (isValid) {
              wordCandidates.add(Word(text: word, cells: List.from(cells)));

              // CharacterProvider에 단어 사용 횟수 증가 요청
              _characterProvider.updateWordUsage(word);
            }
          }
        }
      }
    }

    return wordCandidates;
  }

  /// 단어 점수 계산 (Word 객체 버전)
  int calculateWordPoints(Word word, int level) {
    return _calculateWordPointsInternal(word.text, level);
  }

  /// 단어 점수 계산 (문자열 버전)
  int calculateWordPointsForString(String word, {int level = 1}) {
    return _calculateWordPointsInternal(word, level);
  }

  /// 내부 단어 점수 계산 구현
  int _calculateWordPointsInternal(String word, int level) {
    if (word.isEmpty) return 0;

    // 기본 점수: 글자당 10점
    int basePoints = word.length * 10;

    // 보너스 점수: 특수 문자나 덜 사용되는 문자에 대한 추가 점수
    int bonusPoints = 0;
    for (int i = 0; i < word.length; i++) {
      String char = word[i];
      // 덜 사용되는 문자에 대한 추가 점수
      if (_characterProvider.isRareCharacter(char)) {
        bonusPoints += 5;
      }
    }

    // 레벨에 따른 보너스 (레벨당 10% 증가)
    double levelMultiplier = 1 + (level - 1) * 0.1;

    return ((basePoints + bonusPoints) * levelMultiplier).round();
  }

  /// 패턴에 맞는 단어 제안 가져오기
  Future<List<String>> getWordSuggestions(String pattern) async {
    if (pattern.isEmpty || pattern.length < 2) {
      return [];
    }
    return await _wordService.getWordAsync(pattern);
  }

  /// 국립국어원 사전 URL 열기
  Future<bool> openDictionary(String word) async {
    final encodedWord = Uri.encodeComponent(word);
    final uri = Uri.parse(
        'https://stdict.korean.go.kr/search/searchResult.do?searchKeyword=$encodedWord');

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('URL 열기 오류: $e');
      return false;
    }
  }

  /// 새 단어 세트 수동 선택
  Future<void> selectNewWordSet() async {
    await _characterProvider.selectNewWordSet();
    syncWithCharacterProvider();
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
    // 로컬 단어 사용 횟수 맵 업데이트
    final providerUsageCount = _characterProvider.wordUsageCount;
    _wordUsageCount = Map.from(providerUsageCount);
    notifyListeners();
  }

  /// 빈도 기반 문자 가져오기
  String getFrequencyBasedChar() {
    return _characterProvider.getRandomCharacter();
  }

  /// 자음 기반 랜덤 문자 가져오기
  String getRandomConsonantChar() {
    return _characterProvider.getRandomCharacter();
  }

  /// 모음 기반 랜덤 문자 가져오기
  String getRandomVowelChar() {
    return _characterProvider.getRandomCharacter();
  }
}
