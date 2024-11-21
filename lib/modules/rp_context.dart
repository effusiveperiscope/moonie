import 'package:flutter/material.dart';
import 'package:moonie/core.dart';
import 'package:objectbox/objectbox.dart';

/// Maintains the nodes in active context and disk storage.
/// Also the factory for nodes and attributes.
class RPContext extends ChangeNotifier {
  final MoonieCore core;
  final Store store;
  late final Box<BaseNode> baseNodes;
  late final Box<AttributeComponent> attributes;

  static Future<RPContext> create(MoonieCore core) async {
    final ctx = RPContext(core);
    ctx.baseNodes = ctx.store.box<BaseNode>();
    ctx.attributes = ctx.store.box<AttributeComponent>();
    return ctx;
  }

  RPContext(this.core) : store = core.store;

  BaseNode createNode(
    BaseRole role,
    String name, {
    String description = '',
  }) {
    final node = BaseNode();
    node.setRole(role);
    node.name = name;
    node.description = description;
    node.context = this;
    node.created = DateTime.now();
    node.id = baseNodes.put(node);
    notifyListeners();
    return node;
  }

  void deleteNode(BaseNode node) {
    baseNodes.remove(node.id);
    notifyListeners();
  }

  /// Not to be called directly exccept by BaseNode
  AttributeComponent createAttribute(String name, String content,
      {String description = ''}) {
    final attr = AttributeComponent();
    attr.name = name;
    attr.description = description;
    attr.content = content;
    attr.context = this;
    attr.id = attributes.put(attr);
    return attr;
  }

  // Right now the plan is just to spit the entire graph out into context
  // If we want to look into more sophisticated solutions later,
  // we could look into letting the LLM use some kind of tool to traverse the graph
  // or something
}

enum BaseRole {
  character,
  user,
  world,
  writingRules,
  item,
  extra,
}

const baseRoleNames = {
  BaseRole.character: 'Character',
  BaseRole.user: 'User',
  BaseRole.world: 'World',
  BaseRole.writingRules: 'Writing Rules',
  BaseRole.item: 'Item',
  BaseRole.extra: 'Extra',
};

// Might hold things like RPG stats, not sure
enum SpecialAttributeType { exampleMessages }

/// A base node of the context graph. Typically a character or a world etc.
@Entity()
class BaseNode extends ChangeNotifier {
  int id = 0;

  int role = BaseRole.extra.index;
  String _name = '';
  String _description = '';

  @Property(type: PropertyType.date)
  DateTime? created;
  @Property(type: PropertyType.date)
  DateTime? modified;

  String get name => _name;
  set name(String value) {
    _name = value;
    modified = DateTime.now();
    notifyListeners();
  }

  String get description => _description;
  set description(String value) {
    _description = value;
    modified = DateTime.now();
    notifyListeners();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    context?.baseNodes.put(this);
  }

  @Backlink('baseNodeParent')
  ToMany<AttributeComponent> _attributes = ToMany();

  @Transient()
  RPContext? context;

  List<AttributeComponent> getAttributes() {
    return _attributes.map((e) {
      e.context = context;
      return e;
    }).toList();
  }

  BaseRole getRole() {
    if (role >= BaseRole.values.length) return BaseRole.extra;
    return BaseRole.values[role];
  }

  void setRole(BaseRole r) {
    role = r.index;
  }

  void addAttribute(AttributeComponent attr) {
    attr.context = context;
    _attributes.add(attr);
  }

  void removeAttribute(AttributeComponent attr) {
    _attributes.remove(attr);
  }

  BaseNode();
}

/// An attribute, typically of a base node (can also be a tree structure).
@Entity()
class AttributeComponent extends ChangeNotifier {
  int id = 0;

  String name = '';
  String description = '';
  String content = '';

  @override
  void notifyListeners() {
    super.notifyListeners();
    context?.attributes.put(this);
  }

  ToOne<BaseNode> baseNodeParent = ToOne();
  ToOne<AttributeComponent> parent = ToOne();
  @Backlink('parent')
  ToMany<AttributeComponent> children = ToMany();

  dynamic getParent() {
    final target = parent.target ?? baseNodeParent.target;
    if (target is AttributeComponent) {
      target.context = context;
    } else if (target is BaseNode) {
      target.context = context;
    }
    return target;
  }

  void setParent(dynamic p) {
    if (p is AttributeComponent) {
      parent.target = p;
    } else if (p is BaseNode) {
      baseNodeParent.target = p;
    }
  }

  List<AttributeComponent> getChildren() {
    return children.map((e) {
      e.context = context;
      return e;
    }).toList();
  }

  @Transient()
  RPContext? context;

  AttributeComponent();
}
