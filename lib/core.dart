import 'package:flutter/material.dart';
import 'package:moonie/openrouter.dart';
import 'package:moonie/settings.dart';

class MoonieCore extends ChangeNotifier {
  late final settings;
  late final OpenRouterInterface openRouterInterface;

  static Future<MoonieCore> create() async {
    MoonieCore core = MoonieCore();
    core.settings = await Settings.read();
    core.openRouterInterface = OpenRouterInterface(core.settings);
    return core;
  }
}
