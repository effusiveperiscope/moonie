import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_selectionarea/flutter_markdown.dart';
import 'package:langchain/langchain.dart';
import 'package:moonie/activities/activity.dart';
import 'package:moonie/core.dart';
import 'package:moonie/openrouter.dart';
import 'package:moonie/utils.dart';
import 'package:provider/provider.dart';

class Chat2Message {
  ChatMessageType type;
  String text;
  bool complete = false;

  String? model;
  String? imageFile;
  String? imageBase64;

  Chat2Message(
      {this.type = ChatMessageType.human, required String text, this.imageFile})
      : text = text {
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
  CancelableOperation? _future;

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

  void interrupt() {
    _future?.cancel();
  }

  Future<void> sendMessage(Chat2Message message) async {
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
    final res = await invoke(chain, prompt);
    if (res == 1) {
      errorMessage = 'Request cancelled';
      return;
    }
  }

  Future<dynamic> invoke(Runnable chain, PromptValue prompt) async {
    if (useStreamingOutputs()) {
      _future = CancelableOperation.fromFuture(
        streamInvoke(chain, prompt),
        onCancel: () {
          messages.removeLast();
          return 1;
        },
      );
    } else {
      _future = CancelableOperation.fromFuture(
        nonStreamInvoke(chain, prompt),
        onCancel: () {
          // Right now we can't really do much about this
          // Because requests aren't interruptible
          return 1;
        },
      );
    }
    return await _future!.valueOrCancellation();
  }

  Future<void> nonStreamInvoke(Runnable chain, PromptValue prompt) async {
    try {
      final res = await chain.invoke(prompt);
      final mes = Chat2Message(type: ChatMessageType.ai, text: res as String);
      mes.model = ori.currentModel();
      mes.complete = true;
      messages.add(mes);
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    } finally {
      ori.testKey();
      busy = false;
    }
  }

  Future<void> streamInvoke(Runnable chain, PromptValue prompt) async {
    final mes = Chat2Message(type: ChatMessageType.ai, text: '');
    try {
      busy = true;
      mes.model = ori.currentModel();
      mes.complete = false;
      messages.add(mes);
      notifyListeners();
      final stream = chain.stream(prompt);
      await stream.forEach((event) {
        mes.text += event as String;
        notifyListeners();
      });
      errorMessage = '';
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    } finally {
      mes.complete = true;
      ori.testKey();
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

  Future<void> retryMessage(Chat2Message? lastMessage) async {
    try {
      if (lastMessage != null) {
        removeMessages(lastMessage);
      }
      busy = true;
      notifyListeners();
      final prompt = PromptValue.chat([
        ...prefill().map((e) => e.message()),
        ...(messages.map((e) => e.message()).toList()),
      ]);
      final openai = ori.completions()!;
      final chain = openai | const StringOutputParser();
      // invoke
      final res = await invoke(chain, prompt);
      if (res == 1) {
        errorMessage = 'Request cancelled';
        return;
      }
      errorMessage = '';
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    } finally {
      ori.testKey();
      busy = false;
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
  late TextEditingController editController = TextEditingController();
  bool editMode = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    editController.dispose();
  }

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
                    SizedBox(
                        width: 24.0,
                        height: 18.0,
                        child: IconButton.outlined(
                          icon: const Icon(Icons.edit),
                          iconSize: 16,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          // Only allow editing complete messages
                          onPressed: message.complete
                              ? () {
                                  setState(() {
                                    editMode = !editMode;
                                    if (editMode == true) {
                                      editController.text = message.text;
                                      print(editController.text);
                                    }
                                  });
                                }
                              : null,
                        )),
                    const SizedBox(width: 16),
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
                    const SizedBox(width: 16),
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
                      child: Builder(builder: (context) {
                        if (editMode) {
                          return TextField(
                            controller: editController,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(), isDense: true),
                            style: const TextStyle(fontSize: 12),
                            maxLines: null,
                            minLines: 1,
                            onChanged: (value) {
                              message.text = value;
                            },
                          );
                        }
                        return MarkdownBody(
                          data: message.text,
                          // For now we'll disable image building
                          // Since the AI can hallucinate invalid links
                          imageBuilder: (uri, title, alt) => const SizedBox(),
                          styleSheet:
                              //MarkdownStyleSheet.fromTheme(Theme.of(context)),
                              fromThemeWithBaseFontSize(context, 12),
                          //style: const TextStyle(fontSize: 12),
                        );
                      }),
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

class Chat2Widget extends ActivityWidget {
  late final OpenRouterInterface openRouterInterface;
  Chat2Widget({super.key, required MoonieCore core})
      : super(
            name: "Chat 2",
            description: "Chat with retries, images, streaming, etc.",
            core: core) {
    openRouterInterface = core.openRouterInterface;
  }

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
                      child: textInput(),
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
                    imageAttachButton(),
                    const SizedBox(width: 8.0),
                    sendButton(controller)
                  ],
                ),
              ),
            )
          ],
        );
      }),
    );
  }

  TextField textInput() {
    return TextField(
        controller: textController,
        decoration:
            const InputDecoration(border: OutlineInputBorder(), isDense: true),
        style: const TextStyle(fontSize: 12),
        maxLines: 7,
        minLines: 1);
  }

  IconButton imageAttachButton() {
    return IconButton.outlined(
        visualDensity: VisualDensity.compact,
        onPressed: () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['png', 'jpg', 'jpeg', 'webp']);
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
            : Image.file(File(imageFile!), width: 16, height: 16));
  }

  ChangeNotifierProvider<OpenRouterSettings> sendButton(
      Chat2Controller controller) {
    final void Function()? invocationCallback;
    if (controller.canSend()) {
      if (controller.busy) {
        invocationCallback = () {
          controller.interrupt();
        };
      } else {
        invocationCallback = () async {
          if (textController.text.isNotEmpty) {
            final mes = Chat2Message(
                type: ChatMessageType.human,
                text: textController.text,
                imageFile: imageFile);
            mes.complete = true;
            await controller.sendMessage(mes);
            textController.clear();
          } else {
            await controller.retryMessage(null);
          }
        };
      }
    } else {
      invocationCallback = null;
    }
    return ChangeNotifierProvider.value(
      value: widget.openRouterInterface.settings.openRouterSettings,
      child: Consumer<OpenRouterSettings>(builder: (context, ors, _) {
        return IconButton.outlined(
            visualDensity: VisualDensity.compact,
            onPressed: invocationCallback,
            icon: controller.busy
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ))
                : const Icon(Icons.send));
      }),
    );
  }
}
