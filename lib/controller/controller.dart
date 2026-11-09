import '../model/board.dart';
import '../model/web_client.dart';
import '../view/ui.dart';

/// Runs the game: asks the  for input, talks to the server through
/// a web client, updates the board, and tells the view what to display.
class GameController {
  final ConsoleUI _ui;

  late WebClient _client;
  late int _size;
  late List<String> _strategies;

  GameController(this._ui);

  Future<void> run() async {
    _ui.showMessage('Omok');
    await _connect();

    do {
      final strategy = _chooseStrategy();
      await _playGame(strategy);
    } while (_ui.promptPlayAgain());

    _ui.showMessage('Goodbye!');
  }

  /// Asks for a server URL until one answers /info correctly.
  Future<void> _connect() async {
    while (true) {
      final url = _ui.promptServerUrl(WebClient.defaultUrl).trim();
      try {
        _client = WebClient(baseUrl: url.isEmpty ? WebClient.defaultUrl : url);
        _size = await _client.getBoardSize();
        _strategies = await _client.getStrategies();
        return;
      } on Exception catch (e) {
        _ui.showError(_describe(e));
      }
    }
  }

  /// Pick a strategy by name or by its 1-based number.
  String _chooseStrategy() {
    while (true) {
      final input = _ui.promptStrategy(_strategies).trim();

      final index = int.tryParse(input);
      if (index != null && index >= 1 && index <= _strategies.length) {
        return _strategies[index - 1];
      }
      for (final s in _strategies) {
        if (s.toLowerCase() == input.toLowerCase()) return s;
      }
      _ui.showError('Please choose one of: ${_strategies.join(', ')}.');
    }
  }

  Future<void> _playGame(String strategy) async {
    final String pid;
    try {
      pid = await _client.newGame(strategy);
    } on Exception catch (e) {
      _ui.showError(_describe(e));
      return;
    }

    final board = Board(_size);
    List<int>? lastServerMove;
    _ui.showBoard(board);

    while (true) {
      final move = _readMove(board);
      if (move == null) return; // user quit

      final PlayResult result;
      try {
        result = await _client.play(pid, move[0], move[1]);
      } on Exception catch (e) {
        _ui.showError(_describe(e)); // let the user retry
        continue;
      }

      // Your move.
      board.place(result.ack.x, result.ack.y, Board.player);
      if (_gameOver(board, result.ack, [result.ack.x, result.ack.y],
          winText: 'You win!')) {
        return;
      }

      final reply = result.reply;
      if (reply == null) return;
      board.place(reply.x, reply.y, Board.server);
      lastServerMove = [reply.x, reply.y];
      if (_gameOver(board, reply, lastServerMove, winText: 'You lose.')) {
        return;
      }

      _ui.showBoard(board, lastMove: lastServerMove);
    }
  }

  /// Shows the final board and message if ended the game.
  bool _gameOver(Board board, Move move, List<int> last,
      {required String winText}) {
    if (!move.isOver) return false;
    _ui.showBoard(board,
        lastMove: last, highlight: move.isWin ? move.row : null);
    _ui.showMessage(move.isWin ? winText : 'The game is a draw.');
    return true;
  }

  /// Reads "4 5" or "4,5"; returns null on q. Rejects off-board or taken cells.
  List<int>? _readMove(Board board) {
    while (true) {
      final input = _ui.promptMove(_size).trim();
      if (input.toLowerCase() == 'q') return null;

      final parts = input.split(RegExp(r'[\s,]+'));
      final x = parts.length == 2 ? int.tryParse(parts[0]) : null;
      final y = parts.length == 2 ? int.tryParse(parts[1]) : null;
      if (x == null || y == null) {
        _ui.showError('Enter two numbers such as "4 5", or q to quit.');
        continue;
      }
      if (!board.isInside(x, y)) {
        _ui.showError('That is outside the board (0-${_size - 1}).');
        continue;
      }
      if (!board.isEmptyAt(x, y)) {
        _ui.showError('That place is already taken.');
        continue;
      }
      return [x, y];
    }
  }

  String _describe(Exception e) => e.toString().replaceFirst('Exception: ', '');
}