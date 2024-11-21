import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StopwatchController extends ChangeNotifier {
  bool _isRunning = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  Duration get elapsed => _elapsed;

  bool get isRunning => _isRunning;

  void _tick(Timer timer) {
    _elapsed = Duration(milliseconds: 100 * timer.tick);
    notifyListeners();
  }

  void start() {
    if (_isRunning) {
      return;
    }
    _isRunning = true;
    _timer = Timer.periodic(const Duration(milliseconds: 100), _tick);
    notifyListeners();
  }

  void stop() {
    if (!_isRunning) {
      return;
    }
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void reset() {
    stop();
    _elapsed = Duration.zero;
    notifyListeners();
  }
}

class Stopwatch extends StatelessWidget {
  final StopwatchController controller;
  Stopwatch({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
        value: controller,
        child: Consumer<StopwatchController>(builder: (context, controller, _) {
          final seconds = controller.elapsed.inSeconds.remainder(60);
          final hundreds =
              controller.elapsed.inMilliseconds.remainder(1000) ~/ 10;
          return Text(
              '${seconds.toString().padLeft(2, '0')}.${hundreds ~/ 10}');
        }));
  }
}
