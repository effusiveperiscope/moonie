import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import 'package:moonie/activities/roleplay/scenario_entities.dart';
import 'package:moonie/modules/rp_context.dart';
import 'package:moonie/modules/rp_entities.dart';
import 'package:moonie/utils.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class RPChat extends ChangeNotifier {
  // Owning references to SlotFill and RPChatMessage
  // Non-owning reference to Scenario
  int id = 0;
  @Transient()
  RPContext? context;

  @Property(type: PropertyType.date)
  DateTime? created;
  DateTime? modified;

  @override
  void notifyListeners() {
    super.notifyListeners();
    context?.chats.put(this);
  }

  @Backlink('chat')
  final messages = ToMany<RPChatMessage>();
  final scenario = ToOne<Scenario>();
  final fills = ToMany<SlotFill>();

  SlotFill createFill(NodeSlot slot, {List<BaseNode>? nodes, String? content}) {
    final fill = SlotFill()..slot.target = slot;
    fill.nodes.addAll(nodes ?? []);
    fill.content = content;
    fill.context = context!;
    modified = DateTime.now();
    context!.slotFills.put(fill);
    return fill;
  }

  List<SlotFill> getFills() {
    return fills.map((m) => m..context = context!).toList();
  }

  RPChatMessage createMessage(
    ChatMessageType type,
    String text,
    String? model,
  ) {
    final mes = RPChatMessage()..chat.target = this;
    mes.type = type.index;
    mes.text = text;
    mes.model = model;
    mes.context = context!;
    mes.id = context!.chatMessages.put(mes);
    modified = DateTime.now();
    notifyListeners();
    return mes;
  }

  void deleteMessage(RPChatMessage mes) {
    messages.remove(mes);
    modified = DateTime.now();
    notifyListeners();
    context!.chatMessages.remove(mes.id);
  }

  List<RPChatMessage> getMessages() {
    return messages.map((m) => RPChatMessage()..chat.target = this).toList();
  }

  RPChat copy() {
    final chat = RPChat()..context = context!;
    chat.created = DateTime.now();
    chat.messages.addAll(getMessages().map((e) => e.copy()));
    chat.scenario.target = scenario.target;
    chat.fills.addAll(getFills().map((e) => e.copy()));
    chat.id = context!.chats.put(chat);
    return chat;
  }
}

@Entity()
class RPChatMessage extends ChangeNotifier {
  // Non-owning reference to RPChat
  int id = 0;
  ChatMessageType _type = ChatMessageType.human;
  String _text = '';
  bool _complete = false;

  String? _model;
  String? _imageFile;
  String? _imageBase64;

  final chat = ToOne<RPChat>();

  @override
  void notifyListeners() {
    super.notifyListeners();
    context?.chatMessages.put(this);
  }

  int get type => _type.index;
  set type(int value) {
    _type = ChatMessageType.values[value];
    notifyListeners();
  }

  String get text => _text;
  set text(String value) {
    _text = value;
    notifyListeners();
  }

  bool get complete => _complete;
  set complete(bool value) {
    _complete = value;
    notifyListeners();
  }

  String? get model => _model;
  set model(String? value) {
    _model = value;
    notifyListeners();
  }

  String? get imageFile => _imageFile;
  set imageFile(String? value) {
    _imageFile = value;
    notifyListeners();
  }

  String? get imageBase64 => _imageBase64;
  set imageBase64(String? value) {
    _imageBase64 = value;
    notifyListeners();
  }

  RPChat getChat() {
    return chat.target!..context = context!;
  }

  @Transient()
  RPContext? context;

  RPChatMessage();

  // factory
  static RPChatMessage ephemeral({
    ChatMessageType type = ChatMessageType.ai,
    String text = '',
    String? imageFile,
  }) {
    RPChatMessage mes = RPChatMessage();
    mes.type = type.index;
    mes.text = text;
    mes.imageFile = imageFile;
    mes.prepareImage();
    return mes;
  }

  void prepareImage() {
    if (imageFile != null) {
      imageBase64 = base64.encode(File(imageFile!).readAsBytesSync());
    }
  }

  ChatMessage message() {
    switch (_type) {
      case ChatMessageType.ai:
        return ChatMessage.ai(text);
      case ChatMessageType.human:
        return ChatMessage.human(ChatMessageContent.multiModal([
          ChatMessageContent.text(text),
          if (imageFile != null)
            ChatMessageContent.image(
                mimeType: imageMimeFromFilePath(imageFile!),
                data: imageBase64!),
        ]));
      case ChatMessageType.system:
        return ChatMessage.system(text);
      default:
        return ChatMessage.human(ChatMessageContent.text(text));
    }
  }

  String name({bool showModel = false}) {
    switch (_type) {
      case ChatMessageType.ai:
        if (showModel) {
          return 'AI ($model)';
        } else {
          return 'AI';
        }
      case ChatMessageType.human:
        return 'You';
      case ChatMessageType.system:
        return 'System';
      default:
        return 'Unknown';
    }
  }

  String toXML() {
    final xml = StringBuffer();
    xml.writeln('<message name="${name(showModel: false)}" type="$type">');
    xml.writeln('\t$text');
    xml.writeln('</message>');
    return xml.toString();
  }

  String toPlainText() {
    return '${name(showModel: false)}: $text';
  }

  RPChatMessage copy() {
    final mes = RPChatMessage();
    mes.type = type;
    mes.text = text;
    mes.complete = complete;
    mes.model = model;
    mes.chat.target = chat.target;
    mes.imageFile = imageFile;
    mes.imageBase64 = imageBase64;
    mes.id = 0;
    context!.chatMessages.put(mes);
    return mes;
  }
}
