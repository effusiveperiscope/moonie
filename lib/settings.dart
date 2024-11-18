import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:moonie/core.dart';
import 'package:moonie/llm_interfaces/llm.dart';
import 'package:moonie/llm_interfaces/openai.dart';
import 'package:moonie/llm_interfaces/openrouter.dart';
import 'package:moonie/utils.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

class Settings extends ChangeNotifier {
  bool _notifyListeners = true;
  bool _useStreamingOutputs = true;
  LLMInterfaceType _interfaceType = LLMInterfaceType.openrouter;

  static const storage = FlutterSecureStorage();

  late OpenRouterSettings openRouterSettings;
  late OpenAISettings openAISettings;

  final MoonieCore core;

  Settings(this.core) {
    openRouterSettings = OpenRouterSettings(this);
    openAISettings = OpenAISettings(this);
  }

  /// Read settings from storage
  static Future<Settings> read(final MoonieCore core) async {
    final settings = Settings(core);
    settings._notifyListeners =
        false; // Avoid triggering redundant writes while reading
    final readOpenRouterSettings =
        await storage.read(key: "openRouterSettings");
    if (readOpenRouterSettings != null) {
      settings.openRouterSettings = OpenRouterSettings.fromJson(
          json.decode(readOpenRouterSettings), settings);
    }
    final readOpenAISettings = await storage.read(key: "openAISettings");
    if (readOpenAISettings != null) {
      settings.openAISettings =
          OpenAISettings.fromJson(json.decode(readOpenAISettings), settings);
    }
    settings._useStreamingOutputs =
        await storage.read(key: "useStreamingOutputs") == "true";
    settings._interfaceType = LLMInterfaceType
        .values[int.parse(await storage.read(key: "llmInterfaceType") ?? "0")];
    settings._notifyListeners = true;
    return settings;
  }

  LLMInterfaceType get interfaceType => _interfaceType;
  set interfaceType(LLMInterfaceType value) {
    _interfaceType = value;
    notifyListeners();
  }

  bool get useStreamingOutputs => _useStreamingOutputs;
  set useStreamingOutputs(bool value) {
    _useStreamingOutputs = value;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    core.settingsUpdatedHook();
    write();
    if (_notifyListeners) {
      super.notifyListeners();
    }
  }

  /// Write settings to storage
  void write() async {
    await storage.write(
        key: "openRouterSettings",
        value: json.encode(openRouterSettings.toJson()));
    await storage.write(
        key: "openAISettings", value: json.encode(openAISettings.toJson()));
    await storage.write(
        key: "useStreamingOutputs", value: _useStreamingOutputs.toString());
    await storage.write(
        key: "llmInterfaceType", value: _interfaceType.index.toString());
  }
}

class SettingsPage extends StatefulWidget {
  final Settings settings;
  const SettingsPage({super.key, required this.settings});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _openRouterKeyController;
  late final TextEditingController _openAiKeyController;
  late final TextEditingController _openAiEndpointController;
  late final PageController _pageController;
  LLMInterfaceType _llmInterfaceType = LLMInterfaceType.openrouter;

  @override
  void initState() {
    super.initState();
    _pageController =
        PageController(initialPage: widget.settings.interfaceType.index);
    _openRouterKeyController = TextEditingController(
        text: widget.settings.openRouterSettings.openRouterKey);
    _openAiKeyController =
        TextEditingController(text: widget.settings.openAISettings.openAiKey);
    _openAiEndpointController = TextEditingController(
        text: widget.settings.openAISettings.openAiEndpoint);
  }

