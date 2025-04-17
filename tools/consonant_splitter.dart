import 'dart:convert';
import 'dart:io';

/// 한국어 단어를 초성별로 분류하여 여러 개의 JSON 파일로 나누는 도구
///
/// 사용법: dart consonant_splitter.dart <입력_json_파일_경로> <출력_디렉토리_경로>
void main(List<String> args) async {
  // 인수 확인
  if (args.length < 2) {
    print('사용법: dart consonant_splitter.dart <입력_json_파일_경로> <출력_디렉토리_경로>');
    exit(1);
  }

  final inputPath = args[0];
  final outputDir = args[1];

  print('초성별 단어 분류 시작: $inputPath -> $outputDir');

  try {
    // 출력 디렉토리 확인
    final dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      print('출력 디렉토리 생성: $outputDir');
    }

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

    // 초성 목록
    final List<String> consonants = [
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
      'ㅎ',
      '기타'
    ];

    // 초성별 단어 맵
    final Map<String, List<String>> wordsByConsonant = {};
    for (final consonant in consonants) {
      wordsByConsonant[consonant] = [];
    }

    // 단어 분류
    int unclassifiedCount = 0;
    for (final word in allWords) {
      if (word is! String || word.isEmpty) {
        unclassifiedCount++;
        continue;
      }

      final String wordStr = word.toString();
      final String firstChar = wordStr[0];
      String consonant = '기타';

      // 초성 판별
      if (firstChar.compareTo('가') >= 0 && firstChar.compareTo('깋') <= 0) {
        consonant = 'ㄱ';
      } else if (firstChar.compareTo('나') >= 0 &&
          firstChar.compareTo('닣') <= 0) {
        consonant = 'ㄴ';
      } else if (firstChar.compareTo('다') >= 0 &&
          firstChar.compareTo('딯') <= 0) {
        consonant = 'ㄷ';
      } else if (firstChar.compareTo('라') >= 0 &&
          firstChar.compareTo('맇') <= 0) {
        consonant = 'ㄹ';
      } else if (firstChar.compareTo('마') >= 0 &&
          firstChar.compareTo('밓') <= 0) {
        consonant = 'ㅁ';
      } else if (firstChar.compareTo('바') >= 0 &&
          firstChar.compareTo('빟') <= 0) {
        consonant = 'ㅂ';
      } else if (firstChar.compareTo('사') >= 0 &&
          firstChar.compareTo('싷') <= 0) {
        consonant = 'ㅅ';
      } else if (firstChar.compareTo('아') >= 0 &&
          firstChar.compareTo('잏') <= 0) {
        consonant = 'ㅇ';
      } else if (firstChar.compareTo('자') >= 0 &&
          firstChar.compareTo('짛') <= 0) {
        consonant = 'ㅈ';
      } else if (firstChar.compareTo('차') >= 0 &&
          firstChar.compareTo('칳') <= 0) {
        consonant = 'ㅊ';
      } else if (firstChar.compareTo('카') >= 0 &&
          firstChar.compareTo('킿') <= 0) {
        consonant = 'ㅋ';
      } else if (firstChar.compareTo('타') >= 0 &&
          firstChar.compareTo('팋') <= 0) {
        consonant = 'ㅌ';
      } else if (firstChar.compareTo('파') >= 0 &&
          firstChar.compareTo('핗') <= 0) {
        consonant = 'ㅍ';
      } else if (firstChar.compareTo('하') >= 0 &&
          firstChar.compareTo('힣') <= 0) {
        consonant = 'ㅎ';
      }

      wordsByConsonant[consonant]!.add(wordStr);
    }

    // 초성별 통계
    print('\n[초성별 단어 수]');
    for (final entry in wordsByConsonant.entries) {
      print('${entry.key}: ${entry.value.length}개');
    }
    print('분류되지 않은 단어: $unclassifiedCount개');

    // 초성별 JSON 파일 저장
    print('\n초성별 JSON 파일 저장 중...');
    for (final entry in wordsByConsonant.entries) {
      final consonant = entry.key;
      final words = entry.value;

      if (words.isEmpty) {
        print('$consonant: 단어 없음, 파일 생성 건너뜀');
        continue;
      }

      final outputPath = '$outputDir/korean_words_$consonant.json';
      final outputFile = File(outputPath);
      final outputJsonString = jsonEncode(words);

      await outputFile.writeAsString(outputJsonString);
      print(
          '$consonant: ${words.length}개 단어 저장 완료 (${(outputJsonString.length / 1024).toStringAsFixed(2)} KB)');
    }

    // 전체 단어를 저장하는 인덱스 파일 생성
    final Map<String, String> index = {};
    for (final consonant in consonants) {
      if (wordsByConsonant[consonant]!.isNotEmpty) {
        index[consonant] = 'korean_words_$consonant.json';
      }
    }

    final indexPath = '$outputDir/words_index.json';
    final indexFile = File(indexPath);
    final indexJsonString = jsonEncode(index);

    await indexFile.writeAsString(indexJsonString);
    print('\n인덱스 파일 저장 완료: $indexPath');

    print('\n초성별 단어 분류 완료!');
  } catch (e) {
    print('오류 발생: $e');
    exit(1);
  }
}
