import 'package:flutter/material.dart';

class AppSession extends ChangeNotifier {
  String username = 'Créateur';

  void updateUsername(String value) {
    username = value;
    notifyListeners();
  }
}
