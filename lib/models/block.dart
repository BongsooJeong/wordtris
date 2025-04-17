import 'package:flutter/material.dart';
import '../utils/point.dart';
import 'dart:math';

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
  
  // 2차원 행렬로 블록 표현 (문자와 위치 매핑)
  late List<List<String?>> matrix;

  Block({
    required this.id,
    required this.shape,
    required this.characters,
    required this.color,
    this.rotationState = 0,
    this.isBomb = false,
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
    // 1셀 블록과 폭탄 블록은 회전하지 않음
    if (shape == BlockShape.single || shape == BlockShape.bomb) {
      // print('1셀/폭탄 블록은 회전하지 않음: $shape');
      return this;
    }
    
    // print('회전 시작 - 현재 블록 모양: $shape, ID: $id');
    
    // 행렬 자체를 회전시키는 방식으로 변경
    final rotatedMatrix = _rotateMatrixClockwise(matrix);
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
      if (newRotationState == 1) newShape = BlockShape.lShapeRotated1;
      else if (newRotationState == 2) newShape = BlockShape.lShapeRotated2;
      else if (newRotationState == 3) newShape = BlockShape.lShapeRotated3;
    } else if (shape == BlockShape.lShapeRotated1) {
      if (newRotationState == 2) newShape = BlockShape.lShapeRotated2;
      else if (newRotationState == 3) newShape = BlockShape.lShapeRotated3;
      else if (newRotationState == 0) newShape = BlockShape.lShape;
    } else if (shape == BlockShape.lShapeRotated2) {
      if (newRotationState == 3) newShape = BlockShape.lShapeRotated3;
      else if (newRotationState == 0) newShape = BlockShape.lShape;
      else if (newRotationState == 1) newShape = BlockShape.lShapeRotated1;
    } else if (shape == BlockShape.lShapeRotated3) {
      if (newRotationState == 0) newShape = BlockShape.lShape;
      else if (newRotationState == 1) newShape = BlockShape.lShapeRotated1;
      else if (newRotationState == 2) newShape = BlockShape.lShapeRotated2;
    }
    
    // 회전된 블록 생성 (같은 문자 배열 사용, 회전된 행렬로 교체)
    final rotatedBlock = copyWith(
      shape: newShape,
      rotationState: newRotationState,
      matrix: rotatedMatrix
    );
    
    // print('회전 완료 - 새 블록 모양: ${rotatedBlock.shape}, 회전 상태: ${rotatedBlock.rotationState}');
    
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
    
    // 1xm 행렬은 mx1 행렬로 변환 (가로->세로)
    if (n == 1) {
      List<List<String?>> rotated = List.generate(
        m, (i) => [mat[0][i]]
      );
      // print('1xm -> mx1 회전: $rotated');
      return rotated;
    }
    
    // mx1 행렬은 1xm 행렬로 변환 (세로->가로)
    if (m == 1) {
      List<String?> row = List.generate(n, (i) => mat[n-i-1][0]);
      List<List<String?>> rotated = [row];
      // print('mx1 -> 1xm 회전: $rotated');
      return rotated;
    }
    
    // 일반적인 nxm 행렬 회전
    // 회전 후 크기는 m x n (행과 열이 바뀜)
    List<List<String?>> rotated = List.generate(
      m, (_) => List<String?>.filled(n, null)
    );
    
    // 시계 방향 90도 회전 적용
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < m; j++) {
        // 원래 [i][j]에 있던 요소는 회전 후 [j][n-i-1]로 이동
        rotated[j][n - i - 1] = mat[i][j];
      }
    }
    
    // print('회전된 행렬: $rotated');
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
      final shapes = [
        BlockShape.horizontal3,
        BlockShape.vertical3,
        BlockShape.lShape,
        BlockShape.reverseLShape,
        BlockShape.corner,
      ];
      return shapes[random.nextInt(shapes.length)];
    } else if (size == 4) {
      final shapes = [
        BlockShape.squareShape,
        BlockShape.horizontal4,
        BlockShape.vertical4,
      ];
      return shapes[random.nextInt(shapes.length)];
    }

    // 기본값 (사이즈가 지원되지 않을 경우)
    return BlockShape.single;
  }

  @override
  String toString() {
    return 'Block(id: $id, shape: $shape, size: $size, characters: $characters, isPlaced: $isPlaced, rotation: $rotationState, isBomb: $isBomb)';
  }
}
