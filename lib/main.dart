import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'space_invaders_game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const SpaceInvadersApp());
}

class SpaceInvadersApp extends StatelessWidget {
  const SpaceInvadersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SpaceInvadersGame.sceneBackgroundColor,
      ),
      home: const Scaffold(
        backgroundColor: SpaceInvadersGame.sceneBackgroundColor,
        body: SafeArea(
          child: GameWidget.controlled(gameFactory: SpaceInvadersGame.new),
        ),
      ),
    );
  }
}
