import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import 'package:moonie/openrouter.dart';
import 'package:moonie/utils.dart';
import 'package:provider/provider.dart';

class Message {
  ChatMessageType type;
  String text;
  String? model;
  String? imageFile;
  String? imageBase64;

  Message(
      {this.type = ChatMessageType.human, required this.text, this.imageFile}) {
    prepareImage();
  }

  void prepareImage() {
    if (imageFile != null) {
      imageBase64 = base64.encode(File(imageFile!).readAsBytesSync());
    }
  }

  ChatMessage message() {
    switch (type) {
      case ChatMessageType.ai:
        return ChatMessage.ai(text);
      case ChatMessageType.human:
        return ChatMessage.human(ChatMessageContent.multiModal([
          ChatMessageContent.text(text),
          if (imageFile != null)
            ChatMessageContent.image(
                mimeType: imageMimeFromFilePath(imageFile!),
                data: imageBase64!),
        ]));
      case ChatMessageType.system:
        return ChatMessage.system(text);
      default:
        return ChatMessage.human(ChatMessageContent.text(text));
    }
  }

  String name({bool showModel = false}) {
    switch (type) {
      case ChatMessageType.ai:
        if (showModel) {
          return 'AI ($model)';
        } else {
          return 'AI';
        }
      case ChatMessageType.human:
        return 'You';
      case ChatMessageType.system:
        return 'System';
      default:
        return 'Unknown';
    }
  }
}

class Chat2Controller extends ChangeNotifier {
  final OpenRouterInterface ori;
  List<Message> messages = [];
  bool _busy = false;
  String errorMessage = '';

  Chat2Controller(this.ori);

  bool get busy => _busy;
  set busy(bool value) {
    _busy = value;
    notifyListeners();
  }

  bool canSend() {
    return ori.completions() != null;
  }

  void clear() {
    messages.clear();
    notifyListeners();
  }

  // TODO this can be customizable later
  List<Message> prefill() {
    return [
      Message(
          type: ChatMessageType.system, text: 'You are a helpful AI assistant.')
    ];
  }

  void sendMessage(Message message) async {
    busy = true;
    final prompt = PromptValue.chat(
      [
        ...prefill().map((e) => e.message()),
        ...messages.map((e) => e.message())
      ],
    );
    final openai = ori.completions()!;
    final chain = openai | const StringOutputParser();

    messages.add(message);
    notifyListeners();
    // invoke
  }

  void nonStreamInvoke(Runnable chain, PromptValue prompt) async {
    try {
      final res = await chain.invoke(prompt);
      final mes = Message(type: ChatMessageType.ai, text: res as String);
      mes.model = ori.currentModel();
      messages.add(mes);
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    } finally {
      ori.testKey(ori.settings.openRouterSettings.openRouterKey!);
      busy = false;
    }
  }

  void streamInvoke(Runnable chain, PromptValue prompt) {
    try {
      busy = true;
      final mes = Message(type: ChatMessageType.ai, text: '');
      messages.add(mes);
      notifyListeners();
      final stream = chain.stream(prompt);
      stream.forEach((event) {
        mes.text += event as String;
        notifyListeners();
      });
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    } finally {
      ori.testKey(ori.settings.openRouterSettings.openRouterKey!);
      busy = false;
    }
  }

  void removeMessages(Message message) async {
    int index = messages.lastIndexWhere((element) => element == message);
    if (index == -1) {
      return;
    }
    messages.removeRange(index, messages.length);
    notifyListeners();
  }

  void retryMessage(Message lastMessage) async {
    removeMessages(lastMessage);
    busy = true;
    notifyListeners();
    final prompt = PromptValue.chat([
      ...prefill().map((e) => e.message()),
      ...(messages.map((e) => e.message()).toList()),
    ]);
    final openai = ori.completions()!;
    final chain = openai | const StringOutputParser();
    // invoke
  }
}

class _MessageWidget extends StatefulWidget {
  final Message message;
  final Chat2Controller controller;
  const _MessageWidget({required this.message, required this.controller});

  @override
  State<_MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<_MessageWidget> {
  TextEditingController editController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final controller = widget.controller;
    return Padding(
        padding: const EdgeInsets.all(4.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(message.name(showModel: true),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    const Spacer(),
                    // Should only be able to retry AI messages
                    if (message.type == ChatMessageType.ai)
                      SizedBox(
                        width: 24.0,
                        height: 18.0,
                        child: IconButton.outlined(
                            icon: const Icon(Icons.restart_alt),
                            iconSize: 16,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              controller.retryMessage(message);
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
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            controller.removeMessages(message);
                          }),
                    )
                  ],
                ),
                const Divider(),
                Text(
                  message.text,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ));
  }
}

class Chat2Widget extends StatefulWidget {
  final OpenRouterInterface openRouterInterface;
  const Chat2Widget({super.key, required this.openRouterInterface});

  @override
  State<Chat2Widget> createState() => _Chat2WidgetState();
}

class _Chat2WidgetState extends State<Chat2Widget> {
  TextEditingController textController =
      TextEditingController(text: 'Hello, this is a test.');
  late final Chat2Controller controller;
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = Chat2Controller(widget.openRouterInterface);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<Chat2Controller>(builder: (context, controller, child) {
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
                          _MessageWidget(
                              message: message, controller: controller),
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
                      value: widget
                          .openRouterInterface.settings.openRouterSettings,
                      child: Consumer<OpenRouterSettings>(
                          builder: (context, ors, _) {
                        return IconButton.outlined(
                            onPressed: controller.canSend()
                                ? () {
                                    controller.sendMessage(Message(
                                      type: ChatMessageType.human,
                                      text: textController.text,
                                    ));
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
