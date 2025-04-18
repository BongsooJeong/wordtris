import 'package:flutter/material.dart';
import 'block.dart';
import '../utils/point.dart';

/// WordTris 게임 그리드 시스템 API 문서
///
/// [Word] 클래스
/// - 완성된 단어 정보를 담는 클래스
/// - text: 단어 문자열
/// - cells: 단어를 구성하는 셀들의 위치
/// - score: 단어의 점수
///
/// [RemovedCell] 클래스
/// - 제거된 셀의 애니메이션 정보를 담는 클래스
/// - position: 셀의 위치
/// - character: 셀의 문자
/// - color: 셀의 색상
///
/// [Grid] 클래스 API
/// - constructor: Grid({required rows, required columns})
///   rows x columns 크기의 게임 그리드 생성
///
/// 주요 메서드:
/// - initializeGrid()
///   그리드를 빈 셀로 초기화
///
/// - copyWith({rows, columns, cells}): Grid
///   그리드의 복사본 생성
///
/// - getCell(int x, int y): Cell?
///   지정된 좌표의 셀 반환
///
/// - getCellAt(Point point): Cell?
///   지정된 포인트의 셀 반환
///
/// - isValidPlacement(List<Point> points): bool
///   블록 배치 가능 여부 확인
///
/// - placeBlock(Block block, List<Point> points): Grid
///   블록을 그리드에 배치
///
/// - findWords(Set<String> validWords): List<Word>
///   가로/세로 방향으로 완성된 단어 찾기
///
/// - removeWords(List<Word> words): Grid
///   완성된 단어들을 그리드에서 제거
///
/// - explodeBomb(Point center): Grid
///   폭탄 효과로 3x3 영역 제거
///
/// - isFull(): bool
///   그리드가 가득 찼는지 확인
///
/// [Cell] 클래스 API
/// - constructor: Cell({character, color, blockId})
///   그리드의 개별 셀 생성
///
/// 속성:
/// - character: 셀에 표시되는 문자
/// - color: 셀의 색상
/// - blockId: 셀이 속한 블록의 ID
/// - isEmpty: 셀이 비어있는지 여부
///
/// 메서드:
/// - clear()
///   셀의 내용을 지움
/// - copyWith({...}): Cell
///   셀의 복사본 생성

/// 단어를 표현하는 클래스
class Word {
  final String text;
  final List<Point> cells;
  final int score;

  Word({
    required this.text,
    required this.cells,
    this.score = 0,
  });

  @override
  String toString() => "Word('$text', cells: $cells)";
}

/// 애니메이션을 위한 제거될 셀 정보
class RemovedCell {
  final Point position;
  final String character;
  final Color color;

  RemovedCell({
    required this.position,
    required this.character,
    required this.color,
  });
}

/// 게임의 그리드 구조를 표현하는 클래스
class Grid {
  final int rows;
  final int columns;
  late List<List<Cell>> cells;

  // 마지막으로 제거된 셀들의 정보 (애니메이션용)
  List<RemovedCell> lastRemovedCells = [];

  Grid({
    required this.rows,
    required this.columns,
  }) {
    initializeGrid();
  }

  /// 그리드 초기화
  void initializeGrid() {
    cells = List.generate(
      rows,
      (i) => List.generate(
        columns,
        (j) => Cell(),
      ),
    );
  }

  /// 그리드 복사본 생성 메서드
  Grid copyWith({
    int? rows,
    int? columns,
    List<List<Cell>>? cells,
  }) {
    if ((rows != null && rows != this.rows) ||
        (columns != null && columns != this.columns)) {
      // 크기가 변경되면 새 그리드 생성
      return Grid(
        rows: rows ?? this.rows,
        columns: columns ?? this.columns,
      );
    }

    // 크기는 같고 셀 내용만 변경
    Grid newGrid = Grid(rows: this.rows, columns: this.columns);
    if (cells != null) {
      for (int i = 0; i < rows!; i++) {
        for (int j = 0; j < columns!; j++) {
          newGrid.cells[i][j] = cells[i][j];
        }
      }
      return newGrid;
    }

    // 셀을 복사
    for (int i = 0; i < this.rows; i++) {
      for (int j = 0; j < this.columns; j++) {
        newGrid.cells[i][j] = this.cells[i][j].copyWith();
      }
    }
    return newGrid;
  }

  /// 특정 위치의 셀을 반환하는 메서드 (범위 검증 포함)
  Cell? getCell(int x, int y) {
    if (x < 0 || x >= columns || y < 0 || y >= rows) {
      return null;
    }
    return cells[y][x];
  }

  /// 포인트 위치의 셀을 반환하는 메서드
  Cell? getCellAt(Point point) {
    return getCell(point.x, point.y);
  }

  /// 그리드에서 Block 배치가 유효한지 확인하는 메서드
  bool isValidPlacement(List<Point> points) {
    // 모든 점이 그리드 내에 있고 비어있는지 확인
    for (Point point in points) {
      Cell? cell = getCellAt(point);
      if (cell == null || !cell.isEmpty) {
        return false;
      }
    }
    return true;
  }

