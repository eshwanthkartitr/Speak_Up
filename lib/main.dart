import 'package:flutter/material.dart';
import 'package:flutter_samples/rive_app/home.dart';
import 'package:flutter_samples/rive_app/on_boarding/onboarding_view.dart';
import 'package:flutter_samples/rive_app/theme_provider.dart';
import 'package:flutter_samples/rive_app/utils/onboarding_utils.dart';
import 'package:provider/provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check if the user has seen the onboarding screen
  final hasSeenOnboarding = await OnboardingUtils.hasSeenOnboarding();
  
  runApp(MyApp(hasSeenOnboarding: hasSeenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  
  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Flutter Samples',
            theme: themeProvider.themeData,
            home: hasSeenOnboarding ? const RiveAppHome() : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}

// Wrapper for OnboardingView that handles navigation after onboarding
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OnBoardingView(
      closeModal: () {
        // Mark onboarding as seen and navigate to home
        OnboardingUtils.setOnboardingAsSeen();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RiveAppHome()),
        );
      },
    );
  }
}
