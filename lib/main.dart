import 'package:flutter/material.dart';
import 'package:flutter_samples/rive_app/home.dart';
import 'package:flutter_samples/rive_app/on_boarding/onboarding_view.dart';
import 'package:flutter_samples/rive_app/theme_provider.dart';
import 'package:flutter_samples/rive_app/utils/onboarding_utils.dart';
import 'package:flutter_samples/rive_app/services/user_provider.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: hasSeenOnboarding ? const RiveApp() : const OnboardingScreen(),
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
          MaterialPageRoute(builder: (_) => const RiveApp()),
        );
      },
    );
  }
}

class RiveApp extends StatelessWidget {
  const RiveApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: SessionAwareApp(),
    );
  }
}

class SessionAwareApp extends StatefulWidget {
  @override
  _SessionAwareAppState createState() => _SessionAwareAppState();
}

class _SessionAwareAppState extends State<SessionAwareApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Track user activity
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App is in the foreground - check session and record activity
        userProvider.recordActivity();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // App is not in the foreground - do nothing
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Track user interaction to record activity
      onPointerDown: (_) => _recordUserActivity(context),
      onPointerMove: (_) => _recordUserActivity(context),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Flutter Samples',
            theme: themeProvider.themeData,
            debugShowCheckedModeBanner: false,
            home: const RiveAppHome(),
          );
        },
      ),
    );
  }

  // Debounced activity recording to avoid too many writes
  DateTime _lastRecorded = DateTime.now();
  void _recordUserActivity(BuildContext context) {
    final now = DateTime.now();
    // Only record if at least 1 minute has passed since last recording
    if (now.difference(_lastRecorded).inMinutes >= 1) {
      _lastRecorded = now;
      Provider.of<UserProvider>(context, listen: false).recordActivity();
    }
  }
}
