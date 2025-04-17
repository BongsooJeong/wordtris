import 'dart:convert';
import 'dart:io';

/// 한국어 단어 CSV 파일을 JSON 형식으로 변환하는 도구
/// 특수문자 제거 및 전처리 기능 추가
/// 3글자 이상 단어만 포함
///
/// 사용법: dart csv_to_json_converter.dart <입력_csv_파일_경로> <출력_json_파일_경로>
void main(List<String> args) async {
  // 인수 확인
  if (args.length < 2) {
    print(
        '사용법: dart csv_to_json_converter.dart <입력_csv_파일_경로> <출력_json_파일_경로>');
    exit(1);
  }

  final inputPath = args[0];
  final outputPath = args[1];

  print('변환 시작: $inputPath -> $outputPath');

  try {
    // CSV 파일 읽기
    final file = File(inputPath);
    if (!await file.exists()) {
      print('오류: 입력 파일을 찾을 수 없습니다 - $inputPath');
      exit(1);
    }

    print('파일 읽는 중...');
    final lines = await file.readAsLines();
    print('CSV 파일 읽기 완료: ${lines.length}개 라인');

    // CSV에서 단어 추출 (첫 번째 열만 사용)
    final List<String> words = [];
    final Set<String> uniqueWords = {}; // 중복 제거를 위한 Set
    int skippedCount = 0;
    int specialCharCount = 0;
    int shortWordCount = 0; // 2글자 이하 단어 개수

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

      String word = columns[0].trim();

      // 특수문자 처리
      if (word.contains(RegExp(r'[^\uAC00-\uD7A3가-힣a-zA-Z0-9]'))) {
        // 특수문자 처리 방법 1: 분리하여 각각의 단어로 저장
        final cleanWords = _processSpecialCharWord(word);
        if (cleanWords.isNotEmpty) {
          for (final cleanWord in cleanWords) {
            if (!uniqueWords.contains(cleanWord)) {
              uniqueWords.add(cleanWord);
              words.add(cleanWord);
            }
          }
        }
        specialCharCount++;
      } else if (word.isNotEmpty) {
        // 일반 단어 처리 - 3글자 이상만 추가
        if (word.length >= 3 && !uniqueWords.contains(word)) {
          uniqueWords.add(word);
          words.add(word);
        } else if (word.length < 3) {
          shortWordCount++;  // 짧은 단어 카운트 증가
          skippedCount++;    // 스킵 카운트에도 추가
        }
      } else {
        skippedCount++;
      }

      // 진행 상황 표시 (10만 단어마다)
      if (words.length % 100000 == 0 && words.isNotEmpty) {
        print('처리 중: ${words.length}개 단어 추출됨');
      }
    }

    print('단어 추출 완료: ${words.length}개 단어 ($skippedCount개 건너뜀)');
    print('특수문자 포함 단어: $specialCharCount개');
    print('2글자 이하 단어: $shortWordCount개 (필터링됨)');

    // JSON 파일로 저장
    final jsonString = jsonEncode(words);
    final outputFile = File(outputPath);
    await outputFile.writeAsString(jsonString);

    print(
        'JSON 파일 저장 완료: $outputPath (${(jsonString.length / 1024 / 1024).toStringAsFixed(2)} MB)');
    print('완료!');
  } catch (e) {
    print('변환 중 오류 발생: $e');
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
    if (cleaned.length >= 3) {  // 3글자 이상인 단어만 추가
      result.add(cleaned);
    }
  }

  // 3. 하이픈(-) 연결 단어 처리: "기지개-하다" => "기지개하다"
  if (word.contains('-')) {
    final noHyphen = word.replaceAll('-', '');
    final cleaned =
        noHyphen.replaceAll(RegExp(r'[^\uAC00-\uD7A3가-힣a-zA-Z0-9]'), '').trim();
    if (cleaned.length >= 3 && !result.contains(cleaned)) {  // 3글자 이상인 단어만 추가
      result.add(cleaned);
    }
  }

  return result;
}
