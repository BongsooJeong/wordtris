import 'dart:math';
import 'package:flutter/material.dart';
import 'block.dart';
import 'grid.dart';
import '../utils/point.dart';

/// WordTris 게임 상태 관리 API 문서
///
/// [GameStatus] 열거형
/// - ready: 게임 준비 상태
/// - playing: 게임 진행 중
/// - paused: 게임 일시 정지
/// - gameOver: 게임 종료
///
/// [GameState] 클래스 API
/// - constructor: GameState({grid, activeBlocks, score, level, status, completedWords})
///   게임 상태 객체 생성
///
/// 주요 메서드:
/// - initialize(): GameState
///   새 게임을 시작하기 위한 초기 상태 생성
///
/// - generateNewBlocks(): GameState
///   새로운 블록을 생성하여 활성 블록 리스트에 추가 (최대 5개)
///
/// - placeBlock(Block block, List<Point> points): GameState
///   블록을 게임 그리드의 지정된 위치에 배치
///
/// - processWords(Set<String> validWords): GameState
///   완성된 단어를 처리하고 점수 계산
///
/// - endGame(): GameState
///   게임을 종료 상태로 변경
///
/// 속성:
/// - grid: 게임 보드 그리드
/// - activeBlocks: 현재 사용 가능한 블록 목록
/// - score: 현재 게임 점수
/// - level: 현재 게임 레벨 (1-10)
/// - status: 현재 게임 상태
/// - completedWords: 완성한 단어 목록
///
/// 내부 메서드:
/// - _generateInitialBlocks(): List<Block>
///   초기 블록 세트 생성
/// - _getShapeForSize(int size): BlockShape
///   블록 크기에 맞는 모양 선택

/// 게임 상태 열거형
enum GameStatus {
  ready, // 게임 준비
  playing, // 게임 중
  paused, // 일시 정지
  gameOver, // 게임 오버
}

/// 게임의 전체 상태를 관리하는 클래스
class GameState {
  final Grid grid;
  final List<Block> activeBlocks;
  final int score;
  final int level;
  final GameStatus status;
  final List<String> completedWords;

  // 랜덤 생성기
  static final Random _random = Random();

  // 생성자
  GameState({
    Grid? grid,
    List<Block>? activeBlocks,
    this.score = 0,
    this.level = 1,
    this.status = GameStatus.ready,
    List<String>? completedWords,
  })  : grid = grid ?? Grid(rows: 10, columns: 10),
        activeBlocks = activeBlocks ?? [],
        completedWords = completedWords ?? [];

  /// 게임 상태 복제 메서드
  GameState copyWith({
    Grid? grid,
    List<Block>? activeBlocks,
    int? score,
    int? level,
    GameStatus? status,
    List<String>? completedWords,
  }) {
    return GameState(
      grid: grid ?? this.grid,
      activeBlocks: activeBlocks ?? List.from(this.activeBlocks),
      score: score ?? this.score,
      level: level ?? this.level,
      status: status ?? this.status,
      completedWords: completedWords ?? List.from(this.completedWords),
    );
  }

  /// 새 게임 초기화
  GameState initialize() {
    // 새 그리드 생성
    final newGrid = Grid(rows: 10, columns: 10);

    // 초기 블록 생성
    final newBlocks = _generateInitialBlocks();

    return GameState(
      grid: newGrid,
      activeBlocks: newBlocks,
      score: 0,
      level: 1,
      status: GameStatus.playing,
      completedWords: [],
    );
  }

  /// 초기 블록 생성
  List<Block> _generateInitialBlocks() {
    List<Block> blocks = [];

    // 기본 문자셋 (자음, 모음)
    final List<String> charSet = [
      'ㄱ',
      'ㄴ',
      'ㄷ',
      'ㄹ',
      'ㅁ',
      'ㅂ',
      'ㅅ',
      'ㅇ',
      'ㅈ',
      'ㅊ',
      'ㅋ',
      'ㅌ',
      'ㅍ',
      'ㅎ',
      'ㅏ',
      'ㅑ',
      'ㅓ',
      'ㅕ',
      'ㅗ',
      'ㅛ',
      'ㅜ',
      'ㅠ',
      'ㅡ',
      'ㅣ',
      '가',
      '나',
      '다',
      '라',
      '마',
      '바',
      '사',
      '아',
      '자',
      '차',
      '카',
      '타',
      '파',
      '하',
    ];

    // 기본 색상셋
    final List<Color> colorSet = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];

