import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import 'package:moonie/openrouter.dart';

class BasicChatController extends ChangeNotifier {
  final OpenRouterInterface ori;
  List<Map<String, dynamic>> messages = [];

  BasicChatController(this.ori);

  bool canSend() {
    return ori.completions() != null;
  }

  void sendMessage(String message) async {
    final prompt = PromptTemplate.fromTemplate('{message}');
    final openai = ori.completions()!;
    final chain = prompt | openai | const StringOutputParser();
    final res = await chain.invoke({'message': message});
    print(res);
  }
}

class BasicInputWidget extends StatefulWidget {
  const BasicInputWidget({
    super.key,
  });

  @override
  State<BasicInputWidget> createState() => _BasicInputWidgetState();
}

class _BasicInputWidgetState extends State<BasicInputWidget> {
  TextEditingController textController =
      TextEditingController(text: 'Hello World');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
            child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text("Hi")],
            ),
          ),
        )),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: textController,
          ),
        )
      ],
    );
  }
}
