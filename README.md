# NammaExpense 💰
> *Smart, Context-Aware Expense Tracker for Digital India*

**NammaExpense** (My Expense) is a modern, intuitive Flutter application designed to make personal finance management effortless. It goes far beyond standard transaction logging by offering intelligent, context-aware suggestions, custom categories, native dashboard widgets, and deep visual insights into your spending habits.

## ✨ Key Features

### 🚀 Phase 1: Core Fundamentals
*   **Transactions**: Log Income and Expenses cleanly with full granular control (Categories, Wallets, Mood, Date).
*   **Customization**: Create **Custom Categories** natively with over 40 distinct icons and 20 base colors stored via local JSON without schema bloat.
*   **Profile Modes**: Tailored environments for **Students** and **Professionals** that automatically load targeted default categories.
*   **Local Storage**: Secure, 100% offline-first architecture using `SQLite` and `SharedPreferences`.

### 📊 Phase 2: Analytics & Limits
*   **Visual Stats**: Interactive Doughnut Charts that strictly match customized category colors for immediate visual recognition.
*   **Time Filters**: Slice data flawlessly between Daily, Weekly, and Monthly breakdowns.
*   **Subscription & Recharge Manager**: Track recurring payments. Specially handles multi-month recharge logic strictly based on exact validity days rather than generic monthly cycles.
*   **Android Homescreen Widget**: A dynamic, native Android widget bridging into Flutter that automatically resizes to compact 2x2 squares, horizontal 1x2 banners, or large interactive panels.
*   **Themes**: Deeply integrated Dark, Light, and System modes following Material 3 guidelines.

### 🧠 Phase 3: Advanced Intelligence & Entry Streams
*   **Context-Aware Quick Add**: Rapid-entry FAB sheet dynamically suggests the most relevant categories based strictly on the current **Time of Day** (e.g., Breakfast vs. Dinner) and **Weekend state**.
*   **Clipboard SMS Parsing**: Instantly scans your clipboard for bank/SMS transaction strings and automatically extracts the spent amount. 
*   **Voice Inputs**: Tap the mic and simply say *"Spent 500 on lunch"* to instantly populate a transaction via Speech-to-Text inference.
*   **Bulk Add**: A powerful, spreadsheet-style spreadsheet interface enabling you to input numerous distinct transactions at once seamlessly.

## 🛠️ Tech Stack
*   **Framework**: Flutter & Dart (3.9.0+)
*   **State Management**: `Provider`
*   **Persistence**: `sqflite` (relational data) & `shared_preferences` (settings/categories config)
*   **Charts**: `fl_chart`, `flutter_heatmap_calendar`
*   **Voice**: `speech_to_text`
*   **Native Embeds**: Android Kotlin/XML (Widgets)

## 📦 Installation
Download the latest APK file directly from **Releases**.

To run from source:
1.  Clone the repository:
    ```bash
    git clone https://github.com/yourusername/NammaExpense.git
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Execute (A physical device is recommended for Voice & Widget support):
    ```bash
    flutter run
    ```

## 🤝 Contributing
Contributions are absolutely welcome! Please open an issue or submit a Pull Request.

---
*Made with ❤️ using Flutter*
