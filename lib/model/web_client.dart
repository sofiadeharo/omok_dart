//Sofia De Haro
//this file is in charge of communicating with the server and getting the information from it
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Talks to the web service: /info, /new, and /play.
class WebClient {
  static const defaultUrl =
      'https://www.cs.utep.edu/cheon/cs3360/project/omok/';
  final Uri _base;

  WebClient({String baseUrl = defaultUrl}) : _base = _parseBase(baseUrl);

  static Uri _parseBase(String url) {
    var text = url.trim();
    if (!text.endsWith('/')) {
      text += '/';
    }
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw Exception('Invalid base URL: $url');
    }
    return uri;
  }

  /// Strategy names offered by the server.
  Future<List<String>> getStrategies() async {
    final json = await _get('info');
    try {
      return (json['strategies'] as List).map((s) => s.toString()).toList();
    } on TypeError {
      throw Exception('Server sent an unexpected response format.');
    }
  }

  /// Board size (the board is size x size).
  Future<int> getBoardSize() async {
    final json = await _get('info');
    try {
      return json['size'] as int;
    } on TypeError {
      throw Exception('Server sent an unexpected response format.');
    }
  }

  /// Starts a new game against [strategy] and returns its play id (pid).
  Future<String> newGame(String strategy) async {
    final json = await _get('new', {'strategy': strategy});
    try {
      return json['pid'] as String;
    } on TypeError {
      throw Exception('Server sent an unexpected response format.');
    }
  }

  /// Plays (x, y) in the game [pid]; returns your move and the server's reply.
  Future<PlayResult> play(String pid, int x, int y) async {
    final json = await _get('play', {'pid': pid, 'x': '$x', 'y': '$y'});
    try {
      return PlayResult.fromJson(json);
    } on TypeError {
      throw Exception('Server sent an unexpected response format.');
    }
  }

  Future<Map<String, dynamic>> _get(String path,
      [Map<String, String>? query]) async {
    final url = _base.resolve(path).replace(queryParameters: query);

    final http.Response response;
    try {
      response = await http.get(url).timeout(const Duration(seconds: 10));
    } on SocketException {
      throw Exception('Could not connect to the server.');
    } on TimeoutException {
      throw Exception('The server took too long to respond.');
    } on http.ClientException {
      throw Exception('Could not connect to the server.');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw Exception('Server sent an invalid response.');
    } on TypeError {
      throw Exception('Server sent an unexpected response format.');
    }

    if (json['response'] == false) {
      throw Exception('Server error: ${json['reason'] ?? 'unknown reason'}');
    }
    return json;
  }
}

/// One move reported by the server (yours or the computer's).
class Move {
  final int x, y;
  final bool isWin, isDraw;
  final List<List<int>> row; // winning row as [x, y] pairs

  Move({
    required this.x,
    required this.y,
    required this.isWin,
    required this.isDraw,
    required this.row,
  });

  bool get isOver => isWin || isDraw;

  factory Move.fromJson(Map<String, dynamic> json) {
    final flat = List<int>.from(json['row'] as List? ?? const []);
    return Move(
      x: json['x'] as int,
      y: json['y'] as int,
      isWin: json['isWin'] == true,
      isDraw: json['isDraw'] == true,
      row: [
        for (var i = 0; i + 1 < flat.length; i += 2) [flat[i], flat[i + 1]],
      ],
    );
  }
}

/// The server's answer to a play request.
class PlayResult {
  final Move ack;    // your move
  final Move? reply; // the computer's move (absent if your move ended the game)

  PlayResult(this.ack, this.reply);

  factory PlayResult.fromJson(Map<String, dynamic> json) => PlayResult(
        Move.fromJson(json['ack_move'] as Map<String, dynamic>),
        json['move'] == null
            ? null
            : Move.fromJson(json['move'] as Map<String, dynamic>),
      );
}