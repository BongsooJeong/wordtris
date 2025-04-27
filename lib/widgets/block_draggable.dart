import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/block.dart';
import '../providers/game_provider.dart';
import 'block_widget.dart';
import 'block_highlight_handler.dart';

/// 드래그 가능한 블록 위젯
class BlockDraggable extends StatelessWidget {
  final Block block;
  final double cellSize;
  final BlockHighlightHandler highlightHandler;
  final bool isCompactMode; // 모바일 뷰를 위한 컴팩트 모드

  const BlockDraggable({
    super.key,
    required this.block,
    required this.cellSize,
    required this.highlightHandler,
    this.isCompactMode = false, // 기본값은 일반 모드
  });

  /// 블록의 회전 처리
  void _handleTap(BuildContext context, Block block) {
    try {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      gameProvider.rotateBlockInTray(block);
    } catch (e) {
      print("블록 회전 중 오류 발생: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기에 따른 패딩 조정
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding =
        isCompactMode ? (screenWidth < 360 ? 2.0 : 4.0) : 8.0;

    // 드래그 피드백의 투명도 조정
    final feedbackOpacity = isCompactMode ? 0.8 : 0.7;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Draggable<Block>(
        data: block,
        onDragStarted: () {
          // 추천 단어 하이라이트 기능 제거
          // 모바일 기기에서 진동 피드백 추가 (나중에 HapticFeedback 추가)
        },
        onDragEnd: (details) {
          // 드래그 종료 시 처리
          // 하이라이트 처리 제거
        },
        onDraggableCanceled: (velocity, offset) {
          // 드래그 취소 시 처리
          // 하이라이트 처리 제거
        },
        // 드래그 중일 때 보여줄 위젯
        feedback: Material(
          color: Colors.transparent,
          elevation: isCompactMode ? 3.0 : 4.0,
          child: BlockWidget(
            block: block,
            opacity: feedbackOpacity,
            cellSize: cellSize,
          ),
        ),
        // 드래그 앵커 전략 - 블록의 중앙점이 마우스 포인터에 위치하도록 설정
        dragAnchorStrategy: (draggable, context, position) {
          // 블록 위젯의 중앙점을 계산
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final size = renderBox.size;
          return Offset(size.width / 2, size.height / 2);
        },
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: BlockWidget(
            block: block,
            opacity: 0.3,
            cellSize: cellSize,
          ),
        ),
        child: GestureDetector(
          onTap: () => _handleTap(context, block),
          child: BlockWidget(
            block: block,
            opacity: 1.0,
            cellSize: cellSize,
            isCompactMode: isCompactMode, // 컴팩트 모드 전달
          ),
        ),
      ),
    );
  }
}
