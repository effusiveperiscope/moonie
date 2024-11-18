import 'package:flutter/material.dart';
import 'package:moonie/llm.dart';
import 'package:moonie/objectbox.g.dart';
import 'package:moonie/openrouter.dart';
import 'package:moonie/settings.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class MoonieCore extends ChangeNotifier {
  late final Settings settings;
  late final OpenRouterInterface openRouterInterface;
  late final LLMInterface interface;
  late final Store store;

  static const moonieCoreFolder = 'moonie';

  static Future<MoonieCore> create() async {
    MoonieCore core = MoonieCore();
    core.settings = await Settings.read();
    core.openRouterInterface = OpenRouterInterface(core.settings);
    final ors = core.settings.openRouterSettings;
    if (ors.openRouterKey != null) {
      core.openRouterInterface.testKey().then((_) {
        core.openRouterInterface.fetchModels();
      });
    }
    core.interface = core.openRouterInterface;

    final docsDir = await getApplicationDocumentsDirectory();
    core.store = openStore(p.join(docsDir.path, moonieCoreFolder));
    return core;
  }
}
