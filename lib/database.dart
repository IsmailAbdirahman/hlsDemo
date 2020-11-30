import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Database extends ChangeNotifier {


  Set<String> videoName;

  Future saveVideoName(String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(name, name);
    notifyListeners();
  }

  getVideoName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    videoName = prefs.getKeys();
    notifyListeners();
  }
}
