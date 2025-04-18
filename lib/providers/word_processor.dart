import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import '../models/grid.dart';
import '../services/word_service.dart';
import '../utils/point.dart';

/// WordTris 게임의 한글 단어 처리를 담당하는 클래스 API 문서
///
/// [WordProcessor] 클래스
/// 한글 문자 생성, 단어 검증, 점수 계산 등을 담당하는 클래스
///
/// 주요 기능:
/// - 빈도 기반 한글 문자 생성
/// - 자음/모음 기반 문자 생성
/// - 단어 검증 및 점수 계산
/// - 사전 검색 기능
///
/// 초기화 메서드:
/// - initialize(): Future<void>
///   한글 처리를 위한 초기 설정 수행
///
/// 문자 생성 메서드:
/// - getFrequencyBasedChar(): String
///   빈도 기반으로 한글 문자 생성
///
/// - getRandomConsonantChar(): String
///   자음 기반의 랜덤 문자 생성
///
/// - getRandomVowelChar(): String
///   모음 기반의 랜덤 문자 생성
///
/// 단어 처리 메서드:
/// - findWords(Grid grid): Future<List<Word>>
///   그리드에서 유효한 단어 찾기
///
/// - getWordSuggestions(String pattern): Future<List<String>>
///   패턴에 맞는 단어 제안 가져오기
///
/// - calculateWordPoints(Word word, int level): int
///   단어의 점수 계산
///
/// 사전 기능:
/// - openDictionary(String word): Future<bool>
///   국립국어원 사전에서 단어 검색

/// 한글 단어 처리를 담당하는 클래스
class WordProcessor {
  final WordService _wordService = WordService();
  final Random _random = Random();

  // 빈도 기반 한글 글자 데이터
  List<String> _top100Chars = [];
  List<String> _top101_200Chars = [];
  List<String> _top201_300Chars = [];
  bool _frequencyDataLoaded = false;

  // 현재 게임에 사용 중인 선택된 단어 목록
  List<String> _selectedWords = [];

  // 현재 사용 가능한 글자 목록
  final Set<String> _availableCharacters = {};

  // 각 단어 사용 횟수 카운트
  final Map<String, int> _wordUsageCount = {};

  // 단어 선택 시 최소/최대 길이
  static const int _minWordLength = 2;
  static const int _maxWordLength = 5;

  // 한 번에 선택할 단어 수
  static const int _wordsPerBatch = 10;

  // 자주 사용되는 한글 글자 목록 (약 150개)
  static const List<String> _commonKoreanChars = [
    // 기본 자주 사용되는 초성+중성 조합
    '가', '나', '다', '라', '마', '바', '사', '아', '자', '차', '카', '타', '파', '하',
    '개', '내', '대', '래', '매', '배', '새', '애', '재', '채', '캐', '태', '패', '해',
    '거', '너', '더', '러', '머', '버', '서', '어', '저', '처', '커', '터', '퍼', '허',
    '게', '네', '데', '레', '메', '베', '세', '에', '제', '체', '케', '테', '페', '헤',
    '고', '노', '도', '로', '모', '보', '소', '오', '조', '초', '코', '토', '포', '호',
    '구', '누', '두', '루', '무', '부', '수', '우', '주', '추', '쿠', '투', '푸', '후',
    '그', '느', '드', '르', '므', '브', '스', '으', '즈', '츠', '크', '트', '프', '흐',
    '기', '니', '디', '리', '미', '비', '시', '이', '지', '치', '키', '티', '피', '히',

    // 자주 사용되는 복합 글자
    '강', '경', '공', '관', '교', '국', '군', '권', '귀', '규', '균', '극', '근', '금', '기',
    '길', '김', '꿈', '나', '날', '남', '내', '논', '달', '담', '당', '대', '더', '데', '도',
    '동', '돈', '되', '된', '두', '들', '등', '딸', '때', '땅', '떼', '뜻', '라', '락', '란',
    '람', '량', '러', '려', '력', '련', '령', '례', '로', '록', '론', '료', '루', '류', '률',
    '리', '린', '림', '립', '마', '만', '말', '맑', '매', '맵', '면', '명', '몸', '무', '물',
    '미', '민', '바', '방', '배', '백', '뱀', '버', '번', '벌', '범', '법', '변', '별', '보',
    '복', '본', '부', '북', '불', '비', '빛', '사', '산', '살', '상', '새', '생', '서', '석',
    '선', '설', '성', '세', '소', '속', '손', '송', '수', '순', '술', '숲', '쉬', '슬', '습',
    '시', '식', '신', '실', '심', '십', '싸', '쌀', '썩', '쏘', '씨', '아', '악', '안', '알',
    '암', '압', '앞', '야', '양', '어', '억', '언', '얼', '엄', '업', '에'
  ];

