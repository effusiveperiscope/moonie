import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:moonie/activities/activity.dart';
import 'package:moonie/activities/knowledge_decomposition/prompts.dart';
import 'package:moonie/core.dart';
import 'package:moonie/modules/rp_context.dart';
import 'package:moonie/modules/rp_entities.dart';
import 'package:moonie/utils.dart';
import 'package:moonie/widgets/stopwatch.dart';
import 'package:provider/provider.dart';

// NOTE on this -- the more I use this the more I'm convinced it's not actually that useful.
// It's a fun trick but suffers from a few drawbacks.
// 1. The LLMs have too much of a tendency to summarize character contents, losing important information.
// 2. The latency is too high for local models.
// 3. You don't really gain that much compared to just copying and pasting the text into appropriate fields manually.

// Tree structure for keeping track of knowledge decomposition process
// Strictly models information dependencies -- not representative of the actual knowledge
// structure
class KnowledgeOp extends ChangeNotifier {
  final String name;
  Function(KnowledgeOp, dynamic)? operation;
  // Useful for dynamically modifying the tree if this node accepts manual input
  Function(KnowledgeOp)? postResultHook;
  Map<String, Type>? resultSchema;
  Map<String, dynamic>? _result;
  dynamic userdata;

  KnowledgeOp? parent;
  final List<KnowledgeOp> children = [];
  bool done = false;
  bool _busy = false;

  bool get busy => _busy;
  set busy(bool value) {
    _busy = value;
    notifyListeners();
  }

  KnowledgeOp(this.name, {this.operation, this.postResultHook}) {
    operation ??= (node, input) => input;
  }

  dynamic get result => _result;
  set result(dynamic value) {
    if (value == null) {
      _result = null;
      done = false;
      return;
    }
    _result = value;
    done = true;
    postResultHook?.call(this);
    notifyListeners();
  }

  Future<void> invoke(dynamic input, {bool invokeRecursively = false}) async {
    busy = true;
    result = await operation!(this, input);
    busy = false;
    if (invokeRecursively) {
      for (final child in children) {
        await child.invoke(result);
      }
    }
  }

  // dfs traversal for execution order
  List<KnowledgeOp> traversal() {
    final res = <KnowledgeOp>[this];
    for (final child in children) {
      res.addAll(child.traversal());
    }
    return res;
  }

  KnowledgeOp addChild(KnowledgeOp child) {
    children.add(child);
    child.parent = this;
    notifyListeners();
    return child;
  }

  void deleteChild(KnowledgeOp child) {
    children.remove(child);
    child.parent = null;
    notifyListeners();
  }

  void deleteChildren() {
    for (final child in children) {
      deleteChild(child);
    }
    notifyListeners();
  }

  void reset() {
    result = null;
    done = false;
    notifyListeners();
  }

  void resetTree() {
    reset();
    for (final child in children) {
      child.resetTree();
    }
  }
}

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
  late final KnowledgeOp root;

  KnowledgeDecomposer({required this.core, required this.context}) {
    root = KnowledgeOp('root');
    final listCharacters = root.addChild(
        KnowledgeOp('List Characters', operation: (node, input) async {
      // Wait... this has to add its own nodes
      final text = input['input'];
      final res = await executePrompt(listCharactersPrompt, {'input': text});
      final List characters = (res as Map)['characters'];
      characters.removeWhere((element) =>
          element == '{{user}}' || element.toLowerCase() == 'user');
      return {'characters': res['characters'], 'input': text};
    }, postResultHook: (node) {
      // Dynamically reset/rebuild character nodes
      for (final child in List.from(node.children)) {
        if (child.userdata != 'character') {
          continue;
        }
        node.deleteChild(child);
      }
      final characters = node.result['characters'];
      for (final String character in characters) {
        node.addChild(charactersNode(character));
        node.userdata = 'character';
      }
    }));
    listCharacters.addChild(userNode());
    listCharacters.addChild(focusWorldNode());
    root.addChild(rulesNode());
  }

  KnowledgeOp charactersNode(String character) {
    return KnowledgeOp(character, operation: (node, input) async {
      final text = input['input'];
      final character = node.name;
      final res = await executePrompt(
          decomposeCharacterPrompt, {'input': text, 'character': character});
      return res;
    });
  }

  KnowledgeOp userNode() {
    return KnowledgeOp('User', operation: (node, input) async {
      final characters = input['characters'];
      final text = input['input'];
      final res = await executePrompt(
          decomposeUserPrompt, {'text': text, 'characters': characters});
      return res;
    });
  }

  KnowledgeOp focusWorldNode() {
    final node = KnowledgeOp('Focus World', operation: (node, input) async {
      final characters = input['characters'];
      final text = input['input'];
      final res = await executePrompt(
          focusWorldPrompt, {'text': text, 'characters': characters});
      return res;
    });
    node.addChild(worldNode());
    return node;
  }

  KnowledgeOp worldNode() {
    return KnowledgeOp('World', operation: (node, input) async {
      final text = input['input'];
      final res = await executePrompt(decomposeWorldPrompt, {'text': text});
      return res;
    });
  }

  KnowledgeOp rulesNode() {
    return KnowledgeOp('Writing Rules', operation: (node, input) async {
      final text = input['input'];
      final res =
          await executePrompt(decomposeWritingRulesPrompt, {'text': text});
      return res;
    });
  }

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
      root.invoke({'input': input});
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

  Runnable buildChain(String prompt) {
    return ChatPromptTemplate.fromTemplate(prompt) |
        completions()! |
        JsonOutputParser();
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

    // The good news is that everything after this, conceptually, is a cakewalk in comparison :)

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
        characterNode.createAttribute('appearance', charRes['appearance']);
        characterNode.createAttribute('personality', charRes['personality']);
        characterNode.createAttribute(
            'relations_and_backstory', charRes['relations_and_backstory']);
        characterNode.createAttribute('abilities', charRes['abilities']);
      }
      error('');
    } catch (e) {
      error(e.toString());
      return [];
    }
    return [];
  }
}

