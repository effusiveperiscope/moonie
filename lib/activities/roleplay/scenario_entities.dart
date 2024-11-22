// ignore_for_file: unnecessary_getters_setters

import 'package:flutter/material.dart';
import 'package:moonie/activities/roleplay/chat_entities.dart';
import 'package:moonie/modules/rp_context.dart';
import 'package:moonie/modules/rp_entities.dart';
import 'package:objectbox/objectbox.dart';

Set<String> reservedTags = {'condition', 'messages', 'instructions'};

bool isReservedTag(String tag) => reservedTags.contains(tag);

@Entity()
class NodeSlot extends ChangeNotifier {
  // Owning reference to SlotFill
  int id = 0;

  bool _isStringSlot = false;
  bool _allowsMultiple = false;

  String? _tag; // such as 'character1', 'character2', 'world', 'rules', etc.

  BaseRole _role = BaseRole.extra;

  @Transient()
  RPContext? context;

  final defaultFill = ToOne<SlotFill>();
  String? _defaultStringFill;

  @override
  void notifyListeners() {
    super.notifyListeners();
    context?.slots.put(this);
  }

  // String/node fills should be mutually exclusive
  void setDefaultFill(SlotFill fill) {
    assert(defaultStringFill == null);
    defaultFill.target = fill;
    notifyListeners();
  }

  String? get defaultStringFill => _defaultStringFill;
  set defaultStringFill(String? value) {
    assert(defaultFill.target == null);
    _defaultStringFill = value;
    notifyListeners();
  }

  void resetDefaultFill() {
    defaultFill.target = null;
    defaultStringFill = null;
    notifyListeners();
  }

  bool get isStringSlot => _isStringSlot;
  set isStringSlot(bool value) {
    _isStringSlot = value;
    notifyListeners();
  }

  String? get tag => _tag;
  set tag(String? value) {
    if (_tag != null) {
      //assert(_tag!.contains('.')); // dots are used for accessing attributes
      assert(!isReservedTag(_tag!.trim()));
      // How expansion works: .name, if executed on multiple nodes, makes a comma list
      // .instruction should provide an instruction iff there is a slot fill
      // All this logic will be implemented in RPChat for building prompt
    }
    _tag = value;
    notifyListeners();
  }

  bool get allowsMultiple => _allowsMultiple;
  set allowsMultiple(bool value) {
    _allowsMultiple = value;
    notifyListeners();
  }

  int get role => _role.index;
  set role(int value) {
    _role = BaseRole.values[value];
    notifyListeners();
  }

  dynamic getDefaultFill() {
    if (defaultStringFill != null) {
      return defaultStringFill!;
    }
    if (defaultFill.target != null) {
      return defaultFill.target!..context = context!;
    }
    return null;
  }

  NodeSlot copy() {
    final slot = NodeSlot();
    slot.isStringSlot = isStringSlot;
    slot.allowsMultiple = allowsMultiple;
    slot.tag = tag;
    slot.role = role;
    if (defaultFill.target != null) {
      slot.defaultFill.target = defaultFill.target!.copy();
    }
    slot.defaultStringFill = defaultStringFill;
    slot.context = context!;
    slot.id = context!.slots.put(slot);
    context!.notifyListeners();
    return slot;
  }
}

@Entity()
class SlotFill extends ChangeNotifier {
  // Non-owning references to BaseNode and NodeSlot
  int id = 0;

  @Transient()
  RPContext? context;

  String? _content;

  @override
  void notifyListeners() {
    super.notifyListeners();
    context?.slotFills.put(this);
  }

  final slot = ToOne<NodeSlot>();
  final nodes = ToMany<BaseNode>();

  String? get content => _content;
  set content(String? value) {
    assert(slot.target?.isStringSlot == true);
    _content = value;
    notifyListeners();
  } // only for string fills

  void setNodes(List<BaseNode> nodes) {
    if (slot.target?.allowsMultiple != true) {
      assert(nodes.length == 1);
    }
    this.nodes.addAll(nodes);
    notifyListeners();
  }

  void addNode(BaseNode node) {
    if (slot.target?.allowsMultiple != true) {
      assert(nodes.isEmpty);
    }
    nodes.add(node);
    notifyListeners();
  }

  void removeNode(BaseNode node) {
    nodes.remove(node);
    notifyListeners();
  }

  bool validate() {
    if (slot.target == null) return false; // should always have a slot
    if (slot.target?.isStringSlot == true) {
      return content != null;
    }
    return true;
  }

  SlotFill copy() {
    final newFill = SlotFill()..slot.target = slot.target;
    newFill.content = content;
    newFill.nodes.addAll(nodes);
    newFill.id = 0;
    context!.slotFills.put(newFill);
    return newFill;
  }
}

@Entity()
class Scenario extends ChangeNotifier {
  // Owning references to NodeSlot and RPChat
  int id = 0;

  String _name = '';
  String? _description;
  String? _imagePath;

  @Property(type: PropertyType.date)
  DateTime? created;
  @Property(type: PropertyType.date)
  DateTime? modified;

  @override
  void notifyListeners() {
    super.notifyListeners();
    context?.scenarios.put(this);
  }

  String get name => _name;
  set name(String value) {
    _name = value;
  }

  void setName(String value) {
    _name = value;
    modified = DateTime.now();
    notifyListeners();
  }

  String? get description => _description;
  set description(String? value) {
    _description = value;
  }

  void setDescription(String? value) {
    _description = value;
    modified = DateTime.now();
    notifyListeners();
  }

  String? get imagePath => _imagePath;
  set imagePath(String? value) {
    _imagePath = value;
  }

  void setImagePath(String? value) {
    _imagePath = value;
    modified = DateTime.now();
    notifyListeners();
  }

  final slots = ToMany<NodeSlot>();
  final chats = ToMany<RPChat>();

  bool testSlot(String tag) => slots.any((slot) => slot.tag == tag);

  NodeSlot createSlot(String tag, BaseRole role,
      {bool isStringSlot = false, bool allowsMultiple = false}) {
    assert(!testSlot(tag)); // can't have two slots with the same tag
    final slot = NodeSlot();
    slot.tag = tag;
    slot.role = role.index;
    slot.isStringSlot = isStringSlot;
    slot.allowsMultiple = allowsMultiple;
    slot.context = context!;
    slot.id = context!.slots.put(slot);
    slots.add(slot);
    notifyListeners();
    return slot;
  }

  @Transient()
  RPContext? context;

  RPChat createChat() {
    final chat = RPChat();
    chat.created = DateTime.now();
    chat.context = context!;
    chat.id = context!.chats.put(chat);
    chat.scenario.target = this;
    chats.add(chat);
    notifyListeners();
    return chat;
  }

  Scenario copy() {
    final scenario = Scenario();
    scenario.name = name;
    scenario.description = description;
    scenario.imagePath = imagePath;
    scenario.created = DateTime.now();
    scenario.modified = modified;
    scenario.slots.addAll(slots.map((e) => e.copy()));
    scenario.chats.addAll(chats.map((e) => e.copy()));
    scenario.context = context!;
    scenario.id = context!.scenarios.put(scenario);
    context!.notifyListeners();
    return scenario;
  }

  // Probably make this more sophisticated later
  static const String basePrompt = '''
You are engaging in an interactive roleplay scenario with the user, {user}. 

Scenario details:
- Premise: {premise}
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
