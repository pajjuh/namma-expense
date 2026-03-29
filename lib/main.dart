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
import 'screens/quick_guide_screen.dart';

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

          Widget home;
          if (userProvider.userName.isEmpty) {
            home = const OnboardingScreen();
          } else if (!userProvider.hasSeenGuide) {
            home = const _FirstTimeGuideWrapper();
          } else {
            home = const DashboardScreen();
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
            home: home,
          );
        },
      ),
    );
  }
}

/// Wrapper that shows the Quick Guide once, then marks it seen and goes to Dashboard.
class _FirstTimeGuideWrapper extends StatefulWidget {
  const _FirstTimeGuideWrapper();

  @override
  State<_FirstTimeGuideWrapper> createState() => _FirstTimeGuideWrapperState();
}

class _FirstTimeGuideWrapperState extends State<_FirstTimeGuideWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QuickGuideScreen()),
      ).then((_) {
        Provider.of<UserProvider>(context, listen: false).markGuideSeen();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const DashboardScreen();
  }
}
