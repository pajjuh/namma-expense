import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/subscription_provider.dart';
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
      ],
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          return MaterialApp(
            title: 'NammaExpense',
            debugShowCheckedModeBanner: false,
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
