/// WordTris 게임의 단어 처리 및 검증을 담당하는 서비스 API 문서
///
/// [WordService] 클래스
/// SQLite 데이터베이스와 파일 기반 초성 인덱스를 사용하여 한글 단어를 관리하는 싱글톤 클래스
///
/// 주요 기능:
/// - 단어 데이터베이스 초기화 및 관리
/// - 초성별 단어 인덱싱 및 로딩
/// - 단어 유효성 검사
/// - 단어 검색 및 제안
/// - 웹/모바일 환경 대응
///
/// 초기화 및 데이터 로드:
/// - initialize(): Future<void>
///   서비스 초기화 및 필수 데이터 로드
///
/// - _initDatabase(): Future<void>
///   SQLite 데이터베이스 초기화
///
/// - _loadInitialWords(Database db): Future<void>
///   초기 단어 데이터 로드
///
/// 단어 처리:
/// - isValidWordAsync(String word): Future<bool>
///   단어의 유효성 비동기 검사
///
/// - getWordAsync(String pattern): Future<List<String>>
///   패턴에 맞는 단어 검색
///
/// 초성 관리:
/// - loadConsonantData(String consonant): Future<void>
///   특정 초성의 단어 데이터 로드
///
/// - preloadCommonConsonants(): Future<void>
///   자주 사용되는 초성 데이터 미리 로드
///
/// 캐시 관리:
/// - clearCache(): void
///   단어 캐시 초기화
///
/// - _loadWordIndex(): Future<bool>
///   초성 인덱스 파일 로드

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math';
import 'dart:collection';

/// 단어 검증을 담당하는 서비스 클래스
class WordService {
  static const String dbName = 'words.db';
  static const String tableName = 'korean_words';

  static final WordService _instance = WordService._internal();
  Database? _database;
  final Map<String, bool> _wordCache = {}; // 캐시
  bool _isInitialized = false;
  final Set<String> _validWords = {}; // 유효한 단어 집합
  bool _useFallbackWords = false;

  // 초성별 단어 맵 (필요한 초성의 단어만 로드)
  final Map<String, Set<String>> _consonantWordMap = {};

  // 초성 인덱스 파일 로드 여부
  bool _indexLoaded = false;

  // 초성 인덱스 맵
  Map<String, String> _consonantIndex = {};

  factory WordService() {
    return _instance;
  }

  WordService._internal();

  /// DB 초기화
  Future<void> initialize() async {
    print('WordService 초기화 시작');
    try {
      // 초성 인덱스 먼저 로드
      bool indexLoaded = await _loadWordIndex();
      if (indexLoaded) {
        print('인덱스 로드 성공: ${_consonantIndex.length}개 초성 파일 확인');

        // 주요 초성 먼저 로드 (자주 사용되는 초성)
        await loadConsonantData('ㄱ');
        await loadConsonantData('ㄴ');
        await loadConsonantData('ㄷ');
        await loadConsonantData('ㄹ');
        await loadConsonantData('ㅁ');
        await loadConsonantData('ㅂ');
        await loadConsonantData('ㅅ');
        await loadConsonantData('ㅇ');
        await loadConsonantData('ㅈ');
        await loadConsonantData('ㅊ');
        await loadConsonantData('ㅋ');
        await loadConsonantData('ㅌ');
        await loadConsonantData('ㅍ');
        await loadConsonantData('ㅎ');

        _isInitialized = true;
        return;
      }

      // 인덱스 로드 실패 시 기존 DB 방식 시도
      await _initDatabase();
      if (_database != null || _useFallbackWords) {
        await _loadValidWords();
        _isInitialized = true;
        print(
            'WordService 초기화 완료: ${_useFallbackWords ? "기본 단어 목록 사용" : "데이터베이스 사용"}');
      } else {
        print('WordService 초기화 실패: 데이터베이스가 null이고 기본 단어 목록도 로드되지 않음');
      }
    } catch (e) {
      print('WordService 초기화 중 오류 발생: $e');
      _useFallbackWords = true;
      await _loadValidWords();
      _isInitialized = true;
    }
  }

