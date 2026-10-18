import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:pathfinding_visualizer/main.dart';

void main() {
  testWidgets('renders the visualizer and its controls', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PathfindingApp());

    expect(find.text('Pathfinding Visualizer'), findsOneWidget);
    expect(find.text('GRID EXPLORER'), findsOneWidget);
    expect(find.text('Visualize path'), findsOneWidget);
    expect(find.text('A*'), findsOneWidget);
  });
}
