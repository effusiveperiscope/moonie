import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:moonie/activities/activity.dart';
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
  String errorMessage = '';
  String statusMessage = '';
  bool _busy = false;

  KnowledgeDecomposer({required this.core});

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

  static const String listCharactersPrompt =
      """Determine the name(s) of the primary character(s) (i.e. persons, human or otherwise)
in the following text. 
A 'primary character' is one that has a name and is described in detail over 
a significant portion of the text, not one that is only mentioned tangentially.
- Return an output in raw JSON format.
- Do not consider '{{user}}' (the roleplayer) as a character.
- If a character is unnamed or not described, do not include them.
- If no characters are present, return the object with an empty array.
- You may use a 'thinking' field to explain your reasoning.

Example output: 
{{
"thinking": "Ok. John Doe and Jane Doe are both characters in this text. In addition, a third character, 'Chester', is mentioned but not described.",
"characters": ["John Doe", "Jane Doe"]}}

The text: {input}""";

  static const String decomposeCharacterPrompt =
      """You will be given a text and the name of a character within that text.
Your task is to reformat the text into a structured JSON description of that character
to construct a knowledge base.

- If there is no information pertaining to a particular field, leave an empty string.
- Capture as much correct detail as possible without making assumptions. 
- You are allowed to copy descriptions verbatim if suitable.
- Do not refer to 'the text' in your descriptions. These descriptions will be used downstream in other systems where the text will not be available.
- You may use a 'thinking' field to explain your reasoning.
- Follow the below format, using the same keys.

{{
  "thinking": "Ok. I don't see any information pertaining to Liora's abilities, so I'll leave that blank.",
  "appearance": "Liora stands at 5'7 with a lean, athletic build that hints at years of rigorous training. Her deep emerald-green eyes are striking, often described as piercing, and seem to hold unspoken wisdom. Long, dark brown hair is usually tied into a practical braid, though loose strands frame her sharp, freckled face.",
  "personality": "...",
  "relations_and_backstory": "..."
  "abilities": ""
}}

The character: {character}
The text: {input}
""";

  // Determines what characters are present in the text,
  // Then extracts information on each.
  // For longer documents we probably want something paginated/gist-like like horsona uses?
  Future<List<BaseNode>> handleCharacterRole(String input) async {
    final ifc = core.interface;

    try {
      // We don't need to determine the 'relevance' because we can just let the user
      // discard any irrelevant output. Thus we should err on the capturing more irrelevant information than omitting accidentally
      final listCharsChain =
          ChatPromptTemplate.fromTemplate(listCharactersPrompt) |
              ifc.completions()! |
              JsonOutputParser();
      //final chain = listCharsChain.withRetry(addJitter: true)
      status('Looking for characters...');
      final res = await listCharsChain
          .withRetry(addJitter: true)
          .invoke({'input': input});
      final List characters = (res as Map)['characters'];
      characters.removeWhere((element) =>
          element == '{{user}}' || element.toLowerCase() == 'user');
      status('Got characters: $characters');
      for (final char in characters) {
        final decomposeCharChain =
            ChatPromptTemplate.fromTemplate(decomposeCharacterPrompt) |
                ifc.completions()! |
                JsonOutputParser();
        final charRes = await decomposeCharChain
            .withRetry(addJitter: true)
            .invoke({'input': input, 'character': char});
        status('Decomposed character: $char..., res: $charRes');
        print(charRes);
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
    decomposer = KnowledgeDecomposer(core: widget.core);
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
                    'Note - this can be fairly token intensive because it passes the entire card in as context repeatedly. Advise use on local model if possible.'),
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
                child: ActionChip(
                  label: const Text('Extract knowledge'),
                  onPressed: (cardPath != null && decomposer.busy == false)
                      ? () {
                          decomposer.extract(
                              card!.replaceCharName(card!.description));
                        }
                      : null,
                ),
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