  /// 데이터베이스 초기화 시도
  Future<void> _initDatabase() async {
    try {
      if (kIsWeb) {
        print('웹 환경 감지됨 - 데이터베이스 기능 제한됨');
        _useFallbackWords = true;
        return;
      }

      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'korean_words.db');
      print('데이터베이스 경로: $path');

      // 데이터베이스가 없으면 생성
      _database =
          await openDatabase(path, version: 1, onCreate: (db, version) async {
        print('데이터베이스 생성 중...');
        await db.execute('''
            CREATE TABLE $tableName (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              word TEXT NOT NULL,
              length INTEGER NOT NULL
            )
          ''');

        // 앱 번들에서 단어 목록 로드
        await _loadInitialWords(db);
      }, onOpen: (db) async {
        print('데이터베이스 열기 성공');
        // 단어 수 확인
        final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $tableName'));
        print('데이터베이스 단어 수: $count');

        // 단어가 없으면 초기 데이터 로드
        if (count == 0) {
          await _loadInitialWords(db);
        }
      });

      print('데이터베이스 초기화 성공');
    } catch (e) {
      print('데이터베이스 초기화 실패: $e');
      // 오류시 데이터베이스 참조를 null로 설정
      _database = null;
    }
  }

  /// 초기 단어 로드
  Future<void> _loadInitialWords(Database db) async {
    try {
      // 앱 번들에서 단어 파일 로드
      final String data =
          await rootBundle.loadString('assets/data/korean_words.json');
      final List<dynamic> words = json.decode(data);

      print('초기 단어 로드: ${words.length}개 단어');

      // 트랜잭션으로 단어 삽입
      await db.transaction((txn) async {
        final batch = txn.batch();

        for (final word in words) {
          batch.insert(tableName, {
            'word': word,
            'length': word.length,
          });
        }

        await batch.commit(noResult: true);
      });

      print('초기 단어 로드 완료');
    } catch (e) {
      print('초기 단어 로드 오류: $e');
    }
  }

  /// 유효한 단어 로드
  Future<void> _loadValidWords() async {
    print('유효한 단어 로드 중...');
    _validWords.clear();

    if (_useFallbackWords || kIsWeb) {
      print('기본 단어 목록/JSON 사용');
      try {
        // 앱 번들에서 단어 파일 로드
        final String data =
            await rootBundle.loadString('assets/data/korean_words.json');
        final List<dynamic> words = json.decode(data);
        for (final word in words) {
          _validWords.add(word.toString());
        }
        print('JSON에서 ${_validWords.length}개의 단어 로드됨');
      } catch (e) {
        print('JSON 로드 오류, 내장 단어 사용: $e');
        _validWords.addAll(_getFallbackWords());
      }
      return;
    }

    if (_database == null) {
      print('데이터베이스가 null임 - 기본 단어 목록 사용');
      _useFallbackWords = true;
      _validWords.addAll(_getFallbackWords());
      return;
    }

    try {
      final words = await _database!.query(tableName);
      for (var wordMap in words) {
        _validWords.add(wordMap['word'] as String);
      }
      print('데이터베이스에서 ${_validWords.length}개의 단어 로드됨');
    } catch (e) {
      print('단어 로드 중 오류 발생: $e');
      _useFallbackWords = true;
      _validWords.addAll(_getFallbackWords());
    }
  }

  Set<String> _getFallbackWords() {
    // 기본 단어 목록 - 실제 구현에서는 더 큰 목록 사용
    return {
      '사과',
      '바나나',
      '오렌지',
      '포도',
      '수박',
      '딸기',
      '키위',
      '망고',
      '파인애플',
      '복숭아',
      '학교',
      '공부',
      '시험',
      '숙제',
      '선생님',
      '학생',
      '교실',
      '책상',
      '의자',
      '칠판',
      '컴퓨터',
      '스마트폰',
      '태블릿',
      '노트북',
      '마우스',
      '키보드',
      '모니터',
      '프린터',
      '스캐너',
      '헤드폰',
      '자동차',
      '버스',
      '지하철',
      '비행기',
      '기차',
      '자전거',
      '오토바이',
      '택시',
      '트럭',
      '보트',
      '가족',
      '부모님',
      '형제',
      '자매',
      '친구',
      '이웃',
      '동료',
      '선배',
      '후배',
      '연인',
      '사랑',
      '행복',
      '슬픔',
      '분노',
      '기쁨',
      '두려움',
      '놀라움',
      '혐오',
      '미소',
      '눈물',
      '하늘',
      '바다',
      '산',
      '강',
      '호수',
      '숲',
      '사막',
      '정글',
      '빙하',
      '화산',
      '음악',
      '영화',
      '드라마',
      '책',
      '그림',
      '춤',
      '노래',
      '시',
      '소설',
      '공연',
      '한국',
      '미국',
      '중국',
      '일본',
      '영국',
      '프랑스',
      '독일',
      '호주',
      '캐나다',
      '브라질',
      '음식',
      '요리',
      '식당',
      '카페',
      '맛집',
      '주방',
      '식사',
      '간식',
      '건강',
      '영양'
    };
  }

  /// 초성별 단어 파일 로드 여부 확인
  bool isConsonantDataLoaded(String consonant) {
    return _consonantWordMap.containsKey(consonant);
  }

  /// 초성 인덱스 로드
  Future<bool> _loadWordIndex() async {
    if (_indexLoaded) return true;

    try {
      print('초성 인덱스 로드 시도');
      final String indexData =
          await rootBundle.loadString('assets/data/korean_words_index.json');

      // JSON 파일은 초성별 단어 수를 저장하고 있음
      final Map<String, dynamic> rawData = json.decode(indexData);

      // 초성 인덱스 맵 생성 - 파일 경로 형식으로 변환
      _consonantIndex = {};
      rawData.forEach((consonant, count) {
        // 파일 이름 패턴 지정
        _consonantIndex[consonant] = 'korean_words_$consonant.json';
      });

      _indexLoaded = true;
      print('초성 인덱스 로드 성공: ${_consonantIndex.length}개 항목');
      return true;
    } catch (e) {
      print('초성 인덱스 로드 실패: $e');
      _indexLoaded = false;
      return false;
    }
  }

  /// 특정 초성에 해당하는 단어 데이터 로드
  Future<bool> loadConsonantData(String consonant) async {
    // 이미 로드된 초성인지 확인
    if (_consonantWordMap.containsKey(consonant)) {
      return true;
    }

    try {
      String filePath;
      if (_indexLoaded && _consonantIndex.containsKey(consonant)) {
        filePath = 'assets/data/${_consonantIndex[consonant]!}';
      } else {
        print('초성 $consonant에 대한 인덱스 정보 없음');
        return false;
      }

      print('$filePath 로드 시도');
      final String data = await rootBundle.loadString(filePath);
      final List<dynamic> words = json.decode(data);

      // 세트 초기화
      final Set<String> wordSet = {};
      for (final word in words) {
        wordSet.add(word.toString());
      }

      // 맵에 추가
      _consonantWordMap[consonant] = wordSet;
      print('$consonant 초성 단어 ${wordSet.length}개 로드 완료');
      return true;
    } catch (e) {
      print('$consonant 초성 단어 로드 실패: $e');
      return false;
    }
  }

  /// 단어 초성 판별
  String getConsonantFromWord(String word) {
    if (word.isEmpty) {
      return '기타';
    }

    final String firstChar = word[0];

    // 초성 판별
    if (firstChar.compareTo('가') >= 0 && firstChar.compareTo('깋') <= 0) {
      return 'ㄱ';
    } else if (firstChar.compareTo('나') >= 0 && firstChar.compareTo('닣') <= 0) {
      return 'ㄴ';
    } else if (firstChar.compareTo('다') >= 0 && firstChar.compareTo('딯') <= 0) {
      return 'ㄷ';
    } else if (firstChar.compareTo('라') >= 0 && firstChar.compareTo('맇') <= 0) {
      return 'ㄹ';
    } else if (firstChar.compareTo('마') >= 0 && firstChar.compareTo('밓') <= 0) {
      return 'ㅁ';
    } else if (firstChar.compareTo('바') >= 0 && firstChar.compareTo('빟') <= 0) {
      return 'ㅂ';
    } else if (firstChar.compareTo('사') >= 0 && firstChar.compareTo('싷') <= 0) {
      return 'ㅅ';
    } else if (firstChar.compareTo('아') >= 0 && firstChar.compareTo('잏') <= 0) {
      return 'ㅇ';
    } else if (firstChar.compareTo('자') >= 0 && firstChar.compareTo('짛') <= 0) {
      return 'ㅈ';
    } else if (firstChar.compareTo('차') >= 0 && firstChar.compareTo('칳') <= 0) {
      return 'ㅊ';
    } else if (firstChar.compareTo('카') >= 0 && firstChar.compareTo('킿') <= 0) {
      return 'ㅋ';
    } else if (firstChar.compareTo('타') >= 0 && firstChar.compareTo('팋') <= 0) {
      return 'ㅌ';
    } else if (firstChar.compareTo('파') >= 0 && firstChar.compareTo('핗') <= 0) {
      return 'ㅍ';
    } else if (firstChar.compareTo('하') >= 0 && firstChar.compareTo('힣') <= 0) {
      return 'ㅎ';
    }

    return '기타';
  }

  /// 단어가 유효한지 확인하는 메서드 (초성별 파일 사용)
  @override
  bool isValidWord(String word) {
    if (!_isInitialized) {
      // print('WordService가 초기화되지 않음');
      return false;
    }

    // print('단어 확인: "$word"');

    // 이미 캐시에 있는지 확인
    if (_wordCache.containsKey(word)) {
      // print('캐시에서 확인: ${_wordCache[word]}');
      return _wordCache[word]!;
    }

    // 단어의 초성 확인
    final String consonant = getConsonantFromWord(word);
    // print('초성: "$consonant"');

    // 초성별 데이터가 로드되어 있는지 확인
    if (!_consonantWordMap.containsKey(consonant) ||
        _consonantWordMap[consonant]!.isEmpty) {
      // print('초성 "$consonant"의 단어 데이터가 로드되지 않음. 로드 필요.');
      // 비동기 로드 시도 (다음 검증을 위해)
      loadConsonantData(consonant);
    } else {
      // print('초성 "$consonant"의 단어 데이터 로드됨 (${_consonantWordMap[consonant]!.length}개 단어)');
    }

    // 초성별 데이터가 로드되어 있으면 활용
    if (_consonantWordMap.containsKey(consonant) &&
        _consonantWordMap[consonant]!.isNotEmpty) {
      final bool isValid = _consonantWordMap[consonant]!.contains(word);
      _wordCache[word] = isValid;
      // print('초성 데이터에서 확인: $isValid');
      return isValid;
    }

    // 기존 로직: 전체 단어 목록에서 확인
    bool isValid = _validWords.contains(word);
    _wordCache[word] = isValid;
    // print('전체 단어 목록에서 확인: $isValid (전체 단어 수: ${_validWords.length})');

    return isValid;
  }

  /// 단어 존재 비동기 확인 (앱 동작 중 첫 단어 검색 시 사용)
  Future<bool> isValidWordAsync(String word) async {
    if (!_isInitialized) {
      await initialize();
    }

    // 너무 짧은 단어는 무효
    if (word.length < 3) return false;

    // print('단어 비동기 확인: "$word"');

    // 캐시 확인
    if (_wordCache.containsKey(word)) {
      // print('캐시에서 비동기 확인: ${_wordCache[word]}');
      return _wordCache[word]!;
    }

    // 단어의 초성 확인
    final String consonant = getConsonantFromWord(word);
    // print('비동기 초성: "$consonant"');

    // 해당 초성의 단어 목록 로드 (아직 로드되지 않은 경우)
    if (!_consonantWordMap.containsKey(consonant) ||
        _consonantWordMap[consonant]!.isEmpty) {
      // print('비동기: 초성 "$consonant"의 단어 데이터 로드 시작...');
      bool loaded = await loadConsonantData(consonant);
      // print('비동기: 초성 "$consonant"의 단어 데이터 로드 ${loaded ? "성공" : "실패"}');
    } else {
      // print('비동기: 초성 "$consonant"의 단어 데이터 이미 로드됨 (${_consonantWordMap[consonant]!.length}개 단어)');
    }

    // 초성에 해당하는 단어 데이터가 있으면 확인
    if (_consonantWordMap.containsKey(consonant) &&
        _consonantWordMap[consonant]!.isNotEmpty) {
      final bool isValid = _consonantWordMap[consonant]!.contains(word);
      _wordCache[word] = isValid;
      // print('비동기: 초성 데이터에서 확인: $isValid');
      return isValid;
    }

    // 기존 로직: 전체 데이터베이스에서 확인
    try {
      if (_database == null) {
        final isValid = _checkWordInDatabase(word);
        _wordCache[word] = isValid;
        // print('비동기: 내장 데이터에서 확인: $isValid');
        return isValid;
      }

      final result = await _database!.query(
        tableName,
        where: 'word = ?',
        whereArgs: [word],
        limit: 1,
      );

      final bool isValid = result.isNotEmpty;
      _wordCache[word] = isValid;
      // print('비동기: 데이터베이스에서 확인: $isValid');
      return isValid;
    } catch (e) {
      print('단어 비동기 조회 오류: $e');
      final isValid = _checkWordInDatabase(word);
      _wordCache[word] = isValid;
      return isValid;
    }
  }

  /// 특정 패턴으로 시작하는 단어들 찾기 (초성 최적화)
  @override
  List<String> getWord(String pattern) {
    if (!_isInitialized) {
      print('WordService가 초기화되지 않음');
      return [];
    }

    List<String> matchingWords = [];

    // 패턴이 비어있거나 3글자 미만이면 빈 목록 반환
    if (pattern.isEmpty || pattern.length < 3) {
      return [];
    }

    // 패턴의 첫 글자로 초성 판별
    final String consonant = getConsonantFromWord(pattern);

    // 초성에 해당하는 데이터가 이미 로드되어 있는 경우 활용
    if (_consonantWordMap.containsKey(consonant) &&
        _consonantWordMap[consonant]!.isNotEmpty) {
      // 정규식 생성 - 패턴으로 시작하는 단어 찾기
      try {
        final RegExp regex = RegExp('^$pattern');

        // 초성에 해당하는 단어들 중 패턴과 일치하는 단어 찾기
        for (String word in _consonantWordMap[consonant]!) {
          if (regex.hasMatch(word)) {
            matchingWords.add(word);

            // 최대 20개까지만 반환 (성능 최적화)
            if (matchingWords.length >= 20) {
              break;
            }
          }
        }

        if (matchingWords.isNotEmpty) {
          return matchingWords;
        }
      } catch (e) {
        print('getWord 정규식 오류 (초성 데이터): $e');
      }
    }

    // 기존 로직: 전체 로드된 단어 목록에서 검색
    try {
      final RegExp regex = RegExp('^$pattern');

      for (String word in _validWords) {
        if (regex.hasMatch(word)) {
          matchingWords.add(word);

          // 최대 20개까지만 반환 (성능 최적화)
          if (matchingWords.length >= 20) {
            break;
          }
        }
      }
    } catch (e) {
      print('getWord 정규식 오류 (전체 데이터): $e');
    }

    return matchingWords;
  }

  /// 패턴으로 시작하는 단어 비동기 검색 (앱 동작 중 사용)
  Future<List<String>> getWordAsync(String pattern) async {
    if (!_isInitialized) {
      await initialize();
    }

    List<String> matchingWords = [];

    // 패턴이 비어있거나 3글자 미만이면 빈 목록 반환
    if (pattern.isEmpty || pattern.length < 3) {
      return [];
    }

    // 패턴의 첫 글자로 초성 판별
    final String consonant = getConsonantFromWord(pattern);

    // 해당 초성의 단어 목록 로드
    if (!_consonantWordMap.containsKey(consonant)) {
      await loadConsonantData(consonant);
    }

    // 초성에 해당하는 단어 데이터가 있으면 검색
    if (_consonantWordMap.containsKey(consonant) &&
        _consonantWordMap[consonant]!.isNotEmpty) {
      try {
        final RegExp regex = RegExp('^$pattern');

        for (String word in _consonantWordMap[consonant]!) {
          if (regex.hasMatch(word)) {
            matchingWords.add(word);

            // 최대 20개까지만 반환 (성능 최적화)
            if (matchingWords.length >= 20) {
              break;
            }
          }
        }

        return matchingWords;
      } catch (e) {
        print('getWordAsync 정규식 오류: $e');
      }
    }

    // 초성별 파일에 단어가 없으면 전체 단어 목록에서 검색
    return getWord(pattern);
  }

  /// 게임에서 사용할 단어들 사전 로드 (게임 준비 단계에서 호출)
  Future<void> preloadCommonConsonants() async {
    if (!_isInitialized) {
      await initialize();
    }

    // 자주 사용되는 초성 로드
    final List<String> commonConsonants = [
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

    print('자주 사용되는 초성 단어 목록 로드 중...');

    for (final consonant in commonConsonants) {
      if (!_consonantWordMap.containsKey(consonant)) {
        await loadConsonantData(consonant);
      }
    }

    print('자주 사용되는 초성 단어 로드 완료');
  }

  /// 유효한 단어 세트 반환
  Set<String> getValidWords() {
    if (!_isInitialized) {
      print('WordService가 초기화되지 않음, 기본 단어 목록 반환');
      return Set.from(_getFallbackWords());
    }

    // 이미 유효한 단어가 있으면 그대로 반환
    if (_validWords.isNotEmpty) {
      return _validWords;
    }

    // 초성별 데이터에서 단어 수집
    Set<String> allWords = {};

    for (var consonantSet in _consonantWordMap.values) {
      allWords.addAll(consonantSet);
    }

    // 수집된 단어가 있으면 반환
    if (allWords.isNotEmpty) {
      return allWords;
    }

    // 없으면 기본 단어 목록 반환
    return Set.from(_getFallbackWords());
  }

  /// 데이터베이스에 저장된 총 단어 수 반환
  Future<int> getWordCount() async {
    if (!_isInitialized) {
      await initialize();
    }

    // 초성별 단어 맵을 사용하는 경우
    if (_indexLoaded && _consonantWordMap.isNotEmpty) {
      int totalCount = 0;
      for (var consonantSet in _consonantWordMap.values) {
        totalCount += consonantSet.length;
      }

      // 아직 로드되지 않은 초성이 있으면 그 수를 추정
      if (_consonantWordMap.length < _consonantIndex.length) {
        // 평균 단어 수 계산
        if (_consonantWordMap.isNotEmpty) {
          double avgWordsPerConsonant = totalCount / _consonantWordMap.length;
          int estimatedTotal =
              (avgWordsPerConsonant * _consonantIndex.length).round();
          return estimatedTotal;
        }
      }

      return totalCount > 0 ? totalCount : _validWords.length;
    }

    // 데이터베이스가 초기화되지 않은 경우
    if (_database == null) {
      return _validWords.length;
    }

    try {
      final result =
          await _database!.rawQuery('SELECT COUNT(*) as count FROM $tableName');
      return Sqflite.firstIntValue(result) ?? _validWords.length;
    } catch (e) {
      print('단어 수 조회 오류: $e');
      return _validWords.length;
    }
  }

  /// 데이터베이스에서 단어 조회
  bool _checkWordInDatabase(String word) {
    // 메모리에 로드된 단어 확인
    if (_validWords.contains(word)) {
      return true;
    }

    // 임시 구현 (실제로는 비동기 DB 조회 필요)
    // TODO: 실제 DB 조회 구현
    final validWords = [
      '가나',
      '나다',
      '다라',
      '라마',
      '마바',
      '바사',
      '사아',
      '아자',
      '자차',
      '차카',
      '가다',
      '나라',
      '다마',
      '라바',
      '마사',
      '바아',
      '사자',
      '아차',
      '자카',
      '차타',
      '가마',
      '나바',
      '다사',
      '라아',
      '마자',
      '바차',
      '사카',
      '아타',
      '자파',
      '차하',
      '가바',
      '나사',
      '다아',
      '라자',
      '마차',
      '바카',
      '사타',
      '아파',
      '자하',
      '차가',
      '가사',
      '나아',
      '다자',
      '라차',
      '마카',
      '바타',
      '사파',
      '아하',
      '자가',
      '차나',
      '가나다',
      '다라마',
      '마바사',
      '아자차',
      '카타파',
      '하가나',
      '사랑',
      '행복',
      '가족',
      '친구',
      '학교',
      '회사',
      '시간',
      '공부',
      '여행',
      '음식'
    ];

    return validWords.contains(word);
  }

  /// 데이터베이스 닫기
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
  }

  bool get isInitialized => _isInitialized;
}
