# 한국어 단어 테트리스 - 데이터 모델 설계

## 개요
한국어 단어 테트리스 게임의 효과적인 구현을 위한 데이터 모델 설계 문서입니다. 이 문서는 게임에서 사용될 주요 데이터 구조와 관계를 정의합니다.

## 핵심 모델

### 1. Block 모델
블록은 게임의 기본 단위로, 크기와 모양이 다양하며 각 칸에는 한글 글자가 포함되어 있습니다.

```dart
/// 블록 모양 정의 (상대적 위치)
enum BlockShape {
  // 1셀 블록
  single, // 1x1

  // 2셀 블록
  horizontal2, // 2x1 가로
  vertical2, // 1x2 세로

  // 3셀 블록
  horizontal3, // 3x1 가로
  vertical3, // 1x3 세로
  lShape, // ㄱ자 모양
  reverseLShape, // ㄴ자 모양
  corner, // ꓔ자 모양
  
  // 4셀 블록
  squareShape, // 2x2 정사각형
  horizontal4, // 4x1 가로 긴 블록
  vertical4, // 1x4 세로 긴 블록

  // 특수 블록
  bomb, // 폭탄 블록
}

/// 게임에서 사용되는 블록 모델
class Block {
  final int id;                     // 블록 고유 ID
  final BlockShape shape;           // 블록 형태
  final List<String> characters;    // 블록에 표시될 한글 글자들
  final Color color;                // 블록 색상
  bool isPlaced = false;            // 그리드에 배치 여부
  int rotationState = 0;            // 회전 상태 (0, 1, 2, 3) - 0°, 90°, 180°, 270°
  bool isBomb = false;              // 폭탄 블록 여부
  
  // 2차원 행렬로 블록 표현 
  late List<List<String?>> matrix;  // 블록 형태와 문자 저장용 행렬

  // 블록 크기 (문자 개수)
  int get size => characters.length;
  
  // 초기 행렬 생성
  void _initMatrix() {
    // 블록 모양에 따라 행렬 구성
    // ...
  }

  // 블록 회전
  Block rotate() {
    // 다음 회전 상태로 변경 (0->1->2->3->0)
    int nextRotation = (rotationState + 1) % 4;
    
    // 회전된 새 블록 생성
    Block rotated = copyWith(rotationState: nextRotation);
    rotated.matrix = _rotateMatrixClockwise(matrix);
    
    return rotated;
  }
  
  // 블록의 상대적 셀 위치 반환
  List<Point> getRelativePoints() {
    // 행렬 기반으로 셀 위치 반환
    // ...
  }
  
  // 특정 상대 위치의 문자 가져오기
  String? getCharacterAt(int x, int y) {
    // 행렬에서 문자 가져오기
    // ...
  }
  
  // 블록 생성 정적 메서드
  static BlockShape getRandomShapeForSize(int size, Random random) {
    // 블록 크기별 모양 선택
    // size 1: single
    // size 2: horizontal2, vertical2
    // size 3: horizontal3, vertical3, lShape, reverseLShape, corner
    // size 4: squareShape, horizontal4, vertical4
    // ...
  }
}
```

### 2. Grid 모델
게임 그리드는 블록들의 배치와 관리를 담당합니다.

```dart
/// 단어를 표현하는 클래스
class Word {
  final String text;                // 단어 텍스트
  final List<Point> cells;          // 단어의 셀 위치
  final int score;                  // 단어 점수
}

/// 애니메이션을 위한 제거될 셀 정보
class RemovedCell {
  final Point position;             // 셀의 위치 
  final String character;           // 셀의 문자
  final Color color;                // 셀의 색상
}

/// 게임의 그리드 구조를 표현하는 클래스
class Grid {
  final int rows;                   // 그리드 행 수 (10)
  final int columns;                // 그리드 열 수 (10)
  late List<List<Cell>> cells;      // 그리드 셀 배열
  
  // 마지막으로 제거된 셀들 (애니메이션용)
  List<RemovedCell> lastRemovedCells = [];
  
  // 그리드 초기화
  void initializeGrid() {
    // 빈 셀로 초기화
    // ...
  }
  
  // 블록 배치
  Grid placeBlock(Block block, List<Point> positions) {
    // 블록을 그리드에 배치
    // ...
  }
  
  // 단어 제거
  Grid removeWords(List<Word> words) {
    // 완성된 단어 제거
    // ...
  }
  
  // 폭탄 효과 적용
  Grid explodeBomb(Point center) {
    // 폭탄 블록 주변 3x3 영역 제거
    // ...
  }
}

/// 그리드의 개별 셀
class Cell {
  String? character;                // 셀에 있는 글자 (null = 빈 셀)
  Color? color;                     // 셀 색상
  int? blockId;                     // 셀을 차지하는 블록 ID
  
  bool get isEmpty => character == null;
}
```

### 3. GameProvider 모델
게임 상태와 로직을 관리하는 Provider 클래스입니다.

