import 'package:flutter/material.dart';
import 'package:langchain_openai/src/chat_models/chat_openai.dart';
import 'package:langchain_openai/src/chat_models/types.dart';
import 'package:moonie/cookie.dart';
import 'package:moonie/core.dart';
import 'package:moonie/llm_interfaces/llm.dart';
import 'package:moonie/settings.dart';
import 'package:provider/provider.dart';

class OpenAISettings extends ChangeNotifier {
  Settings? settings;
  OpenAISettings(this.settings);

  String? _openAiKey;
  String? _currentModel;

  String? _openAiEndpoint = 'http://localhost:5000/v1';

  String? get openAiKey => _openAiKey;
  set openAiKey(String? value) {
    _openAiKey = value;
    notifyListeners();
  }

  String? get currentModel => _currentModel;
  set currentModel(String? value) {
    _currentModel = value;
    notifyListeners();
  }

  String? get openAiEndpoint => _openAiEndpoint;
  set openAiEndpoint(String? value) {
    _openAiEndpoint = value;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    settings?.notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'openAiKey': _openAiKey,
        'currentModel': _currentModel,
        'openAiEndpoint': _openAiEndpoint
      };

  factory OpenAISettings.fromJson(
          Map<String, dynamic> json, Settings? settings) =>
      OpenAISettings(settings)
        .._openAiKey = json['openAiKey']
        .._currentModel = json['currentModel']
        .._openAiEndpoint = json['openAiEndpoint'];
}

class OpenAIInterface extends ChangeNotifier implements LLMInterface {
  Settings settings;
  OpenAIInterface(this.settings);

  final dio = myDio();
  List<String> availableModels = [];
  String errorMessage = '';
  // I don't plan on ever using the official endpoint so I don't care about credit
  // This is purely for openAI compatible / semi-compatible local APIs.

  @override
  void setKey(String key) {
    settings.openAISettings.openAiKey = key;
    notifyListeners();
  }

  Future<List<String>?> fetchModels() async {
    final oas = settings.openAISettings;
    try {
      // Only for oobabooga
      final response = await dio
          .get('${settings.openAISettings.openAiEndpoint}/internal/model/list');
      if (response.data['model_names'] != null) {
        availableModels = response.data['model_names'].cast<String>();
      }
      if (!availableModels.contains(oas.currentModel)) {
        oas.currentModel = availableModels.first;
        // No concept of free models here.
      }
      errorMessage = '';
      notifyListeners();
      return availableModels;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  List<String> getModels() => availableModels;

  @override
  ChatOpenAI? completions(
      {String? overrideModel,
      double? temperature,
      ChatOpenAIResponseFormat? responseFormat}) {
    final oas = settings.openAISettings;
    String? model = overrideModel ?? oas.currentModel;
    if (model == null || oas.openAiEndpoint == null) {
      return null;
    }
    return ChatOpenAI(
      apiKey: oas.openAiKey,
      baseUrl: oas.openAiEndpoint!,
      defaultOptions: ChatOpenAIOptions(
          model: model,
          temperature: temperature,
          responseFormat: responseFormat),
    );
  }

  @override
  String? currentModel() {
    return settings.openAISettings.currentModel;
  }

  @override
  void postGenHook() {}

  @override
  Widget infoWidget(MoonieCore core) {
    return SizedBox(
      width: 220,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: this),
          ChangeNotifierProvider.value(value: this.settings.openAISettings)
        ],
        child: Consumer2<OpenAIInterface, OpenAISettings>(
            builder: (context, interface, settings, _) => Text(
                'OAI model: ${settings.currentModel}',
                style: const TextStyle(fontSize: 10.0))),
      ),
    );
  }
}
