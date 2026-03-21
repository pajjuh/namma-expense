// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Namma Expense';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get transactions => 'Transactions';

  @override
  String get stats => 'Stats';

  @override
  String get psychology => 'Psychology';

  @override
  String get settings => 'Settings';

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get viewAll => 'View All';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get quickAdd => 'Quick Add';

  @override
  String get bulkAdd => 'Bulk Add';

  @override
  String get amount => 'Amount';

  @override
  String get title => 'Title';

  @override
  String get category => 'Category';

  @override
  String get wallet => 'Wallet';

  @override
  String get date => 'Date';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get manageCategories => 'Manage Categories';

  @override
  String get newCategory => 'New Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get language => 'Language';

  @override
  String get manualAdd => 'Manual Add';

  @override
  String get voiceAdd => 'Voice Add';

  @override
  String get subs => 'Subs';

  @override
  String get editTransaction => 'Edit Transaction';

  @override
  String get requiredField => 'Required';

  @override
  String get invalidNumber => 'Invalid Number';

  @override
  String get titleHint => 'e.g. Lunch, Salary';

  @override
  String get more => 'More...';

  @override
  String get howDidYouFeel => 'How did you feel?';

  @override
  String get updateTransaction => 'Update Transaction';

  @override
  String get saveTransaction => 'Save Transaction';

  @override
  String get allCategories => 'All Categories';

  @override
  String get categoryRequired => 'Please select a category';

  @override
  String get categoryName => 'Category Name';

  @override
  String get selectColor => 'Select Color';

  @override
  String get selectIcon => 'Select Icon';

  @override
  String get enterName => 'Please enter a name';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get createCategory => 'Create Category';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String get deleteCategoryWarning =>
      'Are you sure you want to delete this custom category? Transactions using this category may display incorrectly.';

  @override
  String get delete => 'Delete';

  @override
  String get defaultCategoriesWarning =>
      'Default categories cannot be modified';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get enableDarkTheme => 'Enable dark theme';

  @override
  String get budget => 'Budget';

  @override
  String get dailyLimitStr => 'Daily Spending Limit';

  @override
  String get dailyLimitSaved => 'Daily limit saved!';

  @override
  String get dailyLimitWarningText =>
      'You will see a warning when you exceed this limit.';

  @override
  String get excludeSubs => 'Exclude Subscriptions & Recharges';

  @override
  String get excludeSubsDesc =>
      'Do not let recurring/generated bills trip the daily limit warning.';

  @override
  String get preferences => 'Preferences';

  @override
  String get manageCategoriesDesc => 'Add, edit, or delete custom categories';

  @override
  String get userMode => 'User Mode';
}
