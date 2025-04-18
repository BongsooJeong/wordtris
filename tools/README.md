# 단어 테트리스 도구

이 디렉토리에는 한국어 단어 테트리스 게임 개발에 사용되는 도구들이 포함되어 있습니다.

## 데이터 변환 도구

### 1. CSV 변환 도구 (csv_to_json_converter.dart)

CSV 형식의 한국어 단어 목록(예: kr_korean.csv)을 JSON 형식으로 변환합니다.

#### 사용법:
```bash
dart csv_to_json_converter.dart <입력_csv_파일_경로> <출력_json_파일_경로>
```

#### 예시:
```bash
dart csv_to_json_converter.dart ../data/kr_korean.csv ../assets/data/korean_words_full.json
```

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

### 3. 초성별 단어 분류 (consonant_splitter.dart)

대용량 JSON 단어 목록을 초성별로 나눠서 여러 개의 작은 JSON 파일로 변환합니다.

#### 사용법:
```bash
dart consonant_splitter.dart <입력_json_파일_경로> <출력_디렉토리_경로>
```

### 4. 특수문자 제거 및 단어 정제 (korean_word_cleaner.dart)

기존 JSON 단어 목록에서 특수문자를 제거하고 단어를 정제하는 도구입니다.

#### 사용법:
```bash
dart korean_word_cleaner.dart <입력_json_파일_경로> <출력_json_파일_경로>
```

## 빈도수 분석 도구

### 1. 한글 문자 빈도수 분석 (korean_char_frequency.dart)

한글 단어 목록에서 각 문자(초성, 중성, 종성)의 출현 빈도를 분석합니다.

#### 사용법:
```bash
dart korean_char_frequency.dart <입력_json_파일_경로>
```

### 2. 빈도수 데이터 내보내기 (export_frequency_data.dart)

분석된 문자 빈도수 데이터를 게임에서 사용할 수 있는 형식으로 내보냅니다.

#### 사용법:
```bash
dart export_frequency_data.dart <입력_json_파일_경로> <출력_디렉토리_경로>
```

## 사전 처리 도구

### 1. 국립국어원 사전 처리기 (nikl_processor.dart)

국립국어원 사전 데이터를 처리하여 게임에 사용할 수 있는 형식으로 변환합니다.

#### 사용법:
```bash
dart nikl_processor.dart <입력_파일_경로> <출력_JSON_파일_경로>
```

### 2. 사전 데이터 처리기 (process_dictionary.dart)

다양한 형식의 사전 데이터를 통합하고 처리하는 도구입니다.

#### 사용법:
```bash
dart process_dictionary.dart <입력_디렉토리_경로> <출력_파일_경로>
```

### 3. 직접 내보내기 도구 (direct_export.dart)

처리된 사전 데이터를 게임에서 직접 사용할 수 있는 형식으로 내보냅니다.

#### 사용법:
```bash
dart direct_export.dart <입력_파일_경로> <출력_디렉토리_경로>
```

## PowerShell 도구

### 1. PowerShell 초기화 스크립트 (powershell_init.ps1)

Windows 환경에서 개발 환경을 설정하는 스크립트입니다.

### 2. PowerShell 헬퍼 스크립트 (powershell_helper.ps1)

자주 사용하는 PowerShell 함수들을 모아둔 유틸리티 스크립트입니다.

### 3. PowerShell 실행 스크립트 (run_in_powershell.ps1)

Dart 스크립트를 PowerShell 환경에서 실행하기 위한 래퍼 스크립트입니다.

## 최적화된 워크플로우

대용량 사전 데이터 처리를 위한 권장 워크플로우:

1. CSV 데이터 변환:
   ```bash
   dart csv_to_json_converter.dart ../data/kr_korean.csv ../assets/data/korean_words_full.json
   ```

2. 단어 정제:
   ```bash
   dart korean_word_cleaner.dart ../assets/data/korean_words_full.json ../assets/data/korean_words_clean.json
   ```

3. 문자 빈도수 분석:
   ```bash
   dart korean_char_frequency.dart ../assets/data/korean_words_clean.json
   ```

4. 빈도수 데이터 내보내기:
   ```bash
   dart export_frequency_data.dart ../assets/data/korean_words_clean.json ../assets/data
   ```

5. 초성별 단어 분리:
   ```bash
   dart consonant_splitter.dart ../assets/data/korean_words_clean.json ../assets/data
   ```

## 성능 고려사항

- 대용량 데이터 처리 시 충분한 메모리가 필요합니다.
- 초성별로 분리된 파일과 빈도수 데이터를 함께 사용하면 게임의 성능이 최적화됩니다.
- PowerShell 스크립트를 사용하면 Windows 환경에서 더 효율적으로 작업할 수 있습니다. 