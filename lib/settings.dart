import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moonie/core.dart';
import 'package:moonie/openrouter.dart';
import 'package:moonie/utils.dart';
import 'package:provider/provider.dart';

class Settings extends ChangeNotifier {
  String _openRouterKey = "";
  String? _currentModel;

  String? get currentModel => _currentModel;
  set currentModel(String? value) {
    _currentModel = value;
    notifyListeners();
  }

  bool _showOnlyFreeModels = true;

  bool get showOnlyFreeModels => _showOnlyFreeModels;
  set showOnlyFreeModels(bool value) {
    _showOnlyFreeModels = value;
    notifyListeners();
  }

  String get openRouterKey => _openRouterKey;
  set openRouterKey(String value) {
    _openRouterKey = value;
    notifyListeners();
  }

  static const storage = FlutterSecureStorage();

  /// Read settings from storage
  static Future<Settings> read() async {
    final settings = Settings();
    settings.showOnlyFreeModels =
        (await storage.read(key: "showOnlyFreeModels")) == "true";
    settings.openRouterKey = await storage.read(key: "openRouterKey") ?? "";
    final currentModelValue = await storage.read(key: "currentModel");
    settings.currentModel =
        currentModelValue?.isEmpty ?? true ? null : currentModelValue;
    return settings;
  }

  /// Write settings to storage
  Future<void> write() async {
    await storage.write(
        key: "showOnlyFreeModels", value: showOnlyFreeModels.toString());
    await storage.write(key: "openRouterKey", value: openRouterKey);
    await storage.write(key: "currentModel", value: currentModel ?? "");
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
    _openRouterKeyController =
        TextEditingController(text: widget.settings.openRouterKey);
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
                    value: settings.showOnlyFreeModels,
                    onChanged: (value) {
                      setState(() {
                        settings.showOnlyFreeModels = value!;
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
                          final dropdownitems = value.availableModels
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .where((e) => settings.showOnlyFreeModels
                                  ? e.value!.contains(':free')
                                  : true)
                              .toList();

                          return DropdownButton<String>(
                            isExpanded: true,
                            value: settings.currentModel,
                            items: dropdownitems,
                            style: const TextStyle(fontSize: 12.0),
                            onChanged: (String? value) {
                              setState(() {
                                core.settings.currentModel = value!;
                              });
                            },
                          );
                        })),
                  ),
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
                  .testKey(widget._openRouterKeyController.text)
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
                      "credits remaining: ${data["data"]?["limit_remaining"].toStringAsFixed(4)} (${formatDateTime1(DateTime.now())})";
                  widget.settings.openRouterKey =
                      widget._openRouterKeyController.text;
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
