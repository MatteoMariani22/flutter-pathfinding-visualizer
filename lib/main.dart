import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'pathfinding.dart';

void main() => runApp(const PathfindingApp());

class PathfindingApp extends StatelessWidget {
  const PathfindingApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0B1020);
    return MaterialApp(
      title: 'Pathfinding Visualizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C6CFF),
          brightness: Brightness.dark,
          surface: const Color(0xFF12192B),
        ),
        useMaterial3: true,
      ),
      home: const VisualizerPage(),
    );
  }
}

class VisualizerPage extends StatefulWidget {
  const VisualizerPage({super.key});

  @override
  State<VisualizerPage> createState() => _VisualizerPageState();
}

class _VisualizerPageState extends State<VisualizerPage> {
  static const _rows = 18;
  static const _columns = 30;
  static const _start = Cell(9, 4);
  static const _goal = Cell(9, 25);
  static const _panel = Color(0xFF12192B);
  static const _muted = Color(0xFF8A96AE);
  static const _purple = Color(0xFF8B7CFF);
  static const _cyan = Color(0xFF44D7E8);
  static const _green = Color(0xFF65E6AE);

  final Set<Cell> _walls = {};
  final Set<Cell> _visited = {};
  final Set<Cell> _path = {};
  SearchAlgorithm _algorithm = SearchAlgorithm.aStar;
  SearchResult? _result;
  Timer? _timer;
  int _animationIndex = 0;
  double _speed = 1;
  bool _isAnimating = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleWall(Cell cell) {
    if (_isAnimating || cell == _start || cell == _goal) return;
    setState(() {
      _clearSearch();
      if (!_walls.add(cell)) _walls.remove(cell);
    });
  }

  void _clearSearch() {
    _timer?.cancel();
    _timer = null;
    _visited.clear();
    _path.clear();
    _result = null;
    _animationIndex = 0;
    _isAnimating = false;
  }

  void _clearBoard() {
    setState(() {
      _clearSearch();
      _walls.clear();
    });
  }

  void _generateMaze() {
    final random = Random();
    setState(() {
      _clearSearch();
      _walls
        ..clear()
        ..addAll([
          for (var row = 0; row < _rows; row++)
            for (var column = 0; column < _columns; column++)
              if (Cell(row, column) != _start &&
                  Cell(row, column) != _goal &&
                  random.nextDouble() < 0.23)
                Cell(row, column),
        ]);
      for (var row = 0; row < _rows; row++) {
        _walls.remove(Cell(row, 14));
      }
      for (var column = _start.column; column <= _goal.column; column++) {
        _walls.remove(Cell(_start.row, column));
      }
    });
  }

  void _startSearch() {
    if (_isAnimating) {
      _timer?.cancel();
      setState(() => _isAnimating = false);
      return;
    }
    if (_result != null &&
        _animationIndex < _result!.visited.length + _result!.path.length) {
      _animateResult();
      return;
    }

    setState(() {
      _clearSearch();
      _result = findPath(
        rows: _rows,
        columns: _columns,
        start: _start,
        goal: _goal,
        walls: _walls,
        algorithm: _algorithm,
      );
    });
    _animateResult();
  }

