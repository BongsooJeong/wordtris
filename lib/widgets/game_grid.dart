import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/block.dart';
import '../models/grid.dart';
import '../providers/game_provider.dart';
import '../utils/point.dart';
import 'dart:math' as math;
import 'game_grid_animations.dart';
import 'game_grid_block_placement.dart';

/// GameGrid API 문서
///
/// 게임의 그리드 UI를 구성하고, 블록 배치와 애니메이션을 관리하는 StatefulWidget입니다.
///
/// ## 주요 API 목록
///
/// ### 위젯 구성
/// - `GameGrid({Key? key, double cellSize = 32.0, double gridPadding = 16.0})`: 게임 그리드 위젯 생성
///   - `cellSize`: 각 셀의 크기 (기본값: 32.0)
///   - `gridPadding`: 그리드 주변 여백 (기본값: 16.0)
///
/// ### 레이아웃 구조
/// ```
/// Container (패딩, 테두리)
/// └─ Column
///    └─ Row[]
///       └─ GridCell[] (각 셀)
///          ├─ Container (배경, 테두리)
///          └─ Text (문자)
/// ```
///
/// ### 상태 관리 (_GameGridState)
/// - `draggedBlock`: 현재 드래그 중인 블록
/// - `draggedPosition`: 드래그 중인 블록의 위치
/// - `_animations`: 애니메이션 관리자 인스턴스
/// - `_blockPlacement`: 블록 배치 관리자 인스턴스
///
/// ### 빌드 메서드
/// - `build(BuildContext)`: 메인 위젯 구조 생성
///   - Consumer<GameProvider>를 사용하여 게임 상태 관리
///   - DragTarget을 통한 드래그 앤 드롭 처리
///
/// - `_buildGameGrid(BuildContext, GameProvider)`: 게임 그리드 구조 생성
///   - Stack을 사용하여 기본 그리드와 애니메이션 효과 레이어 구성
///   - 그리드 셀, 폭발 효과, 페이드 애니메이션 포함
///
/// - `_buildGridBase(Grid, int, int, double, double, double)`: 기본 그리드 구조 생성
///   - Column과 Row를 사용하여 그리드 매트릭스 구성
///   - 테두리와 패딩이 있는 Container로 감싸짐
///
/// - `_buildGridCell(BuildContext, GameProvider, Grid, int, int, double, double, double)`: 개별 셀 위젯 생성
///   - Container를 사용하여 셀 스타일링
///   - 문자 표시 및 드래그 상태에 따른 시각적 피드백
///
/// ### 애니메이션 처리
/// - `_handleAnimations(GameProvider)`: 애니메이션 상태 관리
///   - 셀 제거 애니메이션 처리
///   - 애니메이션 상태 초기화 및 동기화
///
/// ### 레이아웃 스타일
/// - 그리드: 회색 테두리, 둥근 모서리 (8.0)
/// - 셀: 회색 배경, 둥근 모서리 (4.0)
/// - 문자: 흰색, 굵은 글씨, 셀 크기의 60%
/// - 셀 간격: 1.0 (cellMargin)
/// - 유효한 배치 위치: 초록색 테두리 (2.0)

/// 게임 그리드를 표시하는 위젯 API 문서
///
/// [GameGrid] 클래스
/// 게임의 그리드 UI를 구성하고, 블록 배치와 애니메이션을 관리하는 StatefulWidget
///
/// 게임 그리드를 표시하는 위젯
class GameGrid extends StatefulWidget {
  final double cellSize;
  final double gridPadding;

  const GameGrid({
    super.key,
    this.cellSize = 32.0,
    this.gridPadding = 16.0,
  });

