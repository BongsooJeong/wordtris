import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// WordTris 게임의 단어 데이터베이스 관리 서비스 API 문서
///
/// [WordDatabaseService] 클래스
/// SQLite 데이터베이스를 사용하여 한글 단어를 관리하고 캐싱하는 싱글톤 클래스
///
/// 주요 기능:
/// - SQLite 데이터베이스 초기화 및 관리
/// - 자주 사용되는 단어 메모리 캐싱
/// - 단어 유효성 검사
/// - 단어 추가 및 검색
/// - 웹 환경 대응 (임시 단어 목록 사용)
///
/// 데이터베이스 관리:
/// - database: Future<Database?>
///   데이터베이스 인스턴스 반환
///
/// - _initDatabase(): Future<Database>
///   데이터베이스 초기화 및 생성
///
/// - _createTables(Database db): Future<void>
///   필요한 테이블과 인덱스 생성
///
/// 캐시 관리:
/// - initializeCache(): Future<void>
///   자주 사용되는 단어를 메모리에 캐싱
///
/// 단어 처리:
/// - isValidWord(String word): Future<bool>
///   단어의 유효성 검사 (캐시 및 데이터베이스)
///
/// - addWord(String word): Future<bool>
///   새로운 단어 추가
///
/// - searchWords(String pattern): Future<List<String>>
///   패턴에 맞는 단어 검색
///
/// 통계:
/// - getWordStats(): Future<Map<String, dynamic>>
///   단어 통계 정보 반환

/// 한글 단어 데이터베이스를 관리하는 서비스 클래스
class WordDatabaseService {
  static final WordDatabaseService _instance = WordDatabaseService._internal();
  static Database? _database;

  // 메모리 캐시 - 자주 사용되는 단어를 저장
  final Set<String> _wordCache = {};
  bool _isCacheInitialized = false;

  // 테스트용 임시 단어 목록
  final List<String> _tempWords = [
    '사과',
    '바나나',
    '오렌지',
    '포도',
    '키위',
    '학교',
    '학생',
    '공부',
    '선생님',
    '교실',
    '컴퓨터',
    '프로그램',
    '개발자',
    '코딩',
    '소프트웨어',
    '한국',
    '서울',
    '부산',
    '대구',
    '인천',
    '책상',
    '의자',
    '침대',
    '소파',
    '냉장고',
  ];

  // 싱글톤 패턴
  factory WordDatabaseService() {
    return _instance;
  }

  WordDatabaseService._internal();

  /// 데이터베이스 초기화 및 반환
  Future<Database?> get database async {
    if (kIsWeb) {
      return null; // 웹에서는 데이터베이스 사용 안함
    }

    if (_database != null) return _database!;

    try {
      _database = await _initDatabase();
      return _database;
    } catch (e) {
      print('데이터베이스 초기화 오류: $e');
      return null;
    }
  }

