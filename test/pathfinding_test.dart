import 'package:flutter_test/flutter_test.dart';
import 'package:pathfinding_visualizer/pathfinding.dart';

void main() {
  group('findPath', () {
    for (final algorithm in SearchAlgorithm.values) {
      test('${algorithm.label} finds the shortest path around a wall', () {
        final result = findPath(
          rows: 5,
          columns: 5,
          start: const Cell(2, 0),
          goal: const Cell(2, 4),
          walls: {const Cell(2, 1), const Cell(2, 2), const Cell(2, 3)},
          algorithm: algorithm,
        );

        expect(result.found, isTrue);
        expect(result.path.first, const Cell(2, 0));
        expect(result.path.last, const Cell(2, 4));
        expect(result.path.length, 7);
        expect(result.path.every((cell) => !{
          const Cell(2, 1),
          const Cell(2, 2),
          const Cell(2, 3),
        }.contains(cell)), isTrue);
        for (var i = 1; i < result.path.length; i++) {
          final previous = result.path[i - 1];
          final current = result.path[i];
          expect(
            (previous.row - current.row).abs() +
                (previous.column - current.column).abs(),
            1,
          );
        }
        expect(result.visited.toSet().length, result.visited.length);
      });

      test('${algorithm.label} reports an unreachable goal', () {
        final result = findPath(
          rows: 3,
          columns: 3,
          start: const Cell(1, 0),
          goal: const Cell(1, 2),
          walls: {const Cell(0, 1), const Cell(1, 1), const Cell(2, 1)},
          algorithm: algorithm,
        );

        expect(result.found, isFalse);
        expect(result.path, isEmpty);
      });

      test('${algorithm.label} handles identical start and goal', () {
        final result = findPath(
          rows: 2,
          columns: 2,
          start: const Cell(0, 0),
          goal: const Cell(0, 0),
          walls: const {},
          algorithm: algorithm,
        );

        expect(result.path, [const Cell(0, 0)]);
        expect(result.visited, [const Cell(0, 0)]);
      });
    }

    test('rejects invalid grid dimensions', () {
      expect(
        () => findPath(
          rows: 0,
          columns: 2,
          start: const Cell(0, 0),
          goal: const Cell(0, 1),
          walls: const {},
          algorithm: SearchAlgorithm.aStar,
        ),
        throwsArgumentError,
      );
    });

    test('rejects a wall covering an endpoint', () {
      expect(
        () => findPath(
          rows: 2,
          columns: 2,
          start: const Cell(0, 0),
          goal: const Cell(1, 1),
          walls: {const Cell(0, 0)},
          algorithm: SearchAlgorithm.breadthFirst,
        ),
        throwsArgumentError,
      );
    });
  });
}
