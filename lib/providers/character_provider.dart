import 'package:flutter/material.dart';
import './character_manager.dart';
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
/// - 표시할 단어 목록 관리
/// - 사용 가능한 글자 목록 유지
/// - 단어 사용 횟수 추적
///
/// 초기화 메서드:
/// - initialize(): Future<void>
///   문자 제공자 초기화 및 초기 단어 세트 선택
///
/// 단어 관련 메서드:
/// - selectNewWordSet({bool replaceAll = false}): Future<void>
///   새 단어 세트 선택 (전체 교체 또는 추가)
///
/// - updateWordUsage(String word): void
///   단어 사용 기록 업데이트
///
/// - incrementWordUsageCount(String word): void
///   단어 사용 횟수 증가
///
/// 문자 관련 메서드:
/// - getRandomCharacter(): Future<String>
///   사용 가능한 글자 중 하나를 선택하고 목록에서 제거
///
/// - getFrequencyBasedChar(): Future<String>
///   빈도 기반으로 한글 문자 선택
///
/// - getRandomConsonantChar(): Future<String>
///   랜덤 자음 기반 문자 선택
///
/// - getRandomVowelChar(): Future<String>
///   랜덤 모음 기반 문자 선택
///
/// 유틸리티 메서드:
/// - isRareCharacter(String char): bool
///   희귀 문자 여부 확인 (점수 계산용)
///
/// Getters:
/// - selectedWords: List<String>
///   현재 화면에 표시할 단어 목록
///
/// - wordUsageCount: Map<String, int>
///   각 단어의 사용 횟수
///
/// - availableCharacters: Set<String>
///   현재 사용 가능한 글자 목록
class CharacterProvider with ChangeNotifier {
  final CharacterManager _manager;

  // 현재 게임에 사용 중인 선택된 단어 목록 (글자 생성용)
  final List<String> _selectedWords = [];

  // 화면에 표시하는 추천 단어 목록 (UI 표시용)
  final List<String> _displayedWords = [];

  // 현재 사용 가능한 글자 목록
  final Set<String> _availableCharacters = {};

  // 각 단어 사용 횟수 카운트
  final Map<String, int> _wordUsageCount = {};

  // 한 번에 표시할 최대 단어 수
  static const int _maxDisplayedWords = 20;

  // 재귀 호출 방지 플래그
  bool _isSelectingWordSet = false;

  CharacterProvider(WordService wordService)
      : _manager = CharacterManager(wordService);

  /// 초기화
  Future<void> initialize() async {
    print(
        '🚀 CharacterProvider 초기화 시작 (initialized=${_manager.isInitialized})');

    // 내부 매니저 초기화
    await _manager.initialize();

    // 초기 단어 세트 선택
    print('📝 초기 단어 세트 선택 시작');
    await selectNewWordSet(replaceAll: true);
    print('📝 초기 단어 세트 선택 완료');

    print(
        '✅ CharacterProvider 초기화 완료 (_initialized=${_manager.isInitialized})');
  }

  /// 새 단어 배치 선택
  Future<void> selectNewWordSet({bool replaceAll = false}) async {
    // 이미 단어 세트 선택 중이면 중복 호출 방지
    if (_isSelectingWordSet) {
      print('⚠️ [DEBUG] 이미 단어 세트 선택 중입니다. 중복 호출 무시.');
      return;
    }

    _isSelectingWordSet = true;

    try {
      print('📦 [DEBUG] 새로운 단어 배치 선택 시작');
      print('🔍 [DEBUG] 모드: ${replaceAll ? "전체 교체" : "추가"}');

      if (replaceAll) {
        // 기존 상태 초기화
        _selectedWords.clear();
        _displayedWords.clear();
        _wordUsageCount.clear();

        // 초기 단어 세트 가져오기
        final initialWords = await _manager.getInitialWordSet();

        // 단어 목록 설정 및 사용 횟수 초기화
        for (String word in initialWords) {
          _selectedWords.add(word);
          _displayedWords.add(word);
          _wordUsageCount[word] = 0;
        }

        print(
            '🆕 [DEBUG] 초기화 - 새 단어 ${_selectedWords.length}개 선택됨: $_selectedWords');
      } else {
        // 기존 단어 유지하면서 새 단어 추가
        await _addNewWords();
      }

      // 선택된 단어가 없는 경우 기본 단어 추가
      if (_selectedWords.isEmpty) {
        print('⚠️ [DEBUG] 선택된 단어가 없습니다. 기본 단어 목록 사용');
        final defaultWords = _manager.getDefaultWords();

        for (String word in defaultWords) {
          _selectedWords.add(word);
          _displayedWords.add(word);
          _wordUsageCount[word] = 0;
        }
      }

      // 사용 가능한 글자 목록 업데이트
      _updateAvailableCharacters();

      print('✅ [DEBUG] 선택된 단어 배치 (${_selectedWords.length}개): $_selectedWords');
      notifyListeners();
    } finally {
      _isSelectingWordSet = false;
    }
  }

