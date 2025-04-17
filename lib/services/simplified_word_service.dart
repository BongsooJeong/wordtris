import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 단순화된 한글 단어 서비스 클래스
class WordService {
  static final WordService _instance = WordService._internal();

  // 메모리 캐시
  final Set<String> _wordCache = {};
  bool _isInitialized = false;

  // 테스트용 임시 단어 목록 (실제 데이터가 로드되지 않을 경우를 대비)
  final List<String> _sampleWords = [
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
    '봄',
    '여름',
    '가을',
    '겨울',
    '눈',
    '비',
    '바람',
    '해',
    '구름',
    '하늘',
    '바다',
    '산',
    '강',
    '숲',
    '꽃',
    '나무',
    '풀',
    '물',
    '불',
    '땅',
  ];

  // 싱글톤 패턴
  factory WordService() {
    return _instance;
  }

  WordService._internal();

  /// 초기화 메서드
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 에셋에서 단어 파일 로드 시도
      if (await _loadWordsFromAsset()) {
        _isInitialized = true;
        print('단어 데이터베이스 로드 완료: ${_wordCache.length}개 단어');
        return;
      }

      // 에셋 로드 실패 시 샘플 단어 사용
      _wordCache.addAll(_sampleWords);
      _isInitialized = true;
      print('샘플 단어 로드 완료: ${_wordCache.length}개 단어');
    } catch (e) {
      print('단어 서비스 초기화 오류: $e');
      // 오류 발생 시 샘플 단어 사용
      _wordCache.clear();
      _wordCache.addAll(_sampleWords);
      _isInitialized = true;
      print('오류로 인해 샘플 단어로 대체: ${_wordCache.length}개 단어');
    }
  }

  /// 에셋에서 단어 파일 로드
  Future<bool> _loadWordsFromAsset() async {
    try {
      // 단어 파일 로드 (한 줄에 단어 하나씩)
      final String data =
          await rootBundle.loadString('assets/data/korean_words.txt');
      if (data.isEmpty) return false;

      // 줄 단위로 분리하여 캐시에 추가
      final lines = const LineSplitter().convert(data);
      _wordCache.clear();

      int count = 0;
      for (final word in lines) {
        final trimmed = word.trim();
        if (trimmed.isNotEmpty) {
          _wordCache.add(trimmed);
          count++;

          // 단어 수가 너무 많으면 메모리 사용량을 줄이기 위해 제한
          if (count >= 100000 && kIsWeb) {
            print('웹 환경을 위해 단어 수를 제한합니다: $count');
            break;
          }
        }
      }

      return true;
    } catch (e) {
      print('단어 파일 로드 오류: $e');
      return false;
    }
  }

  /// 단어가 유효한지 확인
  Future<bool> isValidWord(String word) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (word.length < 2) return false; // 최소 2글자 이상
    return _wordCache.contains(word);
  }

  /// 단어 목록 가져오기
  Future<List<String>> getWords({int limit = 100}) async {
    if (!_isInitialized) {
      await initialize();
    }

    final List<String> words = _wordCache.toList();
    if (limit >= words.length) {
      return words;
    }

    return words.sublist(0, limit);
  }

  /// 통계 가져오기
  Future<Map<String, dynamic>> getStats() async {
    if (!_isInitialized) {
      await initialize();
    }

    return {
      'totalWords': _wordCache.length,
      'wordsByLength': _calculateWordStats(),
    };
  }

  /// 단어 통계 계산
  Map<int, int> _calculateWordStats() {
    Map<int, int> stats = {};
    for (String word in _wordCache) {
      int length = word.length;
      stats[length] = (stats[length] ?? 0) + 1;
    }
    return stats;
  }
}