  @override
  State<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends State<GameGrid> with TickerProviderStateMixin {
  Block? draggedBlock;
  Offset? draggedPosition;

  // 애니메이션과 블록 배치 관련 인스턴스 선언
  late final GameGridAnimations _animations;
  late final GameGridBlockPlacement _blockPlacement;

  @override
  void initState() {
    super.initState();
    // 인스턴스 초기화
    _animations = GameGridAnimations(this);
    _blockPlacement = GameGridBlockPlacement(this);
  }

  @override
  void dispose() {
    // 애니메이션 컨트롤러 해제
    _animations.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        // 애니메이션 처리
        _handleAnimations(gameProvider);

        // 게임 그리드 빌드
        return _buildGameGrid(context, gameProvider);
      },
    );
  }

  /// 애니메이션 상태 처리
  void _handleAnimations(GameProvider gameProvider) {
    if (gameProvider.grid.lastRemovedCells.isNotEmpty &&
        !_animations.isAnimatingRemoval) {
      // 애니메이션 실행이 아직 시작되지 않았을 때만 애니메이션 시작
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 애니메이션 시작 전에 제거된 셀 목록 복사
        List<RemovedCell> cellsToAnimate =
            List.from(gameProvider.grid.lastRemovedCells);

        // 애니메이션을 시작하기 전에 Provider의 lastRemovedCells 초기화
        gameProvider.resetAnimationState();

        // 복사해 둔 셀 목록으로 애니메이션 시작
        _animations.startCellFadeAnimation(cellsToAnimate);
      });
    } else if (gameProvider.grid.lastRemovedCells.isNotEmpty &&
        _animations.isAnimatingRemoval) {
      // 애니메이션 중이지만 lastRemovedCells가 남아있는 경우
      // 애니메이션이 진행 중인 상태에서 새로운 셀 제거가 일어난 경우, Provider의 상태만 초기화
      WidgetsBinding.instance.addPostFrameCallback((_) {
        gameProvider.resetAnimationState();
      });
    }
  }

  /// 게임 그리드 구축
  Widget _buildGameGrid(BuildContext context, GameProvider gameProvider) {
    final grid = gameProvider.grid;
    final rows = grid.rows;
    final columns = grid.columns;

    // 셀 사이즈 및 간격 정의
    final double actualCellSize = widget.cellSize;
    const double cellMargin = 1.0;
    const double cellSpacing = cellMargin * 2;
    final double totalCellSize = actualCellSize + cellSpacing;

    return DragTarget<Block>(
      onAccept: (data) {
        // 드래그 상태 초기화
        setState(() {
          draggedBlock = null;
          draggedPosition = null;
        });
      },
      onAcceptWithDetails: (details) {
        _blockPlacement.handleBlockPlacement(
            context,
            details,
            widget.gridPadding,
            totalCellSize,
            (point) => _animations.startExplosionAnimation(point));
      },
      onMove: (details) {
        _blockPlacement.handleBlockDrag(
            context, details, widget.gridPadding, totalCellSize);
      },
      onLeave: (data) {
        // 드래그가 그리드 영역을 벗어났을 때
        setState(() {
          draggedBlock = null;
          draggedPosition = null;
        });
      },
      builder: (context, candidateItems, rejectedItems) {
        return Stack(
          children: [
            // 기본 그리드
            _buildGridBase(
                grid, rows, columns, actualCellSize, cellMargin, totalCellSize),

            // 폭발 효과 애니메이션
            if (_animations.explosionCenter != null &&
                _animations.explosionAnimation != null)
              _animations.buildExplosionEffect(
                  totalCellSize, widget.gridPadding, actualCellSize),

            // 사라지는 셀 애니메이션
            if (_animations.fadeAnimation != null &&
                _animations.fadingCells.isNotEmpty)
              ..._animations.buildFadingCells(totalCellSize, actualCellSize,
                  cellMargin, widget.gridPadding),
          ],
        );
      },
    );
  }

  /// 그리드 기본 구조 구축
  Widget _buildGridBase(Grid grid, int rows, int columns, double actualCellSize,
      double cellMargin, double totalCellSize) {
    return Container(
      padding: EdgeInsets.all(widget.gridPadding),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int y = 0; y < rows; y++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int x = 0; x < columns; x++)
                  _buildGridCell(context, Provider.of<GameProvider>(context),
                      grid, x, y, actualCellSize, cellMargin, totalCellSize),
              ],
            ),
        ],
      ),
    );
  }

  /// 그리드 셀 위젯 구축
  Widget _buildGridCell(
    BuildContext context,
    GameProvider gameProvider,
    Grid grid,
    int x,
    int y,
    double cellSize,
    double cellMargin,
    double totalCellSize,
  ) {
    // 현재 셀의 상태 확인
    Cell cell = grid.cells[y][x];
    Color cellColor = Colors.grey.shade200;
    String cellText = '';

    // 셀에 문자가 있으면 표시
    if (!cell.isEmpty) {
      cellColor = cell.color ?? Colors.blue;
      cellText = cell.character ?? '';
    }

    // 드래그 중인 블록 처리 로직
    bool isValidPlacement = false;
    bool isPartOfDraggedBlock = false;

    if (draggedBlock != null && draggedPosition != null) {
      // 이 셀이 드래그 중인 블록의 일부인지 확인
      isPartOfDraggedBlock = _blockPlacement.isCellPartOfDraggedBlock(
          x, y, draggedBlock!, widget.gridPadding, totalCellSize);

      // 배치 가능 여부 확인
      isValidPlacement = _blockPlacement.isValidPlacementForCell(
          x, y, draggedBlock!, widget.gridPadding, totalCellSize);
    }

    // 드래그 중인 블록 셀의 색상 및 테두리 설정
    BoxDecoration decoration;

    if (isPartOfDraggedBlock) {
      // 이 셀이 드래그 중인 블록의 일부인 경우
      if (isValidPlacement) {
        // 배치 가능한 경우: 초록색 테두리와 투명한 초록색 배경
        decoration = BoxDecoration(
          color: draggedBlock!.color.withOpacity(0.4), // 블록 색상을 투명도 적용
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: Colors.green, width: 2.0),
        );
      } else {
        // 배치 불가능한 경우: 빨간색 테두리와 투명한 빨간색 배경
        decoration = BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: Colors.red, width: 2.0),
        );
      }
    } else {
      // 일반 셀
      decoration = BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(4.0),
      );
    }

    return Container(
      width: cellSize,
      height: cellSize,
      margin: EdgeInsets.all(cellMargin),
      decoration: decoration,
      child: Center(
        child: cellText.isNotEmpty
            ? Text(
                cellText,
                style: TextStyle(
                  fontSize: cellSize * 0.6,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : isPartOfDraggedBlock && draggedBlock != null
                ? Text(
                    // 드래그 중인 블록의 문자 표시
                    _blockPlacement.getCharacterForPosition(
                            draggedBlock!, x, y) ??
                        '',
                    style: TextStyle(
                      fontSize: cellSize * 0.6,
                      fontWeight: FontWeight.bold,
                      color: isValidPlacement
                          ? Colors.white.withOpacity(0.7)
                          : Colors.red.withOpacity(0.7),
                    ),
                  )
                : null,
      ),
    );
  }
}