class KnowledgeOpWidget extends StatefulWidget {
  final KnowledgeOp op;
  const KnowledgeOpWidget({super.key, required this.op});

  @override
  State<KnowledgeOpWidget> createState() => _KnowledgeOpWidgetState();
}

class _KnowledgeOpWidgetState extends State<KnowledgeOpWidget> {
  bool collapsed = false;
  StopwatchController stopwatchController = StopwatchController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ChangeNotifierProvider.value(
      value: widget.op,
      child: Consumer<KnowledgeOp>(
        builder: (context, op, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 48,
              color: colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  children: [
                    Text(widget.op.name),
                    const Spacer(),
                    Stopwatch(
                      controller: stopwatchController,
                    ),
                    const SizedBox(width: 8),
                    if (op.parent != null)
                      ActionChip(
                        visualDensity: VisualDensity.compact,
                        avatar: op.busy
                            ? const CircularProgressIndicator()
                            : const Icon(Icons.start),
                        label: const Text('Invoke'),
                        padding: const EdgeInsets.all(2),
                        onPressed:
                            (op.parent == null || op.parent!.result == null)
                                ? null
                                : () async {
                                    stopwatchController.reset();
                                    stopwatchController.start();
                                    await op.invoke(op.parent?.result);
                                    stopwatchController.stop();
                                  },
                      ),
                    IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: collapsed
                            ? const Icon(Icons.arrow_drop_down)
                            : const Icon(Icons.arrow_drop_up),
                        onPressed: () => setState(
                              () => collapsed = !collapsed,
                            ))
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Expanded(
                    child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        child: collapsed
                            ? null
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // TODO we could make this more sophisticated
                                  Container(
                                    color: colorScheme.surfaceBright,
                                    child: Text(widget.op.result != null
                                        ? 'Result: ${widget.op.result.toString()}'
                                        : 'Result:'),
                                  ),
                                  const SizedBox(height: 8),
                                  ...op.children
                                      .map((e) => KnowledgeOpWidget(op: e))
                                      .toList()
                                ],
                              )),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
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
        child: Column(
          children: [
            Card(
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
                  const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Note 2: ' +
                          '''
the more I use this the more I'm convinced it's not actually that useful.
It's a fun trick but suffers from a few drawbacks.
1. The LLMs have too much of a tendency to summarize character contents, losing important information. If you're willing to write your own nodes it's preferable in almost every case.
2. You don't really gain that much compared to just copying and pasting the text into appropriate fields manually.
''')),
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
                                      File(value.files.first.path!)
                                          .existsSync()) {
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
                        label: const Text('Start extraction'),
                        onPressed:
                            (cardPath != null && decomposer.busy == false)
                                ? () {
                                    decomposer.root.resetTree();
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
            Card(child: KnowledgeOpWidget(op: decomposer.root)),
          ],
        ),
      ),
    );
  }
}
