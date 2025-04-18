/// GameGridBlockPlacement API 문서
///
/// 게임 그리드의 블록 배치 로직을 관리하는 클래스입니다.
///
/// ## 주요 API 목록
///
/// ### 생성자
/// - `GameGridBlockPlacement(dynamic state)`: 블록 배치 관리자 인스턴스 생성
///   - `state`: State<GameGrid>를 구현한 클래스
///
/// ### 블록 드래그 관련 메서드
/// - `handleBlockDrag(BuildContext, DragTargetDetails<Block>, double, double)`: 블록 드래그 처리
///   - 드래그 중인 블록의 위치를 그리드 셀에 맞춰 조정
///   - 상태 업데이트 및 시각적 피드백 제공
///
/// - `handleBlockPlacement(BuildContext, DragTargetDetails<Block>, double, double, Function(Point))`: 블록 배치 처리
///   - 드래그가 완료된 위치에 블록 배치
///   - 폭탄 블록 처리 및 배치 실패 시 햅틱 피드백
///
/// ### 블록 위치 계산 메서드
/// - `calculateBlockPositions(Block, int, int)`: 블록의 실제 위치 계산
///   - 블록의 중심점을 기준으로 각 셀의 상대적 위치 계산
///   - 그리드 좌표계로 변환된 위치 목록 반환
///
/// ### 유효성 검사 메서드
/// - `canPlaceBlockAt(GameProvider, Block, int, int)`: 블록 배치 가능 여부 확인
///   - 그리드 범위 검사
///   - 셀 충돌 검사
///
/// - `isValidPlacementForCell(int, int, Block, double, double)`: 드래그 중 셀 단위 배치 가능 여부 확인
///   - 현재 드래그 중인 위치에서 특정 셀에 블록 배치 가능 여부 확인
///   - 시각적 피드백을 위한 유효성 검사
///
/// ### 블록 조작 메서드
/// - `placeBlock(GameProvider, Block, int, int)`: 블록 실제 배치
///   - 계산된 위치에 블록 배치 실행
///
/// - `getCharacterForPosition(Block, int, int)`: 특정 위치의 문자 반환
///   - 블록의 특정 위치에 표시될 문자 계산
///
/// ### 상태 관리
/// - `draggedBlock`: 현재 드래그 중인 블록
/// - `draggedPosition`: 현재 드래그 중인 위치
/// - `_setState`: 상태 업데이트 함수
/// - `_getContext`: 컨텍스트 접근 함수

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/block.dart';
import '../providers/game_provider.dart';
import '../utils/point.dart';

/// 게임 그리드의 블록 배치 로직을 관리하는 클래스
class GameGridBlockPlacement {
  /// 상태 관련
  final dynamic _gameGridState;
  final Function _setState;
  late final dynamic Function() _getContext;

  // 부모의 상태에 접근하기 위한 getter/setter
  Block? get draggedBlock => _gameGridState.draggedBlock;
  set draggedBlock(Block? value) => _gameGridState.draggedBlock = value;

  Offset? get draggedPosition => _gameGridState.draggedPosition;
  set draggedPosition(Offset? value) => _gameGridState.draggedPosition = value;

  /// 생성자
  GameGridBlockPlacement(dynamic state)
      : _gameGridState = state,
        _setState = state.setState {
    _getContext = () => state.context;
  }

  /// 블록 드래그 처리
  void handleBlockDrag(
    BuildContext context,
    DragTargetDetails<Block> details,
    double gridPadding,
    double totalCellSize,
  ) {
    // 드래그 중인 블록과 위치 정보 업데이트
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.offset);

    // 위치를 한 칸 오른쪽으로 이동시킴
    final Offset adjustedPosition = Offset(
      localPosition.dx + totalCellSize, // X 좌표를 한 칸 오른쪽으로 이동
      localPosition.dy,
    );