  /// 블록을 그리드에 배치하는 메서드
  Grid placeBlock(Block block, List<Point> points) {
    if (!isValidPlacement(points)) {
      throw Exception('Invalid block placement');
    }

    Grid newGrid = copyWith();

    // 블록의 기준점 계산 (첫 번째 포인트)
    Point basePoint = points[0];

    // 블록의 상대적 위치 가져오기
    List<Point> relativePoints = block.getRelativePoints();
    Point originPoint = relativePoints[0];

    for (Point point in points) {
      // 블록 내의 상대적 위치 계산
      int relX = point.x - basePoint.x + originPoint.x;
      int relY = point.y - basePoint.y + originPoint.y;

      // 해당 위치의 문자 가져오기
      String? character = block.getCharacterAt(relX, relY);
      if (character == null) continue;

      newGrid.cells[point.y][point.x] = Cell(
        character: character,
        color: block.color,
        blockId: block.id,
      );
    }

    return newGrid;
  }

  /// 완성된 단어를 찾는 메서드 (가로, 세로 방향)
  List<Word> findWords(Set<String> validWords) {
    List<Word> found = [];

    // 가로 방향 단어 검색
    for (int y = 0; y < rows; y++) {
      String currentWord = '';
      List<Point> wordCells = [];

      for (int x = 0; x < columns; x++) {
        Cell cell = cells[y][x];

        if (!cell.isEmpty) {
          currentWord += cell.character!;
          wordCells.add(Point(x, y));
        } else if (currentWord.isNotEmpty) {
          // 단어가 끝나면 확인
          if (currentWord.length >= 2 && validWords.contains(currentWord)) {
            found.add(Word(
              text: currentWord,
              cells: List.from(wordCells),
              score: 0,
            ));
          }

          // 단어 초기화
          currentWord = '';
          wordCells = [];
        }
      }

      // 줄 끝에서 단어 확인
      if (currentWord.length >= 2 && validWords.contains(currentWord)) {
        found.add(Word(
          text: currentWord,
          cells: List.from(wordCells),
          score: 0,
        ));
      }
    }

    // 세로 방향 단어 검색
    for (int x = 0; x < columns; x++) {
      String currentWord = '';
      List<Point> wordCells = [];

      for (int y = 0; y < rows; y++) {
        Cell cell = cells[y][x];

        if (!cell.isEmpty) {
          currentWord += cell.character!;
          wordCells.add(Point(x, y));
        } else if (currentWord.isNotEmpty) {
          // 단어가 끝나면 확인
          if (currentWord.length >= 2 && validWords.contains(currentWord)) {
            found.add(Word(
              text: currentWord,
              cells: List.from(wordCells),
              score: 0,
            ));
          }

          // 단어 초기화
          currentWord = '';
          wordCells = [];
        }
      }

      // 열 끝에서 단어 확인
      if (currentWord.length >= 2 && validWords.contains(currentWord)) {
        found.add(Word(
          text: currentWord,
          cells: List.from(wordCells),
          score: 0,
        ));
      }
    }

    return found;
  }

  /// 완성된 단어를 그리드에서 제거하는 메서드
  Grid removeWords(List<Word> words) {
    Grid newGrid = copyWith();
    List<RemovedCell> removedCells = [];

    for (Word word in words) {
      for (Point cellPoint in word.cells) {
        // 제거하기 전에 셀 정보 저장 (애니메이션용)
        Cell cell = cells[cellPoint.y][cellPoint.x];
        if (!cell.isEmpty) {
          removedCells.add(RemovedCell(
            position: cellPoint,
            character: cell.character!,
            color: cell.color!,
          ));
        }

        // 셀 제거
        newGrid.cells[cellPoint.y][cellPoint.x] = Cell();
      }
    }

    // 애니메이션용 제거된 셀 정보 저장
    newGrid.lastRemovedCells = removedCells;
    return newGrid;
  }

  /// 폭탄 효과로 주변 3x3 영역을 제거하는 메서드
  Grid explodeBomb(Point center) {
    Grid newGrid = copyWith();
    List<RemovedCell> removedCells = [];

    // 3x3 영역의 셀 제거
    for (int y = center.y - 1; y <= center.y + 1; y++) {
      for (int x = center.x - 1; x <= center.x + 1; x++) {
        // 그리드 범위 내에 있는지 확인
        if (y >= 0 && y < rows && x >= 0 && x < columns) {
          // 제거하기 전에 셀 정보 저장 (애니메이션용)
          Cell cell = cells[y][x];
          if (!cell.isEmpty) {
            removedCells.add(RemovedCell(
              position: Point(x, y),
              character: cell.character!,
              color: cell.color!,
            ));
          }

          // 셀 제거
          newGrid.cells[y][x] = Cell();
        }
      }
    }

    // 애니메이션용 제거된 셀 정보 저장
    newGrid.lastRemovedCells = removedCells;
    return newGrid;
  }

  /// 그리드가 꽉 찼는지 확인하는 메서드
  bool isFull() {
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < columns; x++) {
        if (cells[y][x].isEmpty) {
          return false;
        }
      }
    }
    return true;
  }
}

/// 그리드의 개별 셀을 표현하는 클래스
class Cell {
  String? character;
  Color? color;
  int? blockId;

  Cell({
    this.character,
    this.color,
    this.blockId,
  });

  bool get isEmpty => character == null;

  /// 셀의 내용을 지우는 메서드
  void clear() {
    character = null;
    color = null;
    blockId = null;
  }

  /// 셀 복제 메서드
  Cell copyWith({
    String? character,
    Color? color,
    int? blockId,
    bool clearCell = false,
  }) {
    if (clearCell) {
      return Cell();
    }

    return Cell(
      character: character ?? this.character,
      color: color ?? this.color,
      blockId: blockId ?? this.blockId,
    );
  }
}
