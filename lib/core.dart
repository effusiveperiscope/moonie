import 'package:flutter/material.dart';
import 'package:moonie/llm_interfaces/llm.dart';
import 'package:moonie/llm_interfaces/openai.dart';
import 'package:moonie/modules/rp_context.dart';
import 'package:moonie/objectbox.g.dart';
import 'package:moonie/llm_interfaces/openrouter.dart';
import 'package:moonie/settings.dart';
import 'package:path_provider/path_provider.dart';

class MoonieCore extends ChangeNotifier {
  late final Settings settings;
  late final OpenRouterInterface openRouterInterface;
  late final OpenAIInterface openAiInterface;
  late LLMInterface interface;
  late final Store store;
  late final RPContext rpContext;

  static const moonieCoreFolder = 'moonie';

  static Future<MoonieCore> create() async {
    MoonieCore core = MoonieCore();
    core.settings = await Settings.read(core);
    core.openRouterInterface = OpenRouterInterface(core.settings);
    core.openAiInterface = OpenAIInterface(core.settings);

    final ors = core.settings.openRouterSettings;
    if (ors.openRouterKey != null) {
      core.openRouterInterface.testKey().then((_) {
        core.openRouterInterface.fetchModels();
      });
    }
    core.settingsUpdatedHook();

    //final docsDir = await getApplicationDocumentsDirectory();
    //core.store = openStore(directory: p.join(docsDir.path, moonieCoreFolder));
    core.store = openStore();

    core.rpContext = await RPContext.create(core);
    return core;
  }

  void settingsUpdatedHook() {
    switch (settings.interfaceType) {
      case LLMInterfaceType.openrouter:
        interface = openRouterInterface;
        break;
      case LLMInterfaceType.openai:
        interface = openAiInterface;
        break;
    }
  }
}