  void _animateResult() {
    final result = _result!;
    setState(() => _isAnimating = true);
    _timer = Timer.periodic(
      Duration(milliseconds: max(4, (22 / _speed).round())),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_animationIndex < result.visited.length) {
          setState(() => _visited.add(result.visited[_animationIndex++]));
        } else {
          final pathIndex = _animationIndex - result.visited.length;
          if (pathIndex < result.path.length) {
            setState(() {
              _path.add(result.path[pathIndex]);
              _animationIndex++;
            });
          } else {
            timer.cancel();
            setState(() => _isAnimating = false);
          }
        }
      },
    );
  }

  Color _cellColor(Cell cell) {
    if (cell == _start) return _green;
    if (cell == _goal) return const Color(0xFFFF6B86);
    if (_path.contains(cell)) return _cyan;
    if (_walls.contains(cell)) return const Color(0xFF39435A);
    if (_visited.contains(cell)) return const Color(0xFF5142A5);
    return const Color(0xFF19233A);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 40 : 20,
                vertical: 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isWide),
                      const SizedBox(height: 26),
                      _buildMetrics(),
                      const SizedBox(height: 18),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 284, child: _buildControls()),
                            const SizedBox(width: 18),
                            Expanded(child: _buildGridPanel()),
                          ],
                        )
                      else ...[
                        _buildControls(),
                        const SizedBox(height: 16),
                        _buildGridPanel(),
                      ],
                      const SizedBox(height: 18),
                      _buildAlgorithmNote(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isWide) => Row(
    children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: _purple.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.route_rounded, color: _purple, size: 25),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PATHFINDER',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 2.2,
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Pathfinding Visualizer',
              style: TextStyle(
                fontSize: isWide ? 25 : 21,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),
      ),
      if (isWide)
        const _StatusPill(
          icon: Icons.circle,
          label: 'READY TO EXPLORE',
          color: _green,
        ),
    ],
  );

  Widget _buildMetrics() {
    final result = _result;
    final items = [
      _MetricData(
        'NODES VISITED',
        _visited.length.toString().padLeft(2, '0'),
        Icons.grid_view_rounded,
        _purple,
      ),
      _MetricData(
        'PATH LENGTH',
        result == null || !result.found ? '--' : '${result.path.length - 1}',
        Icons.show_chart_rounded,
        _cyan,
      ),
      _MetricData(
        'EXECUTION',
        result == null ? '--' : '${result.elapsed.inMicroseconds} µs',
        Icons.bolt_rounded,
        const Color(0xFFFFC66D),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(child: _MetricCard(data: items[i])),
            if (i != items.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildControls() => _Panel(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('SEARCH ALGORITHM'),
        const SizedBox(height: 11),
        DropdownButtonFormField<SearchAlgorithm>(
          initialValue: _algorithm,
          decoration: _inputDecoration(),
          dropdownColor: _panel,
          items: SearchAlgorithm.values
              .map(
                (algorithm) => DropdownMenuItem(
                  value: algorithm,
                  child: Text(
                    algorithm.label,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              )
              .toList(),
          onChanged: _isAnimating
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() {
                    _algorithm = value;
                    _clearSearch();
                  });
                },
        ),
        const SizedBox(height: 21),
        const _SectionLabel('ANIMATION SPEED'),
        Row(
          children: [
            const Icon(Icons.slow_motion_video, color: _muted, size: 17),
            Expanded(
              child: Slider(
                value: _speed,
                min: 0.5,
                max: 2,
                divisions: 5,
                activeColor: _purple,
                onChanged: (value) => setState(() => _speed = value),
              ),
            ),
            Text(
              '${_speed.toStringAsFixed(1)}×',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton.icon(
            onPressed: _startSearch,
            icon: Icon(
              _isAnimating ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            label: Text(
              _isAnimating
                  ? 'Pause visualization'
                  : _animationIndex > 0 && _result != null
                  ? 'Resume visualization'
                  : 'Visualize path',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isAnimating ? null : _generateMaze,
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Random maze'),
                style: _outlineStyle(),
              ),
            ),
            const SizedBox(width: 9),
            IconButton(
              onPressed: _clearBoard,
              tooltip: 'Clear board',
              icon: const Icon(Icons.restart_alt_rounded),
              style: IconButton.styleFrom(
                foregroundColor: _muted,
                backgroundColor: const Color(0xFF1B2439),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 21),
        const Divider(color: Color(0xFF263148), height: 1),
        const SizedBox(height: 16),
        const _SectionLabel('HOW TO USE'),
        const SizedBox(height: 12),
        const _HintRow(
          icon: Icons.touch_app_rounded,
          text: 'Click or drag to draw walls',
        ),
        const SizedBox(height: 9),
        const _HintRow(
          icon: Icons.play_arrow_rounded,
          text: 'Run the selected algorithm',
        ),
        const SizedBox(height: 9),
        const _HintRow(
          icon: Icons.refresh_rounded,
          text: 'Reset to try a new layout',
        ),
      ],
    ),
  );

  Widget _buildGridPanel() => _Panel(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionLabel('GRID EXPLORER')),
            _StatusPill(
              icon: Icons.circle,
              label: _isAnimating ? 'SEARCHING' : '30 × 18',
              color: _isAnimating ? _cyan : _muted,
            ),
          ],
        ),
        const SizedBox(height: 15),
        LayoutBuilder(
          builder: (context, constraints) {
            final cellSize = min(
              24.0,
              (constraints.maxWidth - (_columns - 1) * 3) / _columns,
            );
            return Center(
              child: SizedBox(
                width: cellSize * _columns + (_columns - 1) * 3,
                child: Listener(
                  onPointerDown: (event) =>
                      _paintWallAt(event.localPosition, cellSize),
                  onPointerMove: (event) {
                    if (event.buttons != 0) {
                      _paintWallAt(event.localPosition, cellSize, drag: true);
                    }
                  },
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _columns,
                      crossAxisSpacing: 3,
                      mainAxisSpacing: 3,
                      mainAxisExtent: cellSize,
                    ),
                    itemCount: _rows * _columns,
                    itemBuilder: (context, index) {
                      final cell = Cell(index ~/ _columns, index % _columns);
                      final isStart = cell == _start;
                      final isGoal = cell == _goal;
                      return Tooltip(
                        message: isStart
                            ? 'Start'
                            : isGoal
                            ? 'Goal'
                            : 'Row ${cell.row + 1}, column ${cell.column + 1}',
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 130),
                          decoration: BoxDecoration(
                            color: _cellColor(cell),
                            borderRadius: BorderRadius.circular(
                              min(5, cellSize * 0.2),
                            ),
                            boxShadow: cell == _start || cell == _goal
                                ? [
                                    BoxShadow(
                                      color: _cellColor(cell)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Icon(
                              isStart
                                  ? Icons.play_arrow_rounded
                                  : isGoal
                                  ? Icons.flag_rounded
                                  : null,
                              size: cellSize * 0.72,
                              color: const Color(0xFF0B1020),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 17),
        Wrap(
          spacing: 17,
          runSpacing: 10,
          children: const [
            _LegendItem(color: _green, label: 'Start'),
            _LegendItem(color: Color(0xFFFF6B86), label: 'Goal'),
            _LegendItem(color: Color(0xFF5142A5), label: 'Visited'),
            _LegendItem(color: _cyan, label: 'Shortest path'),
            _LegendItem(color: Color(0xFF39435A), label: 'Wall'),
          ],
        ),
      ],
    ),
  );

  Widget _buildAlgorithmNote() {
    final description = switch (_algorithm) {
      SearchAlgorithm.breadthFirst => 'Breadth-first search explores equally in every direction. On an unweighted grid, it always finds a shortest path.',
      SearchAlgorithm.dijkstra => 'Dijkstra explores the lowest-cost frontier first. With uniform edge weights, it guarantees an optimal path.',
      SearchAlgorithm.aStar => 'A* combines the path cost so far with Manhattan distance to the goal to guide the search efficiently.',
    };
    return _Panel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: _cyan, size: 19),
          const SizedBox(width: 11),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${_algorithm.label} · ${_algorithm.complexity}  ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: const TextStyle(color: _muted, height: 1.45),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() => InputDecoration(
    filled: true,
    fillColor: const Color(0xFF1A2338),
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );

  ButtonStyle _outlineStyle() => OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFFD0D7E6),
    side: const BorderSide(color: Color(0xFF2A3650)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  void _paintWallAt(Offset position, double cellSize, {bool drag = false}) {
    if (_isAnimating) return;
    final stride = cellSize + 3;
    final row = (position.dy / stride).floor();
    final column = (position.dx / stride).floor();
    if (row < 0 || row >= _rows || column < 0 || column >= _columns) return;
    final cell = Cell(row, column);
    if (drag) {
      if (cell != _start && cell != _goal && !_walls.contains(cell)) {
        _toggleWall(cell);
      }
    } else {
      _toggleWall(cell);
    }
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: _VisualizerPageState._panel,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF202A40)),
    ),
    child: child,
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 10,
      letterSpacing: 1.15,
      color: _VisualizerPageState._muted,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 8),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            letterSpacing: 0.7,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) => _Panel(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(data.icon, color: data.color, size: 15),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _VisualizerPageState._muted,
                  fontSize: 9,
                  letterSpacing: 0.65,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            data.value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    ),
  );
}

class _HintRow extends StatelessWidget {
  const _HintRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: _VisualizerPageState._purple),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: _VisualizerPageState._muted,
            fontSize: 11,
          ),
        ),
      ),
    ],
  );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: _VisualizerPageState._muted,
        ),
      ),
    ],
  );
}
