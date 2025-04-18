import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import '../models/grid.dart';
import '../services/word_service.dart';
import '../utils/point.dart';

/// 한글 단어 처리를 담당하는 클래스
class WordProcessor {
  final WordService _wordService = WordService();

  // 빈도 기반 한글 글자 데이터
  List<String> _top100Chars = [];
  List<String> _top101_200Chars = [];
  List<String> _top201_300Chars = [];
  bool _frequencyDataLoaded = false;

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

  /// 빈도 기반 랜덤 글자 선택
  String getFrequencyBasedChar() {
    if (!_frequencyDataLoaded) {
      _setupDefaultFrequencyData();
    }

    final random = Random();
    final roll = random.nextDouble();

    if (roll < 0.4) {
      // 40% 확률로 상위 100개 중 선택
      return _top100Chars[random.nextInt(_top100Chars.length)];
    } else if (roll < 0.7) {
      // 30% 확률로 상위 101-200개 중 선택
      return _top101_200Chars.isEmpty
          ? _top100Chars[random.nextInt(_top100Chars.length)]
          : _top101_200Chars[random.nextInt(_top101_200Chars.length)];
    } else if (roll < 0.9) {
      // 20% 확률로 상위 201-300개 중 선택
      return _top201_300Chars.isEmpty
          ? _top100Chars[random.nextInt(_top100Chars.length)]
          : _top201_300Chars[random.nextInt(_top201_300Chars.length)];
    } else {
      // 10% 확률로 기존 한글 글자에서 선택
      return _commonKoreanChars[random.nextInt(_commonKoreanChars.length)];
    }
  }

  /// 랜덤 자음 기반 문자 생성
  String getRandomConsonantChar() {
    final random = Random();
    final consonant = _consonants[random.nextInt(_consonants.length)];
    final vowel = _vowels[random.nextInt(_vowels.length)];

    if (_charMapping.containsKey(consonant) &&
        _charMapping[consonant]!.containsKey(vowel)) {
      return _charMapping[consonant]![vowel]!;
    }

    const defaultChars = ['가', '나', '다', '라', '마', '바', '사', '아', '자', '차'];
    return defaultChars[random.nextInt(defaultChars.length)];
  }

  /// 랜덤 모음 기반 문자 생성
  String getRandomVowelChar() {
    final random = Random();
    final vowel = _vowels[random.nextInt(_vowels.length)];
    final consonant = _consonants[random.nextInt(_consonants.length)];

    if (_charMapping.containsKey(consonant) &&
        _charMapping[consonant]!.containsKey(vowel)) {
      return _charMapping[consonant]![vowel]!;
    }

    const defaultChars = ['아', '야', '어', '여', '오', '요', '우', '유', '으', '이'];
    return defaultChars[random.nextInt(defaultChars.length)];
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

          if (word.length >= 3) {
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

          if (word.length >= 3) {
            bool isValid = await _wordService.isValidWordAsync(word);
            if (isValid) {
              wordCandidates.add(Word(text: word, cells: List.from(cells)));
            }
          }
        }
      }
    }

    return wordCandidates;
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
}
