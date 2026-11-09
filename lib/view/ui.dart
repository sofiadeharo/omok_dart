import 'dart:io';
import '../model/board.dart';

/// Console view: reads input and prints. No game logic or networking.
class ConsoleUI {
  void showMessage(String message) => print(message);

  void showError(String message) => print('Error: $message');

  String promptServerUrl(String defaultUrl) {
    stdout.write('Enter the server URL [default: $defaultUrl]: ');
    return stdin.readLineSync() ?? '';
  }

  String promptStrategy(List<String> strategies) {
    print('Select the server strategy:');
    for (var i = 0; i < strategies.length; i++) {
      print('  ${i + 1}. ${strategies[i]}');
    }
    stdout.write('Enter the number or name [default: 1]: ');
    final input = (stdin.readLineSync() ?? '').trim();
    return input.isEmpty ? '1' : input;
  }

  /// Returns "q" on quit or end of input so the game exits cleanly.
  String promptMove(int size) {
    stdout.write('Enter x y (0-${size - 1}), or q to quit: ');
    return stdin.readLineSync() ?? 'q';
  }

  bool promptPlayAgain() {
    stdout.write('Play again? [y/N]: ');
    final input = (stdin.readLineSync() ?? '').trim().toLowerCase();
    return input == 'y' || input == 'yes';
  }

  /// [lastMove] is the computer's latest move as [x, y] (shown as "(X)");
  /// [highlight] is the winning row as [x, y] pairs (shown as "[O]").
  void showBoard(Board board,
      {List<int>? lastMove, List<List<int>>? highlight}) {
    final buffer = StringBuffer();

    buffer.write('    ');
    for (var x = 0; x < board.size; x++) {
      buffer.write(x.toString().padLeft(2).padRight(3));
    }
    buffer.writeln();

    for (var y = 0; y < board.size; y++) {
      buffer.write('${y.toString().padLeft(3)} ');
      for (var x = 0; x < board.size; x++) {
        final symbol = _symbol(board.at(x, y));
        final isLast = lastMove != null && lastMove[0] == x && lastMove[1] == y;
        final isWinning =
            highlight != null && highlight.any((p) => p[0] == x && p[1] == y);

        if (isWinning) {
          buffer.write('[$symbol]');
        } else if (isLast) {
          buffer.write('($symbol)');
        } else {
          buffer.write(' $symbol ');
        }
      }
      buffer.writeln();
    }
    print(buffer);
  }

  String _symbol(int stone) {
    if (stone == Board.player) return 'O';
    if (stone == Board.server) return 'X';
    return '.';
  }
}