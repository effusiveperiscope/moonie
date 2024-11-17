import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import 'package:moonie/activities/2_chat.dart';
import 'package:dio/dio.dart';
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:moonie/activities/activity.dart';
import 'package:moonie/core.dart';
import 'package:moonie/utils.dart';

// Testing retrieval of information from a webpage and subsequent interaction
class WebpageToKnowledgeBaseController extends Chat2Controller {
  String _pageUrl = '';
  String _targetTopic = '';
  String pageContents = '';

  String get pageUrl => _pageUrl;
  set pageUrl(String value) {
    _pageUrl = value;
    notifyListeners();
  }

  String get targetTopic => _targetTopic;
  set targetTopic(String value) {
    _targetTopic = value;
    notifyListeners();
  }

  WebpageToKnowledgeBaseController(super.openRouterInterface);

  @override
  buildPrompt() async {
    final prompt = ChatPromptTemplate.fromPromptMessages([
      SystemChatMessagePromptTemplate.fromTemplate(
          'You are an assistant that obtains knowledge from a webpage whose contents are: {pageContents}'),
      SystemChatMessagePromptTemplate.fromTemplate(
          '''Please extract information from the webpage about the following topic: {targetTopic}
          In particular if the webpage is about a person or character, collect information on that person/character.
          ''')
    ]).formatMessages(
        {'pageContents': pageContents, 'targetTopic': targetTopic});
    return PromptValue.chat(
        [...prompt, ...(messages.map((e) => e.message()).toList())]);
  }

  @override
  bool canSend() {
    return ori.completions() != null && pageContents.isNotEmpty;
  }

  Future<void> start() async {
    if (pageUrl.isEmpty) {
      error('Please enter a URL');
      return;
    }

    busy = true;
    final dio = Dio();
    final response = dio.get(_pageUrl);
    final rawPage = (await response).data as String;
    pageContents = cleanPlainText(cleanHtml(rawPage));
    messages.clear();
    notifyListeners();

    final chain = buildChain();
    final res = await invoke(chain, await buildPrompt());
    if (res == 1) {
      error('Request cancelled');
      return;
    }
    error('');

    busy = false;
  }
}

class WebpageToKnowledgeBase extends ActivityWidget {
  const WebpageToKnowledgeBase({super.key, required super.core})
      : super(
            name: "Webpage to knowledge base",
            description: "Obtain information from a webpage");

  @override
  State<WebpageToKnowledgeBase> createState() => _WebpageToKnowledgeBaseState();
}

class _WebpageToKnowledgeBaseState extends State<WebpageToKnowledgeBase> {
  late WebpageToKnowledgeBaseController controller;
  TextEditingController urlController = TextEditingController();
  TextEditingController topicController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller =
        WebpageToKnowledgeBaseController(widget.core.openRouterInterface);
  }

  @override
  void dispose() {
    super.dispose();
    urlController.dispose();
    topicController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle inputStyle = TextStyle(fontSize: 12.0);
    return Chat2Widget(
      core: widget.core,
      controller: controller,
      children: [
        Card(
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                      labelText: 'Page URL', border: OutlineInputBorder()),
                  style: inputStyle,
                  onChanged: (value) {
                    setState(() {
                      controller.pageUrl = value;
                    });
                  },
                ))),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: topicController,
                      decoration: const InputDecoration(
                          labelText: 'Topic', border: OutlineInputBorder()),
                      style: inputStyle,
                      onChanged: (value) {
                        setState(() {
                          controller.targetTopic = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8.0),
                    IconButton.outlined(
                      onPressed: () {
                        controller.start();
                      },
                      icon: const Icon(Icons.send),
                      visualDensity: VisualDensity.compact,
                    )
                  ],
                ))),
      ],
    );
  }
}
