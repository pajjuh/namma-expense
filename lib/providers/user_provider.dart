import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/constants.dart';

class UserProvider with ChangeNotifier {
  String _userName = '';
  String _currency = '₹';
  UserMode _userMode = UserMode.student;
  bool _isDarkTheme = false;
  double _dailyLimit = 0.0;
  bool _isLoading = true;

  String get userName => _userName;
  String get currency => _currency;
  UserMode get userMode => _userMode;
  bool get isDarkTheme => _isDarkTheme;
  double get dailyLimit => _dailyLimit;
  bool get isLoading => _isLoading;

  List<Category> get categories {
    switch (_userMode) {
      case UserMode.student:
        return studentCategories;
      case UserMode.professional:
        return professionalCategories;
      case UserMode.homemaker:
        return homemakerCategories;
    }
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString(AppKeys.userName) ?? '';
    _currency = prefs.getString(AppKeys.userCurrency) ?? '₹';
    
    // Load Mode
    final modeIndex = prefs.getInt(AppKeys.userMode) ?? 0;
    _userMode = UserMode.values.length > modeIndex 
        ? UserMode.values[modeIndex] 
        : UserMode.student;

    _isDarkTheme = prefs.getBool(AppKeys.isDarkTheme) ?? false;
    _dailyLimit = prefs.getDouble(AppKeys.dailyLimit) ?? 0.0;
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveUser(String name, String currency, UserMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppKeys.userName, name);
    await prefs.setString(AppKeys.userCurrency, currency);
    await prefs.setInt(AppKeys.userMode, mode.index);

    _userName = name;
    _currency = currency;
    _userMode = mode;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppKeys.isDarkTheme, isDark);
    _isDarkTheme = isDark;
    notifyListeners();
  }

  Future<void> setDailyLimit(double limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppKeys.dailyLimit, limit);
    _dailyLimit = limit;
    notifyListeners();
  }
}
