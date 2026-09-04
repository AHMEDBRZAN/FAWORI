import 'package:flutter/material.dart';

class Favorites extends ChangeNotifier {
  final Set<String> _ids = {};
  bool contains(String id) => _ids.contains(id);
  void toggle(String id) {
    _ids.contains(id) ? _ids.remove(id) : _ids.add(id);
    notifyListeners();
  }
}
