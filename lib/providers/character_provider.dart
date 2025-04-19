import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../services/word_service.dart';

/// WordTris 게임의 한글 문자 생성 및 관리를 담당하는 클래스 API 문서
///
/// [CharacterProvider] 클래스
/// 빈도 기반 한글 문자 생성과 단어 세트 관리를 담당하는 클래스
///
/// 주요 기능:
/// - 빈도 기반 한글 문자 생성
/// - 단어 세트에서 문자 관리
/// - 사용된 단어 추적
///
/// 초기화 메서드:
/// - initialize(): Future<void>
///   한글 문자 처리를 위한 초기 설정 수행
///
/// 문자 생성 메서드:
/// - getRandomCharacter(): String
///   단어 세트에서 랜덤 문자 생성
///
/// - getCharFromWordSet(): String
///   선택된 단어 세트에서 무작위로 문자 생성
///
/// - getFrequencyBasedChar(): String
///   빈도 기반으로 문자 생성
///
/// - getRandomConsonantChar(): String
///   자음 기반 문자 생성
///
/// - getRandomVowelChar(): String
///   모음 기반 문자 생성
///
/// 단어 관리 메서드:
/// - selectNewWordSet(): Future<void>
///   새로운 단어 세트 선택
///
/// - incrementWordUsageCount(String word): void
///   단어 사용 횟수 증가
///
/// - updateWordUsage(String word): void
///   단어 사용 정보 업데이트
///
/// - isRareCharacter(String char): bool
///   희귀 문자 여부 확인
///
/// Getters:
/// - selectedWords: List<String>
///   현재 선택된 단어 목록
///
/// - wordUsageCount: Map<String, int>
///   단어별 사용 횟수
///
/// - availableCharacters: Set<String>
///   현재 사용 가능한 문자 목록

/// WordTris 게임의 한글 문자 생성 및 관리를 담당하는 클래스
///
/// 주요 기능:
/// - 빈도 기반 한글 문자 생성
/// - 단어 세트에서 문자 관리
/// - 사용된 단어 추적
class CharacterProvider with ChangeNotifier {
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

  CharacterProvider(this._wordService);

