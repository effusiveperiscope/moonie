import 'package:flutter/material.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:moonie/core.dart';

abstract class LLMInterface {
  String? currentModel();
  void setKey(String key);
  void postGenHook(); // Handles things like updating credit limits
  ChatOpenAI? completions(
      {String? overrideModel,
      double? temperature,
      ChatOpenAIResponseFormat? responseFormat});
  Widget infoWidget(MoonieCore core);
}

enum LLMInterfaceType { openrouter, openai }