  /// 새 단어를 추가합니다 (기존 단어는 유지)
  Future<void> _addNewWords() async {
    print('📦 [DEBUG] 새 단어 배치 추가 시작');

    // 새 단어 배치 가져오기
    final newWords = await _manager.getNewWordBatch(_selectedWords);

    if (newWords.isEmpty) {
      print('⚠️ [DEBUG] 추가할 새 단어가 없습니다.');
      return;
    }

    // 새 단어 추가 및 사용 횟수 초기화
    for (String word in newWords) {
      _selectedWords.add(word);
      if (!_displayedWords.contains(word)) {
        _displayedWords.add(word);
      }
      _wordUsageCount[word] = 0;
    }
    print('➕ [DEBUG] 단어 배치에 새 단어 ${newWords.length}개 추가: $newWords');

    // 표시되는 단어 개수가 최대 표시 개수를 초과하면 오래된 단어부터 제거
    final List<String> removedWords = [];
    while (_displayedWords.length > _maxDisplayedWords) {
      final String removed = _displayedWords.removeAt(0);
      removedWords.add(removed);
    }

    if (removedWords.isNotEmpty) {
      print(
          '🗑️ [DEBUG] 최대 표시 개수 초과로 표시 목록에서 ${removedWords.length}개 단어 제거됨: $removedWords');
    }

    // 선택된 단어에서 고유 글자 추출 업데이트
    _updateAvailableCharacters();

    // 단어 추가 후 남은 글자 수 로그 추가
    print(
        '✅ [DEBUG] 새 단어 배치 추가 완료. 현재 단어 ${_selectedWords.length}개, 표시 중인 단어 ${_displayedWords.length}개, 사용 가능한 글자 ${_availableCharacters.length}개');
  }

  /// 사용 가능한 글자 목록 업데이트
  void _updateAvailableCharacters() {
    _availableCharacters.clear();

    // 매니저를 통해 글자 목록 생성
    final chars = _manager.generateAvailableCharacters(_selectedWords);
    _availableCharacters.addAll(chars);
  }

  /// 글자 목록 채우기 (새 단어 세트 추가)
  Future<void> _refillCharacters() async {
    print('📦 [DEBUG] 사용 가능한 글자가 없어 새 단어 세트 추가');

    // 기존 글자 생성용 단어 목록만 제거하고, 화면 표시용 단어 목록은 유지
    List<String> displayedWordsCopy = List.from(_displayedWords);
    print('🔄 [DEBUG] 화면 표시용 단어 목록 백업: $displayedWordsCopy');

    // 글자 생성용 단어 목록 초기화
    _selectedWords.clear();
    print('🗑️ [DEBUG] 모든 글자를 소진한 글자 생성용 단어 목록 제거');

    // 새 단어 추가
    await _addNewWords();

    // 새로 추가된 단어 목록 가져오기
    List<String> newAddedWords = _selectedWords
        .where((word) => !displayedWordsCopy.contains(word))
        .toList();
    print('🆕 [DEBUG] 새로 추가된 단어 (${newAddedWords.length}개): $newAddedWords');

    // 표시 목록 업데이트: 기존 단어 + 새 단어 (최대 표시 개수 유지)
    _displayedWords.clear();
    _displayedWords.addAll(displayedWordsCopy); // 기존 표시되던 단어 복원

    // 새 단어들을 표시 목록에 추가
    for (String word in newAddedWords) {
      _displayedWords.add(word);
      // 최대 표시 개수를 초과하면 가장 오래된 단어 제거
      if (_displayedWords.length > _maxDisplayedWords) {
        _displayedWords.removeAt(0);
      }
    }

    print(
        '📋 [DEBUG] 업데이트된 화면 표시 단어 목록 (${_displayedWords.length}개): $_displayedWords');

    // 여전히 글자가 없으면 기존 단어에서 추출
    if (_availableCharacters.isEmpty) {
      print('⚠️ [DEBUG] 새 단어 추가 후에도 글자가 없습니다. 기존 단어에서 글자 추출');
      _availableCharacters.clear();
      final chars = _manager.generateAvailableCharacters(_selectedWords);
      _availableCharacters.addAll(chars);
    }

    print(
        '🔄 [DEBUG] 글자 목록 재충전 완료. 글자 생성용 단어 ${_selectedWords.length}개, 화면 표시용 단어 ${_displayedWords.length}개, 사용 가능한 글자 ${_availableCharacters.length}개');

    // 단어 목록이 변경되었으므로 알림
    notifyListeners();
  }