    // 3개의 블록 생성
    for (int i = 0; i < 3; i++) {
      // 블록 크기 랜덤 선택 (1-3)
      int size = _random.nextInt(3) + 1;

      // 문자 랜덤 선택
      List<String> characters = [];
      for (int j = 0; j < size; j++) {
        characters.add(charSet[_random.nextInt(charSet.length)]);
      }

      // 색상 선택
      Color color = colorSet[_random.nextInt(colorSet.length)];

      // 블록 추가
      blocks.add(Block(
        id: DateTime.now().millisecondsSinceEpoch + i,
        shape: _getShapeForSize(size),
        characters: characters,
        color: color,
      ));
    }

    return blocks;
  }

  /// 블록 크기에 맞는 모양 반환
  BlockShape _getShapeForSize(int size) {
    switch (size) {
      case 1:
        return BlockShape.single;
      case 2:
        return _random.nextBool()
            ? BlockShape.horizontal2
            : BlockShape.vertical2;
      case 3:
        List<BlockShape> shapes = [
          BlockShape.horizontal3,
          BlockShape.vertical3,
          BlockShape.lShape,
          BlockShape.reverseLShape,
          BlockShape.corner,
        ];
        return shapes[_random.nextInt(shapes.length)];
      default:
        return BlockShape.single;
    }
  }

  /// 새 블록 생성
  GameState generateNewBlocks() {
    // 현재 활성 블록 수 확인
    if (activeBlocks.length >= 5) {
      return this; // 최대 5개 블록으로 제한
    }

    // 필요한 블록 수 (총 5개까지)
    int needed = 5 - activeBlocks.length;

    // 새 블록 생성
    List<Block> newBlocks = List.from(activeBlocks);
    List<Block> generatedBlocks =
        _generateInitialBlocks().take(needed).toList();
    newBlocks.addAll(generatedBlocks);

    return copyWith(activeBlocks: newBlocks);
  }

  /// 블록을 그리드에 배치
  GameState placeBlock(Block block, List<Point> points) {
    // 블록 배치 가능 여부 확인
    if (!grid.isValidPlacement(points)) {
      return this; // 배치 불가능한 경우 현재 상태 유지
    }

    // 블록 배치
    Grid newGrid = grid.placeBlock(block, points);

    // 활성 블록에서 제거
    List<Block> newActiveBlocks = List.from(activeBlocks);
    newActiveBlocks.removeWhere((b) => b.id == block.id);

    return copyWith(
      grid: newGrid,
      activeBlocks: newActiveBlocks,
    );
  }

  /// 단어 처리
  GameState processWords(Set<String> validWords) {
    // 그리드에서 유효한 단어 찾기
    List<Word> words = grid.findWords(validWords);

    if (words.isEmpty) {
      return this; // 유효한 단어가 없으면 현재 상태 유지
    }

    // 완성된 단어 리스트 업데이트
    List<String> newCompletedWords = List.from(completedWords);
    for (Word word in words) {
      if (!newCompletedWords.contains(word.text)) {
        newCompletedWords.add(word.text);
      }
    }

    // 점수 계산
    int additionalScore = 0;
    for (Word word in words) {
      // 기본 점수: 글자 당 10점
      int wordScore = word.text.length * 10;

      // 레벨에 따른 보너스
      wordScore += (wordScore * level * 0.1).round();

      additionalScore += wordScore;
    }

    // 단어 제거 후 그리드 업데이트
    Grid newGrid = grid.removeWords(words);

    // 레벨 계산 (1000점마다 레벨업)
    int newLevel = ((score + additionalScore) / 1000).floor() + 1;
    if (newLevel > 10) newLevel = 10; // 최대 레벨 10

    return copyWith(
      grid: newGrid,
      score: score + additionalScore,
      level: newLevel,
      completedWords: newCompletedWords,
    );
  }

  /// 게임 종료
  GameState endGame() {
    return copyWith(status: GameStatus.gameOver);
  }
}
