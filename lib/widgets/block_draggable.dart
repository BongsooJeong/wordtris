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

  const BlockDraggable({
    super.key,
    required this.block,
    required this.cellSize,
    required this.highlightHandler,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Draggable<Block>(
        data: block,
        onDragStarted: () {
          // 드래그 시작 시 처리
          highlightHandler.highlightBlockCharacters(block);
        },
        onDragEnd: (details) {
          // 드래그 종료 시 처리
          highlightHandler.highlightBlockCharacters(block, clear: true);
        },
        onDraggableCanceled: (velocity, offset) {
          // 드래그 취소 시 처리
          highlightHandler.highlightBlockCharacters(block, clear: true);
        },
        // 드래그 중일 때 보여줄 위젯
        feedback: Material(
          color: Colors.transparent,
          elevation: 4.0,
          child: BlockWidget(
            block: block,
            opacity: 0.7,
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
        child: MouseRegion(
          onEnter: (_) {
            // 마우스가 블록에 들어왔을 때
            highlightHandler.highlightBlockCharacters(block);
          },
          onExit: (_) {
            // 마우스가 블록에서 나갔을 때
            highlightHandler.highlightBlockCharacters(block, clear: true);
          },
          child: GestureDetector(
            onTap: () => _handleTap(context, block),
            child: BlockWidget(
              block: block,
              opacity: 1.0,
              cellSize: cellSize,
            ),
          ),
        ),
      ),
    );
  }
}
