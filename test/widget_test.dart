import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_2/flame_demo_game.dart';

void main() {
  testWidgets('starts the Flame game', (tester) async {
    await tester.pumpWidget(GameWidget(game: FlameDemoGame()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
