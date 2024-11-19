import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:moonie/activities/activity.dart';
import 'package:moonie/activities/knowledge_decomposition/prompts.dart';
import 'package:moonie/core.dart';
import 'package:moonie/modules/rp_context.dart';
import 'package:moonie/utils.dart';
import 'package:provider/provider.dart';

// TODO - if you run this with a local (i.e. small) model, chances are the results are going to be
// unreliable. Therefore it might be prudent to allow the user to modify the results at each step
// of generation, or even do some work on behalf of the AI. For example,
// Finding the relevant characters within the card is something that the user could do trivially;
// the only reason it's here is so we can fully automate the system.
class KnowledgeDecomposer extends ChangeNotifier {
  final MoonieCore core;
  final RPContext context;
  String errorMessage = '';
  String statusMessage = '';
  bool _busy = false;

  KnowledgeDecomposer({required this.core, required this.context});

  bool get busy => _busy;
  set busy(bool value) {
    _busy = value;
    notifyListeners();
  }

  void error(String e) {
    errorMessage = e;
    notifyListeners();
  }

  void status(String e) {
    statusMessage = e;
    notifyListeners();
  }

  List<BaseNode> extract(String input) {
    try {
      busy = true;
      handleCharacterRole(input);
      error('');
    } catch (e) {
      error(e.toString());
    } finally {
      busy = false;
    }
    return [];
  }

  ChatOpenAI? completions() {
    final ifc = core.interface;
    return ifc.completions();
  }

  dynamic executePrompt(String prompt, dynamic input) {
    final chain = ChatPromptTemplate.fromTemplate(prompt) |
        completions()! |
        JsonOutputParser();
    return chain.invoke(input);
  }

  // Determines what characters are present in the text,
  // Then extracts information on each.
  // For longer documents we probably want something paginated/gist-like like horsona uses?
  Future<List<BaseNode>> handleCharacterRole(String input) async {
    final ifc = core.interface;

    // TODO Eventually we should somehow move all of these into a
    // programmatic tree structure - so we can recalculate parts of the
    // knowledge nodes and update dependent parts of the graph at will

    // DFS traversal would be preferred?
    // DFS is only useful in a 'speculative' way - so the UI can show the user
    // what operation needs to be performed next

    // Or even build the tree step-by-step allowing for user interaction?
    // In this scenario, we would withhold building actual nodes in RP context until the end
    // (user decides to 'commit' the tree)

    // Have to determine the actual need -- if this works fine no need to change?
    // It almost certainly will not work fine with current models.
    // Allowing for user input (so the user can determine whether these things
    // are even necessary) will save us token golf

    try {
      // We don't need to determine the 'relevance' because we can just let the user
      // discard any irrelevant output. Thus we should err on the capturing more irrelevant information than omitting accidentally
      status('Looking for characters...');
      final res = await executePrompt(listCharactersPrompt, {'input': input});
      final List characters = (res as Map)['characters'];
      characters.removeWhere((element) =>
          element == '{{user}}' || element.toLowerCase() == 'user');
      status('Got characters: $characters');
      for (final char in characters) {
        final charRes = await executePrompt(
            decomposeCharacterPrompt, {'input': input, 'character': char});
        status('Decomposed character: $char..., res: $charRes');
        BaseNode characterNode = context.createNode(BaseRole.character, char);
        characterNode.addAttribute(
            context.createAttribute('appearance', charRes['appearance']));
        characterNode.addAttribute(
            context.createAttribute('personality', charRes['personality']));
        characterNode.addAttribute(context.createAttribute(
            'relations_and_backstory', charRes['relations_and_backstory']));
        characterNode.addAttribute(
            context.createAttribute('abilities', charRes['abilities']));
      }
      error('');
    } catch (e) {
      error(e.toString());
      return [];
    }
    return [];
  }
}

class KnowledgeDecomposerWidget extends ActivityWidget {
  const KnowledgeDecomposerWidget({super.key, required super.core})
      : super(
          name: "Knowledge Decomposer",
          description:
              "Decompose text into knowledge components (currently takes SillyTavern cards as input)",
        );

  @override
  State<KnowledgeDecomposerWidget> createState() =>
      _KnowledgeDecomposerWidgetState();
}

class _KnowledgeDecomposerWidgetState extends State<KnowledgeDecomposerWidget> {
  String? cardPath;
  String errorMessage = '';
  String cardSummary = '';
  TavernCard? card;
  late final KnowledgeDecomposer decomposer;

  @override
  void initState() {
    super.initState();
    decomposer =
        KnowledgeDecomposer(core: widget.core, context: widget.core.rpContext);
  }

  void tryLoadCard() {
    try {
      card = TavernCard.fromTavernPath(cardPath!);
      cardSummary = card!.cardSummary();
    } catch (e) {
      errorMessage = e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Card(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                    'Note - this can be fairly token intensive because it passes the entire card in as context repeatedly.'
                    'Advise use on local model if possible. Generally a large context size (>4096) is not necessary (depending on card size).'),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      //mainAxisSize: MainAxisSize.min,
                      children: [
                        ActionChip(
                          label: const Text("Provide SillyTavern Card"),
                          avatar: const Icon(Icons.account_box_outlined),
                          onPressed: () {
                            FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['png'],
                            ).then((value) {
                              if (value != null &&
                                  File(value.files.first.path!).existsSync()) {
                                setState(() {
                                  cardPath = value.files.first.path;
                                  tryLoadCard();
                                });
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        if (errorMessage.isNotEmpty)
                          Text(errorMessage,
                              style: const TextStyle(color: Colors.red)),
                        if (cardSummary.isNotEmpty) Text(cardSummary),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (cardPath != null)
                    Expanded(child: Image.file(File(cardPath!))),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(children: [
                  ActionChip(
                    label: const Text('Extract knowledge'),
                    onPressed: (cardPath != null && decomposer.busy == false)
                        ? () {
                            decomposer.extract(
                                'Scenario name: ${card!.name}\nDescription: ${card!.replaceCharName(card!.description)}');
                          }
                        : null,
                  ),
                ]),
              ),
              ChangeNotifierProvider.value(
                  value: decomposer,
                  child: Consumer<KnowledgeDecomposer>(
                      builder: (context, decomposer, _) {
                    if (decomposer.statusMessage.isNotEmpty) {
                      return Row(
                        children: [
                          if (decomposer.busy)
                            const CircularProgressIndicator(),
                          Expanded(child: Text(decomposer.statusMessage)),
                        ],
                      );
                    } else {
                      return Container();
                    }
                  })),
              ChangeNotifierProvider.value(
                  value: decomposer,
                  child: Consumer<KnowledgeDecomposer>(
                      builder: (context, decomposer, _) {
                    if (decomposer.errorMessage.isNotEmpty) {
                      return Text(decomposer.errorMessage,
                          style: const TextStyle(color: Colors.red));
                    } else {
                      return Container();
                    }
                  })),
            ],
          ),
        )),
      ),
    );
  }
}
