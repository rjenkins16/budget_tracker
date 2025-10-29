import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'package:http/http.dart' as http;

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _currentStep = 0;
  bool _started = false;

  final List<Widget> _steps = [];

final Color bgColor = const Color(0xFF4B2E2B); // Darker chocolate brown
  final Color accentColor = const Color(0xFF2F4F2F); // Forest green

  @override
  void initState() {
    super.initState();
    _steps.addAll([
      SignupScreen(onNext: _nextStep),
      AccountLinkingScreen(onNext: _nextStep, onBack: _previousStep),
      BudgetCategoriesScreen(onNext: _nextStep, onBack: _previousStep),
      SavingsGoalsScreen(onNext: _nextStep, onBack: _previousStep),
    ]);
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _startOnboarding() {
    setState(() {
      _started = true;
      _currentStep = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
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
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                  );
                },
                child: Text(
                  'Already have an account? Sign in',
                  style: TextStyle(color: accentColor.withOpacity(0.8), fontSize: 16),
                ),
              ),
            ],
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

// ------------------------- Placeholder SignInScreen -------------------------
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: const Center(child: Text('Sign in screen placeholder')),
    );
  }
}

// ------------------------- Placeholder onboarding step screens -------------------------
class SignupScreen extends StatelessWidget {
  final VoidCallback? onNext;
  const SignupScreen({super.key, this.onNext});

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

class AccountLinkingScreen extends StatelessWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const AccountLinkingScreen({super.key, this.onNext, this.onBack});

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

class BudgetCategoriesScreen extends StatelessWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const BudgetCategoriesScreen({super.key, this.onNext, this.onBack});

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

class SavingsGoalsScreen extends StatelessWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  const SavingsGoalsScreen({super.key, this.onNext, this.onBack});

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