  // 자음+모음 조합 문자 매핑
  static final Map<String, Map<String, String>> _charMapping = {
    'ㄱ': {
      'ㅏ': '가',
      'ㅑ': '갸',
      'ㅓ': '거',
      'ㅕ': '겨',
      'ㅗ': '고',
      'ㅛ': '교',
      'ㅜ': '구',
      'ㅠ': '규',
      'ㅡ': '그',
      'ㅣ': '기',
      'ㅐ': '개',
      'ㅒ': '걔',
      'ㅔ': '게',
      'ㅖ': '계'
    },
    // 나머지 자음에 대한 매핑은 실제 구현 시 추가
  };

  static const List<String> _consonants = [
    'ㄱ',
    'ㄴ',
    'ㄷ',
    'ㄹ',
    'ㅁ',
    'ㅂ',
    'ㅅ',
    'ㅇ',
    'ㅈ',
    'ㅊ',
    'ㅋ',
    'ㅌ',
    'ㅍ',
    'ㅎ'
  ];

  static const List<String> _vowels = [
    'ㅏ',
    'ㅑ',
    'ㅓ',
    'ㅕ',
    'ㅗ',
    'ㅛ',
    'ㅜ',
    'ㅠ',
    'ㅡ',
    'ㅣ',
    'ㅐ',
    'ㅒ',
    'ㅔ',
    'ㅖ'
  ];

  /// 초기화
  Future<void> initialize() async {
    if (!_wordService.isInitialized) {
      await _wordService.initialize();
      await _wordService.preloadCommonConsonants();
    }

    if (!_frequencyDataLoaded) {
      await _loadFrequencyData();
    }

    // 초기 단어 세트 선택
    await _selectNewWordBatch();
  }

  /// 빈도 데이터 파일 로드
  Future<void> _loadFrequencyData() async {
    try {
      // Top 100 글자 로드
      final top100Text =
          await rootBundle.loadString('assets/data/korean_chars_top100.txt');
      _top100Chars = top100Text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      // Top 101-200 글자 로드
      final top200Text = await rootBundle
          .loadString('assets/data/korean_chars_top101_200.txt');
      _top101_200Chars = top200Text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      // Top 201-300 글자 로드
      final top300Text = await rootBundle
          .loadString('assets/data/korean_chars_top201_300.txt');
      _top201_300Chars = top300Text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      print(
          '빈도 데이터 로드 완료: Top 100 (${_top100Chars.length}개), Top 101-200 (${_top101_200Chars.length}개), Top 201-300 (${_top201_300Chars.length}개)');
      _frequencyDataLoaded = true;
    } catch (e) {
      print('빈도 데이터 로드 실패: $e');
      _setupDefaultFrequencyData();
    }
  }

  /// 기본 빈도 데이터 설정
  void _setupDefaultFrequencyData() {
    _top100Chars = _commonKoreanChars.take(100).toList();
    _top101_200Chars = _commonKoreanChars.length > 100
        ? _commonKoreanChars.sublist(100, min(200, _commonKoreanChars.length))
        : [];
    _top201_300Chars = _commonKoreanChars.length > 200
        ? _commonKoreanChars.sublist(200, min(300, _commonKoreanChars.length))
        : [];
    _frequencyDataLoaded = true;
  }

  /// 새 단어 배치 선택
  Future<void> _selectNewWordBatch() async {
    print('새로운 단어 배치 선택 중...');

    // 기존 사용 중인 단어들 사용 횟수 초기화
    _wordUsageCount.clear();

    // 서비스에서 단어 목록 가져오기
    List<String> allWords = _wordService.getValidWords().toList();

    if (allWords.isEmpty) {
      print('사용 가능한 단어가 없습니다. 서비스가 제대로 초기화되었는지 확인하세요.');
      // 서비스가 초기화되지 않았거나 단어가 없는 경우, 강제로 초기화 시도
      await _wordService.initialize();
      allWords = _wordService.getValidWords().toList();
    }

    // 단어 필터링 (길이에 따라)
    List<String> filteredWords = allWords
        .where((word) =>
            word.length >= _minWordLength && word.length <= _maxWordLength)
        .toList();

    if (filteredWords.isEmpty) {
      print('필터링된 단어가 없습니다. 모든 단어 사용');
      filteredWords = allWords;
    }

    // 필터링된 단어 중 무작위로 선택
    filteredWords.shuffle(_random);
    _selectedWords = filteredWords.take(_wordsPerBatch).toList();

    // 선택된 단어가 없는 경우(예외 상황)에도 게임이 작동하게 기본 단어 추가
    if (_selectedWords.isEmpty) {
      _selectedWords = [
        '사과',
        '바나나',
        '학교',
        '공부',
        '친구',
        '가족',
        '행복',
        '사랑',
        '여행',
        '음식'
      ];
    }

    // 선택된 단어에서 고유 글자 추출
    _updateAvailableCharacters();

    print('선택된 단어 배치: $_selectedWords');
    print('사용 가능한 글자 목록: $_availableCharacters');
  }

