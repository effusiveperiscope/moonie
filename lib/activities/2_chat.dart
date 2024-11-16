import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_selectionarea/flutter_markdown.dart';
import 'package:langchain/langchain.dart';
import 'package:moonie/openrouter.dart';
import 'package:moonie/utils.dart';
import 'package:provider/provider.dart';

class Chat2Message {
  ChatMessageType type;
  String text;
  String? model;
  String? imageFile;
  String? imageBase64;

  Chat2Message(
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
  List<Chat2Message> messages = [];
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
  List<Chat2Message> prefill() {
    return [
      Chat2Message(
          type: ChatMessageType.system, text: 'You are a helpful AI assistant.')
    ];
  }

  bool useStreamingOutputs() {
    return ori.settings.useStreamingOutputs;
  }

  void sendMessage(Chat2Message message) async {
    busy = true;
    final openai = ori.completions()!;
    final chain = openai | const StringOutputParser();

    messages.add(message);
    notifyListeners();
    // invoke
    final prompt = PromptValue.chat(
      [
        ...prefill().map((e) => e.message()),
        ...messages.map((e) => e.message())
      ],
    );
    if (useStreamingOutputs()) {
      streamInvoke(chain, prompt);
    } else {
      await nonStreamInvoke(chain, prompt);
    }
  }

  Future<void> nonStreamInvoke(Runnable chain, PromptValue prompt) async {
    try {
      final res = await chain.invoke(prompt);
      final mes = Chat2Message(type: ChatMessageType.ai, text: res as String);
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

  void streamInvoke(Runnable chain, PromptValue prompt) async {
    try {
      busy = true;
      final mes = Chat2Message(type: ChatMessageType.ai, text: '');
      mes.model = ori.currentModel();
      messages.add(mes);
      notifyListeners();
      final stream = chain.stream(prompt);
      await stream.forEach((event) {
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

  void removeMessages(Chat2Message message) async {
    int index = messages.lastIndexWhere((element) => element == message);
    if (index == -1) {
      return;
    }
    messages.removeRange(index, messages.length);
    notifyListeners();
  }

  void retryMessage(Chat2Message lastMessage) async {
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
    if (useStreamingOutputs()) {
      streamInvoke(chain, prompt);
    } else {
      await nonStreamInvoke(chain, prompt);
    }
  }
}

class _MessageWidget extends StatefulWidget {
  final Chat2Message message;
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
                    Expanded(
                      child: Text(message.name(showModel: true),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
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
                Row(
                  children: [
                    Expanded(
                      child: MarkdownBody(
                        selectable: true,
                        data: message.text,
                        // For now we'll disable image building
                        // Since the AI can hallucinate invalid links
                        imageBuilder: (uri, title, alt) => const SizedBox(),
                        styleSheet:
                            MarkdownStyleSheet.fromTheme(Theme.of(context)),
                        //style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    if (message.imageFile != null)
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.file(File(message.imageFile!)),
                      ))
                  ],
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
  String? imageFile;

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
                        style: const TextStyle(fontSize: 12),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    IconButton.outlined(
                      onPressed: () {
                        controller.clear();
                      },
                      icon: const Icon(Icons.restart_alt),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8.0),
                    IconButton.outlined(
                        visualDensity: VisualDensity.compact,
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform
                              .pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: [
                                'png',
                                'jpg',
                                'jpeg',
                                'webp'
                              ]);
                          if (result == null) {
                            setState(() {
                              imageFile = null;
                            });
                            return;
                          }
                          setState(() {
                            imageFile = result.files.single.path;
                          });
                        },
                        icon: imageFile == null
                            ? const Icon(Icons.image)
                            : Image.file(File(imageFile!),
                                width: 16, height: 16)),
                    const SizedBox(width: 8.0),
                    ChangeNotifierProvider.value(
                      value: widget
                          .openRouterInterface.settings.openRouterSettings,
                      child: Consumer<OpenRouterSettings>(
                          builder: (context, ors, _) {
                        return IconButton.outlined(
                            visualDensity: VisualDensity.compact,
                            onPressed: controller.canSend()
                                ? () {
                                    controller.sendMessage(Chat2Message(
                                        type: ChatMessageType.human,
                                        text: textController.text,
                                        imageFile: imageFile));
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
