import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:moonie/settings.dart';

class OpenRouterSettings extends ChangeNotifier {
  Settings? settings;
  OpenRouterSettings(this.settings);

  String? _openRouterKey;
  String? _currentModel;
  bool _showOnlyFreeModels = true;

  bool get showOnlyFreeModels => _showOnlyFreeModels;
  set showOnlyFreeModels(bool value) {
    _showOnlyFreeModels = value;
    notifyListeners();
  }

  String? get openRouterKey => _openRouterKey;
  set openRouterKey(String? value) {
    _openRouterKey = value;
    notifyListeners();
  }

  String? get currentModel => _currentModel;
  set currentModel(String? value) {
    _currentModel = value;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    settings?.notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'openRouterKey': _openRouterKey,
        'currentModel': _currentModel,
      };

  factory OpenRouterSettings.fromJson(
          Map<String, dynamic> json, Settings? settings) =>
      OpenRouterSettings(settings)
        .._openRouterKey = json['openRouterKey']
        .._currentModel = json['currentModel'];
}

class OpenRouterInterface extends ChangeNotifier {
  Settings settings;
  OpenRouterInterface(this.settings);

  final dio = Dio();
  List<String> availableModels = [];
  double? creditsRemaining;
  String errorMessage = '';

  // https://openrouter.ai/docs/quick-start
  static const String openRouterEndpoint = 'https://openrouter.ai/api/v1';

  String? currentModel() {
    return settings.openRouterSettings.currentModel;
  }

  // https://openrouter.ai/docs/models
  Future<List<String>?> fetchModels() async {
    try {
      final response = await dio.get('https://openrouter.ai/api/v1/models');
      availableModels.clear();
      availableModels =
          response.data['data'].map((e) => e['id']).toList().cast<String>();
      notifyListeners();
      // If the current model is not available, set it to the first available model
      if (!availableModels.contains(settings.openRouterSettings.currentModel)) {
        settings.openRouterSettings.currentModel = availableModels.first;
        // if showOnlyfreeMOdels is enabled prefer a free model
        if (settings.openRouterSettings.showOnlyFreeModels) {
          final firstFree =
              availableModels.firstWhereOrNull((e) => e.contains(':free'));
          settings.openRouterSettings.currentModel = firstFree;
        }
      }
      return availableModels;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    }
  }

  List<String> getModels() {
    List<String> models = availableModels;
    if (settings.openRouterSettings.showOnlyFreeModels) {
      models = models.where((e) => e.contains(':free')).toList();
    }
    return models;
  }

  // https://openrouter.ai/docs/limits
  Future<Map<String, dynamic>?> testKey(String key) async {
    try {
      final response = await dio.get('https://openrouter.ai/api/v1/auth/key',
          options: Options(headers: {'Authorization': 'Bearer $key'}));
      Map<String, dynamic>? data = response.data;
      creditsRemaining = data?['data']?['limit_remaining'];
      notifyListeners();
      return data;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    }
  }

  ChatOpenAI? completions({String? overrideModel}) {
    final orSettings = settings.openRouterSettings;
    String? model = overrideModel ?? orSettings.currentModel;
    if (model == null) {
      return null;
    }
    return ChatOpenAI(
        apiKey: orSettings.openRouterKey,
        baseUrl: openRouterEndpoint,
        defaultOptions: ChatOpenAIOptions(model: model));
  }
}
