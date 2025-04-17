import 'dart:convert';
import 'dart:io';

/// 기존 JSON 단어 목록에서 특수문자를 제거하고 단어 정제하는 도구
///
/// 사용법: dart korean_word_cleaner.dart <입력_json_파일_경로> <출력_json_파일_경로>
void main(List<String> args) async {
  // 인수 확인
  if (args.length < 2) {
    print('사용법: dart korean_word_cleaner.dart <입력_json_파일_경로> <출력_json_파일_경로>');
    exit(1);
  }

  final inputPath = args[0];
  final outputPath = args[1];

  print('단어 정제 시작: $inputPath -> $outputPath');

  try {
    // JSON 파일 읽기
    final file = File(inputPath);
    if (!await file.exists()) {
      print('오류: 입력 파일을 찾을 수 없습니다 - $inputPath');
      exit(1);
    }

    print('JSON 파일 읽는 중...');
    final String jsonString = await file.readAsString();
    print(
        'JSON 파일 읽기 완료 (${(jsonString.length / 1024 / 1024).toStringAsFixed(2)} MB)');

    // JSON 디코딩
    final List<dynamic> dirtyWords = jsonDecode(jsonString);
    print('기존 단어 수: ${dirtyWords.length}');

    // 정제된 단어 저장 (중복 제거)
    final Set<String> uniqueCleanWords = {};
    final List<String> cleanWords = [];

    // 특수문자 포함 단어 통계
    int specialCharCount = 0;
    int addedFromSpecialChar = 0;

    // 진행 상황 표시 변수
    int processedCount = 0;
    final int totalCount = dirtyWords.length;
    final int reportInterval = (totalCount / 10).round(); // 10% 단위로 보고

    print('단어 정제 중...');

    for (final word in dirtyWords) {
      processedCount++;

      if (processedCount % reportInterval == 0) {
        final progress = (processedCount / totalCount * 100).toStringAsFixed(1);
        print('진행률: $progress% ($processedCount/$totalCount)');
      }

      if (word is! String || word.isEmpty) {
        continue;
      }

      final String originalWord = word.toString();

      // 특수문자 포함 여부 확인
      if (originalWord.contains(RegExp(r'[^\uAC00-\uD7A3가-힣a-zA-Z0-9]'))) {
        specialCharCount++;

        // 특수문자 처리
        final List<String> processedWords =
            _processSpecialCharWord(originalWord);
        for (final cleanWord in processedWords) {
          if (!uniqueCleanWords.contains(cleanWord)) {
            uniqueCleanWords.add(cleanWord);
            cleanWords.add(cleanWord);
            addedFromSpecialChar++;
          }
        }
      } else {
        // 일반 단어는 그대로 추가
        if (!uniqueCleanWords.contains(originalWord)) {
          uniqueCleanWords.add(originalWord);
          cleanWords.add(originalWord);
        }
      }
    }

    print('\n단어 정제 완료');
    print('특수문자 포함 단어: $specialCharCount개');
    print('특수문자 처리로 추가된 단어: $addedFromSpecialChar개');
    print('정제 후 총 단어 수: ${cleanWords.length}개');

    // 정제된 단어 출력 (샘플)
    if (cleanWords.isNotEmpty) {
      print('\n정제된 단어 샘플:');
      int sampleSize = cleanWords.length < 10 ? cleanWords.length : 10;
      for (int i = 0; i < sampleSize; i++) {
        print('- ${cleanWords[i]}');
      }
    }

    // JSON 파일로 저장
    final outputJsonString = jsonEncode(cleanWords);
    final outputFile = File(outputPath);
    await outputFile.writeAsString(outputJsonString);

    print(
        '\nJSON 파일 저장 완료: $outputPath (${(outputJsonString.length / 1024 / 1024).toStringAsFixed(2)} MB)');
    print('완료!');
  } catch (e) {
    print('오류 발생: $e');
    exit(1);
  }
}

/// 특수문자가 포함된 단어 처리
List<String> _processSpecialCharWord(String word) {
  // 특수문자 분리 패턴 ('^', '-' 등)
  final separators = ['^', '-', '_', '/', '\\', ',', '.', '·', '='];
  List<String> result = [];

  // 1. 특수문자를 기준으로 단어 분리
  List<String> parts = [word];
  for (final separator in separators) {
    List<String> newParts = [];
    for (final part in parts) {
      newParts.addAll(part.split(separator));
    }
    parts = newParts;
  }

  // 2. 분리된 각 부분 정제 (특수문자 제거, 공백 제거, 한글/영문/숫자만 유지)
  for (final part in parts) {
    final cleaned =
        part.replaceAll(RegExp(r'[^\uAC00-\uD7A3가-힣a-zA-Z0-9]'), '').trim();
    if (cleaned.length >= 2) {
      // 2글자 이상인 단어만 추가
      result.add(cleaned);
    }
  }

  // 3. 하이픈(-) 또는 특수문자 연결 단어 처리: "기지개-하다" => "기지개하다"
  final noSpecialChars =
      word.replaceAll(RegExp(r'[^\uAC00-\uD7A3가-힣a-zA-Z0-9]'), '').trim();
  if (noSpecialChars.length >= 2 && !result.contains(noSpecialChars)) {
    result.add(noSpecialChars);
  }

  return result;
}