    // 조정된 위치 정보 저장
    _setState(() {
      draggedBlock = details.data;
      draggedPosition = adjustedPosition;
    });
  }

  /// 블록 배치 처리
  void handleBlockPlacement(
    BuildContext context,
    DragTargetDetails<Block> details,
    double gridPadding,
    double totalCellSize,
    Function(Point) onBombPlaced,
  ) {
    // 드래그 완료 시, 가장 가까운 셀 위치 계산
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.offset);

    // 위치를 한 칸 오른쪽으로 이동시킴
    final Offset adjustedPosition = Offset(
      localPosition.dx + totalCellSize, // X 좌표를 한 칸 오른쪽으로 이동
      localPosition.dy,
    );

    // 셀 크기를 기준으로 행과 열 인덱스 계산
    final double adjustedX = adjustedPosition.dx - gridPadding;
    final double adjustedY = adjustedPosition.dy - gridPadding;
    final int col = (adjustedX / totalCellSize).floor();
    final int row = (adjustedY / totalCellSize).floor();

    // 게임 프로바이더 가져오기
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final grid = gameProvider.grid;
    final rows = grid.rows;
    final columns = grid.columns;

    // 유효한 위치인지 확인하고 블록 배치
    if (row >= 0 && row < rows && col >= 0 && col < columns) {
      // 블록의 위치 계산
      List<Point> positions = calculateBlockPositions(details.data, row, col);

      // 블록 배치 시도
      final bool canPlace =
          canPlaceBlockAt(gameProvider, details.data, row, col);

      if (canPlace) {
        // 폭탄 블록인 경우 애니메이션 시작
        if (details.data.isBomb) {
          onBombPlaced(Point(col, row));
        }

        // 블록 배치
        placeBlock(gameProvider, details.data, row, col);
      } else {
        // 배치할 수 없는 경우 시각적 피드백 (진동 등)
        HapticFeedback.mediumImpact();
      }
    } else {
      // 그리드 밖에 놓은 경우 피드백
      HapticFeedback.mediumImpact();
    }

    // 드래그 상태 초기화
    _setState(() {
      draggedBlock = null;
      draggedPosition = null;
    });
  }

  /// 블록 배치 가능 여부 확인
  bool canPlaceBlockAt(
      GameProvider gameProvider, Block block, int row, int col) {
    List<Point> positions = calculateBlockPositions(block, row, col);

    // 모든 위치가 그리드 범위 내에 있는지 확인
    for (var point in positions) {
      if (point.x < 0 ||
          point.y < 0 ||
          point.x >= gameProvider.grid.columns ||
          point.y >= gameProvider.grid.rows) {
        return false;
      }
    }

    // 모든 위치가 비어있는지 확인
    for (var point in positions) {
      if (!gameProvider.grid.cells[point.y][point.x].isEmpty) {
        return false;
      }
    }

    return true;
  }

  /// 블록 배치 실행
  void placeBlock(GameProvider gameProvider, Block block, int row, int col) {
    List<Point> positions = calculateBlockPositions(block, row, col);
    gameProvider.placeBlock(block, positions);
  }

  /// 블록의 위치 계산
  List<Point> calculateBlockPositions(Block block, int baseRow, int baseCol) {
    List<Point> positions = [];

    // 블록 모양에 따라 상대적인 위치 계산
    List<Point> relativePoints = block.getRelativePoints();

    // 블록의 경계 계산
    int minX = 999, minY = 999, maxX = -1, maxY = -1;

    for (var point in relativePoints) {
      if (point.x < minX) minX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.x > maxX) maxX = point.x;
      if (point.y > maxY) maxY = point.y;
    }

    // 블록의 실제 폭과 높이
    int width = maxX - minX + 1;
    int height = maxY - minY + 1;

    // 중앙 배치를 위한 오프셋 계산
    int offsetX = width ~/ 2;
    int offsetY = height ~/ 2;

    // 모든 블록 셀의 위치 계산 (블록의 중앙이 기준)
    for (var point in relativePoints) {
      int row = baseRow + (point.y - minY) - offsetY;
      int col = baseCol + (point.x - minX) - offsetX;
      positions.add(Point(col, row));
    }

    return positions;
  }

  /// 셀 위치에 블록 배치 가능 여부 확인 (드래그 중)
  bool isValidPlacementForCell(
      int x, int y, Block block, double gridPadding, double totalCellSize) {
    if (draggedBlock == null || draggedPosition == null) return false;

    // 드래그 위치에서 블록의 기준 셀 위치 계산
    final double adjustedX = draggedPosition!.dx - gridPadding;
    final double adjustedY = draggedPosition!.dy - gridPadding;

    // 그리드 내부로 위치 계산 (열과 행)
    final gameProvider =
        Provider.of<GameProvider>(_getContext(), listen: false);
    final int gridRows = gameProvider.grid.rows;
    final int gridColumns = gameProvider.grid.columns;

    // 셀 위치로 변환
    final int baseCol = (adjustedX / totalCellSize).floor();
    final int baseRow = (adjustedY / totalCellSize).floor();

    // 그리드 범위를 벗어나면 false 반환
    if (baseCol < 0 ||
        baseCol >= gridColumns ||
        baseRow < 0 ||
        baseRow >= gridRows) {
      return false;
    }

    // 현재 셀이 블록에 포함되는지 확인
    List<Point> positions = calculateBlockPositions(block, baseRow, baseCol);
    bool isPartOfDraggedBlock = positions.any((p) => p.x == x && p.y == y);

    // 포함된다면 배치 가능 여부 확인
    if (isPartOfDraggedBlock) {
      // 모든 위치가 그리드 범위 내에 있고 비어있는지 확인
      bool isValid = true;
      for (var point in positions) {
        if (point.x < 0 ||
            point.y < 0 ||
            point.x >= gameProvider.grid.columns ||
            point.y >= gameProvider.grid.rows) {
          isValid = false;
          break;
        }

        if (!gameProvider.grid.cells[point.y][point.x].isEmpty) {
          isValid = false;
          break;
        }
      }

      return isValid;
    }

    return false;
  }

  /// 셀이 드래그 중인 블록의 일부인지 확인
  bool isCellPartOfDraggedBlock(
      int x, int y, Block block, double gridPadding, double totalCellSize) {
    if (draggedBlock == null || draggedPosition == null) return false;

    // 드래그 위치에서 블록의 기준 셀 위치 계산
    final double adjustedX = draggedPosition!.dx - gridPadding;
    final double adjustedY = draggedPosition!.dy - gridPadding;

    // 셀 위치로 변환
    final int baseCol = (adjustedX / totalCellSize).floor();
    final int baseRow = (adjustedY / totalCellSize).floor();

    // 현재 셀이 블록에 포함되는지 확인
    List<Point> positions = calculateBlockPositions(block, baseRow, baseCol);
    return positions.any((p) => p.x == x && p.y == y);
  }

  /// 특정 위치에 표시할 문자 가져오기
  String? getCharacterForPosition(Block block, int x, int y) {
    // 블록의 상대적 위치에서 문자 직접 가져오기
    return block.getCharacterAt(x, y);
  }
}
