import 'dart:io';
import 'dart:convert';

/// 빈도 분석 데이터를 100개 단위로 파일로 정리하는 도구
void main() async {
  // 파일 경로 설정
  final inputFilePath = 'assets/data/common_korean_chars.json';
  final outputDir = 'assets/data';
  
  print('글자 빈도 데이터 파일 생성 시작...');
  
  try {
    // JSON 파일 읽기
    final file = File(inputFilePath);
    final jsonString = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(jsonString);
    
    // 데이터 추출
    final List<String> top100 = List<String>.from(data['top100']);
    final List<String> top101_200 = List<String>.from(data['top101_200']);
    final List<String> top201_300 = List<String>.from(data['top201_300']);
    
    // 순위별 데이터 세트 생성
    final Map<String, dynamic> top100Data = {
      'chars': top100,
      'rank': 'top100',
      'description': '가장 많이 사용되는 상위 100개 한글 글자',
      'generatedAt': DateTime.now().toIso8601String(),
    };
    
    final Map<String, dynamic> top200Data = {
      'chars': top101_200,
      'rank': 'top101_200',
      'description': '자주 사용되는 101-200위 한글 글자',
      'generatedAt': DateTime.now().toIso8601String(),
    };
    
    final Map<String, dynamic> top300Data = {
      'chars': top201_300,
      'rank': 'top201_300',
      'description': '자주 사용되는 201-300위 한글 글자',
      'generatedAt': DateTime.now().toIso8601String(),
    };
    
    // 파일로 저장
    await _writeJsonFile('$outputDir/korean_chars_top100.json', top100Data);
    await _writeJsonFile('$outputDir/korean_chars_top101_200.json', top200Data);
    await _writeJsonFile('$outputDir/korean_chars_top201_300.json', top300Data);
    
    // 한글자당 한줄씩의 텍스트 파일도 생성 (CSV 형식)
    await _writeTextFile('$outputDir/korean_chars_top100.txt', top100);
    await _writeTextFile('$outputDir/korean_chars_top101_200.txt', top101_200);
    await _writeTextFile('$outputDir/korean_chars_top201_300.txt', top201_300);
    
    // 결과 요약
    final totalRank = List<Map<String, dynamic>>.from(data['totalRank']);
    
    print('\n빈도 분석 파일 생성 완료:');
    print('1. 상위 100개 글자: korean_chars_top100.json, korean_chars_top100.txt');
    print('2. 101-200위 글자: korean_chars_top101_200.json, korean_chars_top101_200.txt');
    print('3. 201-300위 글자: korean_chars_top201_300.json, korean_chars_top201_300.txt');
    
    print('\n상위 10개 글자:');
    for (int i = 0; i < 10; i++) {
      final entry = totalRank[i];
      print('${i+1}. ${entry['char']}: ${entry['count']}회 (${entry['percent']}%)');
    }
    
    print('\n사용 예시:');
    print('''
// JSON 파일 로드 예시 (Flutter)
Future<List<String>> loadTop100Chars() async {
  final jsonString = await rootBundle.loadString('assets/data/korean_chars_top100.json');
  final data = jsonDecode(jsonString);
  return List<String>.from(data['chars']);
}

// 텍스트 파일 로드 예시 (Flutter)
Future<List<String>> loadTop100CharsFromText() async {
  final text = await rootBundle.loadString('assets/data/korean_chars_top100.txt');
  return text.split('\\n').where((line) => line.trim().isNotEmpty).toList();
}
''');
    
  } catch (e) {
    print('오류 발생: $e');
  }
}

/// JSON 파일 쓰기
Future<void> _writeJsonFile(String path, Map<String, dynamic> data) async {
  final file = File(path);
  final encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString(encoder.convert(data), flush: true);
  print('파일 생성됨: $path');
}

/// 텍스트 파일 쓰기 (CSV 형식)
Future<void> _writeTextFile(String path, List<String> chars) async {
  final file = File(path);
  final buffer = StringBuffer();
  
  // 각 글자를 한 줄에 하나씩 작성
  for (final char in chars) {
    buffer.writeln(char);
  }
  
  await file.writeAsString(buffer.toString(), flush: true);
  print('파일 생성됨: $path');
} 