  /// 초기화
  Future<void> initialize() async {
    // 이미 초기화되었으면 중복 초기화 방지
    if (_initialized) {
      print('🔄 CharacterProvider가 이미 초기화되었습니다. 중복 호출 무시');
      return;
    }

    print('🚀 CharacterProvider 초기화 시작 (initialized=$_initialized)');

    if (!_wordService.isInitialized) {
      print('📚 WordService 초기화 시작');
      await _wordService.initialize();
      await _wordService.preloadCommonConsonants();
      print('📚 WordService 초기화 완료');
    }

    if (!_frequencyDataLoaded) {
      print('📊 빈도 데이터 로드 시작');
      await _loadFrequencyData();
      print('📊 빈도 데이터 로드 완료');
    }

    // 초기 단어 세트 선택
    print('📝 초기 단어 세트 선택 시작 (via initialize)');
    await selectNewWordSet();
    print('📝 초기 단어 세트 선택 완료 (via initialize)');

    // 초기화 완료 표시
    _initialized = true;
    print('✅ CharacterProvider 초기화 완료 (_initialized=$_initialized)');
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
  Future<void> selectNewWordSet({bool replaceAll = false}) async {
    print('📦 [DEBUG] 새로운 단어 배치 선택 시작 - 호출 스택: ${StackTrace.current}');
    print('🔍 [DEBUG] 모드: ${replaceAll ? "전체 교체" : "추가"}');
    // print('🔄 [DEBUG] 선택 전 단어 수: ${_selectedWords.length}개');

    // 초기 호출 여부 또는 전체 교체 모드인 경우
    bool isInitialCall = _selectedWords.isEmpty;

    if (isInitialCall || replaceAll) {
      // 기존 사용 중인 단어들의 사용 횟수 초기화
      _wordUsageCount.clear();

      // 서비스에서 단어 목록 가져오기
      List<String> allWords = _wordService.getValidWords().toList();

      if (allWords.isEmpty) {
        print('⚠️ [DEBUG] 사용 가능한 단어가 없습니다. 서비스가 제대로 초기화되었는지 확인하세요.');
        // 서비스가 초기화되지 않았거나 단어가 없는 경우, 강제로 초기화 시도
        await _wordService.initialize();
        allWords = _wordService.getValidWords().toList();
        // print('🔄 [DEBUG] WordService 재초기화 후 단어 개수: ${allWords.length}개');
      }

      // 단어 필터링 (길이에 따라)
      List<String> filteredWords = allWords
          .where((word) =>
              word.length >= _minWordLength && word.length <= _maxWordLength)
          .toList();

      if (filteredWords.isEmpty) {
        print('⚠️ [DEBUG] 필터링된 단어가 없습니다. 모든 단어 사용');
        filteredWords = allWords;
      } else {
        // print('📋 [DEBUG] 길이 필터링 후 단어 개수: ${filteredWords.length}개');
      }

      // 필터링된 단어 중 무작위로 선택
      filteredWords.shuffle(_random);

      // print(
      //     '🎲 [DEBUG] 선택 전 - 초기호출: $isInitialCall, 필터링된 단어: ${filteredWords.length}개, 현재 단어: ${_selectedWords.length}개');

      // 기존 단어 모두 제거
      _selectedWords.clear();

      // 초기 단어 세트 선택 (_initialWordsCount개)
      for (int i = 0; i < min(_initialWordsCount, filteredWords.length); i++) {
        String word = filteredWords[i];
        _selectedWords.add(word);
        _wordUsageCount[word] = 0; // 새 단어의 사용 횟수 명시적으로 초기화
      }

      print(
          '🆕 [DEBUG] 초기화 - 새 단어 ${_selectedWords.length}개 선택됨: $_selectedWords');
    } else {
      // 추가 모드 - 이미 존재하는 메서드 사용
      await _addNewWords();
    }

    // 선택된 단어가 없는 경우(예외 상황)에도 게임이 작동하게 기본 단어 추가
    if (_selectedWords.isEmpty) {
      print('⚠️ [DEBUG] 선택된 단어가 없습니다. 기본 단어 목록 사용');
      List<String> defaultWords = [
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

      for (String word in defaultWords) {
        _selectedWords.add(word);
        _wordUsageCount[word] = 0; // 기본 단어의 사용 횟수 초기화
      }
    }

    // 단어 사용 횟수 정보 디버깅 출력
    // print('📊 [DEBUG] 현재 단어 사용 횟수:');
    // _selectedWords.forEach((word) {
    //   print('  - "$word": ${_wordUsageCount[word] ?? 0}회');
    // });

    // 선택된 단어에서 고유 글자 추출
    _updateAvailableCharacters();

    print('✅ [DEBUG] 선택된 단어 배치 (${_selectedWords.length}개): $_selectedWords');
    // print(
    //     '🔤 [DEBUG] 사용 가능한 글자 목록 (${_availableCharacters.length}개): $_availableCharacters');

    // 변경사항 알림
    // print(
    //     '📢 [DEBUG] CharacterProvider.notifyListeners() 호출 - selectNewWordSet');
    // UI 갱신을 위한 상태 변경 알림 호출
    notifyListeners();
    // print(
    //     '📢 [DEBUG] CharacterProvider.notifyListeners() 완료 - selectNewWordSet');
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
      print('🔄 사용 가능한 글자가 없어서 글자 목록 재생성');
      // 기존 단어에서 글자만 다시 채우기
      _refillCharacters();

      // 그래도 없으면 기본 글자 반환
      if (_availableCharacters.isEmpty) {
        return _commonKoreanChars[_random.nextInt(_commonKoreanChars.length)];
      }
    }

    // 사용 가능한 글자 중 랜덤 선택
    List<String> charList = _availableCharacters.toList();
    int selectedIndex = _random.nextInt(charList.length);
    String selectedChar = charList[selectedIndex];

    // 선택된 글자를 목록에서 제거
    _availableCharacters.remove(selectedChar);

    // 선택된 글자가 포함된 단어 사용 횟수 업데이트
    _updateCharacterUsageInWords(selectedChar);

    // 글자 수가 너무 적어지면 글자 목록 재생성 (단어 세트는 그대로 유지)
    if (_availableCharacters.length < 5) {
      print('🔄 사용 가능한 글자가 5개 미만으로 줄어 글자 목록을 재생성합니다');
      _refillCharacters();
    }

    return selectedChar;
  }

  /// 선택된 글자가 포함된 단어들의 사용 추적 업데이트
  void _updateCharacterUsageInWords(String character) {
    // 이 글자를 포함하는 단어들을 찾아서 사용 상태 업데이트
    bool anyWordUpdated = false;

    for (String word in _selectedWords) {
      if (word.contains(character)) {
        // 단어 사용 횟수 맵에 없으면 초기화
        if (!_wordUsageCount.containsKey(word)) {
          _wordUsageCount[word] = 0;
        }

        // 이 단어의 모든 글자가 이미 사용되었는지 확인
        bool allCharsUsed = true;
        for (int i = 0; i < word.length; i++) {
          String char = word[i];
          if (char != character && _availableCharacters.contains(char)) {
            // 아직 사용되지 않은 글자가 있음
            allCharsUsed = false;
            break;
          }
        }

        if (allCharsUsed) {
          // 단어의 모든 글자가 사용됨 - 사용 횟수 증가
          _wordUsageCount[word] = (_wordUsageCount[word] ?? 0) + 1;
          // print('📊 [DEBUG] 단어 "$word"의 모든 글자가 사용됨 - 사용 횟수: ${_wordUsageCount[word]}');
          anyWordUpdated = true;
        }
      }
    }

    if (anyWordUpdated) {
      // 단어 사용 비율 확인 및 새 단어 추가 여부 결정
      _checkWordUsageRatioAndUpdateIfNeeded();
    }
  }

  /// 단어 사용 비율을 확인하고 필요시 새 단어 세트 추가
  void _checkWordUsageRatioAndUpdateIfNeeded() {
    // 사용된 단어 수와 비율 계산
    int usedWordsCount =
        _selectedWords.where((w) => (_wordUsageCount[w] ?? 0) > 0).length;
    double usageRatio = usedWordsCount / _selectedWords.length;

    // print('📊 [DEBUG] 현재 단어 사용 비율: ${(usageRatio * 100).toStringAsFixed(1)}% ($usedWordsCount/${_selectedWords.length})');

    // 70% 이상의 단어가 사용되었는지 확인
    if (usageRatio >= 0.7) {
      print('🔔 [DEBUG] 70% 이상의 단어가 사용되었습니다. 새 단어 세트를 추가합니다.');
      _addNewWords();
    }
  }

  /// 기존 단어에서 글자만 다시 채우기 (단어 세트 변경 없음)
  void _refillCharacters() {
    _availableCharacters.clear();

    // 현재 선택된 단어에서 글자 추출하여 다시 채우기
    for (String word in _selectedWords) {
      for (int i = 0; i < word.length; i++) {
        _availableCharacters.add(word[i]);
      }
    }

    // 글자 수가 여전히 너무 적으면 기본 글자 추가
    if (_availableCharacters.length < 10) {
      for (int i = 0; i < 10 && i < _commonKoreanChars.length; i++) {
        _availableCharacters.add(_commonKoreanChars[i]);
      }
    }

    print('🔄 글자 목록 재충전 완료. 현재 ${_availableCharacters.length}개 글자 가능');
  }

  /// 빈도 기반 랜덤 글자 선택
  String getFrequencyBasedChar() {
    return getCharFromWordSet();
  }

  /// 랜덤 자음 기반 문자 생성
  String getRandomConsonantChar() {
    return getCharFromWordSet();
  }

  /// 랜덤 모음 기반 문자 생성
  String getRandomVowelChar() {
    return getCharFromWordSet();
  }

  /// 단어 사용 횟수 증가시키기
  void incrementWordUsageCount(String word) {
    print('incrementWordUsageCount 호출: $word');

    // 단어 사용 카운트 증가
    if (_selectedWords.contains(word)) {
      _wordUsageCount[word] = (_wordUsageCount[word] ?? 0) + 1;
      print('단어 "$word" 사용 횟수 증가: ${_wordUsageCount[word]}');

      // 사용된 단어의 수 계산
      var usedWordsCount =
          _selectedWords.where((w) => (_wordUsageCount[w] ?? 0) > 0).length;
      var usageRatio = usedWordsCount / _selectedWords.length;
      print(
          '현재 단어 사용 비율: ${(usageRatio * 100).toStringAsFixed(1)}% ($usedWordsCount/${_selectedWords.length})');

      // 여기서 단어 세트 변경 로직을 추가하려 했으나 아직 구현하지 않음
    } else {
      print('단어 "$word"는 선택된 단어 목록에 없습니다.');
    }
  }

  /// 현재 선택된 단어 목록 반환
  List<String> get selectedWords => List.unmodifiable(_selectedWords);

  /// 단어 사용 횟수 반환
  Map<String, int> get wordUsageCount => Map.unmodifiable(_wordUsageCount);

  /// 사용 가능한 문자 목록 반환
  Set<String> get availableCharacters => Set.unmodifiable(_availableCharacters);

  /// 랜덤 문자 생성 (블록, 그리드 채우기용)
  String getRandomCharacter() {
    return getCharFromWordSet();
  }

  /// 희귀 문자 여부 확인 (점수 계산용)
  bool isRareCharacter(String char) {
    // Top 200에 포함되지 않은 글자는 희귀 글자로 간주
    return !_top100Chars.contains(char) && !_top101_200Chars.contains(char);
  }

  /// 단어 사용 정보 업데이트
  void updateWordUsage(String word) {
    // print('📊 [DEBUG] 단어 사용 정보 업데이트: "$word"');

    if (!_selectedWords.contains(word)) {
      // print('⚠️ [DEBUG] 단어 "$word"는 선택된 단어 목록에 없습니다.');
      return;
    }

    // 단어 사용 횟수 증가 - 단어가 그리드에서 형성되었을 때 호출됨
    _wordUsageCount[word] = (_wordUsageCount[word] ?? 0) + 1;
    // print('📈 [DEBUG] 단어 "$word" 사용 횟수 증가: ${_wordUsageCount[word]}');

    // 단어 사용 비율 확인 및 새 단어 추가 여부 결정
    _checkWordUsageRatioAndUpdateIfNeeded();

    // 변경사항 알림
    // print('📢 [DEBUG] CharacterProvider.notifyListeners() 호출 - updateWordUsage');
    notifyListeners();
    // print('📢 [DEBUG] CharacterProvider.notifyListeners() 완료 - updateWordUsage');
  }

  /// 새 단어를 추가합니다 (기존 단어는 유지)
  Future<void> _addNewWords() async {
    print('📦 [DEBUG] 새 단어 배치 추가 시작');
    // print('🔄 [DEBUG] 추가 전 단어 수: ${_selectedWords.length}개');

    // 서비스에서 단어 목록 가져오기
    List<String> allWords = _wordService.getValidWords().toList();
    if (allWords.isEmpty) {
      print('⚠️ [DEBUG] 사용 가능한 단어가 없습니다.');
      return;
    }

    // 단어 필터링 (길이에 따라)
    List<String> filteredWords = allWords
        .where((word) =>
            word.length >= _minWordLength && word.length <= _maxWordLength)
        .toList();

    // 이미 선택된 단어를 제외한 단어들만 필터링
    filteredWords =
        filteredWords.where((word) => !_selectedWords.contains(word)).toList();
    // print('📋 [DEBUG] 중복 제거 후 필터링된 단어 개수: ${filteredWords.length}개');

    if (filteredWords.isEmpty) {
      print('⚠️ [DEBUG] 추가할 새 단어가 없습니다. 모든 단어 재사용');
      // 사용된 단어를 제외한 모든 단어를 다시 사용
      filteredWords = allWords
          .where((word) =>
              word.length >= _minWordLength &&
              word.length <= _maxWordLength &&
              !_selectedWords.contains(word))
          .toList();

      if (filteredWords.isEmpty) {
        print('⚠️ [DEBUG] 여전히 단어가 없습니다. 기본 단어 사용');
        filteredWords = [
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
        ].where((word) => !_selectedWords.contains(word)).toList();
      }
    }

    // 필터링된 단어 중 무작위로 선택
    filteredWords.shuffle(_random);

    // 새 단어 추가 (_wordsPerBatch개)
    final int newWordCount = min(_wordsPerBatch, filteredWords.length);
    List<String> newWords = filteredWords.take(newWordCount).toList();

    if (newWords.isEmpty) {
      print('⚠️ [DEBUG] 추가할 새 단어가 없습니다.');
      return;
    }

    // 새 단어 추가 및 사용 횟수 초기화
    for (String word in newWords) {
      _selectedWords.add(word);
      _wordUsageCount[word] = 0; // 새 단어의 사용 횟수 초기화
    }
    print('➕ [DEBUG] 단어 배치에 새 단어 ${newWords.length}개 추가: $newWords');

    // 단어 개수가 최대 표시 개수를 초과하면 오래된 단어부터 제거
    final List<String> removedWords = [];
    while (_selectedWords.length > _maxDisplayedWords) {
      final String removed = _selectedWords.removeAt(0); // 가장 오래된 단어 제거
      removedWords.add(removed);
      _wordUsageCount.remove(removed); // 사용 횟수 정보도 제거
    }

    if (removedWords.isNotEmpty) {
      print(
          '🗑️ [DEBUG] 최대 표시 개수 초과로 ${removedWords.length}개 단어 제거됨: $removedWords');
    }

    // 단어 사용 횟수 정보 디버깅 출력
    // print('📊 [DEBUG] 현재 단어 사용 횟수:');
    // _selectedWords.forEach((word) {
    //   print('  - "$word": ${_wordUsageCount[word] ?? 0}회');
    // });

    // 선택된 단어에서 고유 글자 추출 (사용 가능한 글자 업데이트)
    _updateAvailableCharacters();

    print('✅ [DEBUG] 새 단어 배치 추가 완료. 현재 단어 ${_selectedWords.length}개');
    // print('📋 [DEBUG] 현재 단어 목록: $_selectedWords');

    // 변경사항 알림 - UI 갱신을 위해 반드시 호출해야 함
    // print('📢 [DEBUG] CharacterProvider.notifyListeners() 호출 - _addNewWords');
    notifyListeners();
    // print('📢 [DEBUG] CharacterProvider.notifyListeners() 완료 - _addNewWords');
  }
}
