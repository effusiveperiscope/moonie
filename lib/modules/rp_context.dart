import 'package:flutter/material.dart';
import 'package:moonie/core.dart';
import 'package:objectbox/objectbox.dart';

enum BaseRole {
  character,
  user,
  world,
  writingRules,
  extra,
}

@Entity()
class BaseNode extends ChangeNotifier {
  int id = 0;

  int role = BaseRole.extra.index;
  String name = '';
  String description = '';

  @override
  void notifyListeners() {
    super.notifyListeners();
    context?.baseNodes.put(this);
  }

  @Backlink('baseNodeParent')
  ToMany<AttributeComponent> attributes = ToMany();

  @Transient()
  RPContext? context;

  List<AttributeComponent> getAttributes() {
    return attributes.map((e) {
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

  BaseNode();
}

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

class RPContext extends ChangeNotifier {
  final MoonieCore core;
  final Store store;
  late final Box<BaseNode> baseNodes;
  late final Box<AttributeComponent> attributes;

  final List<BaseNode> activeContext = [];

  static Future<RPContext> create(MoonieCore core) async {
    final ctx = RPContext(core);
    ctx.baseNodes = ctx.store.box<BaseNode>();
    ctx.attributes = ctx.store.box<AttributeComponent>();
    return ctx;
  }

  RPContext(this.core) : store = core.store;

  BaseNode createNode(
    BaseRole role,
    String name,
    String description,
  ) {
    final node = BaseNode();
    node.setRole(role);
    node.name = name;
    node.description = description;
    node.context = this;
    return node;
  }
}
