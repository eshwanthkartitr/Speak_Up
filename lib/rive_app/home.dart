import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'dart:ui';  // Add this import for ImageFilter
import 'package:flutter_samples/rive_app/navigation/side_menu.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import 'dart:math' as math;
import 'package:flutter_samples/rive_app/navigation/custom_tab_bar.dart';
import 'package:flutter_samples/rive_app/navigation/home_tab_view.dart';
import 'package:flutter_samples/rive_app/on_boarding/onboarding_view.dart';
import 'package:flutter_samples/rive_app/theme.dart';
import 'package:flutter_samples/rive_app/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_samples/rive_app/assets.dart' as app_assets;
import 'package:flutter_samples/rive_app/screens/chat_screen.dart';
import 'package:flutter_samples/rive_app/screens/search_screen.dart';
import 'package:flutter_samples/rive_app/screens/practice_screen.dart';
import 'package:flutter_samples/rive_app/screens/notifications_screen.dart';
import 'package:flutter_samples/rive_app/screens/profile_screen.dart';

// Common Tab Scene for the tabs other than 1st one, showing only tab name in center
Widget commonTabScene(String tabName, bool isDarkMode) {
  return Container(
      color: RiveAppTheme.getBackgroundColor(isDarkMode),
      alignment: Alignment.center,
      child: Text(tabName,
          style: TextStyle(
              fontSize: 28, 
              fontFamily: "Poppins", 
              color: RiveAppTheme.getTextColor(isDarkMode)
          ))
  );
}

class RiveAppHome extends StatefulWidget {
  const RiveAppHome({Key? key}) : super(key: key);

  @override
  State<RiveAppHome> createState() => _RiveAppHomeState();
}

