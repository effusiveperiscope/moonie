import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import 'package:moonie/core.dart';
import 'package:moonie/llm_interfaces/llm.dart';
import 'package:moonie/settings.dart';
import 'package:provider/provider.dart';

class BasicChatController extends ChangeNotifier {
  final LLMInterface ifc;
  List<(ChatMessageType, String)> messages = [];
  bool _busy = false;
  String errorMessage = '';

  static const String systemPrompt = 'You are a helpful AI assistant.';

  bool get busy => _busy;
  set busy(bool value) {
    _busy = value;
    notifyListeners();
  }

  BasicChatController(this.ifc);

  bool canSend() {
    return ifc.completions() != null;
  }

  void clear() {
    messages.clear();
    notifyListeners();
  }

  void sendMessage(String message) async {
    busy = true;
    final prompt = ChatPromptTemplate.fromTemplates(
      [
        (ChatMessageType.system, systemPrompt),
        ...messages,
        (ChatMessageType.human, '{message}'),
      ],
    );
    final openai = ifc.completions()!;
    final chain = prompt | openai | const StringOutputParser();
    messages.add((ChatMessageType.human, message));
    notifyListeners();
    try {
      final res = await chain.invoke({'message': message});
      messages.add((ChatMessageType.ai, res as String));
      ifc.postGenHook();
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return;
    } finally {
      busy = false;
    }
  }

  void removeMessages((ChatMessageType, String) message) async {
    int index = messages.lastIndexWhere((element) => element == message);
    if (index == -1) {
      return;
    }
    messages.removeRange(index, messages.length);
    notifyListeners();
  }

  void retryMessage((ChatMessageType, String) lastMessage) async {
    removeMessages(lastMessage);
    busy = true;
    notifyListeners();
    final prompt = ChatPromptTemplate.fromTemplates(
        [(ChatMessageType.system, systemPrompt), ...messages]);
    final openai = ifc.completions()!;
    final chain = prompt | openai | const StringOutputParser();
    final res = await chain.invoke({});
    messages.add((ChatMessageType.ai, res as String));
    ifc.postGenHook();
    busy = false;
    notifyListeners();
  }
}

class BasicChatWidget extends StatefulWidget {
  final MoonieCore core;
  late final LLMInterface ifc;
  BasicChatWidget({super.key, required this.core}) {
    ifc = core.interface;
  }

  @override
  State<BasicChatWidget> createState() => _BasicChatWidgetState();
}

class _BasicChatWidgetState extends State<BasicChatWidget> {
  TextEditingController textController =
      TextEditingController(text: 'Hello, this is a test.');
  late final BasicChatController controller;
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = BasicChatController(widget.ifc);
  }

  String chatMessageTypeToName(ChatMessageType type) {
    switch (type) {
      case ChatMessageType.ai:
        return 'AI';
      case ChatMessageType.human:
        return 'You';
      case ChatMessageType.system:
        return 'System';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ChangeNotifierProvider.value(
      value: controller,
      child:
          Consumer<BasicChatController>(builder: (context, controller, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: SelectableRegion(
                  selectionControls: MaterialTextSelectionControls(),
                  focusNode: focusNode,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final message in controller.messages)
                          Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                              chatMessageTypeToName(message.$1),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12)),
                                          const Spacer(),
                                          SizedBox(
                                            width: 24.0,
                                            height: 18.0,
                                            child: IconButton.outlined(
                                                icon: const Icon(
                                                    Icons.restart_alt),
                                                iconSize: 16,
                                                padding: EdgeInsets.zero,
                                                visualDensity:
                                                    VisualDensity.compact,
                                                onPressed: () {
                                                  controller
                                                      .retryMessage(message);
                                                }),
                                          ),
                                          const SizedBox(width: 24),
                                          SizedBox(
                                            width: 24.0,
                                            height: 18.0,
                                            child: IconButton.outlined(
                                                icon: const Icon(Icons.delete),
                                                iconSize: 16,
                                                padding: EdgeInsets.zero,
                                                visualDensity:
                                                    VisualDensity.compact,
                                                onPressed: () {
                                                  controller
                                                      .removeMessages(message);
                                                }),
                                          )
                                        ],
                                      ),
                                      const Divider(),
                                      Text(
                                        message.$2,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                        if (controller.errorMessage.isNotEmpty)
                          Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    controller.errorMessage,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.red),
                                  ),
                                ),
                              )),
                      ]),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textController,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    IconButton.outlined(
                      onPressed: () {
                        controller.clear();
                      },
                      icon: const Icon(Icons.restart_alt),
                    ),
                    const SizedBox(width: 8.0),
                    ChangeNotifierProvider.value(
                      value: widget.core.settings,
                      child: Consumer<Settings>(builder: (context, s, _) {
                        return IconButton.outlined(
                            onPressed: controller.canSend()
                                ? () {
                                    controller.sendMessage(textController.text);
                                  }
                                : null,
                            icon: controller.busy
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ))
                                : const Icon(Icons.send));
                      }),
                    )
                  ],
                ),
              ),
            )
          ],
        );
      }),
    );
  }
}
