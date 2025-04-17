import 'dart:convert';
import 'dart:io';

/// 국립국어원 사전 데이터를 처리하는 도구
/// 국립국어원 사전 XML 또는 CSV 데이터를 WordTris에 사용할 수 있는 JSON 형식으로 변환
///
/// 사용법: dart nikl_processor.dart <입력_파일_경로> <출력_json_파일_경로>
void main(List<String> args) async {
  // 인수 확인
  if (args.length < 2) {
    print('사용법: dart nikl_processor.dart <입력_파일_경로> <출력_json_파일_경로>');
    exit(1);
  }

  final inputPath = args[0];
  final outputPath = args[1];

  print('변환 시작: $inputPath -> $outputPath');

  try {
    // 파일 형식 확인 (확장자 기반)
    if (inputPath.toLowerCase().endsWith('.xml')) {
      print('XML 파일 처리는 현재 구현되지 않았습니다. CSV 파일을 사용해주세요.');
      exit(1);
    } else if (inputPath.toLowerCase().endsWith('.csv')) {
      await processCsvFile(inputPath, outputPath);
    } else {
      print('지원되지 않는 파일 형식입니다. CSV 파일만 지원합니다.');
      exit(1);
    }

    print('완료!');
  } catch (e) {
    print('처리 중 오류 발생: $e');
    exit(1);
  }
}


/// CSV 파일 처리
Future<void> processCsvFile(String inputPath, String outputPath) async {
  // CSV 파일 읽기
  final file = File(inputPath);
  if (!await file.exists()) {
    print('오류: 입력 파일을 찾을 수 없습니다 - $inputPath');
    exit(1);
  }

  print('파일 읽는 중...');
  final lines = await file.readAsLines();
  print('CSV 파일 읽기 완료: ${lines.length}개 라인');

  // 단어 추출
  final List<String> words = [];
  final Set<String> uniqueWords = {}; // 중복 제거를 위한 Set
  int skippedCount = 0;
  int hyphenWordCount = 0;
  int filteredWordsCount = 0; // '어미', '접사' 등이 필터링된 단어 수

  // 헤더 확인 (선택 사항)
  bool hasHeader = true;
  int startIndex = hasHeader ? 1 : 0;

  for (int i = startIndex; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) {
      skippedCount++;
      continue;
    }

    final columns = line.split(',');
    if (columns.isEmpty) {
      skippedCount++;
      continue;
    }

    // 첫 번째 열이 표제어(단어)로 가정
    String originalWord = columns[0].trim();
    
    // 특정 단어 로깅 (디버깅용)
    if (originalWord == "다지" || originalWord.contains("다지")) {
      print("디버깅: 발견된 단어: '$originalWord', 열 개수: ${columns.length}, 두 번째 열: ${columns.length > 1 ? columns[1] : '없음'}");
    }
    
    // '어미', '접사' 등이 포함된 단어 필터링
    if (columns.length > 1) {
      String wordType = columns[1].trim();
      
      // 두 번째 컬럼이 '어미' 또는 '접사'인 경우 필터링
      if (wordType == '어미' || wordType == '접사') {
        filteredWordsCount++;
        
        // 특정 단어 필터링 로깅 (디버깅용)
        if (originalWord == "다지" || originalWord.contains("다지")) {
          print("디버깅: 필터링된 단어: '$originalWord', 유형: '$wordType'");
        }
        
        continue; // 이 단어 건너뛰기
      }
    }
    
    // 특정 단어는 직접 필터링
    List<String> specialFilterWords = ['다지', '다요', '다우', '다이', '다지다'];
    if (specialFilterWords.contains(originalWord)) {
      filteredWordsCount++;
      print("디버깅: 직접 필터링된 단어: '$originalWord'");
      continue; // 이 단어 건너뛰기
    }
    
    String cleanedWord;
    
    // 하이픈(-) 처리
    if (originalWord.contains('-')) {
      // 하이픈을 제거하고 붙인 단어 추가 (예: "제양-시롭다" -> "제양시롭다")
      cleanedWord = originalWord.replaceAll('-', '');
      cleanedWord = cleanWord(cleanedWord);
      hyphenWordCount++;
      
      if (isValidKoreanWord(cleanedWord) && !uniqueWords.contains(cleanedWord)) {
        uniqueWords.add(cleanedWord);
        words.add(cleanedWord);
      } else {
        skippedCount++;
      }
      
      // 하이픈 앞부분만 따로 추가하지 않음 (예: "제양-시롭다"에서 "제양"을 추가하지 않음)
    } else {
      // 일반 단어 처리
      cleanedWord = cleanWord(originalWord);
      
      if (isValidKoreanWord(cleanedWord) && !uniqueWords.contains(cleanedWord)) {
        uniqueWords.add(cleanedWord);
        words.add(cleanedWord);
      } else {
        skippedCount++;
      }
    }

    // 진행 상황 표시 (10만 단어마다)
    if (words.length % 100000 == 0 && words.isNotEmpty) {
      print('처리 중: ${words.length}개 단어 추출됨');
    }
  }

  print('단어 추출 완료: ${words.length}개 단어 ($skippedCount개 건너뜀)');
  print('어미/접사 필터링: $filteredWordsCount개');
  print('하이픈 포함 단어: $hyphenWordCount개');

  // 단어를 알파벳순으로 정렬
  words.sort();

  // JSON 파일로 저장
  final jsonString = jsonEncode(words);
  final outputFile = File(outputPath);
  await outputFile.writeAsString(jsonString);

  print('JSON 파일 저장 완료: $outputPath (${(jsonString.length / 1024 / 1024).toStringAsFixed(2)} MB)');
  
  // 초성별 파일 분리
  await splitByConsonant(words, outputPath);
}