```dart
/// 게임 상태를 관리하는 Provider 클래스
class GameProvider with ChangeNotifier {
  late Grid _grid;                           // 게임 그리드
  final List<Block> _availableBlocks = [];   // 사용 가능한 블록들
  int _score = 0;                            // 현재 점수
  int _level = 1;                            // 현재 레벨
  bool _isGameOver = false;                  // 게임 오버 여부
  bool _isGamePaused = false;                // 일시정지 여부
  final Random _random = Random();           // 랜덤 생성기
  int _wordClearCount = 0;                   // 단어 제거 횟수 카운터
  bool _bombGenerated = false;               // 폭탄 생성 플래그
  
  // 게임 초기화
  Future<void> _initializeGame() async {
    // 그리드 생성, 상태 초기화, 블록 생성
    // ...
  }
  
  // 블록 생성
  Block _createRandomBlock() {
    // 블록 크기 확률 조정: 1칸 5%, 2칸 15%, 3칸 40%, 4칸 40%
    int blockSize;
    final sizeRoll = _random.nextDouble();
    
    if (sizeRoll < 0.05) {
      blockSize = 1;  // 5%
    } else if (sizeRoll < 0.20) {
      blockSize = 2;  // 15%
    } else if (sizeRoll < 0.60) {
      blockSize = 3;  // 40%
    } else {
      blockSize = 4;  // 40%
    }
    
    // 블록 모양, 색상, 문자 생성
    // ...
  }
  
  // 블록 회전
  Block rotateBlock(Block block) {
    return block.rotate();
  }
  
  // 블록 배치
  Future<bool> placeBlock(Block block, List<Point> positions) async {
    // 배치 확인, 블록 배치, 단어 확인, 점수 갱신
    // ...
  }
  
  // 단어 확인
  Future<void> _checkForWords() async {
    // 가로/세로 방향 단어 확인, 점수 계산, 제거
    // ...
  }
  
  // 점수 추가 및 레벨 업
  void _addScore(int points) {
    _score += points;
    
    // 단어 제거 횟수 증가
    _wordClearCount++;
    
    // 레벨 업 체크 (1000점마다 레벨 업)
    int newLevel = (_score / 1000).floor() + 1;
    if (newLevel > _level) {
      _level = newLevel;
    }
  }
}
```

## 데이터 구조와 알고리즘

### 1. 블록 회전 알고리즘
블록은 2차원 행렬로 표현되며, 회전 시 행렬을 시계 방향으로 90도 회전합니다.

```dart
List<List<String?>> _rotateMatrixClockwise(List<List<String?>> mat) {
  final int n = mat.length;
  final int m = mat[0].length;
  
  // m x n 크기의 새 행렬 생성 (행과 열 바꿈)
  List<List<String?>> rotated = List.generate(
    m, (_) => List<String?>.filled(n, null)
  );
  
  // 시계 방향 90도 회전 적용
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < m; j++) {
      rotated[j][n - i - 1] = mat[i][j];
    }
  }
  
  return rotated;
}
```

### 2. 블록 배치 위치 계산
그리드에 블록을 배치할 때 정확한 위치 계산이 필요합니다.

```dart
// 블록 배치 위치 계산
List<Point> _calculateBlockPositions(Block block, int baseRow, int baseCol) {
  List<Point> positions = [];
  
  // 블록의 상대적 위치 기반으로 그리드 위치 계산
  for (var point in block.getRelativePoints()) {
    int row = baseRow + point.y;
    int col = baseCol + point.x;
    positions.add(Point(col, row));
  }
  
  return positions;
}
```

### 3. 단어 검색 알고리즘
그리드에서 가로/세로로 형성된 단어를 찾는 알고리즘:

```dart
// 그리드에서 단어 찾기
Future<List<Word>> _findWords() async {
  List<Word> wordCandidates = [];
  
  // 가로 단어 검색
  for (int y = 0; y < _grid.rows; y++) {
    for (int startX = 0; startX < _grid.columns - 1; startX++) {
      // 빈 셀 건너뛰기
      if (_grid.cells[y][startX].isEmpty) continue;
      
      String word = _grid.cells[y][startX].character!;
      List<Point> cells = [Point(startX, y)];
      
      // 연속된 문자 확인
      for (int x = startX + 1; x < _grid.columns; x++) {
        if (_grid.cells[y][x].isEmpty) break;
        
        word += _grid.cells[y][x].character!;
        cells.add(Point(x, y));
        
        // 2글자 이상이면 단어 확인
        if (word.length >= 2) {
          bool isValid = await _wordService.isValidWordAsync(word);
          if (isValid) {
            wordCandidates.add(Word(text: word, cells: List.from(cells)));
          }
        }
      }
    }
  }
  
  // 세로 단어 검색도 동일한 방식으로 수행
  // ...
  
  return wordCandidates;
}
```

## 성능 최적화

### 1. 단어 검증 최적화
```dart
class WordService {
  final Map<String, bool> _cache = {}; // 단어 캐시
  Set<String> _validWords = {}; // 유효 단어 세트
  
  Future<bool> isValidWordAsync(String word) async {
    // 캐시에 있으면 캐시 결과 반환
    if (_cache.containsKey(word)) {
      return _cache[word]!;
    }
    
    // 단어 검증 수행
    bool isValid = _validWords.contains(word);
    
    // 결과 캐싱
    _cache[word] = isValid;
    
    return isValid;
  }
}
```

### 2. 블록 위치 계산 최적화
블록 배치 가능 여부를 빠르게 확인하기 위한 방법:

```dart
bool canPlaceBlockAt(Block block, Point position) {
  List<Point> positions = _calculateBlockPositions(block, position);
  
  // 그리드 범위 체크
  for (var point in positions) {
    if (point.x < 0 || point.y < 0 || 
        point.x >= _grid.columns || point.y >= _grid.rows) {
      return false;
    }
  }
  
  // 빈 셀 체크
  for (var point in positions) {
    if (!_grid.cells[point.y][point.x].isEmpty) {
      return false;
    }
  }
  
  return true;
}
``` 