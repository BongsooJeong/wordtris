import 'package:flutter/material.dart';
import '../utils/point.dart';
import 'dart:math';

/// Block 클래스 API 문서
///
/// [BlockShape]
/// - 블록의 모양을 정의하는 열거형
/// - single, horizontal2, vertical2 등 다양한 블록 모양 제공
///
/// [Block] 클래스 API
/// - constructor: Block({id, shape, characters, color, rotationState, isBomb})
///   블록 객체를 생성하고 초기 행렬을 구성
///
/// 주요 메서드:
/// - rotate(): Block
///   블록을 시계 방향으로 90도 회전시킨 새로운 블록 반환
///
/// - getRelativePoints(): List<Point>
///   블록의 상대적 셀 위치 목록 반환
///
/// - getCharacterAt(int x, int y): String?
///   지정된 상대 위치의 문자 반환
///
/// - copyWith({...}): Block
///   블록의 속성을 변경한 새로운 블록 복사본 생성
///
/// 정적 메서드:
/// - getRandomShapeForSize(int size, Random random): BlockShape
///   지정된 크기에 맞는 랜덤 블록 모양 생성
///
/// 속성:
/// - id: 블록의 고유 식별자
/// - shape: 블록의 모양 (BlockShape)
/// - characters: 블록을 구성하는 문자 목록
/// - color: 블록의 색상
/// - isPlaced: 블록이 보드에 배치되었는지 여부
/// - rotationState: 현재 회전 상태 (0-3)
/// - isBomb: 폭탄 블록 여부
/// - isWildcard: 와일드카드 여부
/// - matrix: 블록의 2차원 배열 표현
/// - size: 블록의 크기 (문자 개수)

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
  lShapeRotated1, // ㄱ자 회전1
  lShapeRotated2, // ㄱ자 회전2
  lShapeRotated3, // ㄱ자 회전3
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
  final int id;
  final BlockShape shape;
  final List<String> characters;
  final Color color;
  bool isPlaced = false;
  int rotationState = 0; // 0, 1, 2, 3 (0, 90, 180, 270도)
  bool isBomb = false; // 폭탄 여부
  bool isWildcard = false; // 와일드카드 여부

  // 와일드카드 문자 상수
  static const String wildcardChar = '?';

  // 2차원 행렬로 블록 표현 (문자와 위치 매핑)
  late List<List<String?>> matrix;

  Block({
    required this.id,
    required this.shape,
    required this.characters,
    required this.color,
    this.rotationState = 0,
    this.isBomb = false,
    this.isWildcard = false,
  }) {
    // 초기 행렬 생성
    _initMatrix();
  }

  /// 블록 크기 (문자 개수)
  int get size => characters.length;

  /// 초기 블록 행렬 생성
  void _initMatrix() {
    switch (shape) {
      case BlockShape.single:
        matrix = [
          [characters[0]]
        ];
        break;

      case BlockShape.horizontal2:
        matrix = [
          [characters[0], characters[1]]
        ];
        break;

      case BlockShape.vertical2:
        matrix = [
          [characters[0]],
          [characters[1]]
        ];
        break;

      case BlockShape.horizontal3:
        matrix = [
          [characters[0], characters[1], characters[2]]
        ];
        break;

      case BlockShape.vertical3:
        matrix = [
          [characters[0]],
          [characters[1]],
          [characters[2]]
        ];
        break;

      case BlockShape.lShape:
        matrix = [
          [characters[0], characters[1]],
          [characters[2], null]
        ];
        break;
      case BlockShape.lShapeRotated1:
        matrix = [
          [characters[0], null],
          [characters[1], characters[2]]
        ];
        break;
      case BlockShape.lShapeRotated2:
        matrix = [
          [null, characters[0]],
          [characters[1], characters[2]]
        ];
        break;
      case BlockShape.lShapeRotated3:
        matrix = [
          [characters[0], characters[1]],
          [null, characters[2]]
        ];
        break;

      case BlockShape.reverseLShape:
        matrix = [
          [characters[0], null],
          [characters[1], characters[2]]
        ];
        break;

      case BlockShape.corner:
        matrix = [
          [characters[0], characters[1]],
          [characters[2], null]
        ];
        break;

      case BlockShape.squareShape:
        matrix = [
          [characters[0], characters[1]],
          [characters[2], characters[3]]
        ];
        break;

      case BlockShape.horizontal4:
        matrix = [
          [characters[0], characters[1], characters[2], characters[3]]
        ];
        break;

      case BlockShape.vertical4:
        matrix = [
          [characters[0]],
          [characters[1]],
          [characters[2]],
          [characters[3]]
        ];
        break;

      case BlockShape.bomb:
        matrix = [
          [characters[0]]
        ];
        break;
    }

    // 초기 회전 상태에 맞게 회전
    for (int i = 0; i < rotationState; i++) {
      matrix = _rotateMatrixClockwise(matrix);
    }
  }

  /// 블록 회전
  Block rotate() {
    // 디버그 로그 추가
    // print('ROTATE START - 블록 모양: $shape, ID: $id, 현재 회전 상태: $rotationState');
    // print('ROTATE START - 현재 행렬: $matrix');
    // print('ROTATE START - 문자열: $characters');

    // 1셀 블록과 폭탄 블록은 회전하지 않음
    if (shape == BlockShape.single || shape == BlockShape.bomb) {
      // print('1셀/폭탄 블록은 회전하지 않음: $shape');
      return this;
    }

    // 2x2 정사각형 블록 회전 특별 처리
    if (shape == BlockShape.squareShape) {
      // print('2x2 정사각형 블록 회전 처리 시작');

      // 정사각형 블록 회전을 위한 새 행렬 직접 생성
      // 2x2 행렬의 경우 배열 순서가 [0,1] [2,3]으로 정의되어 있음
      // 시계 방향 90도 회전: [2,0] [3,1]
      // 이전 방식은 반시계방향으로 처리하는 문제가 있었음
      List<List<String?>> newMatrix;

      switch (rotationState) {
        case 0: // 0 -> 90도
          newMatrix = [
            [characters[2], characters[0]],
            [characters[3], characters[1]]
          ];
          break;
        case 1: // 90 -> 180도
          newMatrix = [
            [characters[3], characters[2]],
            [characters[1], characters[0]]
          ];
          break;
        case 2: // 180 -> 270도
          newMatrix = [
            [characters[1], characters[3]],
            [characters[0], characters[2]]
          ];
          break;
        case 3: // 270 -> 0도 (원래대로)
          newMatrix = [
            [characters[0], characters[1]],
            [characters[2], characters[3]]
          ];
          break;
        default:
          newMatrix = matrix; // 예상치 못한 상황
      }

      final newRotationState = (rotationState + 1) % 4;
      // print('정사각형 블록 회전 행렬: $newMatrix');

      // 정사각형 블록은 모양 변경없이 회전 상태와 행렬만 변경
      final rotatedBlock =
          copyWith(rotationState: newRotationState, matrix: newMatrix);

      // print('ROTATE END - 정사각형 블록 회전 완료, 회전 상태: ${rotatedBlock.rotationState}');
      // print('ROTATE END - 회전된 행렬: ${rotatedBlock.matrix}');

      return rotatedBlock;
    }

    // 일반 블록 회전 처리
    final rotatedMatrix = _rotateMatrixClockwise(matrix);
    // print('ROTATED MATRIX: $rotatedMatrix');

    final newRotationState = (rotationState + 1) % 4;

    // horizontal4, vertical4 특별 처리 (모양이 변경되어야 함)
    BlockShape newShape = shape;
    if (shape == BlockShape.horizontal4 && newRotationState % 2 == 1) {
      newShape = BlockShape.vertical4;
    } else if (shape == BlockShape.vertical4 && newRotationState % 2 == 0) {
      newShape = BlockShape.horizontal4;
    } else if (shape == BlockShape.horizontal2 && newRotationState % 2 == 1) {
      newShape = BlockShape.vertical2;
    } else if (shape == BlockShape.vertical2 && newRotationState % 2 == 0) {
      newShape = BlockShape.horizontal2;
    } else if (shape == BlockShape.horizontal3 && newRotationState % 2 == 1) {
      newShape = BlockShape.vertical3;
    } else if (shape == BlockShape.vertical3 && newRotationState % 2 == 0) {
      newShape = BlockShape.horizontal3;
    } else if (shape == BlockShape.lShape) {
      if (newRotationState == 1) {
        newShape = BlockShape.lShapeRotated1;
      } else if (newRotationState == 2)
        newShape = BlockShape.lShapeRotated2;
      else if (newRotationState == 3) newShape = BlockShape.lShapeRotated3;
    } else if (shape == BlockShape.lShapeRotated1) {
      if (newRotationState == 2) {
        newShape = BlockShape.lShapeRotated2;
      } else if (newRotationState == 3)
        newShape = BlockShape.lShapeRotated3;
      else if (newRotationState == 0) newShape = BlockShape.lShape;
    } else if (shape == BlockShape.lShapeRotated2) {
      if (newRotationState == 3) {
        newShape = BlockShape.lShapeRotated3;
      } else if (newRotationState == 0)
        newShape = BlockShape.lShape;
      else if (newRotationState == 1) newShape = BlockShape.lShapeRotated1;
    } else if (shape == BlockShape.lShapeRotated3) {
      if (newRotationState == 0) {
        newShape = BlockShape.lShape;
      } else if (newRotationState == 1)
        newShape = BlockShape.lShapeRotated1;
      else if (newRotationState == 2) newShape = BlockShape.lShapeRotated2;
    }

    // 회전된 블록 생성 (같은 문자 배열 사용, 회전된 행렬로 교체)
    final rotatedBlock = copyWith(
        shape: newShape,
        rotationState: newRotationState,
        matrix: rotatedMatrix);

    // print('ROTATE END - 회전된 블록 모양: ${rotatedBlock.shape}, 회전 상태: ${rotatedBlock.rotationState}');
    // print('ROTATE END - 회전된 행렬: ${rotatedBlock.matrix}');

    return rotatedBlock;
  }

  /// 행렬을 시계 방향으로 90도 회전
  List<List<String?>> _rotateMatrixClockwise(List<List<String?>> mat) {
    final int n = mat.length;

    // 빈 행렬이면 빈 행렬 반환
    if (n == 0) return [[]];

    final int m = mat[0].length;

    // 빈 행이면 빈 리스트 반환
    if (m == 0) return [];

    // print('회전 전 행렬: $mat (${n}x${m})');

    // 2x2 정사각형 행렬인 경우 특별 처리 (명시적으로 회전)
    if (n == 2 && m == 2) {
      // print('2x2 정사각형 행렬 특별 처리 적용');
      final result = [
        [mat[1][0], mat[0][0]],
        [mat[1][1], mat[0][1]]
      ];
      // print('2x2 회전 결과: $result');
      return result;
    }

    // 1xm 행렬은 mx1 행렬로 변환 (가로->세로)
    if (n == 1) {
      List<List<String?>> rotated = List.generate(m, (i) => [mat[0][i]]);
      // print('1xm -> mx1 회전: $rotated');
      return rotated;
    }

    // mx1 행렬은 1xm 행렬로 변환 (세로->가로)
    if (m == 1) {
      List<String?> row = List.generate(n, (i) => mat[n - i - 1][0]);
      List<List<String?>> rotated = [row];
      // print('mx1 -> 1xm 회전: $rotated');
      return rotated;
    }

    // 일반적인 nxm 행렬 회전
    // 회전 후 크기는 m x n (행과 열이 바뀜)
    List<List<String?>> rotated =
        List.generate(m, (_) => List<String?>.filled(n, null));

    // 시계 방향 90도 회전 적용
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < m; j++) {
        // 원래 [i][j]에 있던 요소는 회전 후 [j][n-i-1]로 이동
        rotated[j][n - i - 1] = mat[i][j];
      }
    }

    // print('일반 회전 결과: $rotated');
    return rotated;
  }

  /// 블록의 상대적 셀 위치 반환
  List<Point> getRelativePoints() {
    List<Point> points = [];

    // 행렬을 기반으로 상대적 위치 계산
    for (int i = 0; i < matrix.length; i++) {
      for (int j = 0; j < matrix[i].length; j++) {
        if (matrix[i][j] != null) {
          points.add(Point(j, i));
        }
      }
    }

    return points;
  }

  /// 특정 상대 위치에 있는 문자 가져오기
  String? getCharacterAt(int x, int y) {
    if (y < 0 || y >= matrix.length || x < 0 || x >= matrix[y].length) {
      return null;
    }
    return matrix[y][x];
  }

  /// 블록 복제 메서드
  Block copyWith({
    int? id,
    BlockShape? shape,
    List<String>? characters,
    Color? color,
    bool? isPlaced,
    int? rotationState,
    bool? isBomb,
    List<List<String?>>? matrix,
  }) {
    Block copy = Block(
      id: id ?? this.id,
      shape: shape ?? this.shape,
      characters: characters ?? this.characters,
      color: color ?? this.color,
      rotationState: rotationState ?? this.rotationState,
      isBomb: isBomb ?? this.isBomb,
      isWildcard: this.isWildcard,
    );
    copy.isPlaced = isPlaced ?? this.isPlaced;
    copy.matrix = matrix ?? this.matrix;
    return copy;
  }

  /// 블록 크기에 따른 셰이프 생성
  static BlockShape getRandomShapeForSize(int size, Random random) {
    if (size == 1) {
      return BlockShape.single;
    } else if (size == 2) {
      return random.nextBool() ? BlockShape.horizontal2 : BlockShape.vertical2;
    } else if (size == 3) {
      // 더 간단한 형태의 블록이 더 자주 나오도록 확률 조정
      final roll = random.nextDouble();
      if (roll < 0.4) {
        return BlockShape.horizontal3; // 40% 확률
      } else if (roll < 0.8) {
        return BlockShape.vertical3; // 40% 확률
      } else {
        // 나머지 20%는 복잡한 형태
        final shapes = [
          BlockShape.lShape,
          BlockShape.reverseLShape,
          BlockShape.corner,
        ];
        return shapes[random.nextInt(shapes.length)];
      }
    } else if (size == 4) {
      // 더 간단한 형태의 블록이 더 자주 나오도록 확률 조정
      final roll = random.nextDouble();
      if (roll < 0.4) {
        return BlockShape.horizontal4; // 40% 확률
      } else if (roll < 0.8) {
        return BlockShape.vertical4; // 40% 확률
      } else {
        return BlockShape.squareShape; // 20% 확률
      }
    }

    // 기본값 (사이즈가 지원되지 않을 경우)
    return BlockShape.single;
  }

  @override
  String toString() {
    return 'Block(id: $id, shape: $shape, size: $size, characters: $characters, isPlaced: $isPlaced, rotation: $rotationState, isBomb: $isBomb)';
  }
}