  /// 사용 가능한 글자 목록 업데이트
  void _updateAvailableCharacters() {
    _availableCharacters.clear();

    for (String word in _selectedWords) {
      for (int i = 0; i < word.length; i++) {
        _availableCharacters.add(word[i]);
      }
    }

    // 글자 수가 너무 적으면 기본 글자 추가
    if (_availableCharacters.length < 10) {
      for (int i = 0; i < 10 && i < _commonKoreanChars.length; i++) {
        _availableCharacters.add(_commonKoreanChars[i]);
      }
    }
  }

  /// 현재 선택된 단어 세트에서 글자 가져오기
  String getCharFromWordSet() {
    // 사용 가능한 글자가 없으면 새로운 단어 세트 선택
    if (_availableCharacters.isEmpty) {
      _selectNewWordBatch();

      // 그래도 없으면 기본 글자 반환
      if (_availableCharacters.isEmpty) {
        return _commonKoreanChars[_random.nextInt(_commonKoreanChars.length)];
      }
    }

    // 사용 가능한 글자 중 랜덤 선택
    List<String> charList = _availableCharacters.toList();
    return charList[_random.nextInt(charList.length)];
  }

  /// 빈도 기반 랜덤 글자 선택 (이전 방식)
  String getFrequencyBasedChar() {
    // 현재 선택된 단어 세트에서 글자 가져오기
    return getCharFromWordSet();
  }

  /// 랜덤 자음 기반 문자 생성
  String getRandomConsonantChar() {
    // 현재 선택된 단어 세트에서 글자 가져오기
    return getCharFromWordSet();
  }

  /// 랜덤 모음 기반 문자 생성
  String getRandomVowelChar() {
    // 현재 선택된 단어 세트에서 글자 가져오기
    return getCharFromWordSet();
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

              // 찾은 단어가 현재 선택된 단어 세트에 있으면 사용 카운트 증가
              if (_selectedWords.contains(word)) {
                _wordUsageCount[word] = (_wordUsageCount[word] ?? 0) + 1;

                // 모든 선택된 단어가 한 번 이상 사용되었는지 확인
                if (_isAllWordsUsed()) {
                  // 새 단어 세트 선택
                  _selectNewWordBatch();
                }
              }
            }
          }
        }
      }
    }

    return wordCandidates;
  }

  /// 모든 단어가 사용되었는지 확인
  bool _isAllWordsUsed() {
    int usedWordsCount = 0;

    for (String word in _selectedWords) {
      if (_wordUsageCount.containsKey(word) && _wordUsageCount[word]! > 0) {
        usedWordsCount++;
      }
    }

    // 70% 이상의 단어가 사용되었는지 확인
    return usedWordsCount >= (_selectedWords.length * 0.7).round();
  }

  /// 단어 점수 계산
  int calculateWordPoints(Word word, int level) {
    int points = word.text.length * 10;
    points = (points * (1 + (level - 1) * 0.1)).round();
    return points;
  }

  /// 패턴에 맞는 단어 제안 가져오기
  Future<List<String>> getWordSuggestions(String pattern) async {
    if (pattern.isEmpty || pattern.length < 3) {
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
      print('URL 열기 오류: $e');
      return false;
    }
  }

  /// 현재 선택된 단어 목록 반환
  List<String> get selectedWords => List.unmodifiable(_selectedWords);

  /// 단어 사용 횟수 반환
  Map<String, int> get wordUsageCount => Map.unmodifiable(_wordUsageCount);

  /// 새 단어 세트 수동 선택
  Future<void> selectNewWordSet() async {
    await _selectNewWordBatch();
  }
}
