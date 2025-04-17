import 'dart:io';
import 'dart:convert';
import 'dart:math';

/// 한글 글자 빈도 분석 도구
/// 
/// kr_korean.csv 파일을 분석하여 가장 많이 사용되는 한글 글자를 찾아내고
/// 출현 빈도에 따라 정렬된 리스트를 생성합니다.
void main() async {
  // 파일 경로 설정
  final inputFilePath = 'assets/data/kr_korean.csv';
  final outputFilePath = 'assets/data/common_korean_chars.json';
  
  print('한글 글자 빈도 분석 시작...');
  
  // CSV 파일 읽기 (바이너리로 읽은 후 UTF-8로 디코딩)
  final file = File(inputFilePath);
  final bytes = await file.readAsBytes();
  
  // 다양한 인코딩 시도
  String content;
  try {
    content = utf8.decode(bytes); // UTF-8로 시도
  } catch (e) {
    try {
      content = latin1.decode(bytes); // Latin-1로 시도
    } catch (e) {
      // 모두 실패하면 바이트를 무시하고 강제 디코딩
      content = utf8.decode(bytes, allowMalformed: true);
    }
  }
  
  final lines = content.split('\n');
  
  // 글자 빈도 맵
  final Map<String, int> charFrequency = {};
  
  // 각 라인에서 첫 번째 단어 추출
  int processedWords = 0;
  int totalChars = 0;
  int skippedWords = 0;
  
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    
    final parts = line.split(',');
    if (parts.isEmpty || parts[0].isEmpty) continue;
    
    // 첫 번째 컬럼에서 단어 추출
    String word = parts[0].trim();
    
    // 하이픈 제거
    if (word.contains('-')) {
      word = word.split('-')[0].trim();
    }

    bool containsKorean = false;
    
    // 한글 글자만 처리 (유니코드 범위: AC00-D7A3, 한글 자모: 1100-11FF, 호환용 한글 자모: 3130-318F)
    for (int i = 0; i < word.length; i++) {
      final char = word[i];
      final codeUnit = char.codeUnitAt(0);
      
      // 한글 완성형 범위 확인 (가-힣)
      if (codeUnit >= 0xAC00 && codeUnit <= 0xD7A3) {
        charFrequency[char] = (charFrequency[char] ?? 0) + 1;
        totalChars++;
        containsKorean = true;
      }
    }
    
    if (!containsKorean) {
      skippedWords++;
      if (skippedWords <= 10) {
        print('스킵된 단어: $word (한글이 아님)');
      }
      continue;
    }
    
    processedWords++;
    if (processedWords % 10000 == 0) {
      print('처리 중: $processedWords 단어 분석됨...');
    }
  }
  
  // 빈도별로 정렬
  final sortedChars = charFrequency.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  // 결과 요약
  print('분석 완료:');
  print('전체 단어 수: $processedWords');
  print('스킵된 단어 수: $skippedWords');
  print('전체 글자 수: $totalChars');
  print('고유 글자 수: ${sortedChars.length}');
  
  if (sortedChars.isEmpty) {
    print('경고: 한글 글자를 찾을 수 없습니다. 파일 인코딩을 확인하세요.');
    return;
  }
  
  // 빈도로 분류 (상위 100, 상위 200, 상위 300)
  final top100 = sortedChars.take(min(100, sortedChars.length)).map((e) => e.key).toList();
  
  final top200 = sortedChars.length > 100 
      ? sortedChars.skip(100).take(min(100, sortedChars.length - 100)).map((e) => e.key).toList()
      : <String>[];
      
  final top300 = sortedChars.length > 200
      ? sortedChars.skip(200).take(min(100, sortedChars.length - 200)).map((e) => e.key).toList()
      : <String>[];
  
  // 상위 300개의 글자와 빈도를 보여줌
  print('\n상위 300개 글자 출현 빈도:');
  for (int i = 0; i < min(300, sortedChars.length); i++) {
    final entry = sortedChars[i];
    final frequency = (entry.value / totalChars * 100).toStringAsFixed(2);
    print('${i+1}. ${entry.key}: ${entry.value}회 (${frequency}%)');
  }
  
  // 카테고리별 글자 분포를 JSON으로 저장
  final result = {
    'top100': top100,
    'top101_200': top200,
    'top201_300': top300,
    'totalRank': sortedChars.take(min(300, sortedChars.length)).map((e) => {
      'char': e.key,
      'count': e.value,
      'percent': (e.value / totalChars * 100).toStringAsFixed(2)
    }).toList(),
    'metadata': {
      'totalWords': processedWords,
      'skippedWords': skippedWords,
      'totalChars': totalChars,
      'uniqueChars': sortedChars.length,
      'generatedAt': DateTime.now().toIso8601String(),
    }
  };
  
  // JSON 파일로 저장
  final outputFile = File(outputFilePath);
  await outputFile.writeAsString(
    JsonEncoder.withIndent('  ').convert(result),
    flush: true
  );
  
  print('\n결과가 $outputFilePath에 저장되었습니다.');
  
  // 게임 적용 방법 안내
  print('\n게임 적용 방법:');
  print('1. GameProvider 클래스의 _commonKoreanChars 배열을 JSON에서 로드하도록 변경:');
  print('''
  // 자주 사용되는 한글 글자 로드 (빈도 분석 기반)
  static late List<String> _top100Chars;
  static late List<String> _top101_200Chars;
  static late List<String> _top201_300Chars;
  
  // 빈도 데이터 초기화
  Future<void> _loadCharFrequencyData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/common_korean_chars.json');
      final data = jsonDecode(jsonString);
      
      _top100Chars = List<String>.from(data['top100']);
      _top101_200Chars = List<String>.from(data['top101_200']);
      _top201_300Chars = List<String>.from(data['top201_300']);
      
      print('글자 빈도 데이터 로드 완료: 상위 300개');
    } catch (e) {
      print('글자 빈도 데이터 로드 실패: \$e');
      // 기본 글자 설정
      _top100Chars = ['가', '나', '다', '라', '마'];
      _top101_200Chars = ['바', '사', '아', '자', '차'];
      _top201_300Chars = ['카', '타', '파', '하'];
    }
  }
  ''');
  
  print('2. 글자 선택 로직 구현:');
  print('''
  // 블록 글자 선택 (빈도 기반)
  String _getRandomFrequencyChar() {
    final random = Random();
    final roll = random.nextDouble();
    
    if (roll < 0.6) {  // 60% 확률로 상위 100개 중 선택
      return _top100Chars[random.nextInt(_top100Chars.length)];
    } else if (roll < 0.9) {  // 30% 확률로 상위 101-200개 중 선택
      return _top101_200Chars[random.nextInt(_top101_200Chars.length)];
    } else {  // 10% 확률로 상위 201-300개 중 선택
      return _top201_300Chars[random.nextInt(_top201_300Chars.length)];
    }
  }
  ''');
  
  print('3. _createRandomBlock()에서 글자 생성 부분 변경:');
  print('''
  // 필요한 문자 생성 (빈도 기반 글자 선택)
  for (int i = 0; i < requiredChars; i++) {
    characters.add(_getRandomFrequencyChar());
  }
  ''');
} 