  @override
  void dispose() {
    super.dispose();
    _openRouterKeyController.dispose();
    _openAiKeyController.dispose();
    _openAiEndpointController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final core = Provider.of<MoonieCore>(context, listen: false);
    final settings = core.settings;
    final ori = core.openRouterInterface;
    final oai = core.openAiInterface;
    final OpenRouterSettings ors = settings.openRouterSettings;
    return Scaffold(
        appBar: AppBar(
          title: const Text("settings"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text("connection settings",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          DropdownButton(
                              value: settings._interfaceType,
                              items: const [
                                DropdownMenuItem(
                                    value: LLMInterfaceType.openrouter,
                                    child: Text('openrouter')),
                                DropdownMenuItem(
                                    value: LLMInterfaceType.openai,
                                    child: Text('openai')),
                              ],
                              onChanged: (v) {
                                setState(() {
                                  _llmInterfaceType = v!;
                                  widget.settings.interfaceType = v;
                                  _pageController.jumpToPage(v.index);
                                });
                              })
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      SizedBox(
                        height: 260,
                        child: PageView.builder(
                          scrollDirection: Axis.horizontal,
                          controller: _pageController,
                          itemCount: LLMInterfaceType.values.length,
                          itemBuilder: (context, index) {
                            if (index == LLMInterfaceType.openrouter.index) {
                              return openRouterSettings(ori, settings, ors);
                            } else if (index == LLMInterfaceType.openai.index) {
                              return openAISettings(oai, settings);
                            }
                            return null;
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const Divider(),
              Row(
                children: [
                  const Text('Use streaming outputs'),
                  const Spacer(),
                  Checkbox(
                    value: settings.useStreamingOutputs,
                    onChanged: (value) {
                      setState(() {
                        settings.useStreamingOutputs = value!;
                      });
                    },
                  )
                ],
              )
            ],
          ),
        ));
  }

  Padding openAISettings(OpenAIInterface oai, Settings settings) {
    final oas = settings.openAISettings;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('currently only for oobabooga'),
        const SizedBox(
          height: 8,
        ),
        Row(
          children: [
            const Text("openai key"),
            const Spacer(),
            SizedBox(
                width: 200,
                child: TextField(
                  controller: _openAiKeyController,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                )),
          ],
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            const Text("openai endpoint"),
            const Spacer(),
            SizedBox(
                width: 200,
                child: TextField(
                  controller: _openAiEndpointController,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                )),
          ],
        ),
        const SizedBox(height: 8.0),
        ActionChip(
          label: const Text('Connect'),
          onPressed: () async {
            await oai.fetchModels();
          },
        ),
        ChangeNotifierProvider.value(
            value: oai,
            child: Consumer<OpenAIInterface>(
              builder: (context, value, child) {
                if (oai.errorMessage.isNotEmpty) {
                  return Text(oai.errorMessage,
                      style: const TextStyle(color: Colors.red));
                }
                return const SizedBox.shrink();
              },
            )),
        const Divider(),
        Row(
          children: [
            const Text("models"),
            const Spacer(),
            ChangeNotifierProvider.value(
              value: oai,
              child:
                  Consumer<OpenAIInterface>(builder: (context, value, child) {
                return DropdownButton(
                    value: oas.currentModel,
                    items: oai
                        .getModels()
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    style: const TextStyle(fontSize: 12.0),
                    onChanged: (v) {
                      setState(() {
                        oas.currentModel = v!;
                      });
                    });
              }),
            )
          ],
        )
      ]),
    );
  }

  Padding openRouterSettings(
      OpenRouterInterface ori, Settings settings, OpenRouterSettings ors) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text("openrouter key"),
              const Spacer(),
              SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _openRouterKeyController,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                  )),
            ],
          ),
          const SizedBox(height: 8.0),
          OpenRouterKeyTester(
            ori: ori,
            openRouterKeyController: _openRouterKeyController,
            settings: settings,
          ),
          const SizedBox(height: 8.0),
          const Divider(),
          Row(children: [
            const Text("show only free models"),
            const Spacer(),
            Checkbox(
                value: ors.showOnlyFreeModels,
                onChanged: (value) {
                  setState(() {
                    ors.showOnlyFreeModels = value!;
                  });
                })
          ]),
          Row(
            children: [
              const Text("models"),
              const Spacer(),
              SizedBox(
                width: 240,
                child: ChangeNotifierProvider.value(
                    value: ori,
                    child: Consumer<OpenRouterInterface>(
                        builder: (context, value, child) {
                      final dropdownitems = value
                          .getModels()
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList();
                      var dropdownvalue = ors.currentModel;
                      if (dropdownvalue != null &&
                          dropdownitems.firstWhereOrNull(
                                  (e) => e.value == dropdownvalue) ==
                              null) {
                        dropdownitems.add(DropdownMenuItem(
                            value: dropdownvalue, child: Text(dropdownvalue)));
                      }
                      return DropdownButton<String>(
                        isExpanded: true,
                        value: dropdownvalue,
                        items: dropdownitems,
                        style: const TextStyle(fontSize: 12.0),
                        onChanged: (String? value) {
                          setState(() {
                            ors.currentModel = value!;
                          });
                        },
                      );
                    })),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OpenRouterKeyTester extends StatefulWidget {
  const OpenRouterKeyTester({
    super.key,
    required this.ori,
    required TextEditingController openRouterKeyController,
    required this.settings,
  }) : _openRouterKeyController = openRouterKeyController;

  final OpenRouterInterface ori;
  final TextEditingController _openRouterKeyController;
  final Settings settings;

  @override
  State<OpenRouterKeyTester> createState() => _OpenRouterKeyTesterState();
}

class _OpenRouterKeyTesterState extends State<OpenRouterKeyTester> {
  String status = "";
  @override
  Widget build(BuildContext context) {
    final ors = widget.settings.openRouterSettings;
    return Row(
      children: [
        Text(
          status,
          style: const TextStyle(
            fontSize: 10.0,
          ),
        ),
        const Spacer(),
        ActionChip(
            onPressed: () async {
              widget.ori.setKey(widget._openRouterKeyController.text.trim());
              widget.ori.testKey().then((data) async {
                if (data == null) {
                  setState(() {
                    status =
                        "could not contact openrouter api with provided key. error: ${widget.ori.errorMessage}";
                  });
                  return;
                }
                setState(() {
                  status =
                      "credits remaining: ${widget.ori.creditsRemaining?.toStringAsFixed(4)} (${formatDateTime1(DateTime.now())})";
                  ors.openRouterKey = widget._openRouterKeyController.text;
                });
                final models = await widget.ori.fetchModels();
                if (models == null) {
                  setState(() {
                    status =
                        "could not contact fetch models. error: ${widget.ori.errorMessage}";
                  });
                  return;
                }
                setState(() {});
              });
            },
            visualDensity: VisualDensity.compact,
            label: const Text("connect")),
      ],
    );
  }
}

class SettingsButton extends StatelessWidget {
  const SettingsButton({
    super.key,
    required this.core,
  });

  final MoonieCore core;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                      value: core,
                      child: SettingsPage(settings: core.settings))));
        },
        icon: const Icon(Icons.settings));
  }
}