  /// 단어 사용 횟수 증가시키기
  void incrementWordUsageCount(String word) {
    print('incrementWordUsageCount 호출: $word');

    if (_displayedWords.contains(word)) {
      _wordUsageCount[word] = (_wordUsageCount[word] ?? 0) + 1;
      notifyListeners();
    }
  }

  /// 단어 사용 정보 업데이트
  void updateWordUsage(String word) {
    if (!_displayedWords.contains(word)) {
      return;
    }

    // 단어 사용 횟수 증가 - 단어가 그리드에서 형성되었을 때 호출됨
    _wordUsageCount[word] = (_wordUsageCount[word] ?? 0) + 1;
    notifyListeners();
  }

  /// 현재 선택된 단어 목록 반환 (화면에 표시용)
  List<String> get selectedWords => List.unmodifiable(_displayedWords);

  /// 단어 사용 횟수 반환
  Map<String, int> get wordUsageCount => Map.unmodifiable(_wordUsageCount);

  /// 사용 가능한 문자 목록 반환
  Set<String> get availableCharacters => Set.unmodifiable(_availableCharacters);

  /// 랜덤 문자 생성 (블록, 그리드 채우기용)
  Future<String> getRandomCharacter() async {
    // 사용 가능한 글자가 없으면 새로운 단어 세트 추가
    if (_availableCharacters.isEmpty) {
      print('🔄 사용 가능한 글자가 없어서 새 단어 세트를 추가합니다');
      print(
          '📊 [DEBUG] 현재 글자 생성용 단어 목록 (${_selectedWords.length}개): $_selectedWords');
      print(
          '📊 [DEBUG] 현재 화면 표시용 단어 목록 (${_displayedWords.length}개): $_displayedWords');

      // 이전 단어들은 모두 글자를 소진했으므로 새 단어 세트로 교체
      await _refillCharacters();
    }

    // 글자가 여전히 없으면 기본 글자 하나 반환
    if (_availableCharacters.isEmpty) {
      print('⚠️ [ERROR] 글자 목록이 여전히 비어 있습니다. 기본 글자 반환');
      return '가';
    }

    // 글자 선택
    String selectedChar = _manager.getRandomCharacter(_availableCharacters);

    // 선택된 글자를 목록에서 제거
    _availableCharacters.remove(selectedChar);

    // 매번 남은 글자 수를 로그에 출력
    //print(
    //    '📊 [DEBUG] 글자 "$selectedChar" 사용 후 남은 글자 수: ${_availableCharacters.length}개');

    // 선택된 글자가 포함된 단어 사용 횟수 업데이트
    _updateCharacterUsageInWords(selectedChar);

    return selectedChar;
  }

  /// 선택된 글자가 포함된 단어들의 사용 추적 업데이트
  void _updateCharacterUsageInWords(String character) {
    // 이 글자를 포함하는 단어들 찾기
    List<String> wordsWithChar =
        _manager.findWordsContainingCharacter(character, _selectedWords);

    for (String word in wordsWithChar) {
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
      }
    }
  }

  /// 희귀 문자 여부 확인 (점수 계산용)
  bool isRareCharacter(String char) {
    return _manager.isRareCharacter(char);
  }

  /// 빈도 기반 랜덤 글자 선택
  Future<String> getFrequencyBasedChar() async {
    return await getRandomCharacter();
  }

  /// 랜덤 자음 기반 문자 생성
  Future<String> getRandomConsonantChar() async {
    return await getRandomCharacter();
  }

  /// 랜덤 모음 기반 문자 생성
  Future<String> getRandomVowelChar() async {
    return await getRandomCharacter();
  }
}
