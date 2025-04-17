# 단어 테트리스 도구

이 디렉토리에는 한국어 단어 테트리스 게임 개발에 사용되는 도구들이 포함되어 있습니다.

## CSV 변환 도구

### 1. CSV를 JSON으로 변환 (csv_to_json_converter.dart)

CSV 형식의 한국어 단어 목록(예: kr_korean.csv)을 JSON 형식으로 변환합니다.

#### 사용법:
```bash
dart csv_to_json_converter.dart <입력_csv_파일_경로> <출력_json_파일_경로>
```

#### 예시:
```bash
dart csv_to_json_converter.dart ../data/kr_korean.csv ../assets/data/korean_words_full.json
```

이 스크립트는 CSV 파일에서 한국어 단어를 추출하고 JSON 배열 형태로 저장합니다. 
첫 번째 열에 단어가 있다고 가정하며, 헤더를 건너뛰도록 기본 설정되어 있습니다.

### 2. 대용량 JSON에서 일부 추출 (small_json_extractor.dart)

대용량 JSON 단어 목록에서 일부 단어만 추출하여 게임 테스트용 작은 JSON 파일을 생성합니다.

#### 사용법:
```bash
dart small_json_extractor.dart <입력_json_파일_경로> <출력_json_파일_경로> <단어_수>
```

#### 예시:
```bash
dart small_json_extractor.dart ../assets/data/korean_words_full.json ../assets/data/korean_words.json 1000
```

이 스크립트는 다음과 같은 기능을 제공합니다:
- 단어 길이별 통계 제공
- 다양한 길이의 단어 균형있게 추출 (기본적으로 2글자 단어 50%, 나머지는 3-10글자 단어)
- 추출된 단어 목록을 JSON 형식으로 저장

### 3. 초성별 단어 분류 (consonant_splitter.dart)

대용량 JSON 단어 목록을 초성별로 나눠서 여러 개의 작은 JSON 파일로 변환합니다.
이렇게 하면 검색 효율성이 크게 향상되고 메모리 사용량을 줄일 수 있습니다.

#### 사용법:
```bash
dart consonant_splitter.dart <입력_json_파일_경로> <출력_디렉토리_경로>
```

#### 예시:
```bash
dart consonant_splitter.dart ../assets/data/korean_words_full.json ../assets/data
```

이 스크립트는 다음과 같은 기능을 제공합니다:
- 한국어 단어를 초성(ㄱ, ㄴ, ㄷ, ...)별로 분류
- 각 초성별로 별도의 JSON 파일 생성 (예: korean_words_ㄱ.json)
- 초성별 파일 목록을 담은 인덱스 파일(words_index.json) 생성
- 초성별 단어 수 통계 제공

### 4. 특수문자 제거 및 단어 정제 (korean_word_cleaner.dart)

기존 JSON 단어 목록에서 특수문자를 제거하고 단어를 정제하는 도구입니다.
이 도구는 "기지^사령부", "기지개-하다"와 같은 특수문자가 포함된 단어를 "기지사령부", "기지개하다" 등으로 변환합니다.

#### 사용법:
```bash
dart korean_word_cleaner.dart <입력_json_파일_경로> <출력_json_파일_경로>
```

#### 예시:
```bash
dart korean_word_cleaner.dart ../assets/data/korean_words_full.json ../assets/data/korean_words_clean.json
```

이 스크립트는 다음과 같은 기능을 제공합니다:
- 특수문자(^, -, /, \\ 등)를 기준으로 단어 분리
- 특수문자가 포함된 단어를 정제된 여러 단어로 변환
- 중복 단어 제거
- 정제 과정의 상세한 통계 제공

## 국립국어원 사전 처리기 (nikl_processor.dart)

국립국어원 사전 데이터를 처리하여 WordTris 게임에 사용할 수 있는 형식으로 변환하는 도구입니다.

### 사용법
```bash
dart nikl_processor.dart <입력_파일_경로> <출력_JSON_파일_경로>
```

### 기능
- CSV 또는 XML 형식의 국립국어원 사전 데이터 처리 지원
- 단어 정제 (특수 문자 제거, 공백 제거)
- 유효한 한글 단어만 필터링 (2글자 이상)
- 중복 단어 제거
- 초성별로 단어를 분류하여 개별 JSON 파일로 저장
- 초성별 단어 수를 담은 인덱스 파일 생성

### 예시
```bash
dart nikl_processor.dart assets/data/kr_korean.csv assets/data/korean_words_full.json
```

이 명령은 CSV 파일을 처리하여 전체 단어 목록과 초성별 파일을 생성합니다:
- korean_words_full.json: 모든 단어가 포함된 파일
- korean_words_ㄱ.json, korean_words_ㄴ.json 등: 초성별 단어 파일
- korean_words_index.json: 각 초성별 단어 수를 포함하는 인덱스 파일

## 사용 워크플로우

1. 먼저 CSV 파일을 JSON으로 변환합니다:
   ```bash
   dart csv_to_json_converter.dart ../data/kr_korean.csv ../assets/data/korean_words_full.json
   ```

2. 그 다음, 게임에서 사용할 적당한 크기의 JSON 파일을 생성합니다:
   ```bash
   dart small_json_extractor.dart ../assets/data/korean_words_full.json ../assets/data/korean_words.json 1000
   ```

3. 생성된 `korean_words.json` 파일을 앱에서 사용합니다.

## 최적화된 워크플로우

50만 단어 이상의 대용량 사전을 처리하기 위한 최적화된 워크플로우:

1. CSV를 전체 JSON으로 변환:
   ```bash
   dart csv_to_json_converter.dart ../data/kr_korean.csv ../assets/data/korean_words_full.json
   ```

2. 단어 정제 (특수문자 제거):
   ```bash
   dart korean_word_cleaner.dart ../assets/data/korean_words_full.json ../assets/data/korean_words_clean.json
   ```

3. 초성별로 단어 분리:
   ```bash
   dart consonant_splitter.dart ../assets/data/korean_words_clean.json ../assets/data
   ```

4. 테스트용 작은 JSON 파일이 필요한 경우:
   ```bash
   dart small_json_extractor.dart ../assets/data/korean_words_full.json ../assets/data/korean_words.json 5000
   ```

5. 앱에서는 초성별로 분리된 파일과 인덱스 파일을 사용합니다.

## 성능 고려사항

- 대용량 CSV 파일 처리 시 충분한 메모리가 필요할 수 있습니다.
- 50만 단어 이상의 대용량 JSON 파일은 앱에서 직접 사용하기보다 추출 도구를 통해 적절한 크기로 줄이는 것을 권장합니다. 