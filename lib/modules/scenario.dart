import 'package:flutter/material.dart';
import 'package:moonie/modules/rp_context.dart';
import 'package:moonie/modules/rp_entities.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Scenario extends ChangeNotifier {
  String? _name;
  String? _description;
  String? _imagePath;

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

  final nodes = ToMany<BaseNode>();
}
