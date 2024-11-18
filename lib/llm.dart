import 'package:langchain_openai/langchain_openai.dart';

abstract class OpenAIInterface {
  String? currentModel();
  void setKey(String key);
  void postGenHook(); // Handles things like updating credit limits
  ChatOpenAI? completions({String? overrideModel, double? temperature});
}
