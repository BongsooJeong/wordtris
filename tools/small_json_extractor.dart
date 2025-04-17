import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// 대용량 한국어 단어 JSON에서 일부 단어만 추출하여 작은 JSON 파일 생성
///
/// 사용법: dart small_json_extractor.dart <입력_json_파일_경로> <출력_json_파일_경로> <단어_수>
void main(List<String> args) async {
  // 인수 확인
  if (args.length < 3) {
    print(
        '사용법: dart small_json_extractor.dart <입력_json_파일_경로> <출력_json_파일_경로> <단어_수>');
    exit(1);
  }

  final inputPath = args[0];
  final outputPath = args[1];
  final int wordCount = int.tryParse(args[2]) ?? 1000;

  print('단어 추출 시작: $inputPath -> $outputPath (단어 수: $wordCount)');

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
    final List<dynamic> allWords = jsonDecode(jsonString);
    print('전체 단어 수: ${allWords.length}');

    // 길이별로 분류
    final Map<int, List<String>> wordsByLength = {};
    for (final word in allWords) {
      final String wordStr = word.toString();
      final int length = wordStr.length;

      if (!wordsByLength.containsKey(length)) {
        wordsByLength[length] = [];
      }

      wordsByLength[length]!.add(wordStr);
    }

    // 각 길이별 통계 출력
    print('\n[단어 길이별 통계]');
    for (final entry in wordsByLength.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      print('${entry.key}글자 단어: ${entry.value.length}개');
    }

    // 단어 추출 (2글자부터 10글자까지 균등하게 분배)
    final List<String> selectedWords = [];
    final Random random = Random();

    // 2글자 단어는 더 많이 포함 (50%)
    final int twoCharWordCount = (wordCount * 0.5).round();
    if (wordsByLength.containsKey(2) && wordsByLength[2]!.isNotEmpty) {
      wordsByLength[2]!.shuffle(random);
      selectedWords.addAll(wordsByLength[2]!
          .take(min(twoCharWordCount, wordsByLength[2]!.length)));
    }

    // 나머지 50%는 3-10글자 단어로 균등 분배
    final int remainingCount = wordCount - selectedWords.length;
    final int wordsPerLength = (remainingCount / 8).ceil();

    for (int length = 3; length <= 10; length++) {
      if (wordsByLength.containsKey(length) &&
          wordsByLength[length]!.isNotEmpty) {
        wordsByLength[length]!.shuffle(random);
        selectedWords.addAll(wordsByLength[length]!
            .take(min(wordsPerLength, wordsByLength[length]!.length)));
      }
    }

    // 단어 수가 목표보다 적으면 2글자 단어로 채움
    if (selectedWords.length < wordCount && wordsByLength.containsKey(2)) {
      final int additionalTwoCharWords = wordCount - selectedWords.length;
      final int alreadyTaken = selectedWords.where((w) => w.length == 2).length;

      if (wordsByLength[2]!.length > alreadyTaken) {
        final additionalWords = wordsByLength[2]!.skip(alreadyTaken).take(min(
            additionalTwoCharWords, wordsByLength[2]!.length - alreadyTaken));
        selectedWords.addAll(additionalWords);
      }
    }

    // 단어 셔플
    selectedWords.shuffle(random);

    print('\n최종 선택된 단어 수: ${selectedWords.length}');

    // 선택된 단어 중 일부 출력 (최대 10개)
    print('샘플 단어:');
    for (int i = 0; i < min(10, selectedWords.length); i++) {
      print('- ${selectedWords[i]}');
    }

    // JSON 파일로 저장
    final outputJsonString = jsonEncode(selectedWords);
    final outputFile = File(outputPath);
    await outputFile.writeAsString(outputJsonString);

    print('추출된 단어 JSON 파일 저장 완료: $outputPath');
    print('완료!');
  } catch (e) {
    print('변환 중 오류 발생: $e');
    exit(1);
  }
}
