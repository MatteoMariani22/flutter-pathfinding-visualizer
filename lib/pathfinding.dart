import 'dart:collection';

enum SearchAlgorithm { breadthFirst, dijkstra, aStar }

extension SearchAlgorithmLabel on SearchAlgorithm {
  String get label => switch (this) {
    SearchAlgorithm.breadthFirst => 'BFS',
    SearchAlgorithm.dijkstra => 'Dijkstra',
    SearchAlgorithm.aStar => 'A*',
  };

  String get complexity => switch (this) {
    SearchAlgorithm.breadthFirst => 'O(V + E)',
    SearchAlgorithm.dijkstra || SearchAlgorithm.aStar => 'O(V²)',
  };
}

class Cell {
  const Cell(this.row, this.column);

  final int row;
  final int column;

  @override
  bool operator ==(Object other) =>
      other is Cell && row == other.row && column == other.column;

  @override
  int get hashCode => Object.hash(row, column);
}

class SearchResult {
  const SearchResult({
    required this.visited,
    required this.path,
    required this.elapsed,
  });

  final List<Cell> visited;
  final List<Cell> path;
  final Duration elapsed;

  bool get found => path.isNotEmpty;
}

class _Entry {
  const _Entry(this.cell, this.priority);

  final Cell cell;
  final int priority;
}

SearchResult findPath({
  required int rows,
  required int columns,
  required Cell start,
  required Cell goal,
  required Set<Cell> walls,
  required SearchAlgorithm algorithm,
}) {
  if (rows <= 0 || columns <= 0) {
    throw ArgumentError('Grid dimensions must be positive.');
  }
  if (!_isInside(start, rows, columns) || !_isInside(goal, rows, columns)) {
    throw ArgumentError('Start and goal must be inside the grid.');
  }
  if (walls.contains(start) || walls.contains(goal)) {
    throw ArgumentError('Start and goal cannot be blocked.');
  }

  final stopwatch = Stopwatch()..start();
  final visited = <Cell>[];
  final parents = <Cell, Cell>{};
  final distances = <Cell, int>{start: 0};
  final settled = <Cell>{};
  final queue = Queue<_Entry>()..add(_Entry(start, 0));
  final frontier = <_Entry>[_Entry(start, 0)];

  while (algorithm == SearchAlgorithm.breadthFirst
      ? queue.isNotEmpty
      : frontier.isNotEmpty) {
    final current = algorithm == SearchAlgorithm.breadthFirst
        ? queue.removeFirst()
        : _removeLowestPriority(frontier);
    if (!settled.add(current.cell)) continue;
    visited.add(current.cell);
    if (current.cell == goal) break;

    for (final neighbor in _neighbors(current.cell, rows, columns)) {
      if (walls.contains(neighbor) || settled.contains(neighbor)) continue;
      final nextDistance = distances[current.cell]! + 1;
      if (nextDistance >= (distances[neighbor] ?? 1 << 30)) continue;
      distances[neighbor] = nextDistance;
      parents[neighbor] = current.cell;
      final priority = switch (algorithm) {
        SearchAlgorithm.breadthFirst => nextDistance,
        SearchAlgorithm.dijkstra => nextDistance,
        SearchAlgorithm.aStar =>
          nextDistance + _manhattanDistance(neighbor, goal),
      };
      final entry = _Entry(neighbor, priority);
      if (algorithm == SearchAlgorithm.breadthFirst) {
        queue.add(entry);
      } else {
        frontier.add(entry);
      }
    }
  }
  stopwatch.stop();

  final path = <Cell>[];
  if (settled.contains(goal)) {
    var current = goal;
    path.add(current);
    while (current != start) {
      current = parents[current]!;
      path.add(current);
    }
  }

  return SearchResult(
    visited: List.unmodifiable(visited),
    path: List.unmodifiable(path.reversed),
    elapsed: stopwatch.elapsed,
  );
}

_Entry _removeLowestPriority(List<_Entry> frontier) {
  var bestIndex = 0;
  for (var i = 1; i < frontier.length; i++) {
    if (frontier[i].priority < frontier[bestIndex].priority) {
      bestIndex = i;
    }
  }
  return frontier.removeAt(bestIndex);
}

Iterable<Cell> _neighbors(Cell cell, int rows, int columns) sync* {
  const offsets = [
    (row: -1, column: 0),
    (row: 0, column: 1),
    (row: 1, column: 0),
    (row: 0, column: -1),
  ];
  for (final offset in offsets) {
    final next = Cell(cell.row + offset.row, cell.column + offset.column);
    if (_isInside(next, rows, columns)) yield next;
  }
}

bool _isInside(Cell cell, int rows, int columns) =>
    cell.row >= 0 &&
    cell.row < rows &&
    cell.column >= 0 &&
    cell.column < columns;

int _manhattanDistance(Cell first, Cell second) =>
    (first.row - second.row).abs() + (first.column - second.column).abs();