/// 단어 정제 함수
String cleanWord(String word) {
  // 특수 문자 제거 (하이픈은 이미 별도 처리되어 이 함수로 오지 않음)
  word = word.replaceAll(RegExp(r'[^\uAC00-\uD7A3가-힣]'), '');
  
  // 앞뒤 공백 제거
  return word.trim();
}

/// 유효한 한글 단어인지 확인
bool isValidKoreanWord(String word) {
  // 길이 검사 (3글자 이상)
  if (word.length < 3) return false;
  
  // 한글만 포함되어 있는지 검사
  if (!RegExp(r'^[\uAC00-\uD7A3가-힣]+$').hasMatch(word)) return false;
  
  return true;
}

/// 초성별로 단어 분리하여 저장
Future<void> splitByConsonant(List<String> words, String basePath) async {
  print('초성별 파일 분리 시작...');
  
  // 초성 맵 초기화
  final Map<String, List<String>> consonantMap = {};
  final List<String> consonants = [
    'ㄱ', 'ㄴ', 'ㄷ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅅ', 
    'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ', '기타'
  ];
  
  for (final consonant in consonants) {
    consonantMap[consonant] = [];
  }
  
  // 단어별로 초성 추출 및 분류
  for (final word in words) {
    if (word.isEmpty) continue;
    
    final firstChar = word[0];
    final consonant = getInitialConsonant(firstChar);
    
    consonantMap[consonant]?.add(word);
  }
  
  // 초성별 파일 저장 및 인덱스 생성
  final Map<String, int> indexMap = {};
  
  for (final consonant in consonants) {
    final wordList = consonantMap[consonant] ?? [];
    if (wordList.isEmpty) continue;
    
    final fileName = basePath.replaceAll('.json', '_$consonant.json');
    final jsonString = jsonEncode(wordList);
    await File(fileName).writeAsString(jsonString);
    
    indexMap[consonant] = wordList.length;
    print('$consonant 초성 파일 저장: ${wordList.length}개 단어');
  }
  
  // 인덱스 파일 저장
  final indexPath = basePath.replaceAll('.json', '_index.json');
  await File(indexPath).writeAsString(jsonEncode(indexMap));
  
  print('초성별 파일 분리 완료: ${consonants.length}개 파일');
}

/// 한글 문자에서 초성 추출
String getInitialConsonant(String char) {
  if (char.isEmpty) return '기타';
  
  // 디버깅 추가
  // print('단어: $char, 코드: ${char.codeUnitAt(0).toRadixString(16)}');
  
  // 한글 유니코드 범위: AC00-D7A3
  final code = char.codeUnitAt(0);
  
  if (code < 0xAC00 || code > 0xD7A3) return '기타';
  
  // 초성 추출 공식
  // 초성 = (코드 - 0xAC00) / (21 * 28)
  final index = ((code - 0xAC00) ~/ (21 * 28));
  
  // 초성 매핑
  const initialConsonants = [
    'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 
    'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
  ];
  
  if (index >= 0 && index < initialConsonants.length) {
    // 쌍자음 처리
    final consonant = initialConsonants[index];
    
    // 확인용 출력 - "제양"과 같은 단어는 어떤 초성으로 분류되는지 확인
    if (char == '제') {
      // print('"제" 문자의 초성 인덱스: $index, 초성: ${initialConsonants[index]}');
    }
    
    switch (consonant) {
      case 'ㄲ': return 'ㄱ';
      case 'ㄸ': return 'ㄷ';
      case 'ㅃ': return 'ㅂ';
      case 'ㅆ': return 'ㅅ';
      case 'ㅉ': return 'ㅈ';
      default: return consonant;
    }
  }
  
  return '기타';
} 