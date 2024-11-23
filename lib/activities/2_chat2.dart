import 'dart:io';

import 'package:async/async.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_selectionarea/flutter_markdown.dart';
import 'package:langchain/langchain.dart';
import 'package:moonie/activities/activity.dart';
import 'package:moonie/activities/roleplay/chat_entities.dart';
import 'package:moonie/core.dart';
import 'package:moonie/llm_interfaces/llm.dart';
import 'package:moonie/settings.dart';
import 'package:moonie/utils.dart';
import 'package:provider/provider.dart';

class Chat2Controller extends ChangeNotifier {
  final MoonieCore core;
  List<RPChatMessage> messages = [];
  bool _busy = false;
  String errorMessage = '';
  CancelableOperation? _future;

  String _baseSystemPrompt = 'You are an AI assistant.';
  double _temperature = 1.0;

  double get temperature => _temperature;
  set temperature(double value) {
    _temperature = value;
    notifyListeners();
  }

  String get baseSystemPrompt => _baseSystemPrompt;
  set baseSystemPrompt(String value) {
    _baseSystemPrompt = value;
    notifyListeners();
  }

  Chat2Controller(this.core);

  LLMInterface get ifc => core.interface;

  bool get busy => _busy;
  set busy(bool value) {
    _busy = value;
    notifyListeners();
  }

  bool canSend() {
    return ifc.completions() != null;
  }

  void clear() {
    messages.clear();
    notifyListeners();
  }

  List<RPChatMessage> sysPrompt() {
    return [
      RPChatMessage.ephemeral(
          type: ChatMessageType.system, text: baseSystemPrompt)
    ];
  }

  bool useStreamingOutputs() {
    return core.settings.useStreamingOutputs;
  }

  void interrupt() {
    _future?.cancel();
  }

  void error(String message) {
    errorMessage = message;
    notifyListeners();
  }

  Future<void> sendMessage(RPChatMessage message) async {
    busy = true;
    final chain = buildChain();

    messages.add(message);
    notifyListeners();
    // invoke
    final prompt = buildPrompt();
    final res = await invoke(chain, await prompt);
    if (res == 1) {
      error('Request cancelled');
      return;
    }
  }

  Future<dynamic> invoke(Runnable chain, dynamic prompt) async {
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
      final mes = RPChatMessage.ephemeral(
          type: ChatMessageType.ai, text: res as String);
      mes.complete = true;
      updateWithMessage(mes);
      notifyListeners();
    } catch (e) {
      error(e.toString());
    } finally {
      ifc.postGenHook();
      busy = false;
    }
  }

  Future<void> streamInvoke(Runnable chain, PromptValue prompt) async {
    final mes = RPChatMessage.ephemeral(type: ChatMessageType.ai, text: '');
    try {
      busy = true;
      updateWithMessage(mes);
      notifyListeners();
      final stream = chain.stream(prompt);
      await stream.forEach((event) {
        mes.text += event as String;
        notifyListeners();
      });
      error('');
    } catch (e) {
      error(e.toString());
      notifyListeners();
    } finally {
      mes.complete = true;
      ifc.postGenHook();
      busy = false;
    }
  }

  void updateWithMessage(RPChatMessage message) {
    message.model = ifc.currentModel();
    message.complete = false;
    messages.add(message);
  }

  void removeMessages(RPChatMessage message) async {
    int index = messages.lastIndexWhere((element) => element == message);
    if (index == -1) {
      return;
    }
    messages.removeRange(index, messages.length);
    notifyListeners();
  }

  Future<PromptValue> buildPrompt() async {
    // final jailbreak1 =
    // await rootBundle.loadString('assets/prompts/jailbreak1.txt');
    return PromptValue.chat([
      ...sysPrompt().map((e) => e.message()),
      ...(messages.map((e) => e.message()).toList()),
      //ChatMessage.ai(jailbreak1)
    ]);
  }

  Runnable buildChain() {
    final openai = ifc.completions()!;
    return openai | const StringOutputParser();
  }

  Future<void> retryMessage(RPChatMessage? lastMessage) async {
    try {
      if (lastMessage != null) {
        removeMessages(lastMessage);
      }
      busy = true;
      notifyListeners();
      final prompt = buildPrompt();
      final chain = buildChain();
      // invoke
      final res = await invoke(chain, await prompt);
      if (res == 1) {
        error('Request cancelled');
        return;
      }
      error('');
    } catch (e) {
      error(e.toString());
    } finally {
      ifc.postGenHook();
      busy = false;
    }
  }
}

