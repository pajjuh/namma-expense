import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/user_provider.dart';
import '../helpers/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  String _selectedCurrency = '₹';
  UserMode _selectedMode = UserMode.student;
  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Provider.of<UserProvider>(context, listen: false).saveUser(
        _nameController.text,
        _selectedCurrency,
        _selectedMode,
      );
      // Main.dart will automatically switch to Dashboard
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final logoSize = screenWidth * 0.3; // 30% of screen width
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: screenHeight * 0.02,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - screenHeight * 0.04),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: screenHeight * 0.04),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(screenWidth * 0.05),
                            child: Image.asset(
                              'assets/applogo.jpg',
                              width: logoSize,
                              height: logoSize,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback icon if image fails to load
                                return Container(
                                  width: logoSize,
                                  height: logoSize,
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.shade100,
                                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                                  ),
                                  child: Icon(
                                    Icons.wallet,
                                    size: logoSize * 0.5,
                                    color: Colors.deepPurple,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Welcome to NammaExpense',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          "Let's set up your profile.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        SizedBox(height: screenHeight * 0.05),
                        
                        // Name Input
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'What should we call you?',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        
                        // Currency Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedCurrency,
                          decoration: const InputDecoration(
                            labelText: 'Preferred Currency',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.currency_exchange),
                          ),
                          items: ['₹', '\$', '€', '£'].map((currency) {
                            return DropdownMenuItem(
                              value: currency,
                              child: Text(currency),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedCurrency = val!),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        
                        // Mode Selection
                        Text(
                          'Choose your Mode',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Row(
                          children: [
                            _buildModeCard(UserMode.student, 'Student', FontAwesomeIcons.graduationCap, screenWidth),
                            SizedBox(width: screenWidth * 0.02),
                            _buildModeCard(UserMode.professional, 'Pro', FontAwesomeIcons.briefcase, screenWidth),
                            SizedBox(width: screenWidth * 0.02),
                            _buildModeCard(UserMode.homemaker, 'Home', FontAwesomeIcons.houseUser, screenWidth),
                          ],
                        ),
                        
                        // Spacer to push button to bottom when space available
                        const Spacer(),
                        SizedBox(height: screenHeight * 0.03),
                        
                        FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                          ),
                          child: Text(
                            'Get Started', 
                            style: TextStyle(fontSize: screenWidth * 0.045),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModeCard(UserMode mode, String label, IconData icon, double screenWidth) {
    final isSelected = _selectedMode == mode;
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMode = mode),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.04),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                size: screenWidth * 0.06,
              ),
              SizedBox(height: screenWidth * 0.02),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.035,
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
