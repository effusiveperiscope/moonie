import 'package:flutter/material.dart';
import 'package:moonie/activities/roleplay/chat_entities.dart';
import 'package:moonie/modules/rp_context.dart';
import 'package:moonie/modules/rp_entities.dart';
import 'package:objectbox/objectbox.dart';
import 'package:collection/collection.dart';

@Entity()
class Scenario extends ChangeNotifier {
  int id = 0;

  String? _name;
  String? _description;
  String? _imagePath;

  @Property(type: PropertyType.date)
  DateTime? created;
  @Property(type: PropertyType.date)
  DateTime? modified;

  @override
  void notifyListeners() {
    super.notifyListeners();
    modified = DateTime.now();
    context?.scenarios.put(this);
  }

  String? get name => _name;
  set name(String? value) {
    _name = value;
    notifyListeners();
  }

  String? get description => _description;
  set description(String? value) {
    _description = value;
    notifyListeners();
  }

  String? get imagePath => _imagePath;
  set imagePath(String? value) {
    _imagePath = value;
    notifyListeners();
  }

  // Danger: This is a non-owning (shared) reference
  final nodes = ToMany<BaseNode>();
  final chats = ToMany<RPChat>();

  @Transient()
  RPContext? context;

  RPChat createChat() {
    final chat = RPChat();
    chat.created = DateTime.now();
    chat.context = context!;
    chat.id = context!.chats.put(chat);
    chats.add(chat);
    notifyListeners();
    return chat;
  }

  List<BaseNode> get nodesList =>
      nodes.map((e) => e..context = context).toList();

  // Probably make this more sophisticated later
  String basePrompt() {
    return '''
You are engaging in an interactive roleplay scenario with the user, {user}. 

Scenario details:
- Primary characters (key participants): {character}.
- Character info: {character_content}
- User info: {user_content}
- World info: {world_content}

Current conversation:
<messages> 
{messages}
</messages>

<instructions>
- Continue the roleplay naturally, staying in character based on the provided context.
- Maintain the tone and pacing of the previous messages.
- Additional rules: {rules_content}

In plaintext, write your next response to progress the roleplay.
</instructions>
''';
  }

  String formatBasePrompt(List<RPChatMessage> messages) {
    // Right now we'll assume:
    // - Multiple characters possible
    // - Only one user
    // - Only one world
    // - Multiple rules

    var characterNodes =
        nodesList.where((n) => n.role == BaseRole.character.index);
    var userNode =
        nodesList.firstWhereOrNull((n) => n.role == BaseRole.user.index);
    var worldNode =
        nodesList.firstWhereOrNull((n) => n.role == BaseRole.world.index);
    var rulesNodes =
        nodesList.where((n) => n.role == BaseRole.writingRules.index);

    var characterNames = characterNodes.map((n) => n.name).join(', ');

    return basePrompt()
      ..replaceAll('{user}', userNode?.name ?? 'User')
      ..replaceAll('{character}', characterNames)
      ..replaceAll('{character_content}',
          characterNodes.map((n) => n.toXML()).join('\n'))
      ..replaceAll('{user_content}', userNode?.toXML() ?? '')
      ..replaceAll('{world_content}', worldNode?.toXML() ?? '')
      ..replaceAll(
          '{rules_content}', rulesNodes.map((n) => n.toXML()).join('\n'))
      ..replaceAll('{messages}', messages.map((m) => m.toXML()).join('\n'));
  }
}