class _RiveAppHomeState extends State<RiveAppHome>
    with TickerProviderStateMixin {
  late AnimationController? _animationController;
  late AnimationController? _onBoardingAnimController;
  late Animation<double> _onBoardingAnim;
  late Animation<double> _sidebarAnim;

  late SMIBool _menuBtn;

  bool _showOnBoarding = false;
  int _currentTabIndex = 0;
  late final List<Widget> _screens;

  // Optimize spring physics for smoother animations
  final springDesc = const SpringDescription(
    mass: 0.3,           // Increased mass for smoother motion
    stiffness: 30,       // Reduced stiffness for less abrupt stops
    damping: 10,         // Increased damping to prevent overshooting
  );

  void _onMenuIconInit(Artboard artboard) {
    final controller =
        StateMachineController.fromArtboard(artboard, "State Machine");
    artboard.addController(controller!);
    _menuBtn = controller.findInput<bool>("isOpen") as SMIBool;
    _menuBtn.value = true;
  }

  void _presentOnBoarding(bool show) {
    if (show) {
      setState(() {
        _showOnBoarding = true;
      });
      final springAnim = SpringSimulation(springDesc, 0, 1, 0);
      _onBoardingAnimController?.animateWith(springAnim);
    } else {
      // Use spring simulation for the reverse animation too
      final springAnim = SpringSimulation(springDesc, 1, 0, 0);
      _onBoardingAnimController?.animateWith(springAnim);
      
      // Delay the state change until animation completes
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          setState(() {
            _showOnBoarding = false;
          });
        }
      });
    }
  }

  void onMenuPress() {
    if (_menuBtn.value) {
      final springAnim = SpringSimulation(springDesc, 0, 1, 0);
      _animationController?.animateWith(springAnim);
    } else {
      // Use spring simulation for the reverse animation too
      final springAnim = SpringSimulation(springDesc, 1, 0, 0);
      _animationController?.animateWith(springAnim);
    }
    _menuBtn.change(!_menuBtn.value);

    SystemChrome.setSystemUIOverlayStyle(_menuBtn.value
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light);
  }

  @override
  void initState() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),  // Longer duration for smoother animation
      upperBound: 1,
      vsync: this,
    );
    _onBoardingAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),  // Longer duration
      upperBound: 1,
      vsync: this,
    );

    // Use easeInOut curve for smoother animations instead of linear
    _sidebarAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOutCubic,  // Smoother curve
    ));

    _onBoardingAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _onBoardingAnimController!,
      curve: Curves.easeInOutCubic,  // Smoother curve
    ));

    // Initialize screens
    _screens = [
      const HomeTabView(),        // Keep your existing home tab view
      const ChatScreen(),         // New screen for Chat
      const SearchScreen(),       // New screen for Search
      const PracticeScreen(),     // New screen for Practice/Timer
      const NotificationsScreen(),// New screen for Notifications/Bell
      const ProfileScreen(),      // New screen for User/Profilez
    ];

    super.initState();
  }

  // Method to handle tab changes
  void _handleTabChange(int tabIndex) {
    setState(() {
      _currentTabIndex = tabIndex;
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _onBoardingAnimController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get theme provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Background - Update to use theme-aware background
          Positioned.fill(
            child: Container(color: RiveAppTheme.getBackgroundColor(isDarkMode)),
          ),
          
          // Sidebar with optimized transform
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _sidebarAnim,
              builder: (BuildContext context, Widget? child) {
                // Calculate rotation and translation once
                final rotationY = ((1 - _sidebarAnim.value) * -30) * math.pi / 180;
                final translationX = (1 - _sidebarAnim.value) * -300;
                
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(rotationY)
                    ..translate(translationX),
                  child: child,
                );
              },
              child: FadeTransition(
                opacity: _sidebarAnim,
                child: const SideMenu(),
              ),
            ),
          ),
          
          // Main content with optimized animations
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _showOnBoarding ? _onBoardingAnim : _sidebarAnim,
              builder: (context, child) {
                // Pre-calculate values to improve performance
                final scale = 1 -
                    (_showOnBoarding
                        ? (_onBoardingAnim.value * 0.08)
                        : (_sidebarAnim.value * 0.1));
                final offsetX = _sidebarAnim.value * 265;
                final rotationY = (_sidebarAnim.value * 30) * math.pi / 180;
                
                return Transform.scale(
                  scale: scale,
                  filterQuality: FilterQuality.high,  // Better quality scaling
                  child: Transform.translate(
                    offset: Offset(offsetX, 0),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(rotationY),
                      child: _screens[_currentTabIndex],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Profile button with improved styling
          AnimatedBuilder(
            animation: _sidebarAnim,
            builder: (context, child) {
              return Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                right: (_sidebarAnim.value * -100) + 16,
                child: child!,
              );
            },
            child: GestureDetector(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode 
                        ? [
                            Colors.grey[800]!.withOpacity(0.9),
                            Colors.grey[900]!.withOpacity(0.9),
                          ]
                        : [
                            Colors.white.withOpacity(0.9),
                            Colors.grey[100]!.withOpacity(0.9),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.2)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                    if (!isDarkMode) BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: -3,
                      offset: const Offset(-3, -3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_outline,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  size: 20,
                ),
              ),
              onTap: () {
                _presentOnBoarding(true);
              },
            ),
          ),
          
          // Menu button with improved styling
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _sidebarAnim,
              builder: (context, child) {
                return SafeArea(
                  child: Row(
                    children: [
                      SizedBox(width: _sidebarAnim.value * 216),
                      child!,
                    ],
                  ),
                );
              },
              child: GestureDetector(
                onTap: onMenuPress,
                child: Hero(
                  tag: 'menuButton',
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode
                            ? [
                                Colors.grey[850]!.withOpacity(0.9),
                                Colors.grey[900]!.withOpacity(0.9),
                              ]
                            : [
                                Colors.white.withOpacity(0.95),
                                Colors.grey[100]!.withOpacity(0.95),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                        if (!isDarkMode) BoxShadow(
                          color: Colors.white.withOpacity(0.8),
                          blurRadius: 12,
                          spreadRadius: -2,
                          offset: const Offset(-2, -2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.black.withOpacity(0.1)
                                : Colors.white.withOpacity(0.1),
                          ),
                          child: RiveAnimation.asset(
                            app_assets.menuButtonRiv,
                            stateMachines: const ["State Machine"],
                            animations: const ["open", "close"],
                            onInit: _onMenuIconInit,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Onboarding with optimized animations
          if (_showOnBoarding)
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _onBoardingAnim,
                builder: (context, child) {
                  // Pre-calculate transform values
                  final offset = Offset(
                      0,
                      -(MediaQuery.of(context).size.height +
                              MediaQuery.of(context).padding.bottom) *
                          (1 - _onBoardingAnim.value));
                  
                  return Transform.translate(
                    offset: offset,
                    child: child!,
                  );
                },
                child: SafeArea(
                  top: false,
                  maintainBottomViewPadding: true,
                  child: Container(
                    transform: Matrix4.translationValues(
                        0, -(MediaQuery.of(context).padding.bottom + 18), 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 40,
                            offset: const Offset(0, 40))
                      ],
                    ),
                    child: OnBoardingView(
                      closeModal: () {
                        _presentOnBoarding(false);
                      },
                    ),
                  ),
                ),
              ),
            ),
            
          // Gradient overlay with optimized animation
          IgnorePointer(
            ignoring: true,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedBuilder(
                animation: !_showOnBoarding ? _sidebarAnim : _onBoardingAnim,
                builder: (context, child) {
                  // Pre-calculate opacity value
                  final opacity = 1 -
                      ((!_showOnBoarding
                              ? _sidebarAnim.value
                              : _onBoardingAnim.value) *
                          1);
                          
                  return Container(
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          RiveAppTheme.getBackgroundColor(isDarkMode).withOpacity(0),
                          RiveAppTheme.getBackgroundColor(isDarkMode).withOpacity(opacity)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: RepaintBoundary(
        child: AnimatedBuilder(
          animation: !_showOnBoarding ? _sidebarAnim : _onBoardingAnim,
          builder: (context, child) {
            // Pre-calculate offset value
            final offsetY = !_showOnBoarding
                ? _sidebarAnim.value * 300
                : _onBoardingAnim.value * 200;
                
            return Transform.translate(
              offset: Offset(0, offsetY),
              child: CustomTabBar(
                onTabChange: _handleTabChange, // Connect the tab change handler
              ),
            );
          },
        ),
      ),
    );
  }
}