  /// 데이터베이스 초기화
  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw Exception('웹 플랫폼에서는 SQLite를 사용할 수 없습니다.');
    }

    // 데이터베이스 파일 경로 가져오기
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'korean_words.db');

    // 데이터베이스가 존재하는지 확인하고, 없으면 초기 데이터로 생성
    bool exists = await databaseExists(path);
    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // 임시로 빈 데이터베이스 생성
      Database db = await openDatabase(path, version: 1);
      await _createTables(db);
      return db;
    }

    // 데이터베이스 열기
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );
  }

  /// 테이블 생성
  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS korean_words(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        length INTEGER NOT NULL
      )
    ''');

    // 인덱스 생성
    await db
        .execute('CREATE INDEX IF NOT EXISTS idx_word ON korean_words(word)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_length ON korean_words(length)');
  }

  /// 자주 사용되는 단어 캐싱
  Future<void> initializeCache() async {
    try {
      if (kIsWeb) {
        // 웹에서는 임시 단어 목록 사용
        _wordCache.clear();
        _wordCache.addAll(_tempWords);
        _isCacheInitialized = true;
        return;
      }

      if (_isCacheInitialized) return;

      final db = await database;
      if (db == null) {
        // 데이터베이스 없는 경우 임시 단어 사용
        _wordCache.clear();
        _wordCache.addAll(_tempWords);
        _isCacheInitialized = true;
        return;
      }

      // 길이가 2-5인 단어만 캐싱 (메모리 효율성을 위해)
      List<Map<String, dynamic>> words = await db.query(
        'korean_words',
        columns: ['word'],
        where: 'length BETWEEN ? AND ?',
        whereArgs: [2, 5],
        limit: 10000, // 캐시 크기 제한
      );

      _wordCache.clear();

      if (words.isEmpty) {
        // 데이터베이스에 단어가 없으면 임시 단어 사용
        _wordCache.addAll(_tempWords);
      } else {
        for (var word in words) {
          _wordCache.add(word['word'] as String);
        }
      }

      _isCacheInitialized = true;
    } catch (e) {
      print('단어 캐시 초기화 오류: $e');
      // 오류 발생 시 임시 단어 사용
      _wordCache.clear();
      _wordCache.addAll(_tempWords);
      _isCacheInitialized = true;
    }
  }

  /// 단어가 데이터베이스에 존재하는지 확인
  Future<bool> isValidWord(String word) async {
    if (word.length < 2) return false; // 최소 2글자

    // 캐시에서 먼저 확인
    if (_wordCache.contains(word)) {
      return true;
    }

    if (kIsWeb) {
      // 웹에서는 임시 단어 리스트만 사용
      return _tempWords.contains(word);
    }

    // 데이터베이스에서 확인
    try {
      final db = await database;
      if (db == null) return _tempWords.contains(word);

      List<Map<String, dynamic>> result = await db.query(
        'korean_words',
        columns: ['id'],
        where: 'word = ?',
        whereArgs: [word],
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      print('단어 유효성 확인 오류: $e');
      return _tempWords.contains(word);
    }
  }

  /// 단어 목록 가져오기 (테스트용)
  Future<List<String>> getWords({int limit = 100, int offset = 0}) async {
    if (kIsWeb) {
      return _tempWords;
    }

    try {
      final db = await database;
      if (db == null) return _tempWords;

      List<Map<String, dynamic>> results = await db.query(
        'korean_words',
        columns: ['word'],
        limit: limit,
        offset: offset,
      );

      List<String> words = results.map((row) => row['word'] as String).toList();
      return words.isEmpty ? _tempWords : words;
    } catch (e) {
      print('단어 목록 가져오기 오류: $e');
      return _tempWords;
    }
  }

  /// 문자 다음에 올 수 있는 문자 목록 가져오기 (블록 생성 최적화용)
  Future<List<String>> getNextCharacters(String prefix,
      {int limit = 10}) async {
    try {
      final db = await database;
      List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT DISTINCT substr(word, ${prefix.length + 1}, 1) as next_char
        FROM korean_words
        WHERE word LIKE ?
        LIMIT ?
      ''', ['$prefix%', limit]);

      return results
          .map((row) => row['next_char'] as String)
          .where((char) => char.isNotEmpty)
          .toList();
    } catch (e) {
      print('다음 문자 목록 가져오기 오류: $e');
      return [];
    }
  }

  /// 가장 자주 사용되는 문자 가져오기 (블록 생성 최적화용)
  Future<List<String>> getMostFrequentCharacters({int limit = 20}) async {
    try {
      final db = await database;
      List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT substr(word, 1, 1) as char, COUNT(*) as frequency
        FROM korean_words
        GROUP BY char
        ORDER BY frequency DESC
        LIMIT ?
      ''', [limit]);

      return results
          .map((row) => row['char'] as String)
          .where((char) => char.isNotEmpty)
          .toList();
    } catch (e) {
      print('자주 사용되는 문자 가져오기 오류: $e');
      return [];
    }
  }

  /// 데이터베이스 통계 가져오기
  Future<Map<String, dynamic>> getDatabaseStats() async {
    if (kIsWeb) {
      // 웹에서는 임시 통계 제공
      return {
        'totalWords': _tempWords.length,
        'wordsByLength': _calculateTempWordStats(),
      };
    }

    try {
      final db = await database;
      if (db == null) {
        return {
          'totalWords': _tempWords.length,
          'wordsByLength': _calculateTempWordStats(),
        };
      }

      // 총 단어 수
      List<Map<String, dynamic>> countResult =
          await db.rawQuery('SELECT COUNT(*) as count FROM korean_words');
      int totalWords = Sqflite.firstIntValue(countResult) ?? 0;

      // 길이별 단어 수
      List<Map<String, dynamic>> lengthResults = await db.rawQuery('''
        SELECT length, COUNT(*) as count
        FROM korean_words
        GROUP BY length
        ORDER BY length
      ''');

      Map<int, int> wordsByLength = {};
      for (var row in lengthResults) {
        wordsByLength[row['length'] as int] = row['count'] as int;
      }

      // 데이터가 없으면 임시 데이터 반환
      if (totalWords == 0) {
        return {
          'totalWords': _tempWords.length,
          'wordsByLength': _calculateTempWordStats(),
        };
      }

      return {
        'totalWords': totalWords,
        'wordsByLength': wordsByLength,
      };
    } catch (e) {
      print('데이터베이스 통계 가져오기 오류: $e');
      return {
        'totalWords': _tempWords.length,
        'wordsByLength': _calculateTempWordStats(),
      };
    }
  }

  /// 임시 단어 통계 계산
  Map<int, int> _calculateTempWordStats() {
    Map<int, int> stats = {};
    for (String word in _tempWords) {
      int length = word.length;
      stats[length] = (stats[length] ?? 0) + 1;
    }
    return stats;
  }
}
