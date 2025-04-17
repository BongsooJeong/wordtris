import 'dart:io';

/// CSV 파일에서 단어를 추출하여 텍스트 파일로 저장하는 스크립트
void main() async {
  // 입력 및 출력 파일 경로
  const inputFilePath = 'assets/data/kr_korean.csv';
  const outputFilePath = 'assets/data/korean_words.txt';

  try {
    // 파일 읽기
    final file = File(inputFilePath);
    if (!await file.exists()) {
      print('입력 파일을 찾을 수 없습니다: $inputFilePath');
      return;
    }

    final lines = await file.readAsLines();
    print('읽은 줄 수: ${lines.length}');

    // 단어 추출 (중복 제거)
    final Set<String> uniqueWords = {};
    final Set<String> filteredWords = {};

    for (final line in lines) {
      // CSV 형식 파싱
      final parts = line.split(',');
      if (parts.isEmpty) continue;

      // 첫 번째 부분에서 단어 추출
      final firstPart = parts[0].trim();
      if (firstPart.isEmpty) continue;

      // 복합 단어/품사 구분자 처리
      // 1. 하이픈(-) 처리: "번지-수" -> "번지", "수"
      if (firstPart.contains('-')) {
        final hyphenParts = firstPart.split('-');
        for (final part in hyphenParts) {
          final cleaned = _cleanWord(part);
          if (cleaned.length >= 2) {
            uniqueWords.add(cleaned);
          }
        }

        // 하이픈을 제외한 완전한 단어도 추가
        final fullWord = firstPart.replaceAll('-', '');
        if (fullWord.length >= 2) {
          uniqueWords.add(fullWord);
        }
      }
      // 2. 캐럿(^) 처리: "번지^버스" -> "번지버스", "번지", "버스"
      else if (firstPart.contains('^')) {
        final caretParts = firstPart.split('^');

        // 개별 부분 단어
        for (final part in caretParts) {
          final cleaned = _cleanWord(part);
          if (cleaned.length >= 2) {
            uniqueWords.add(cleaned);
          }
        }

        // 캐럿을 제외한 완전한 단어도 추가
        final fullWord = firstPart.replaceAll('^', '');
        if (fullWord.length >= 2) {
          uniqueWords.add(fullWord);
        }
      }
      // 3. 그 외 일반 단어
      else {
        final cleaned = _cleanWord(firstPart);
        if (cleaned.length >= 2) {
          uniqueWords.add(cleaned);
        }
      }
    }

    // 불필요한 단어 필터링
    for (final word in uniqueWords) {
      bool isValid = true;

      // 숫자나 알파벳이 포함된 단어 필터링
      if (_containsNonKorean(word)) {
        isValid = false;
      }

      if (isValid) {
        filteredWords.add(word);
      }
    }

    print('추출된 고유 단어 수: ${uniqueWords.length}');
    print('필터링 후 단어 수: ${filteredWords.length}');

    // 단어를 한글 자모순으로 정렬
    final sortedWords = filteredWords.toList()..sort();

    // 출력 파일에 저장
    final outputFile = File(outputFilePath);
    await outputFile.writeAsString(sortedWords.join('\n'));

    print('단어 추출 완료! 파일이 저장되었습니다: $outputFilePath');
  } catch (e) {
    print('오류 발생: $e');
  }
}

/// 단어 정리 (특수문자 제거 등)
String _cleanWord(String word) {
  return word.trim().replaceAll(
      RegExp(r'[^\uAC00-\uD7A3\u1100-\u11FF\u3130-\u318F]'), ''); // 한글과 자모음만 유지
}

/// 비한글 문자(숫자, 알파벳 등) 포함 여부 확인
bool _containsNonKorean(String word) {
  // 한글 유니코드 범위: AC00-D7A3(완성형), 1100-11FF(자모), 3130-318F(호환 자모)
  final nonKoreanPattern =
      RegExp(r'[^\uAC00-\uD7A3\u1100-\u11FF\u3130-\u318F]');
  return nonKoreanPattern.hasMatch(word);
}
