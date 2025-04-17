import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/block.dart';
import '../models/grid.dart';
import '../providers/game_provider.dart';
import '../utils/point.dart';
import 'dart:math' as math;

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

  // 폭발 애니메이션 관련 변수
  AnimationController? _explosionController;
  Animation<double>? _explosionAnimation;
  Point? _explosionCenter;
  
  // 블록 사라짐 애니메이션 관련 변수
  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;
  List<RemovedCell> _fadingCells = [];
  bool _animatingRemoval = false;

  @override
  void dispose() {
    // 애니메이션 컨트롤러 해제
    _stopAllAnimations();
    super.dispose();
  }

  // 모든 애니메이션 멈추기
  void _stopAllAnimations() {
    // 폭발 애니메이션 멈추기
    if (_explosionController != null) {
      _explosionController!.stop();
      _explosionController!.dispose();
      _explosionController = null;
    }
    
    // 페이드 애니메이션 멈추기
    if (_fadeController != null) {
      _fadeController!.stop();
      _fadeController!.dispose();
      _fadeController = null;
    }
    
    // 애니메이션 상태 초기화
    if (mounted) {
      setState(() {
        _explosionCenter = null;
        _fadingCells = [];
        _animatingRemoval = false;
      });
    }
  }

  // 폭발 애니메이션 시작
  void _startExplosionAnimation(Point center) {
    // 이전 애니메이션 컨트롤러 해제
    _explosionController?.dispose();

    // 애니메이션 컨트롤러 초기화
    _explosionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // 애니메이션 설정
    _explosionAnimation = CurvedAnimation(
      parent: _explosionController!,
      curve: Curves.easeOut,
    );

    // 폭발 위치 설정
    setState(() {
      _explosionCenter = center;
    });

    // 애니메이션 시작
    _explosionController!.forward().then((_) {
      // 애니메이션 종료 후 상태 초기화
      if (mounted) {
        setState(() {
          _explosionCenter = null;
        });
      }
    });
  }
  
  // 셀 사라짐 애니메이션 시작
  void _startCellFadeAnimation(List<RemovedCell> cells) {
    if (cells.isEmpty) return;
    
    // 이전 애니메이션 컨트롤러 해제
    _fadeController?.dispose();
    
    // 애니메이션 컨트롤러 초기화
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // 애니메이션 설정
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController!,
      curve: Curves.easeInOut,
    );
    
    // 애니메이션 상태 설정
    setState(() {
      _fadingCells = cells;
      _animatingRemoval = true;
    });
    
    // 애니메이션 시작
    _fadeController!.forward().then((_) {
      // 애니메이션 종료 후 상태 초기화
      if (mounted) {
        setState(() {
          _fadingCells = [];
          _animatingRemoval = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        // 새로운 제거된 셀이 있고 애니메이션이 실행 중이 아닐 때만 애니메이션 시작
        if (gameProvider.grid.lastRemovedCells.isNotEmpty && !_animatingRemoval) {
          // 애니메이션 실행이 아직 시작되지 않았을 때만 애니메이션 시작
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // 애니메이션 시작 전에 제거된 셀 목록 복사
            List<RemovedCell> cellsToAnimate = List.from(gameProvider.grid.lastRemovedCells);
            
            // 애니메이션을 시작하기 전에 Provider의 lastRemovedCells 초기화
            gameProvider.resetAnimationState();
            
            // 복사해 둔 셀 목록으로 애니메이션 시작
            _startCellFadeAnimation(cellsToAnimate);
          });
        } else if (gameProvider.grid.lastRemovedCells.isNotEmpty && _animatingRemoval) {
          // 애니메이션 중이지만 lastRemovedCells가 남아있는 경우
          // 애니메이션이 진행 중인 상태에서 새로운 셀 제거가 일어난 경우, Provider의 상태만 초기화
          WidgetsBinding.instance.addPostFrameCallback((_) {
            gameProvider.resetAnimationState();
          });
        }
        
        return buildGameGrid(context, gameProvider);
      },
    );
  }

  /// 게임 그리드 구축
  Widget buildGameGrid(BuildContext context, GameProvider gameProvider) {
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
        // 드래그 완료 시, 가장 가까운 셀 위치 계산
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.offset);

        // 셀 크기를 기준으로 행과 열 인덱스 계산
        // 그리드 패딩 고려하여 좌표 조정
        final double adjustedX = localPosition.dx - widget.gridPadding;
        final double adjustedY = localPosition.dy - widget.gridPadding;
        final col = (adjustedX / totalCellSize).floor();
        final row = (adjustedY / totalCellSize).floor();

        // 유효한 위치인지 확인하고 블록 배치
        if (row >= 0 && row < rows && col >= 0 && col < columns) {
          // 블록의 위치 계산 (현재 위치 기준으로 블록의 셀 배치)
          List<Point> positions =
              _calculateBlockPositions(details.data, row, col);

          // 폭탄 블록인 경우 애니메이션 시작
          if (details.data.isBomb &&
              canPlaceBlockAt(gameProvider, details.data, row, col)) {
            _startExplosionAnimation(Point(col, row));
          }

          // 블록 배치 시도
          placeBlock(gameProvider, details.data, row, col);
        }

        // 드래그 상태 초기화
        setState(() {
          draggedBlock = null;
          draggedPosition = null;
        });
      },
      onMove: (details) {
        // 드래그 중인 블록과 위치 정보 업데이트
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.offset);

        setState(() {
          draggedBlock = details.data;
          draggedPosition = localPosition;
        });
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
            Container(
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
                          buildGridCell(context, gameProvider, grid, x, y,
                              actualCellSize, cellMargin, totalCellSize),
                      ],
                    ),
                ],
              ),
            ),

            // 폭발 효과 애니메이션
            if (_explosionCenter != null && _explosionAnimation != null)
              Positioned(
                left: widget.gridPadding +
                    _explosionCenter!.x * totalCellSize +
                    cellMargin,
                top: widget.gridPadding +
                    _explosionCenter!.y * totalCellSize +
                    cellMargin,
                child: AnimatedBuilder(
                  animation: _explosionAnimation!,
                  builder: (context, child) {
                    final size =
                        actualCellSize * 3 * _explosionAnimation!.value;
                    return Opacity(
                      opacity: (1 - _explosionAnimation!.value) * 0.8,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.3),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.8),
                              blurRadius: size * 0.5,
                              spreadRadius: size * 0.2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: size * 0.6,
                            height: size * 0.6,
                            decoration: BoxDecoration(
                              color: Colors.yellow.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            // 사라지는 셀 애니메이션
            if (_fadeAnimation != null && _fadingCells.isNotEmpty)
              ..._buildFadingCells(totalCellSize, actualCellSize, cellMargin),
          ],
        );
      },
    );
  }

  /// 그리드 셀 위젯 구축
  Widget buildGridCell(
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
      cellColor = cell.color ?? Colors.blue; // null이면 기본 색상 제공
      cellText = cell.character ?? '';
    }

    // 드래그 중인 블록과 위치 관련 로직
    bool showDraggedBlock = false;
    bool isValidPlacement = false;
    Widget? characterWidget;

    if (draggedBlock != null && draggedPosition != null) {
      // 셀 위치에 따른 격자 좌표 계산
      final double gridX = widget.gridPadding + x * totalCellSize;
      final double gridY = widget.gridPadding + y * totalCellSize;
      final double gridEndX = gridX + cellSize;
      final double gridEndY = gridY + cellSize;

      // 현재 마우스 위치를 기준으로 블록이 그리드에 배치될 위치 계산
      final double adjustedX = draggedPosition!.dx - widget.gridPadding;
      final double adjustedY = draggedPosition!.dy - widget.gridPadding;
      final int baseCol = (adjustedX / totalCellSize).floor();
      final int baseRow = (adjustedY / totalCellSize).floor();

      // 드래그 중인 블록의 상대 위치 계산
      List<Point> relativePoints = draggedBlock!.getRelativePoints();
      Point originPoint = relativePoints[0]; // 기준 포인트

      // 블록이 배치될 모든 셀 위치 계산
      List<Point> placementPoints =
          _calculateBlockPositions(draggedBlock!, baseRow, baseCol);
      bool canPlace =
          canPlaceBlockAt(gameProvider, draggedBlock!, baseRow, baseCol);

      // 현재 셀이 블록 배치 영역에 속하는지 확인
      for (int i = 0; i < placementPoints.length; i++) {
        if (placementPoints[i].x == x && placementPoints[i].y == y) {
          showDraggedBlock = true;
          isValidPlacement = canPlace;
          
          // 블록의 상대적 위치 목록에서 대응하는 인덱스 찾기
          if (i < relativePoints.length) {
            Point blockPoint = relativePoints[i];
            // 해당 위치의 문자 가져오기
            String? character = draggedBlock!.getCharacterAt(blockPoint.x, blockPoint.y);
            if (character != null) {
              characterWidget = Text(
                character,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }
            break;
          }
        }
      }
    }

    // 마우스 위치에 있는 셀 강조
    if (showDraggedBlock) {
      // 블록을 놓을 수 있는 위치인지에 따라 색상 변경
      return Container(
        width: cellSize,
        height: cellSize,
        margin: EdgeInsets.all(cellMargin),
        decoration: BoxDecoration(
          color: isValidPlacement
              ? draggedBlock!.color.withOpacity(0.5) // 더 투명하게 설정
              : Colors.red.withOpacity(0.4), // 배치 불가능한 경우 빨간색 강조
          borderRadius: BorderRadius.circular(4.0), // 모서리 둥글게
          border: Border.all(
            color: isValidPlacement ? draggedBlock!.color : Colors.red,
            width: 1.5, // 테두리 두께 감소
          ),
          boxShadow: isValidPlacement
              ? [
                  BoxShadow(
                    color: draggedBlock!.color.withOpacity(0.2), // 그림자 투명도 감소
                    blurRadius: 2, // 그림자 크기 감소
                    spreadRadius: 0, // 퍼짐 없음
                    offset: const Offset(0, 1), // 그림자 위치 조정
                  ),
                ]
              : null, // 배치 불가능한 경우 그림자 없음
        ),
        child: Center(
          child: characterWidget != null
              ? DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  child: characterWidget,
                )
              : null,
        ),
      );
    }

    return Container(
      width: cellSize,
      height: cellSize,
      margin: EdgeInsets.all(cellMargin),
      decoration: BoxDecoration(
        color: cellColor,
        border: Border.all(color: Colors.black.withOpacity(0.2)),
      ),
      alignment: Alignment.center,
      child: !cell.isEmpty
          ? Text(
              cellText,
              style: TextStyle(
                fontSize: cellSize * 0.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  /// 특정 위치에 표시할 문자 가져오기
  Widget? _getCharacterForPosition(Block block, int x, int y) {
    // 블록의 상대적 위치에서 문자 직접 가져오기
    String? character = block.getCharacterAt(x, y);
    
    if (character != null) {
      return Text(
        character,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }

    return null;
  }

  /// 현재 셀이 미리보기 블록의 일부인지 확인
  bool isPartOfBlockPreview(
      Block block, int row, int col, GameProvider gameProvider) {
    List<Point> points =
        calculatePlacementPoints(block, row, col, gameProvider);
    for (Point point in points) {
      if (point.y == row && point.x == col) {
        return true;
      }
    }
    return false;
  }

  /// 블록 배치 위치 계산 (상대적 위치 기반)
  List<Point> calculatePlacementPoints(
      Block block, int row, int col, GameProvider gameProvider) {
    // _calculateBlockPositions와 동일한 로직 사용
    return _calculateBlockPositions(block, row, col);
  }

  /// 블록을 그리드에 배치
  void placeBlock(GameProvider gameProvider, Block block, int row, int col) {
    // 블록 위치 계산
    List<Point> positions = _calculateBlockPositions(block, row, col);

    // 블록 배치
    gameProvider.placeBlock(block, positions);
  }

  /// 블록의 위치 계산
  List<Point> _calculateBlockPositions(Block block, int baseRow, int baseCol) {
    List<Point> positions = [];

    // 블록 모양에 따라 상대적인 위치 계산
    for (var point in block.getRelativePoints()) {
      int row = baseRow + point.y;
      int col = baseCol + point.x;
      positions.add(Point(col, row));
    }

    return positions;
  }

  /// 블록이 특정 위치에 배치 가능한지 확인
  bool canPlaceBlockAt(
      GameProvider gameProvider, Block block, int row, int col) {
    List<Point> positions = _calculateBlockPositions(block, row, col);

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

  // 사라지는 셀 애니메이션 위젯 생성
  List<Widget> _buildFadingCells(double totalCellSize, double actualCellSize, double cellMargin) {
    final List<Widget> widgets = [];
    
    // 각 사라지는 셀마다 애니메이션 추가
    for (final cell in _fadingCells) {
      // 메인 셀 애니메이션
      widgets.add(
        Positioned(
          left: widget.gridPadding + cell.position.x * totalCellSize + cellMargin,
          top: widget.gridPadding + cell.position.y * totalCellSize + cellMargin,
          child: AnimatedBuilder(
            animation: _fadeAnimation!,
            builder: (context, child) {
              // 축소되면서 회전하고 페이드아웃되는 효과
              double scale = 1.0 - _fadeAnimation!.value * 0.5;
              double angle = _fadeAnimation!.value * math.pi * 0.5; // 최대 90도 회전
              
              // 색상 변화 효과 (원래 색상 -> 밝은 색상)
              Color startColor = cell.color;
              Color endColor = Color.lerp(startColor, Colors.white, 0.7)!;
              Color currentColor = Color.lerp(startColor, endColor, _fadeAnimation!.value)!;
              
              return Transform.scale(
                scale: scale,
                child: Transform.rotate(
                  angle: angle,
                  child: Opacity(
                    opacity: 1.0 - _fadeAnimation!.value,
                    child: Container(
                      width: actualCellSize,
                      height: actualCellSize,
                      decoration: BoxDecoration(
                        color: currentColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(6.0),
                        boxShadow: [
                          BoxShadow(
                            color: currentColor.withOpacity(0.3),
                            blurRadius: 3.0 + _fadeAnimation!.value * 5.0,
                            spreadRadius: 1.0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          cell.character,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18 + _fadeAnimation!.value * 5, // 약간 커지는 효과
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        )
      );
      
      // 파티클 효과 (작은 점들이 튀어나가는 효과)
      final int particleCount = 8; // 파티클 개수
      final random = math.Random(cell.position.x * 1000 + cell.position.y);
      
      for (int i = 0; i < particleCount; i++) {
        final double angle = 2 * math.pi * i / particleCount;
        // 수정된 거리 계산 - 애니메이션 값에 실제 거리 배율을 적용
        final double animationValue = _fadeAnimation?.value ?? 0;
        final double distance = animationValue * actualCellSize * 1.5;
        
        // 파티클 위치 계산
        final double particleX = math.cos(angle) * distance;
        final double particleY = math.sin(angle) * distance;
        
        widgets.add(
          Positioned(
            left: widget.gridPadding + cell.position.x * totalCellSize + cellMargin + actualCellSize / 2 + 
                  particleX,
            top: widget.gridPadding + cell.position.y * totalCellSize + cellMargin + actualCellSize / 2 + 
                  particleY,
            child: AnimatedBuilder(
              animation: _fadeAnimation!,
              builder: (context, child) {
                // 랜덤한 초기 지연 적용
                final double delay = random.nextDouble() * 0.3;
                double progress = math.max(0.0, (_fadeAnimation!.value - delay) / (1.0 - delay));
                if (progress <= 0) return const SizedBox();
                
                final double size = 4.0 * (1.0 - progress);
                final double opacity = (1.0 - progress);
                
                return Opacity(
                  opacity: opacity,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: cell.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cell.color.withOpacity(0.3),
                          blurRadius: 2,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        );
      }
      
      // 반짝이는 효과 (셀 중앙에서 퍼져나가는 원)
      widgets.add(
        Positioned(
          left: widget.gridPadding + cell.position.x * totalCellSize + cellMargin,
          top: widget.gridPadding + cell.position.y * totalCellSize + cellMargin,
          child: AnimatedBuilder(
            animation: _fadeAnimation!,
            builder: (context, child) {
              final double progress = _fadeAnimation!.value;
              final double size = actualCellSize * (1.0 + progress * 1.5);
              final double opacity = math.max(0, 0.5 - progress * 0.5);
              
              return Opacity(
                opacity: opacity,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 2.0 * (1.0 - progress),
                    ),
                  ),
                ),
              );
            },
          ),
        )
      );
    }
    
    return widgets;
  }
}
