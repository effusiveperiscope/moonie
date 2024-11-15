import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:moonie/settings.dart';

class OpenRouterInterface extends ChangeNotifier {
  final Settings settings;
  OpenRouterInterface(this.settings);

  final dio = Dio();
  List<String> availableModels = [];

  // https://openrouter.ai/docs/quick-start
  static const String openRouterEndpoint = 'https://openrouter.ai/api/v1';

  // https://openrouter.ai/docs/models
  Future<List<String>?> fetchModels() async {
    try {
      final response = await dio.get('https://openrouter.ai/api/v1/models');
      availableModels.clear();
      availableModels =
          response.data['data'].map((e) => e['id']).toList().cast<String>();
      return availableModels;
    } catch (e) {
      return null;
    }
  }

  // https://openrouter.ai/docs/limits
  Future<Map<String, dynamic>?> testKey(String key) async {
    try {
      final response = await dio.get('https://openrouter.ai/api/v1/auth/key',
          options: Options(headers: {'Authorization': 'Bearer $key'}));
      Map<String, dynamic>? data = response.data;
      return data;
    } catch (e) {
      return null;
    }
  }

  OpenAI? completions() {
    if (settings.currentModel == null) {
      return null;
    }
    return OpenAI(
        apiKey: settings.openRouterKey,
        baseUrl: openRouterEndpoint,
        defaultOptions: OpenAIOptions(model: settings.currentModel));
  }
}