class _MessageWidget extends StatefulWidget {
  final RPChatMessage message;
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
                                      //print(editController.text);
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
  final List<Widget> children;
  final Chat2Controller? controller;
  const Chat2Widget(
      {super.key,
      required super.core,
      this.children = const [],
      this.controller})
      : super(
            name: "Chat 2",
            description:
                "Ephemeral chat with retries, images, streaming, etc. Does not save chats.");

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
    if (widget.controller != null) {
      controller = widget.controller!;
    } else {
      controller = Chat2Controller(widget.core);
    }
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
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: SelectableRegion(
                      selectionControls: MaterialTextSelectionControls(),
                      focusNode: focusNode,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final child in widget.children)
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: child,
                              ),
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
                  Container(),
                  if (imageFile != null)
                    Positioned(
                      bottom: 0.0,
                      left: 8.0,
                      child: Opacity(
                        opacity: 0.3,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.file(
                              File(
                                  imageFile!), // Replace with your image source
                              width: 64, // Adjust size as needed
                              height: 64, // Adjust size as needed
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    )
                ],
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
                    sendButton(controller),
                    const SizedBox(width: 8.0),
                    PopupMenuButton(
                      itemBuilder: (context) {
                        return [
                          resetButton(controller),
                          imageAttachButton(),
                          generationSettings(controller)
                        ];
                      },
                    ),
                  ],
                ),
              ),
            )
          ],
        );
      }),
    );
  }

  PopupMenuItem generationSettings(Chat2Controller controller) {
    return PopupMenuItem(
      child: const Row(
        children: [
          Icon(Icons.settings_outlined),
          SizedBox(width: 8),
          Text('Generation settings')
        ],
      ),
      onTap: () {
        showDialog(
            context: context,
            builder: (context) =>
                GenerationSettingsDialog(controller: controller));
      },
    );
  }

  PopupMenuItem resetButton(Chat2Controller controller) {
    return PopupMenuItem(
        onTap: () {
          controller.clear();
        },
        child: const Row(
          children: [
            Icon(Icons.restart_alt),
            SizedBox(width: 8),
            Text('Reset')
          ],
        ));
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

  PopupMenuItem imageAttachButton() {
    return PopupMenuItem(
        onTap: () async {
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
        child: Row(children: [
          imageFile == null
              ? const Icon(Icons.image)
              : Image.file(File(imageFile!), width: 16, height: 16),
          const SizedBox(width: 8),
          const Text('Attach image')
        ]));
  }

  ChangeNotifierProvider<Settings> sendButton(Chat2Controller controller) {
    final void Function()? invocationCallback;
    if (controller.canSend()) {
      if (controller.busy) {
        invocationCallback = () {
          controller.interrupt();
        };
      } else {
        invocationCallback = () async {
          if (textController.text.isNotEmpty) {
            final mes = RPChatMessage.ephemeral(
                type: ChatMessageType.human,
                text: textController.text,
                imageFile: imageFile);
            mes.complete = true;
            await controller.sendMessage(mes);
            textController.clear();
            imageFile = null;
          } else {
            await controller.retryMessage(null);
          }
        };
      }
    } else {
      invocationCallback = null;
    }
    return ChangeNotifierProvider.value(
      value: widget.core.settings,
      child: Consumer<Settings>(builder: (context, s, _) {
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

class GenerationSettingsDialog extends StatefulWidget {
  const GenerationSettingsDialog({
    required this.controller,
    super.key,
  });

  final Chat2Controller controller;

  @override
  State<GenerationSettingsDialog> createState() =>
      _GenerationSettingsDialogState();
}

class _GenerationSettingsDialogState extends State<GenerationSettingsDialog> {
  late final TextEditingController _systemPromptController;
  late final TextEditingController _temperatureController;

  @override
  void initState() {
    super.initState();
    _systemPromptController =
        TextEditingController(text: widget.controller.baseSystemPrompt);
    _temperatureController =
        TextEditingController(text: widget.controller.temperature.toString());
  }

  @override
  void dispose() {
    super.dispose();
    _systemPromptController.dispose();
    _temperatureController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle inputStyle = TextStyle(fontSize: 12.0);
    return AlertDialog(
      title: const Text('Generation settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _systemPromptController,
            decoration: const InputDecoration(labelText: 'System prompt'),
            maxLines: null,
            style: inputStyle,
            onChanged: (value) {
              setState(() {
                widget.controller.baseSystemPrompt = value;
              });
            },
          ),
          TextField(
            controller: _temperatureController,
            decoration: const InputDecoration(labelText: 'Temperature'),
            style: inputStyle,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              setState(() {
                widget.controller.temperature = double.parse(value);
              });
            },
          )
        ],
      ),
    );
  }
}
