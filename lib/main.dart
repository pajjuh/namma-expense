import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/sms_provider.dart';
import 'providers/locale_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nammaexpense/l10n/app_localizations.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NammaExpenseApp());
}

class NammaExpenseApp extends StatelessWidget {
  const NammaExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUserData()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()..fetchTransactions()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()..fetchSubscriptions()),
        ChangeNotifierProvider(create: (_) => SmsProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer2<UserProvider, LocaleProvider>(
        builder: (context, userProvider, localeProvider, child) {
          if (userProvider.isLoading) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          return MaterialApp(
            title: 'NammaExpense',
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('kn'),
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: userProvider.isDarkTheme ? Brightness.dark : Brightness.light,
              ),
              useMaterial3: true,
              textTheme: GoogleFonts.outfitTextTheme().apply(
                bodyColor: userProvider.isDarkTheme ? Colors.white : Colors.black87,
                displayColor: userProvider.isDarkTheme ? Colors.white : Colors.black87,
              ),
            ),
            home: userProvider.userName.isEmpty
                ? const OnboardingScreen()
                : const DashboardScreen(),
          );
        },
      ),
    );
  }
}
