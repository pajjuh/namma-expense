import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// --- Enums ---

enum TransactionType { income, expense }

enum UserMode { student, professional, homemaker }

enum Mood { happy, neutral, sad }

enum WalletType { cash, upi, card }

enum Period { daily, weekly, monthly, yearly }

enum TransactionOrigin { manual, subscription, rechargeSplit }

enum SubscriptionType { recurring, prepaidRecharge }


// --- Keys for Storage ---
class AppKeys {
  static const String userName = 'userName';
  static const String userCurrency = 'userCurrency';
  static const String userMode = 'userMode';
  static const String isDarkTheme = 'isDarkTheme';
  static const String dailyLimit = 'dailyLimit';
  static const String excludeSubsFromLimit = 'excludeSubsFromLimit';
  static const String walletLock = 'walletLock';
}

// --- Category Data ---

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isCustom;
  final String? iconName;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isCustom = false,
    this.iconName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName ?? 'other',
      'color': color.value,
      'isCustom': isCustom,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: availableIcons[map['iconName']] ?? FontAwesomeIcons.question,
      color: Color(map['color']),
      isCustom: map['isCustom'] ?? true,
      iconName: map['iconName'],
    );
  }
}

// Map of curated icons for custom categories
final Map<String, IconData> availableIcons = {
  'burger': FontAwesomeIcons.burger,
  'bus': FontAwesomeIcons.bus,
  'book': FontAwesomeIcons.book,
  'mobile': FontAwesomeIcons.mobile,
  'gamepad': FontAwesomeIcons.gamepad,
  'utensils': FontAwesomeIcons.utensils,
  'plane': FontAwesomeIcons.plane,
  'gasPump': FontAwesomeIcons.gasPump,
  'fileInvoiceDollar': FontAwesomeIcons.fileInvoiceDollar,
  'chartLine': FontAwesomeIcons.chartLine,
  'bagShopping': FontAwesomeIcons.bagShopping,
  'carrot': FontAwesomeIcons.carrot,
  'lightbulb': FontAwesomeIcons.lightbulb,
  'graduationCap': FontAwesomeIcons.graduationCap,
  'notesMedical': FontAwesomeIcons.notesMedical,
  'broom': FontAwesomeIcons.broom,
  'screwdriverWrench': FontAwesomeIcons.screwdriverWrench,
  'car': FontAwesomeIcons.car,
  'train': FontAwesomeIcons.train,
  'film': FontAwesomeIcons.film,
  'music': FontAwesomeIcons.music,
  'dog': FontAwesomeIcons.dog,
  'cat': FontAwesomeIcons.cat,
  'gift': FontAwesomeIcons.gift,
  'shirt': FontAwesomeIcons.shirt,
  'house': FontAwesomeIcons.house,
  'basketShopping': FontAwesomeIcons.basketShopping,
  'scissors': FontAwesomeIcons.scissors,
  'stethoscope': FontAwesomeIcons.stethoscope,
  'dumbbell': FontAwesomeIcons.dumbbell,
  'mugHot': FontAwesomeIcons.mugHot,
  'beerMugEmpty': FontAwesomeIcons.beerMugEmpty,
  'wifi': FontAwesomeIcons.wifi,
  'tv': FontAwesomeIcons.tv,
  'laptop': FontAwesomeIcons.laptop,
  'phone': FontAwesomeIcons.phone,
  'couch': FontAwesomeIcons.couch,
  'baby': FontAwesomeIcons.baby,
  'planeDeparture': FontAwesomeIcons.planeDeparture,
  'hotel': FontAwesomeIcons.hotel,
  'camera': FontAwesomeIcons.camera,
  'other': FontAwesomeIcons.question,
};

// Default Categories for different Modes

final List<Category> studentCategories = [
  Category(id: 'food', name: 'Food', icon: FontAwesomeIcons.burger, color: Colors.orange),
  Category(id: 'transport', name: 'Transport', icon: FontAwesomeIcons.bus, color: Colors.blue),
  Category(id: 'books', name: 'Books', icon: FontAwesomeIcons.book, color: Colors.brown),
  Category(id: 'recharge', name: 'Recharge', icon: FontAwesomeIcons.mobile, color: Colors.green),
  Category(id: 'entertainment', name: 'Fun', icon: FontAwesomeIcons.gamepad, color: Colors.purple),
  Category(id: 'other', name: 'Other', icon: FontAwesomeIcons.question, color: Colors.grey),
];

final List<Category> professionalCategories = [
  Category(id: 'food', name: 'Dining', icon: FontAwesomeIcons.utensils, color: Colors.orange),
  Category(id: 'travel', name: 'Travel', icon: FontAwesomeIcons.plane, color: Colors.blue),
  Category(id: 'fuel', name: 'Fuel', icon: FontAwesomeIcons.gasPump, color: Colors.redAccent),
  Category(id: 'bills', name: 'Bills', icon: FontAwesomeIcons.fileInvoiceDollar, color: Colors.indigo),
  Category(id: 'investment', name: 'Invest', icon: FontAwesomeIcons.chartLine, color: Colors.green),
  Category(id: 'shopping', name: 'Shopping', icon: FontAwesomeIcons.bagShopping, color: Colors.pink),
];

final List<Category> homemakerCategories = [
  Category(id: 'grocery', name: 'Grocery', icon: FontAwesomeIcons.carrot, color: Colors.green),
  Category(id: 'utilities', name: 'Utilities', icon: FontAwesomeIcons.lightbulb, color: Colors.yellow.shade700),
  Category(id: 'education', name: 'School', icon: FontAwesomeIcons.graduationCap, color: Colors.blue),
  Category(id: 'medical', name: 'Medical', icon: FontAwesomeIcons.notesMedical, color: Colors.red),
  Category(id: 'helper', name: 'Maid/Help', icon: FontAwesomeIcons.broom, color: Colors.teal),
  Category(id: 'maintenance', name: 'Repair', icon: FontAwesomeIcons.screwdriverWrench, color: Colors.grey),
];
