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

  // 빈도 기반 한글 글자 데이터
  List<String> _top100Chars = [];
  List<String> _top101_200Chars = [];
  List<String> _top201_300Chars = [];  // 추가: 201-300위 글자 데이터
  bool _frequencyDataLoaded = false;

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

  // 생성자에서 초기화
  GameProvider() {
    _initializeGame();
  }

  /// 게임 초기화
  Future<void> _initializeGame() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // 단어 서비스 초기화
      if (!_wordService.isInitialized) {
        await _wordService.initialize();
        // 자주 사용되는 초성 관련 단어 목록 미리 로드
        await _wordService.preloadCommonConsonants();
      }

      // 빈도 데이터 로드
      if (!_frequencyDataLoaded) {
        await _loadFrequencyData();
      }

      // 게임 그리드 생성 (10x10)
      _grid = Grid(rows: 10, columns: 10);

      // 게임 상태 초기화
      _score = 0;
      _level = 1;
      _isGameOver = false;
      _isGamePaused = false;
      _formedWords.clear();
      _availableBlocks.clear();
      _wordClearCount = 0;
      _bombGenerated = false;
      
      // print('게임 초기화 완료 - 단어 제거 카운터: $_wordClearCount, 폭탄 플래그: $_bombGenerated');

      // 초기 블록 생성
      _generateBlocks();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = '게임 초기화 오류: $e';
      print(_errorMessage);
      notifyListeners();
    }
  }

  /// 빈도 데이터 파일 로드
  Future<void> _loadFrequencyData() async {
    try {
      // Top 100 글자 로드
      final top100Text = await rootBundle.loadString('assets/data/korean_chars_top100.txt');
      _top100Chars = top100Text.split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
          
      // Top 101-200 글자 로드
      final top200Text = await rootBundle.loadString('assets/data/korean_chars_top101_200.txt');
      _top101_200Chars = top200Text.split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      
      // Top 201-300 글자 로드
      final top300Text = await rootBundle.loadString('assets/data/korean_chars_top201_300.txt');
      _top201_300Chars = top300Text.split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      
      print('빈도 데이터 로드 완료: Top 100 (${_top100Chars.length}개), Top 101-200 (${_top101_200Chars.length}개), Top 201-300 (${_top201_300Chars.length}개)');
      _frequencyDataLoaded = true;
    } catch (e) {
      print('빈도 데이터 로드 실패: $e');
      // 기본 글자 목록 사용
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

  /// 게임 초기화
  Future<void> initialize() async {
    await _initializeGame();
  }

  /// 게임 재시작
  void restartGame() {
    _initializeGame();
  }

  /// 게임 일시정지 토글
  void togglePause() {
    _isGamePaused = !_isGamePaused;
    notifyListeners();
  }

  /// 새로운 블록 생성
  void _generateBlocks() {
    // 블록 수가 최대치보다 적을 때만 생성
    while (_availableBlocks.length < 5) {
      Block newBlock = _createRandomBlock();
      _availableBlocks.add(newBlock);
    }
    notifyListeners();
  }

  /// 빈도 기반 랜덤 글자 선택
  String _getFrequencyBasedChar() {
    if (!_frequencyDataLoaded) {
      _setupDefaultFrequencyData();
    }
    
    final random = Random();
    final roll = random.nextDouble();
    
    if (roll < 0.4) {  // 40% 확률로 상위 100개 중 선택
      return _top100Chars[random.nextInt(_top100Chars.length)];
    } else if (roll < 0.7) {  // 30% 확률로 상위 101-200개 중 선택
      return _top101_200Chars.isEmpty 
          ? _top100Chars[random.nextInt(_top100Chars.length)]
          : _top101_200Chars[random.nextInt(_top101_200Chars.length)];
    } else if (roll < 0.9) {  // 20% 확률로 상위 201-300개 중 선택
      return _top201_300Chars.isEmpty
          ? _top100Chars[random.nextInt(_top100Chars.length)]
          : _top201_300Chars[random.nextInt(_top201_300Chars.length)];
    } else {  // 10% 확률로 기존 한글 글자에서 선택
      return _commonKoreanChars[random.nextInt(_commonKoreanChars.length)];
    }
  }

  /// 랜덤 블록 생성
  Block _createRandomBlock() {
    final random = Random();

    // 5번마다 폭탄 블록 생성 (5, 10, 15, 20, ...)
    if (_wordClearCount > 0 && _wordClearCount % 5 == 0 && !_bombGenerated) {
      // 폭탄 생성 플래그 설정
      _bombGenerated = true;

      // 폭탄 블록 생성
      int blockId =
          DateTime.now().millisecondsSinceEpoch + random.nextInt(1000);
      return Block(
        id: blockId,
        shape: BlockShape.bomb,
        characters: ['💣'],
        color: Colors.red,
        isBomb: true,
      );
    } else if (_wordClearCount > 0 && _wordClearCount % 5 == 0) {
      // 이미 폭탄이 생성된 경우
    }

    // 블록 크기 확률 조정: 각 크기별 25% 확률로 동일하게 설정
    int blockSize;
    final sizeRoll = random.nextDouble();

    if (sizeRoll < 0.25) {
      blockSize = 1;  // 25%
    } else if (sizeRoll < 0.50) {
      blockSize = 2;  // 25%
    } else if (sizeRoll < 0.75) {
      blockSize = 3;  // 25%
    } else {
      blockSize = 4;  // 25%
    }

    // 블록 모양 선택 (크기에 따라)
    BlockShape blockShape = Block.getRandomShapeForSize(blockSize, random);

    // 블록 색상 선택 (크기별 색상)
    Color blockColor = _getColorForBlockSize(blockSize);

    // 블록 문자 생성 (블록 모양에 맞게 문자 배치)
    List<String> characters = [];

    // 모양에 따라 필요한 문자 수 결정
    int requiredChars;
    switch (blockShape) {
      case BlockShape.single:
        requiredChars = 1;
        break;
      case BlockShape.horizontal2:
      case BlockShape.vertical2:
        requiredChars = 2;
        break;
      case BlockShape.horizontal3:
      case BlockShape.vertical3:
      case BlockShape.lShape:
      case BlockShape.reverseLShape:
      case BlockShape.corner:
        requiredChars = 3;
        break;
      case BlockShape.squareShape:
      case BlockShape.horizontal4:
      case BlockShape.vertical4:
        requiredChars = 4;
        break;
      case BlockShape.bomb:
        requiredChars = 1;
        break;
      default:
        requiredChars = 3;
        break;
    }

    // 필요한 문자 생성 (빈도 기반 글자 선택)
    for (int i = 0; i < requiredChars; i++) {
      characters.add(_getFrequencyBasedChar());
    }

    // 블록 ID 생성 (현재 시간 + 랜덤값)
    int blockId = DateTime.now().millisecondsSinceEpoch + random.nextInt(1000);

    return Block(
      id: blockId,
      shape: blockShape,
      characters: characters,
      color: blockColor,
    );
  }

  /// 블록 회전 - 블록 트레이에 있는 블록
  void rotateBlockInTray(Block block) {
    try {
      if (block == null) {
        // print('회전할 블록이 null입니다.');
        return;
      }
      
      // print('GameProvider: 블록 회전 시작 - ID: ${block.id}, 형태: ${block.shape}, 회전상태: ${block.rotationState}');
      // print('GameProvider: 현재 블록 문자: ${block.characters}');
      // print('GameProvider: 현재 행렬: ${block.matrix}');
      
      // 블록 회전 시도
      final rotatedBlock = block.rotate();
      
      // print('GameProvider: 회전 후 블록 - ID: ${rotatedBlock.id}, 형태: ${rotatedBlock.shape}, 회전상태: ${rotatedBlock.rotationState}');
      // print('GameProvider: 회전 후 행렬: ${rotatedBlock.matrix}');
      
      // 블록 목록에서 해당 ID의 블록 찾기
      final index = _availableBlocks.indexWhere((b) => b.id == block.id);
      
      // print('GameProvider: 블록 인덱스: $index, 전체 블록 수: ${_availableBlocks.length}');
      
      if (index != -1) {
        // 회전된 블록으로 교체
        _availableBlocks[index] = rotatedBlock;
        
        // UI 갱신
        notifyListeners();
        // print('GameProvider: 블록 회전 완료 및 UI 갱신 요청');
      } else {
        // print('GameProvider: 오류: 회전할 블록을 찾을 수 없습니다. ID: ${block.id}');
      }
    } catch (e, stackTrace) {
      // print('GameProvider: 블록 회전 중 예외 발생: $e');
      // print('GameProvider: 스택 트레이스: $stackTrace');
    }
  }

  /// 블록 크기에 따른 색상 반환
  Color _getColorForBlockSize(int size) {
    switch (size) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.deepOrange;
      case 4:
        return Colors.purple;
      default:
        return Colors.indigo;
    }
  }

  /// 랜덤 자음 기반 문자 생성
  String _getRandomConsonantChar() {
    final random = Random();
    final consonant = _consonants[random.nextInt(_consonants.length)];
    final vowel = _vowels[random.nextInt(_vowels.length)];

    // 자음+모음 매핑 확인
    if (_charMapping.containsKey(consonant) &&
        _charMapping[consonant]!.containsKey(vowel)) {
      return _charMapping[consonant]![vowel]!;
    }

    // 매핑이 없으면 기본 문자 반환
    const defaultChars = ['가', '나', '다', '라', '마', '바', '사', '아', '자', '차'];
    return defaultChars[random.nextInt(defaultChars.length)];
  }

  /// 랜덤 모음 기반 문자 생성
  String _getRandomVowelChar() {
    final random = Random();
    final vowel = _vowels[random.nextInt(_vowels.length)];
    final consonant = _consonants[random.nextInt(_consonants.length)];

    // 자음+모음 매핑 확인 (반대 순서로)
    if (_charMapping.containsKey(consonant) &&
        _charMapping[consonant]!.containsKey(vowel)) {
      return _charMapping[consonant]![vowel]!;
    }

    // 매핑이 없으면 기본 모음 문자 반환
    const defaultChars = ['아', '야', '어', '여', '오', '요', '우', '유', '으', '이'];
    return defaultChars[random.nextInt(defaultChars.length)];
  }

  /// 블록을 그리드에 배치 (드래그 앤 드롭 방식)
  Future<bool> placeBlock(Block block, List<Point> positions) async {
    // 배치 가능 여부 확인
    if (positions.length != block.size) {
      return false; // 블록 크기와 위치 개수가 일치하지 않음
    }

    if (!_canPlaceBlock(block, positions)) {
      return false;
    }

    // 폭탄 블록 처리
    if (block.isBomb) {
      // 폭탄 효과 적용 (3x3 영역 제거)
      _grid = _grid.explodeBomb(positions[0]);

      // 폭탄 생성 플래그 초기화 - 폭탄을 사용했을 때만 초기화
      _bombGenerated = false;
      
      // 폭탄을 사용했을 때 단어 제거 카운트도 초기화
      // 이렇게 하면 5턴마다 폭탄이 생성되는 주기가 유지됨
      _wordClearCount = 0;

      // 폭탄 효과 애니메이션 및 사운드 효과를 위한 알림
      notifyListeners();

      // 약간의 딜레이 추가 (애니메이션 효과)
      await Future.delayed(const Duration(milliseconds: 500));
    } else {
      // 일반 블록 배치
      _grid = _grid.placeBlock(block, positions);
    }

    // 사용한 블록만 제거
    int removedIndex = _availableBlocks.indexWhere((b) => b.id == block.id);
    if (removedIndex >= 0) {
      _availableBlocks.removeAt(removedIndex);

      // 제거된 블록 자리에만 새 블록 추가
      _availableBlocks.insert(removedIndex, _createRandomBlock());
    }

    // 단어 확인 및 처리 (비동기 대기)
    await _checkForWords();

    // 게임 오버 검사
    _checkGameOver();

    notifyListeners();
    return true;
  }

  /// 특정 위치에 블록 배치 가능 여부 확인 (드래그 앤 드롭 방식)
  bool _canPlaceBlock(Block block, List<Point> positions) {
    // 모든 위치가 그리드 범위 내에 있는지 확인
    for (var point in positions) {
      if (point.x < 0 ||
          point.y < 0 ||
          point.x >= _grid.columns ||
          point.y >= _grid.rows) {
        return false;
      }
    }

    // 모든 위치가 비어있는지 확인
    for (var point in positions) {
      if (!_grid.cells[point.y][point.x].isEmpty) {
        return false;
      }
    }

    return true;
  }

  /// 국립국어원 사전 URL 열기
  Future<bool> openDictionary(String word) async {
    final encodedWord = Uri.encodeComponent(word);
    final uri = Uri.parse('https://stdict.korean.go.kr/search/searchResult.do?searchKeyword=$encodedWord');
    
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

  /// 형성된 단어 확인
  Future<void> _checkForWords() async {
    // 현재 그리드에서 가능한 모든 단어 후보 생성 (직접 검색)
    List<Word> wordCandidates = [];

    // 가로 단어 검색 (수동 검색)
    for (int y = 0; y < _grid.rows; y++) {
      for (int startX = 0; startX < _grid.columns - 1; startX++) {
        // 빈 셀은 건너뛰기
        if (_grid.cells[y][startX].isEmpty) continue;

        String word = _grid.cells[y][startX].character!;
        List<Point> cells = [Point(startX, y)];

        // 가로 방향으로 연속된 문자 확인
        for (int x = startX + 1; x < _grid.columns; x++) {
          if (_grid.cells[y][x].isEmpty) break;

          word += _grid.cells[y][x].character!;
          cells.add(Point(x, y));

          // 길이가 3 이상인 단어만 확인
          if (word.length >= 3) {
            // 비동기 단어 검증 사용
            bool isValid = await _wordService.isValidWordAsync(word);
            if (isValid) {
              wordCandidates.add(Word(text: word, cells: List.from(cells)));
            }
          }
        }
      }
    }

    // 세로 단어 검색 (수동 검색)
    for (int x = 0; x < _grid.columns; x++) {
      for (int startY = 0; startY < _grid.rows - 1; startY++) {
        // 빈 셀은 건너뛰기
        if (_grid.cells[startY][x].isEmpty) continue;

        String word = _grid.cells[startY][x].character!;
        List<Point> cells = [Point(x, startY)];

        // 세로 방향으로 연속된 문자 확인
        for (int y = startY + 1; y < _grid.rows; y++) {
          if (_grid.cells[y][x].isEmpty) break;

          word += _grid.cells[y][x].character!;
          cells.add(Point(x, y));

          // 길이가 3 이상인 단어만 확인
          if (word.length >= 3) {
            // 비동기 단어 검증 사용
            bool isValid = await _wordService.isValidWordAsync(word);
            if (isValid) {
              wordCandidates.add(Word(text: word, cells: List.from(cells)));
            }
          }
        }
      }
    }

    if (wordCandidates.isEmpty) {
      return;
    }

    // 한번에 모든 단어 제거
    _grid = _grid.removeWords(wordCandidates);

    // 단어 목록에 추가
    for (final wordCandidate in wordCandidates) {
      // 단어 점수 계산
      int wordScore = _calculateWordPoints(wordCandidate);
      
      // 점수가 포함된 Word 객체 생성하여 추가
      _formedWords.add(Word(
        text: wordCandidate.text, 
        cells: wordCandidate.cells,
        score: wordScore,
      ));
    }

    // 점수 계산
    int pointsEarned = 0;
    for (final word in wordCandidates) {
      int wordPoints = _calculateWordPoints(word);
      pointsEarned += wordPoints;
    }

    // 점수 추가
    _addScore(pointsEarned);

    notifyListeners();
  }

  /// 단어 점수 계산
  int _calculateWordPoints(Word word) {
    // 기본 점수 (단어 길이 * 10)
    int points = word.text.length * 10;

    // 레벨에 따른 보너스
    points = (points * (1 + (_level - 1) * 0.1)).round();

    return points;
  }

  /// 점수 추가 및 레벨 업 체크
  void _addScore(int points) {
    _score += points;

    // 단어 제거 횟수 증가
    _wordClearCount++;

    // 레벨 업 체크 (1000점마다 레벨 업)
    int newLevel = (_score / 1000).floor() + 1;
    if (newLevel > _level) {
      _level = newLevel;
      // 레벨 업 효과 또는 로직 추가 가능
    }
  }

  /// 게임 오버 체크
  void _checkGameOver() {
    // 1x1 셀이 비어있는지 확인
    bool hasEmptyCell = false;

    for (int row = 0; row < _grid.rows; row++) {
      for (int col = 0; col < _grid.columns; col++) {
        if (_grid.cells[row][col].isEmpty) {
          hasEmptyCell = true;
          break;
        }
      }
      if (hasEmptyCell) break;
    }

    // 비어있는 셀이 없고 더 놓을 블록이 없는 경우 게임 오버
    if (!hasEmptyCell && _availableBlocks.isNotEmpty) {
      _isGameOver = true;
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

    return await _wordService.getWordAsync(pattern);
  }

  // 상수 정의
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
    // 마지막으로 제거된 셀 정보 초기화
    _grid = _grid.copyWith();
    _grid.lastRemovedCells = [];
    notifyListeners();
  }

  set availableBlocks(List<Block> blocks) {
    _availableBlocks = blocks;
    notifyListeners();
  }
}
