/// Local copy of the game board, used only for display and input checks.
class Board {
  static const empty = 0;
  static const player = 1;
  static const server = 2;

  final int size;
  final List<List<int>> _cells;

  Board(this.size)
      : _cells = List.generate(size, (_) => List.filled(size, empty));

  int at(int x, int y) => _cells[y][x];

  bool isInside(int x, int y) => x >= 0 && y >= 0 && x < size && y < size;

  bool isEmptyAt(int x, int y) => at(x, y) == empty;

  void place(int x, int y, int stone) => _cells[y][x] = stone;
}