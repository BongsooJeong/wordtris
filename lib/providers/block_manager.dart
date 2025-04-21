import 'package:flutter/material.dart';
import 'dart:math';
import '../models/block.dart';
import 'word_processor.dart';

/// WordTris 게임의 블록 관리를 담당하는 클래스 API 문서
///
/// [BlockManager] 클래스
/// 블록 생성, 관리 및 변형을 담당하는 클래스
///
/// 주요 기능:
/// - 다양한 모양과 크기의 블록 생성
/// - 빈도 기반 한글 문자를 포함한 블록 생성
/// - 특수 블록(폭탄, 와일드카드 등) 생성
/// - 블록 개수 관리
///
/// 블록 생성 메서드:
/// - generateNewBlock(): Future<Block>
///   빈도 기반으로 새로운 단일 블록 생성
///
/// - generateConsonantBlock(): Future<Block>
///   자음 기반의 단일 블록 생성
///
/// - generateVowelBlock(): Future<Block>
///   모음 기반의 단일 블록 생성
///
/// - generateBlocks(int count): Future<List<Block>>
///   지정된 수만큼의 랜덤 블록 생성
///
/// - createRandomBlock(): Future<Block>
///   다양한 모양과 크기의 랜덤 블록 생성
///
/// - generateBombBlock(): Future<Block>
///   폭탄 블록 생성
///
/// - generateWildcardBlock(): Future<Block>
///   와일드카드 블록 생성 (모든 글자로 사용 가능)
///
/// 유틸리티 메서드:
/// - isBlockCountExceeded(List<Block> blocks): bool
///   블록 수가 최대 제한을 초과하는지 확인

class BlockManager {
  final WordProcessor _wordProcessor;
  final Random _random = Random();

  // 블록 최대 개수
  static const int maxAvailableBlocks = 4;

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
  Future<Block> generateNewBlock() async {
    final character = await _wordProcessor.getFrequencyBasedChar();
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
  Future<Block> generateConsonantBlock() async {
    final character = await _wordProcessor.getRandomConsonantChar();
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
  Future<Block> generateVowelBlock() async {
    final character = await _wordProcessor.getRandomVowelChar();
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
  Future<List<Block>> generateBlocks(int count) async {
    List<Block> blocks = [];
    for (int i = 0; i < count; i++) {
      // 3번째 블록은 와일드카드 블록으로 생성
      if (i == 2) {
        blocks.add(await generateWildcardBlock());
      } else {
        blocks.add(await createRandomBlock());
      }
    }
    return blocks;
  }

  /// 랜덤 블록 생성 (크기와 모양 포함)
  Future<Block> createRandomBlock() async {
    final random = Random();

    // 블록 크기 확률 조정 - 각각 25%로 균등하게 조정
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
    List<String> characters = [];
    for (int i = 0; i < requiredChars; i++) {
      characters.add(await _wordProcessor.getFrequencyBasedChar());
    }

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
  Future<Block> generateBombBlock() async {
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

  /// 와일드카드 블록 생성
  Future<Block> generateWildcardBlock() async {
    final blockId =
        DateTime.now().millisecondsSinceEpoch + _random.nextInt(1000);
    return Block(
      id: blockId,
      shape: BlockShape.single,
      characters: [Block.wildcardChar],
      color: Colors.purple,
      isWildcard: true,
    );
  }
}
