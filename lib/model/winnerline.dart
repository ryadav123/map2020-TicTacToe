import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
//import 'package:TicTacToe/common/constants.dart';
//import 'package:TicTacToe/victory/victory.dart';

class WinnerLine extends CustomPainter {
  Paint _paint;
  String lineType;
  int row;
  int col;
  bool winner;

  @override
  bool hitTest(Offset position) {
    return false;
  }

  WinnerLine(winner,lineType,row,column) {
    this.winner = winner;
    this.lineType = lineType;
    this.row = row;
    this.col = column;
    _paint = Paint();
    _paint.color = Colors.deepOrange;
    _paint.strokeWidth = 10.0;
    _paint.strokeCap = StrokeCap.round;
  }

  @override
  void paint(Canvas canvas, Size size) {
    print('paint');
    if (winner) {
      if (lineType == "Hor") {
        _drawHorizontalLine(row, size, canvas);
      } else if (lineType == "Ver") {
        _drawVerticalLine(col, size, canvas);
      } else if (lineType == "Dia_Asc") {
        _drawDiagonalLine(true, size, canvas);
      } else if (lineType == "Dia_Des")
        _drawDiagonalLine(false, size, canvas);
    }
  }

  void _drawVerticalLine(int column, Size size, Canvas canvas) {
    if (column == 0) {
      var x = size.width / 3 / 2;
      var top = Offset(x, 8.0);
      var bottom = Offset(x, size.height - 8.0);
      canvas.drawLine(top, bottom, _paint);
    } else if (column == 1) {
      var x = size.width / 2;
      var top = Offset(x, 8.0);
      var bottom = Offset(x, size.height - 8.0);
      canvas.drawLine(top, bottom, _paint);
    } else {
      var columnWidth = size.width / 3;
      var x = columnWidth * 2 + columnWidth / 2;
      var top = Offset(x, 8.0);
      var bottom = Offset(x, size.height - 8.0);
      canvas.drawLine(top, bottom, _paint);
    }
  }

  void _drawHorizontalLine(int row, Size size, Canvas canvas) {
    if (row == 0) {
      var y = size.height / 3 / 2;
      var left = Offset(8.0, y);
      var right = Offset(size.width - 8.0, y);
      canvas.drawLine(left, right, _paint);
    } else if (row == 1) {
      var y = size.height / 2;
      var left = Offset(8.0, y);
      var right = Offset(size.width - 8.0, y);
      canvas.drawLine(left, right, _paint);
    } else {
      var columnHeight = size.height / 3;
      var y = columnHeight * 2 + columnHeight / 2;
      var left = Offset(8.0, y);
      var right = Offset(size.width - 8.0, y);
      canvas.drawLine(left, right, _paint);
    }
  }

  void _drawDiagonalLine(bool isAscending, Size size, Canvas canvas) {
    if (isAscending) {
      var bottomLeft = Offset(8.0, size.height - 8.0);
      var topRight = Offset(size.width - 8.0, 8.0);
      canvas.drawLine(bottomLeft, topRight, _paint);
    } else {
      var topLeft = Offset(8.0, 8.0);
      var bottomRight = Offset(size.width - 8.0, size.height - 8.0);
      canvas.drawLine(topLeft, bottomRight, _paint);
    }
  }

  @override
  bool shouldRepaint(WinnerLine oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(WinnerLine oldDelegate) => false;
}
