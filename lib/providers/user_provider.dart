import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/constants.dart';

class UserProvider with ChangeNotifier {
  String _userName = '';
  String _currency = '₹';
  UserMode _userMode = UserMode.student;
  bool _isDarkTheme = false;
  double _dailyLimit = 0.0;
  bool _excludeSubsFromDailyLimit = false;
  bool _isLoading = true;

  String get userName => _userName;
  String get currency => _currency;
  UserMode get userMode => _userMode;
  bool get isDarkTheme => _isDarkTheme;
  double get dailyLimit => _dailyLimit;
  bool get excludeSubsFromDailyLimit => _excludeSubsFromDailyLimit;
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
    _excludeSubsFromDailyLimit = prefs.getBool(AppKeys.excludeSubsFromLimit) ?? false;
    
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

  Future<void> toggleExcludeSubs(bool exclude) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppKeys.excludeSubsFromLimit, exclude);
    _excludeSubsFromDailyLimit = exclude;
    notifyListeners();
  }

  // --- Backup & Restore ---

  Map<String, dynamic> exportSettings() {
    return {
      AppKeys.userName: _userName,
      AppKeys.userCurrency: _currency,
      AppKeys.userMode: _userMode.index,
      AppKeys.isDarkTheme: _isDarkTheme,
      AppKeys.dailyLimit: _dailyLimit,
      AppKeys.excludeSubsFromLimit: _excludeSubsFromDailyLimit,
    };
  }

  Future<void> importSettings(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (data.containsKey(AppKeys.userName)) {
      _userName = data[AppKeys.userName];
      await prefs.setString(AppKeys.userName, _userName);
    }
    
    if (data.containsKey(AppKeys.userCurrency)) {
      _currency = data[AppKeys.userCurrency];
      await prefs.setString(AppKeys.userCurrency, _currency);
    }
    
    if (data.containsKey(AppKeys.userMode)) {
      final modeIndex = data[AppKeys.userMode];
      _userMode = UserMode.values.length > modeIndex ? UserMode.values[modeIndex] : UserMode.student;
      await prefs.setInt(AppKeys.userMode, _userMode.index);
    }
    
    if (data.containsKey(AppKeys.isDarkTheme)) {
      _isDarkTheme = data[AppKeys.isDarkTheme];
      await prefs.setBool(AppKeys.isDarkTheme, _isDarkTheme);
    }
    
    if (data.containsKey(AppKeys.dailyLimit)) {
      _dailyLimit = (data[AppKeys.dailyLimit] as num).toDouble();
      await prefs.setDouble(AppKeys.dailyLimit, _dailyLimit);
    }

    if (data.containsKey(AppKeys.excludeSubsFromLimit)) {
      _excludeSubsFromDailyLimit = data[AppKeys.excludeSubsFromLimit];
      await prefs.setBool(AppKeys.excludeSubsFromLimit, _excludeSubsFromDailyLimit);
    }

    notifyListeners();
  }
}
