import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moonie/core.dart';
import 'package:moonie/openrouter.dart';
import 'package:moonie/utils.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

class Settings extends ChangeNotifier {
  bool _notifyListeners = true;
  bool _useStreamingOutputs = true;

  static const storage = FlutterSecureStorage();

  late OpenRouterSettings openRouterSettings;

  Settings() {
    openRouterSettings = OpenRouterSettings(this);
  }

  /// Read settings from storage
  static Future<Settings> read() async {
    final settings = Settings();
    settings._notifyListeners =
        false; // Avoid triggering redundant writes while reading
    final readOpenRouterSettings =
        await storage.read(key: "openRouterSettings");
    if (readOpenRouterSettings != null) {
      settings.openRouterSettings =
          OpenRouterSettings.fromJson(json.decode(readOpenRouterSettings));
    }
    settings._useStreamingOutputs =
        await storage.read(key: "useStreamingOutputs") == "true";
    settings._notifyListeners = true;
    return settings;
  }

  bool get useStreamingOutputs => _useStreamingOutputs;
  set useStreamingOutputs(bool value) {
    _useStreamingOutputs = value;
    notifyListeners();
  }

  @override
  void notifyListeners() {
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
        key: "useStreamingOutputs", value: _useStreamingOutputs.toString());
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

  @override
  void initState() {
    super.initState();
    _openRouterKeyController = TextEditingController(
        text: widget.settings.openRouterSettings.openRouterKey);
  }

  @override
  void dispose() {
    super.dispose();
    _openRouterKeyController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final core = Provider.of<MoonieCore>(context, listen: false);
    final settings = core.settings;
    final ori = core.openRouterInterface;
    final OpenRouterSettings ors = settings.openRouterSettings;
    return Scaffold(
        appBar: AppBar(
          title: const Text("settings"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text("openrouter",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
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
              KeyTester(
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
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList();
                          var dropdownvalue = ors.currentModel;
                          if (dropdownvalue != null &&
                              dropdownitems.firstWhereOrNull(
                                      (e) => e.value == dropdownvalue) ==
                                  null) {
                            dropdownitems.add(DropdownMenuItem(
                                value: dropdownvalue,
                                child: Text(dropdownvalue!)));
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
}

class KeyTester extends StatefulWidget {
  const KeyTester({
    super.key,
    required this.ori,
    required TextEditingController openRouterKeyController,
    required this.settings,
  }) : _openRouterKeyController = openRouterKeyController;

  final OpenRouterInterface ori;
  final TextEditingController _openRouterKeyController;
  final Settings settings;

  @override
  State<KeyTester> createState() => _KeyTesterState();
}

class _KeyTesterState extends State<KeyTester> {
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
              widget.ori
                  .testKey(widget._openRouterKeyController.text.trim())
                  .then((data) async {
                if (data == null) {
                  setState(() {
                    status =
                        "could not contact openrouter api with provided key";
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
                    status = "could not contact fetch models";
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
