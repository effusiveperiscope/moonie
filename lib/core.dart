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
    final ors = core.settings.openRouterSettings;
    if (ors.openRouterKey != null) {
      core.openRouterInterface.testKey(ors.openRouterKey!).then((_) {
        core.openRouterInterface.fetchModels();
      });
    }
    return core;
  }
}
