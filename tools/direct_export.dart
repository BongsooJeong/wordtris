import 'dart:io';
import 'dart:convert';

/// 상위 300개 한글 글자 빈도 데이터를 직접 파일로 저장하는 도구
void main() async {
  final outputDir = 'assets/data';
  
  print('한글 글자 빈도 데이터 파일 직접 생성 시작...');
  
  // 상위 100개 한글 글자 (빈도순)
  final List<String> top100 = [
    '기', '이', '다', '리', '지', '사', '자', '수', '대', '가',
    '스', '전', '도', '정', '시', '화', '아', '비', '하', '무',
    '고', '소', '구', '동', '조', '부', '상', '성', '산', '장',
    '제', '주', '공', '유', '로', '어', '물', '인', '선', '적',
    '르', '신', '오', '계', '의', '보', '거', '마', '우', '방',
    '연', '치', '미', '경', '라', '레', '일', '나', '중', '트',
    '개', '원', '불', '모', '세', '단', '관', '학', '식', '반',
    '분', '금', '문', '양', '드', '진', '바', '위', '발', '호',
    '질', '재', '그', '회', '생', '해', '파', '교', '간', '서',
    '음', '실', '법', '국', '용', '배', '안', '포', '천', '두'
  ];
  
  // 상위 101-200위 글자
  final List<String> top101_200 = [
    '차', '통', '체', '감', '당', '노', '종', '강', '작', '명',
    '석', '심', '각', '영', '타', '광', '형', '내', '합', '은',
    '삼', '속', '매', '행', '토', '복', '절', '초', '한', '근',
    '피', '프', '과', '크', '증', '역', '저', '직', '루', '에',
    '여', '청', '판', '설', '약', '니', '등', '름', '군', '박',
    '목', '만', '면', '염', '백', '들', '열', '추', '업', '민',
    '락', '운', '독', '외', '건', '결', '살', '임', '래', '후',
    '변', '입', '환', '예', '망', '랑', '출', '요', '카', '병',
    '권', '림', '색', '알', '디', '표', '평', '송', '태', '덕',
    '탄', '야', '러', '철', '막', '애', '돌', '집', '달', '격'
  ];
  
  // 상위 201-300위 글자
  final List<String> top201_300 = [
    '력', '급', '황', '벌', '말', '육', '창', '점', '항', '류',
    '새', '코', '귀', '투', '채', '축', '현', '극', '순', '글',
    '접', '갈', '량', '티', '허', '언', '악', '터', '검', '메',
    '봉', '버', '골', '풍', '침', '남', '승', '닥', '본', '편',
    '술', '압', '죽', '득', '왕', '밀', '렁', '누', '암', '손',
    '향', '담', '취', '농', '충', '온', '족', '곡', '난', '탈',
    '울', '베', '별', '테', '론', '록', '굴', '란', '참', '머',
    '데', '착', '준', '브', '립', '견', '령', '혼', '처', '응',
    '까', '궁', '옥', '월', '게', '좌', '총', '줄', '더', '팔',
    '번', '린', '폐', '네', '혈', '험', '둥', '함', '활', '와'
  ];
  
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
  
  try {
    // 출력 디렉토리 확인
    final dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    // 파일로 저장
    await _writeJsonFile('$outputDir/korean_chars_top100.json', top100Data);
    await _writeJsonFile('$outputDir/korean_chars_top101_200.json', top200Data);
    await _writeJsonFile('$outputDir/korean_chars_top201_300.json', top300Data);
    
    // 한글자당 한줄씩의 텍스트 파일도 생성 (CSV 형식)
    await _writeTextFile('$outputDir/korean_chars_top100.txt', top100);
    await _writeTextFile('$outputDir/korean_chars_top101_200.txt', top101_200);
    await _writeTextFile('$outputDir/korean_chars_top201_300.txt', top201_300);
    
    print('\n빈도 분석 파일 생성 완료:');
    print('1. 상위 100개 글자: korean_chars_top100.json, korean_chars_top100.txt');
    print('2. 101-200위 글자: korean_chars_top101_200.json, korean_chars_top101_200.txt');
    print('3. 201-300위 글자: korean_chars_top201_300.json, korean_chars_top201_300.txt');
    
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