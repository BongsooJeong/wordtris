import 'package:flutter/services.dart';
import 'dart:math';
import '../services/word_service.dart';

/// 한글 문자 관리를 위한 내부 클래스
///
/// 문자 생성, 단어 세트 관리, 사용된 단어 추적 등의 내부 로직을 처리
class CharacterManager {
  final WordService _wordService;
  final Random _random = Random();

  // 빈도 기반 한글 글자 데이터
  List<String> _top100Chars = [];
  List<String> _top101_200Chars = [];
  List<String> _top201_300Chars = [];
  bool _frequencyDataLoaded = false;

  // 초기화 상태 추적
  bool _initialized = false;

  // 현재 게임에 사용 중인 선택된 단어 목록
  final List<String> _selectedWords = [];

  // 현재 사용 가능한 글자 목록
  final Set<String> _availableCharacters = {};

  // 각 단어 사용 횟수 카운트
  final Map<String, int> _wordUsageCount = {};

  // 단어 선택 시 최소/최대 길이
  static const int _minWordLength = 2;
  static const int _maxWordLength = 5;

  // 초기 단어 개수
  static const int _initialWordsCount = 10;

  // 한 번에 추가할 단어 수
  static const int _wordsPerBatch = 10;

  // 한 번에 표시할 최대 단어 수
  static const int _maxDisplayedWords = 20;

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

  CharacterManager(this._wordService);

  /// 초기화 상태 확인
  bool get isInitialized => _initialized;

  /// 빈도 데이터 로드 상태 확인
  bool get isFrequencyDataLoaded => _frequencyDataLoaded;

  /// 초기화
  Future<void> initialize() async {
    // 이미 초기화되었으면 중복 초기화 방지
    if (_initialized) {
      print('🔄 CharacterManager가 이미 초기화되었습니다. 중복 호출 무시');
      return;
    }

    print('🚀 CharacterManager 초기화 시작');

    if (!_wordService.isInitialized) {
      print('📚 WordService 초기화 시작');
      await _wordService.initialize();
      await _wordService.preloadCommonConsonants();
      print('📚 WordService 초기화 완료');
    }

    if (!_frequencyDataLoaded) {
      await _loadFrequencyData();
    }

    // 초기화 완료 표시
    _initialized = true;
    print('✅ CharacterManager 초기화 완료');
  }

  /// 빈도 데이터 파일 로드
  Future<void> _loadFrequencyData() async {
    print('📊 빈도 데이터 로드 시작');

    bool anyFileLoadFailed = false;

    try {
      // Top 100 글자 로드 시도
      try {
        final top100Text =
            await rootBundle.loadString('assets/data/korean_chars_top100.txt');
        _top100Chars = top100Text
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
        print('📊 Top 100 글자 로드 완료: ${_top100Chars.length}개');
      } catch (e) {
        print('⚠️ Top 100 글자 로드 실패: $e - 기본 데이터 사용');
        _top100Chars = _commonKoreanChars.take(100).toList();
        anyFileLoadFailed = true;
      }

      // 나머지 빈도 데이터는 기본 데이터 사용
      _top101_200Chars = _commonKoreanChars.length > 100
          ? _commonKoreanChars.sublist(100, min(200, _commonKoreanChars.length))
          : [];
      print('📊 Top 101-200 글자: ${_top101_200Chars.length}개 (기본 데이터)');

      _top201_300Chars = _commonKoreanChars.length > 200
          ? _commonKoreanChars.sublist(200, min(300, _commonKoreanChars.length))
          : [];
      print('📊 Top 201-300 글자: ${_top201_300Chars.length}개 (기본 데이터)');

      _frequencyDataLoaded = true;

      if (anyFileLoadFailed) {
        print('⚠️ 일부 빈도 데이터 파일이 누락되어 기본 데이터로 대체되었습니다.');
      }

      print(
          '📊 빈도 데이터 준비 완료: Top 100 (${_top100Chars.length}개), Top 101-200 (${_top101_200Chars.length}개), Top 201-300 (${_top201_300Chars.length}개)');
    } catch (e) {
      print('❌ 빈도 데이터 로드 과정에서 예상치 못한 오류 발생: $e');
      _setupDefaultFrequencyData();
    }

    print('📊 빈도 데이터 로드 과정 완료');
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

  /// 초기 단어 세트를 선택
  Future<List<String>> getInitialWordSet() async {
    List<String> allWords = _wordService.getValidWords().toList();
    if (allWords.isEmpty) {
      await _wordService.initialize();
      allWords = _wordService.getValidWords().toList();
    }

    // 단어 필터링 (길이에 따라)
    List<String> filteredWords = allWords
        .where((word) =>
            word.length >= _minWordLength && word.length <= _maxWordLength)
        .toList();

    if (filteredWords.isEmpty) {
      filteredWords = allWords;
    }

    // 필터링된 단어 중 무작위로 선택
    filteredWords.shuffle(_random);

    // 초기 단어 세트 반환
    return filteredWords
        .take(min(_initialWordsCount, filteredWords.length))
        .toList();
  }

  /// 사용 가능한 단어 목록에서 새 단어 배치 가져오기
  Future<List<String>> getNewWordBatch(List<String> currentWords) async {
    List<String> allWords = _wordService.getValidWords().toList();
    if (allWords.isEmpty) {
      return [];
    }

    // 단어 필터링 (길이와 중복 제거)
    List<String> filteredWords = allWords
        .where((word) =>
            word.length >= _minWordLength &&
            word.length <= _maxWordLength &&
            !currentWords.contains(word))
        .toList();

    if (filteredWords.isEmpty) {
      return [];
    }

    // 필터링된 단어 중 무작위로 선택
    filteredWords.shuffle(_random);

    // 새 단어 배치 반환
    return filteredWords
        .take(min(_wordsPerBatch, filteredWords.length))
        .toList();
  }

  /// 기본 단어 목록 반환
  List<String> getDefaultWords() {
    return ['사과', '바나나', '학교', '공부', '친구', '가족', '행복', '사랑', '여행', '음식'];
  }

  /// 현재 선택된 단어 세트에서 사용 가능한 글자 목록 생성
  Set<String> generateAvailableCharacters(List<String> words) {
    Set<String> chars = {};

    for (String word in words) {
      for (int i = 0; i < word.length; i++) {
        chars.add(word[i]);
      }
    }

    // 글자 수가 너무 적으면 기본 글자 추가
    if (chars.length < 10) {
      for (int i = 0; i < 10 && i < _commonKoreanChars.length; i++) {
        chars.add(_commonKoreanChars[i]);
      }
    }

    return chars;
  }

  /// 단어에서 글자 랜덤 선택
  String getRandomCharacter(Set<String> availableChars) {
    if (availableChars.isEmpty) {
      return _commonKoreanChars[_random.nextInt(_commonKoreanChars.length)];
    }

    List<String> charList = availableChars.toList();
    return charList[_random.nextInt(charList.length)];
  }

  /// 희귀 문자 여부 확인 (점수 계산용)
  bool isRareCharacter(String char) {
    // Top 200에 포함되지 않은 글자는 희귀 글자로 간주
    return !_top100Chars.contains(char) && !_top101_200Chars.contains(char);
  }

  /// 단어 목록에서 해당 글자를 포함하는 단어를 모두 찾기
  List<String> findWordsContainingCharacter(
      String character, List<String> wordList) {
    return wordList.where((word) => word.contains(character)).toList();
  }

  /// WordService 인스턴스 반환
  WordService get wordService => _wordService;

  /// 단어 사용 가능 상태 확인
  bool isWordValid(String word) {
    return _wordService.getValidWords().contains(word);
  }
}
