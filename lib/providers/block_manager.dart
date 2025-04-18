import 'package:flutter/material.dart';
import 'dart:math';
import '../models/block.dart';
import 'word_processor.dart';

class BlockManager {
  final WordProcessor _wordProcessor;
  final Random _random = Random();

  // 블록 최대 개수
  static const int maxAvailableBlocks = 5;

  // 색상 팔레트
  static const List<Color> blockColors = [
    Color(0xFFFFC107), // 노랑
    Color(0xFF4CAF50), // 초록
    Color(0xFF2196F3), // 파랑
    Color(0xFFE91E63), // 분홍
    Color(0xFF9C27B0), // 보라
    Color(0xFFFF5722), // 주황
  ];

  BlockManager(this._wordProcessor);

  /// 새로운 블록 생성
  Block generateNewBlock() {
    final character = _wordProcessor.getFrequencyBasedChar();
    final color = blockColors[_random.nextInt(blockColors.length)];
    final blockId =
        DateTime.now().millisecondsSinceEpoch + _random.nextInt(1000);

    return Block(
      id: blockId,
      shape: BlockShape.single,
      characters: [character],
      color: color,
    );
  }

  /// 자음 기반 블록 생성
  Block generateConsonantBlock() {
    final character = _wordProcessor.getRandomConsonantChar();
    final color = blockColors[_random.nextInt(blockColors.length)];
    final blockId =
        DateTime.now().millisecondsSinceEpoch + _random.nextInt(1000);

    return Block(
      id: blockId,
      shape: BlockShape.single,
      characters: [character],
      color: color,
    );
  }

  /// 모음 기반 블록 생성
  Block generateVowelBlock() {
    final character = _wordProcessor.getRandomVowelChar();
    final color = blockColors[_random.nextInt(blockColors.length)];
    final blockId =
        DateTime.now().millisecondsSinceEpoch + _random.nextInt(1000);

    return Block(
      id: blockId,
      shape: BlockShape.single,
      characters: [character],
      color: color,
    );
  }

  /// 여러 개의 새로운 블록 생성
  List<Block> generateBlocks(int count) {
    return List.generate(
      count,
      (index) => createRandomBlock(),
    );
  }

  /// 랜덤 블록 생성 (크기와 모양 포함)
  Block createRandomBlock() {
    final random = Random();

    // 블록 크기 확률 조정: 각 크기별 25% 확률
    int blockSize;
    final sizeRoll = random.nextDouble();

    if (sizeRoll < 0.25) {
      blockSize = 1; // 25%
    } else if (sizeRoll < 0.50) {
      blockSize = 2; // 25%
    } else if (sizeRoll < 0.75) {
      blockSize = 3; // 25%
    } else {
      blockSize = 4; // 25%
    }

    // 블록 모양 선택
    BlockShape blockShape = Block.getRandomShapeForSize(blockSize, random);

    // 블록 색상 선택
    Color blockColor = blockColors[random.nextInt(blockColors.length)];

    // 필요한 문자 수 결정
    int requiredChars;
    switch (blockShape) {
      case BlockShape.single:
        requiredChars = 1;
        break;
      case BlockShape.horizontal2:
      case BlockShape.vertical2:
        requiredChars = 2;
        break;
      case BlockShape.horizontal3:
      case BlockShape.vertical3:
      case BlockShape.lShape:
      case BlockShape.reverseLShape:
      case BlockShape.corner:
        requiredChars = 3;
        break;
      case BlockShape.squareShape:
      case BlockShape.horizontal4:
      case BlockShape.vertical4:
        requiredChars = 4;
        break;
      case BlockShape.bomb:
        requiredChars = 1;
        break;
      default:
        requiredChars = 3;
        break;
    }

    // 문자 생성
    List<String> characters = List.generate(
      requiredChars,
      (_) => _wordProcessor.getFrequencyBasedChar(),
    );

    // 블록 ID 생성
    int blockId = DateTime.now().millisecondsSinceEpoch + random.nextInt(1000);

    return Block(
      id: blockId,
      shape: blockShape,
      characters: characters,
      color: blockColor,
    );
  }

  /// 블록이 최대 개수를 초과하는지 확인
  bool isBlockCountExceeded(List<Block> blocks) {
    return blocks.length >= maxAvailableBlocks;
  }

  /// 폭탄 블록 생성
  Block generateBombBlock() {
    final blockId =
        DateTime.now().millisecondsSinceEpoch + _random.nextInt(1000);
    return Block(
      id: blockId,
      shape: BlockShape.bomb,
      characters: ['💣'],
      color: Colors.red,
      isBomb: true,
    );
  }
}
