import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dashboard.dart';

class PersonalWelcomeFlow extends StatefulWidget {
  const PersonalWelcomeFlow({super.key});

  @override
  State<PersonalWelcomeFlow> createState() => _PersonalWelcomeFlowState();
}

class _PersonalWelcomeFlowState extends State<PersonalWelcomeFlow> {
  int _currentStep = 0;
  bool _started = false;

  final List<Widget> _steps = [];

  final Color bgColor = const Color(0xFF4B2E2B); // Dark chocolate brown
  final Color accentColor = const Color(0xFF2F4F2F); // Forest green

  @override
  void initState() {
    super.initState();
    checkToken();

    _steps.addAll([
      SignupStep(onNext: _nextStep),
      AccountLinkingStep(onNext: _nextStep),
      BudgetCategoriesStep(onNext: _nextStep),
      SavingsGoalsStep(onNext: _completeOnboarding),
    ]);
  }

  Future<void> checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('personal_token');
    if (token != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  void _startOnboarding() {
    setState(() {
      _started = true;
      _currentStep = 0;
    });
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      final response = await http.post(Uri.parse('http://localhost:5050/users/personal/init'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('personal_token', token);
      }
    } catch (e) {
      print('Error initializing personal user: $e');
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: ElevatedButton(
            onPressed: _startOnboarding,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: bgColor,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Get Started', style: TextStyle(fontSize: 18)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _steps.length,
                backgroundColor: bgColor.withOpacity(0.5),
                color: accentColor,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _steps[_currentStep]),
          ],
        ),
      ),
    );
  }
}

// ------------------------- Placeholder steps -------------------------
class SignupStep extends StatelessWidget {
  final VoidCallback? onNext;
  const SignupStep({super.key, this.onNext});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onNext,
        child: const Text('Next: Signup Placeholder'),
      ),
    );
  }
}

class AccountLinkingStep extends StatelessWidget {
  final VoidCallback? onNext;
  const AccountLinkingStep({super.key, this.onNext});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onNext,
        child: const Text('Next: Account Linking Placeholder'),
      ),
    );
  }
}

class BudgetCategoriesStep extends StatelessWidget {
  final VoidCallback? onNext;
  const BudgetCategoriesStep({super.key, this.onNext});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onNext,
        child: const Text('Next: Budget Categories Placeholder'),
      ),
    );
  }
}

class SavingsGoalsStep extends StatelessWidget {
  final VoidCallback? onNext;
  const SavingsGoalsStep({super.key, this.onNext});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onNext,
        child: const Text('Next: Savings Goals Placeholder'),
      ),
    );
  }
}
