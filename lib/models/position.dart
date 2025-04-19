import 'package:flutter/foundation.dart';

/// 그리드 내 위치를 나타내는 Position 클래스
class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Position && other.row == row && other.col == col;
  }

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'Position($row, $col)';
}
