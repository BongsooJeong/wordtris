# 한국어 단어 테트리스 - 단어 데이터베이스 설계

## 개요
한국어 단어 테트리스 게임을 위한 단어 데이터베이스는 약 50만 라인의 한국어 단어 리스트를 활용합니다. 데이터베이스의 주요 목적은 **사용자가 게임에서 블록을 배치하여 생성된 단어가 실제로 존재하는지 확인**하는 것입니다. 이 문서는 대규모 단어 리스트를 효율적으로 저장하고 빠르게 검색하는 방법을 설명합니다.

## 데이터베이스 구조

### 단어 테이블 스키마 (간소화)
```
Table: korean_words
- id: INTEGER PRIMARY KEY
- word: TEXT (단어) - 인덱싱됨
- length: INTEGER (글자 수) - 인덱싱됨
```

### 간소화된 접근 방식
- 단어의 의미, 난이도, 카테고리, 예문 등 추가 정보는 저장하지 않음
- 오직 단어의 존재 여부를 빠르게 확인하는 데 집중
- 길이별 색인을 통한 검색 최적화

## 대규모 단어 리스트 처리

### 원본 데이터 형식
- 50만 라인의 텍스트 파일로 제공되는 한국어 단어 리스트
- 각 라인은 기본적으로 단어만 포함 (추가 정보가 있다면 필터링)

### 데이터 변환 프로세스
1. **전처리 단계**:
   - 중복 단어 제거
   - 비한글 문자 및 특수 문자 필터링
   - 단어 길이 제한 설정 (예: 2~10자)
   - 모든 단어를 표준 형식으로 정규화

2. **데이터베이스 변환**:
   - SQLite 데이터베이스로 변환
   - 단어 텍스트에 대한 인덱스 생성
   - 단어 길이별 인덱스 생성
   - 필요시 트라이(Trie) 자료구조 구축

## 검색 최적화 전략

### 1. 인덱싱 전략
- **전체 텍스트 검색 (Full Text Search)**:
  ```sql
  CREATE VIRTUAL TABLE korean_words_fts USING fts5(word);
  ```
- **길이별 인덱싱**:
  ```sql
  CREATE INDEX idx_word_length ON korean_words(length);
  ```
- **접두사 인덱싱**:
  ```sql
  CREATE INDEX idx_word_prefix ON korean_words(word COLLATE NOCASE);
  ```

### 2. 인메모리 데이터 구조
- **해시맵(HashMap)**: O(1) 시간 복잡도로 단어 존재 여부 검사
  ```dart
  final Map<String, bool> wordMap = {};
  ```
- **블룸 필터(Bloom Filter)**: 메모리 효율적인 존재 여부 검사
  ```dart
  BloomFilter wordFilter = BloomFilter(expectedInsertions: 500000, falsePositiveRate: 0.01);
  ```
- **트라이(Trie)**: 접두사 기반 빠른 검색
  ```dart
  class TrieNode {
    Map<String, TrieNode> children = {};
    bool isEndOfWord = false;
  }
  ```

### 3. 병렬 처리 및 분산 검색
- 단어 길이별로 데이터 샤딩
- 멀티스레딩을 통한 병렬 검색
- 캐시 계층을 통한 최근/자주 사용된 단어 빠른 접근

## 실제 구현 방식

### 1. 초기 로딩 최적화
```dart
Future<void> loadDictionary() async {
  // 앱 설치 시 기본 단어 세트 로드 (10,000개 정도)
  await _loadInitialWordSet();
  
  // 백그라운드에서 전체 단어 세트 점진적 로드
  _loadFullDictionaryInBackground();
}
```

### 2. 단어 검증 로직
```dart
Future<bool> isValidWord(String word) async {
  // 1. 먼저 메모리 캐시 확인 (가장 빠름)
  if (_wordCache.containsKey(word)) {
    return _wordCache[word]!;
  }
  
  // 2. 블룸 필터로 빠르게 필터링 (거짓 양성 가능)
  if (!_bloomFilter.mightContain(word)) {
    return false;
  }
  
  // 3. 데이터베이스 확인 (최종 검증)
  final result = await _database.rawQuery(
    'SELECT 1 FROM korean_words WHERE word = ? LIMIT 1',
    [word]
  );
  
  final isValid = result.isNotEmpty;
  _wordCache[word] = isValid; // 캐시에 결과 저장
  
  return isValid;
}
```

### 3. 길이별 검색 최적화
```dart
Future<bool> isValidWordByLength(String word) async {
  final length = word.length;
  
  // 길이별 테이블이 있는 경우 직접 접근
  final result = await _database.rawQuery(
    'SELECT 1 FROM korean_words_length_$length WHERE word = ? LIMIT 1',
    [word]
  );
  
  return result.isNotEmpty;
}
```

## 메모리 관리 전략

### 1. 단계적 로딩
- 앱 설치 시 핵심 단어 (~10,000개) 포함
- 첫 실행 시 일부 단어 세트 로드
- 백그라운드에서 나머지 단어 점진적 로드
- 사용 패턴에 따라 추가 단어 세트 다운로드

### 2. 메모리 캐싱 관리
- LRU(Least Recently Used) 캐시로 최근 사용 단어 관리
- 메모리 압박 시 캐시 크기 자동 축소
- 앱 백그라운드 전환 시 일부 메모리 해제

### 3. 효율적인 저장 구조
- 가능한 SQLite 데이터베이스 사용하여 메모리 절약
- 단어 리스트 압축 저장
- 인덱스와 데이터 분리로 메모리 효율성 향상

## 실시간 성능 측정

### 검색 성능 목표
- 단일 단어 검색: < 5ms
- 다중 단어 일괄 검색: < 20ms (최대 10개 단어)
- 메모리 사용량: < 100MB (전체 사전 로드 시)

### 성능 모니터링
- 검색 시간 프로파일링
- 메모리 사용량 추적
- 히트/미스 비율 측정으로 캐시 효율성 평가

## 확장 계획
1. 분산 데이터베이스로 확장 가능한 구조
2. 온라인 동기화: 클라우드를 통한 단어 데이터베이스 업데이트
3. 사용자 정의 단어 추가 기능 (옵션)
4. 검색 알고리즘 지속적 최적화 