import 'dart:convert';
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
  bool _showFloatingInsights = true;
  bool _isLoading = true;
  bool _hasSeenGuide = false;
  int _startOfWeek = 1; // 1 = Monday
  int _startOfMonth = 1; // 1 = 1st of month
  int _startOfYearMonth = 1; // 1 = January
  List<Category> _customCategories = [];

  String get userName => _userName;
  String get currency => _currency;
  UserMode get userMode => _userMode;
  bool get isDarkTheme => _isDarkTheme;
  double get dailyLimit => _dailyLimit;
  bool get excludeSubsFromDailyLimit => _excludeSubsFromDailyLimit;
  bool get showFloatingInsights => _showFloatingInsights;
  bool get isLoading => _isLoading;
  bool get hasSeenGuide => _hasSeenGuide;
  int get startOfWeek => _startOfWeek;
  int get startOfMonth => _startOfMonth;
  int get startOfYearMonth => _startOfYearMonth;

  List<Category> get categories {
    List<Category> base;
    switch (_userMode) {
      case UserMode.student:
        base = studentCategories;
        break;
      case UserMode.professional:
        base = professionalCategories;
        break;
      case UserMode.homemaker:
        base = homemakerCategories;
        break;
    }
    return [...base, ..._customCategories];
  }

  List<Category> get customCategories => _customCategories;

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
    _showFloatingInsights = prefs.getBool('show_floating_insights') ?? true;
    _hasSeenGuide = prefs.getBool('has_seen_guide') ?? false;
    _startOfWeek = prefs.getInt('start_of_week') ?? 1;
    _startOfMonth = prefs.getInt('start_of_month') ?? 1;
    _startOfYearMonth = prefs.getInt('start_of_year_month') ?? 1;
    
    final customCatsStr = prefs.getStringList('custom_categories') ?? [];
    importCustomCategories(customCatsStr);
    
    _isLoading = false;
    notifyListeners();
  }

  void importCustomCategories(List<String> jsonList) {
    try {
      _customCategories = jsonList.map((str) => Category.fromMap(jsonDecode(str))).toList();
    } catch (e) {
      _customCategories = [];
    }
  }

  Future<void> _saveCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _customCategories.map((c) => jsonEncode(c.toMap())).toList();
    await prefs.setStringList('custom_categories', jsonList);
  }

  Future<void> addCustomCategory(Category category) async {
    _customCategories.add(category);
    await _saveCustomCategories();
    notifyListeners();
  }

  Future<void> updateCustomCategory(Category category) async {
    final index = _customCategories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _customCategories[index] = category;
      await _saveCustomCategories();
      notifyListeners();
    }
  }

  Future<void> deleteCustomCategory(String id) async {
    _customCategories.removeWhere((c) => c.id == id);
    await _saveCustomCategories();
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

  Future<void> toggleFloatingInsights(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_floating_insights', show);
    _showFloatingInsights = show;
    notifyListeners();
  }

  Future<void> markGuideSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_guide', true);
    _hasSeenGuide = true;
    notifyListeners();
  }

  Future<void> setStartOfWeek(int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('start_of_week', day);
    _startOfWeek = day;
    notifyListeners();
  }

  Future<void> setStartOfMonth(int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('start_of_month', day);
    _startOfMonth = day;
    notifyListeners();
  }

  Future<void> setStartOfYearMonth(int month) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('start_of_year_month', month);
    _startOfYearMonth = month;
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
      'start_of_week': _startOfWeek,
      'start_of_month': _startOfMonth,
      'start_of_year_month': _startOfYearMonth,
      'custom_categories': _customCategories.map((c) => jsonEncode(c.toMap())).toList(),
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
    
    if (data.containsKey('start_of_week')) {
      _startOfWeek = data['start_of_week'];
      await prefs.setInt('start_of_week', _startOfWeek);
    }
    
    if (data.containsKey('start_of_month')) {
      _startOfMonth = data['start_of_month'];
      await prefs.setInt('start_of_month', _startOfMonth);
    }
    
    if (data.containsKey('start_of_year_month')) {
      _startOfYearMonth = data['start_of_year_month'];
      await prefs.setInt('start_of_year_month', _startOfYearMonth);
    }
    
    if (data.containsKey('custom_categories')) {
      final list = (data['custom_categories'] as List).cast<String>();
      importCustomCategories(list);
      await prefs.setStringList('custom_categories', list);
    }

    notifyListeners();
  }
}
