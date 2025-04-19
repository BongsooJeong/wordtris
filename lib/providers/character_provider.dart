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
class CharacterProvider with ChangeNotifier {
  final CharacterManager _manager;

  // 현재 게임에 사용 중인 선택된 단어 목록
  final List<String> _selectedWords = [];

  // 현재 사용 가능한 글자 목록
  final Set<String> _availableCharacters = {};

  // 각 단어 사용 횟수 카운트
  final Map<String, int> _wordUsageCount = {};

  // 한 번에 표시할 최대 단어 수
  static const int _maxDisplayedWords = 20;

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
    try {
      print('📦 [DEBUG] 새로운 단어 배치 선택 시작');
      print('🔍 [DEBUG] 모드: ${replaceAll ? "전체 교체" : "추가"}');

      if (replaceAll) {
        // 기존 상태 초기화
        _selectedWords.clear();
        _wordUsageCount.clear();

        // 초기 단어 세트 가져오기
        List<String> initialWords = [];
        try {
          initialWords = await _manager.getInitialWordSet();
          print('📥 [DEBUG] 초기 단어 세트 가져옴: ${initialWords.length}개');
        } catch (e) {
          print('⚠️ [ERROR] 초기 단어 세트 가져오기 실패: $e');
          initialWords = _manager.getDefaultWords();
          print('🔄 [RECOVERY] 기본 단어 목록으로 대체: ${initialWords.length}개');
        }

        // 안전 점검: 단어가 없으면 기본 단어 사용
        if (initialWords.isEmpty) {
          print('⚠️ [ERROR] 초기 단어 세트가 비어 있음');
          initialWords = _manager.getDefaultWords();
          print('🔄 [RECOVERY] 기본 단어 목록으로 대체: ${initialWords.length}개');
        }

        // 단어 목록 설정 및 사용 횟수 초기화
        for (String word in initialWords) {
          _selectedWords.add(word);
          _wordUsageCount[word] = 0;
        }

        print('🆕 [DEBUG] 초기화 완료, 단어 ${_selectedWords.length}개 선택됨');
      } else {
        // 기존 단어 유지하면서 새 단어 추가
        try {
          await _addNewWords();
        } catch (e) {
          print('⚠️ [ERROR] 새 단어 추가 실패: $e');
          // 오류가 발생해도 기존 단어는 유지
        }
      }

      // 선택된 단어가 없는 경우 기본 단어 추가
      if (_selectedWords.isEmpty) {
        print('⚠️ [DEBUG] 선택된 단어가 없습니다. 기본 단어 목록 사용');
        final defaultWords = _manager.getDefaultWords();

        for (String word in defaultWords) {
          _selectedWords.add(word);
          _wordUsageCount[word] = 0;
        }
      }

      // 사용 가능한 글자 목록 업데이트
      _updateAvailableCharacters();

      print('✅ [DEBUG] 단어 배치 선택 완료: ${_selectedWords.length}개 단어');
      notifyListeners();
    } catch (e, stack) {
      print('❌ [CRITICAL] 단어 배치 선택 중 예기치 않은 오류: $e');
      print('🔍 [STACK] $stack');

      // 비상용 기본 단어 추가
      _selectedWords.clear();
      _wordUsageCount.clear();

      final emergencyWords = ['사과', '바나나', '학교', '공부', '친구'];
      for (String word in emergencyWords) {
        _selectedWords.add(word);
        _wordUsageCount[word] = 0;
      }

      // 사용 가능한 글자 목록 업데이트
      _updateAvailableCharacters();

      // 실패해도 리스너 알림
      notifyListeners();
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
      _wordUsageCount[word] = 0;
    }
    print('➕ [DEBUG] 단어 배치에 새 단어 ${newWords.length}개 추가: $newWords');

    // 단어 개수가 최대 표시 개수를 초과하면 오래된 단어부터 제거
    final List<String> removedWords = [];
    while (_selectedWords.length > _maxDisplayedWords) {
      final String removed = _selectedWords.removeAt(0);
      removedWords.add(removed);
      _wordUsageCount.remove(removed);
    }

    if (removedWords.isNotEmpty) {
      print(
          '🗑️ [DEBUG] 최대 표시 개수 초과로 ${removedWords.length}개 단어 제거됨: $removedWords');
    }

    // 선택된 단어에서 고유 글자 추출 업데이트
    _updateAvailableCharacters();

