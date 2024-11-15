import 'package:flutter/material.dart';
import 'package:moonie/openrouter.dart';
import 'package:moonie/settings.dart';

class MoonieCore extends ChangeNotifier {
  late final Settings settings;
  late final OpenRouterInterface openRouterInterface;

  static Future<MoonieCore> create() async {
    MoonieCore core = MoonieCore();
    core.settings = await Settings.read();
    core.openRouterInterface = OpenRouterInterface(core.settings);
    if (core.settings.openRouterKey.isNotEmpty) {
      core.openRouterInterface.testKey(core.settings.openRouterKey);
    }
    return core;
  }
}