    print('✅ [DEBUG] 새 단어 배치 추가 완료. 현재 단어 ${_selectedWords.length}개');
  }

  /// 사용 가능한 글자 목록 업데이트
  void _updateAvailableCharacters() {
    _availableCharacters.clear();

    // 매니저를 통해 글자 목록 생성
    final chars = _manager.generateAvailableCharacters(_selectedWords);
    _availableCharacters.addAll(chars);
  }

  /// 글자 목록 채우기 (새 단어를 추가하고 글자 목록 재생성)
  Future<void> _refillCharacters() async {
    print('🔄 글자 목록 재충전 시작 - 새 단어 추가 포함');

    // 새 단어 세트 추가
    await _addNewWords();

    // 새 단어가 추가된 후 다시 글자 목록 생성
    _availableCharacters.clear();
    final chars = _manager.generateAvailableCharacters(_selectedWords);
    _availableCharacters.addAll(chars);

    print(
        '🔄 글자 목록 재충전 완료. 새 단어 추가 후 현재 ${_availableCharacters.length}개 글자 가능');
  }

  /// 단어 사용 횟수 증가시키기
  void incrementWordUsageCount(String word) {
    print('incrementWordUsageCount 호출: $word');

    if (_selectedWords.contains(word)) {
      _wordUsageCount[word] = (_wordUsageCount[word] ?? 0) + 1;

      // 사용된 단어 비율 계산 및 필요시 업데이트
      _checkWordUsageRatioAndUpdateIfNeeded();
      notifyListeners();
    }
  }

  /// 단어 사용 정보 업데이트
  void updateWordUsage(String word) {
    if (!_selectedWords.contains(word)) {
      return;
    }

    // 단어 사용 횟수 증가 - 단어가 그리드에서 형성되었을 때 호출됨
    _wordUsageCount[word] = (_wordUsageCount[word] ?? 0) + 1;

    // 단어 사용 비율 확인 및 새 단어 추가 여부 결정
    _checkWordUsageRatioAndUpdateIfNeeded();
    notifyListeners();
  }

  /// 단어 사용 비율을 확인하고 필요시 새 단어 세트 추가
  void _checkWordUsageRatioAndUpdateIfNeeded() {
    // 사용된 단어 수와 비율 계산
    int usedWordsCount =
        _selectedWords.where((w) => (_wordUsageCount[w] ?? 0) > 0).length;
    double usageRatio = usedWordsCount / _selectedWords.length;

    // 70% 이상의 단어가 사용되었는지 확인
    if (usageRatio >= 0.7) {
      print('🔔 [DEBUG] 70% 이상의 단어가 사용되었습니다. 새 단어 세트를 추가합니다.');
      _addNewWords();
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
    // 사용 가능한 글자가 없으면 새로운 단어 세트 선택
    if (_availableCharacters.isEmpty) {
      print('🔄 사용 가능한 글자가 없어서 글자 목록 재생성');
      // 비동기 호출이지만 동기 API용으로 별도 처리
      _refillCharactersSync();
      // 비상용 기본값 제공
      if (_availableCharacters.isEmpty) {
        return '가';
      }
    }

    // 글자 선택
    String selectedChar = _manager.getRandomCharacter(_availableCharacters);

    // 선택된 글자를 목록에서 제거
    _availableCharacters.remove(selectedChar);

    // 선택된 글자가 포함된 단어 사용 횟수 업데이트
    _updateCharacterUsageInWords(selectedChar);

    // 글자 수가 너무 적어지면 글자 목록 재생성 (단어 세트는 그대로 유지)
    if (_availableCharacters.length < 5) {
      print('🔄 사용 가능한 글자가 5개 미만으로 줄어 글자 목록을 재생성합니다');
      // 비동기 호출이지만 동기 API용으로 별도 처리
      _refillCharactersSync();
    }

    return selectedChar;
  }

  /// 동기 API를 위한 글자 목록 재충전 래퍼
  void _refillCharactersSync() {
    // 비동기 호출을 별도 분리해서 백그라운드에서 처리
    Future.microtask(() async {
      await _refillCharacters();
      notifyListeners();
    });

    // 동기적으로 즉시 새 단어 추가 시도
    try {
      // 단어 서비스에서 바로 가져올 수 있는 단어 있는지 확인
      final validWords = _manager.wordService.getValidWords().toList();
      if (validWords.isNotEmpty) {
        // 랜덤으로 5개 단어 선택
        validWords.shuffle();
        final List<String> newWords = [];

        // 기존 단어와 중복되지 않는 단어 최대 5개 추가
        for (String word in validWords) {
          if (word.length >= 2 &&
              word.length <= 5 &&
              !_selectedWords.contains(word)) {
            newWords.add(word);
            if (newWords.length >= 5) break;
          }
        }

        // 새 단어 추가
        for (String word in newWords) {
          _selectedWords.add(word);
          _wordUsageCount[word] = 0;
        }

        if (newWords.isNotEmpty) {
          print('🆕 [SYNC] 새 단어 ${newWords.length}개 즉시 추가: $newWords');
        }
      }
    } catch (e) {
      print('⚠️ [SYNC] 단어 즉시 추가 중 오류: $e');
    }

    // 기존 단어에서 바로 사용 가능한 글자들 추출
    _availableCharacters.clear();
    if (_selectedWords.isNotEmpty) {
      final chars = _manager.generateAvailableCharacters(_selectedWords);
      _availableCharacters.addAll(chars);
      print('🔡 [SYNC] 글자 ${_availableCharacters.length}개 생성됨');
    }

    // 글자가 부족하면 기본 글자 추가
    if (_availableCharacters.isEmpty) {
      _availableCharacters.addAll([
        '가',
        '나',
        '다',
        '라',
        '마',
        '바',
        '사',
        '아',
        '자',
        '차',
        '카',
        '타',
        '파',
        '하'
      ]);
      print('⚠️ [SYNC] 글자가 없어 기본 글자 추가');
    }
  }

  /// 선택된 글자가 포함된 단어들의 사용 추적 업데이트
  void _updateCharacterUsageInWords(String character) {
    // 이 글자를 포함하는 단어들 찾기
    List<String> wordsWithChar =
        _manager.findWordsContainingCharacter(character, _selectedWords);

    bool anyWordUpdated = false;

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
        anyWordUpdated = true;
      }
    }

    if (anyWordUpdated) {
      // 단어 사용 비율 확인 및 새 단어 추가 여부 결정
      _checkWordUsageRatioAndUpdateIfNeeded();
      notifyListeners();
    }
  }

  /// 희귀 문자 여부 확인 (점수 계산용)
  bool isRareCharacter(String char) {
    return _manager.isRareCharacter(char);
  }

  /// 빈도 기반 문자 선택
  String getFrequencyBasedChar() {
    return getRandomCharacter();
  }

  /// 랜덤 자음 선택
  String getRandomConsonantChar() {
    return getRandomCharacter();
  }

  /// 랜덤 모음 선택
  String getRandomVowelChar() {
    return getRandomCharacter();
  }
}
