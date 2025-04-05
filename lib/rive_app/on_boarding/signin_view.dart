import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import 'package:flutter_samples/rive_app/theme.dart';
import 'package:flutter_samples/rive_app/assets.dart' as app_assets;
import 'package:flutter_samples/rive_app/services/user_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';

class SignInView extends StatefulWidget {
  const SignInView({Key? key, this.closeModal}) : super(key: key);

  final Function? closeModal;

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  SMITrigger? _successAnim;
  SMITrigger? _errorAnim;
  SMITrigger? _confettiAnim;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize the user provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _onCheckRiveInit(Artboard artboard) {
    try {
      final controller = StateMachineController.fromArtboard(artboard, "State Machine 1");
      if (controller == null) {
        print("Failed to find State Machine 1 in the check.riv file");
        return;
      }
      
      artboard.addController(controller);
      
      final check = controller.findInput<bool>("Check");
      if (check is SMITrigger) {
        _successAnim = check;
      } else {
        print("Failed to find 'Check' trigger in the animation");
      }
      
      final error = controller.findInput<bool>("Error");
      if (error is SMITrigger) {
        _errorAnim = error;
      } else {
        print("Failed to find 'Error' trigger in the animation");
      }
    } catch (e) {
      print("Error initializing check animation: $e");
    }
  }

  void _onConfettiRiveInit(Artboard artboard) {
    try {
      final controller = StateMachineController.fromArtboard(artboard, "State Machine 1");
      if (controller == null) {
        print("Failed to find State Machine 1 in the confetti.riv file");
        return;
      }
      
      artboard.addController(controller);
      
      final trigger = controller.findInput<bool>("Trigger explosion");
      if (trigger is SMITrigger) {
        _confettiAnim = trigger;
      } else {
        print("Failed to find 'Trigger explosion' in the animation");
      }
    } catch (e) {
      print("Error initializing confetti animation: $e");
    }
  }

  Future<void> login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passController.text.trim();
    
    print('Login attempt: email=$email, password=$password');
    
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both email and password';
        _isLoading = false;
      });
      
      // Safely fire the error animation
      try {
        if (_errorAnim != null) {
          print('Firing error animation for empty fields');
          _errorAnim!.fire();
        } else {
          print('Error animation controller is null');
        }
      } catch (e) {
        print("Error firing error animation: $e");
      }
      return;
    }
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      print('Calling userProvider.login');
      final success = await userProvider.login(email, password);
      print('Login result: $success');
      
      if (success) {
        print('Authentication successful, showing success animation');
        // Safely fire the success animation
        try {
          if (_successAnim != null) {
            _successAnim!.fire();
          } else {
            print('Success animation controller is null');
          }
        } catch (e) {
          print("Error firing success animation: $e");
        }
        
        Future.delayed(const Duration(seconds: 1), () {
          // Safely fire the confetti animation
          print('Firing confetti animation');
          try {
            if (_confettiAnim != null) {
              _confettiAnim!.fire();
            } else {
              print('Confetti animation controller is null');
            }
          } catch (e) {
            print("Error firing confetti animation: $e");
          }
        });
        
        Future.delayed(const Duration(seconds: 2), () {
          print('Closing modal and clearing fields');
          widget.closeModal!();
          _emailController.text = "";
          _passController.text = "";
        });
      } else {
        setState(() {
          _errorMessage = userProvider.error ?? 'Invalid credentials';
          _isLoading = false;
        });
        
        print('Authentication failed: $_errorMessage');
        // Safely fire the error animation
        try {
          if (_errorAnim != null) {
            _errorAnim!.fire();
          } else {
            print('Error animation controller is null');
          }
        } catch (e) {
          print("Error firing error animation: $e");
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      
      print('Exception during login: $e');
      // Safely fire the error animation
      try {
        if (_errorAnim != null) {
          _errorAnim!.fire();
        } else {
          print('Error animation controller is null');
        }
      } catch (e) {
        print("Error firing error animation: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get device height to calculate 80% of screen height
    final double screenHeight = MediaQuery.of(context).size.height;
    final double contentHeight = screenHeight; //0% of screen height
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Container(
            height: contentHeight,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.05, // 5% padding top and bottom within the 80% container
            ),
            child: SingleChildScrollView(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Frosted glass card container
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: 600,
                      maxHeight: contentHeight * 0.9,
                    ),
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 1,
                        )
                      ]
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                            )
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Header with title and subtitle
                                const Text(
                                  "Sign In",
                                  style: TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Learn to speak a different Language it will look good in your Resume we Promise 😉",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: "Inter",
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF666666),
                                    height: 1.5,
                                  )
                                ),
                                const SizedBox(height: 28),
                                
                                // Email field
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Email",
                                    style: TextStyle(
                                      color: Color(0xFF555555),
                                      fontFamily: "Inter",
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  decoration: authInputStyle("email"),
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 20),
                                
                                // Password field
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Password",
                                    style: TextStyle(
                                      color: Color(0xFF555555),
                                      fontFamily: "Inter",
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  obscureText: true,
                                  decoration: authInputStyle("password"),
                                  controller: _passController,
                                  style: const TextStyle(fontSize: 16),
                                ),

                                // Error message
                                if (_errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                
                                // Forgot Password Link
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      "Forgot Password?",
                                      style: TextStyle(
                                        color: Color(0xFF5E5CE6),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Improved Sign In Button
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6E8EFB), Color(0xFF5E5CE6)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF5E5CE6).withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      )
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (!_isLoading) login();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Sign In",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontFamily: "Inter",
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_rounded, color: Colors.white),
                                          ],
                                        ),
                                  ),
                                ),
                                
                                // OR Divider
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Divider(
                                          color: Color(0xFFDDDDDD),
                                          thickness: 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          "OR",
                                          style: TextStyle(
                                            color: Colors.black.withOpacity(0.4),
                                            fontSize: 14,
                                            fontFamily: "Inter",
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const Expanded(
                                        child: Divider(
                                          color: Color(0xFFDDDDDD),
                                          thickness: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Sign up text
                                const Text(
                                  "Sign up with Email, Apple or Google",
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontFamily: "Inter",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  )
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Social login buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // Email Login Button
                                    _buildSocialLoginButton(
                                      icon: const FaIcon(FontAwesomeIcons.envelope, color: Colors.white, size: 20),
                                      backgroundColor: const Color(0xFF5E5CE6),
                                      onTap: () {},
                                    ),
                                    
                                    // Apple Login Button
                                    _buildSocialLoginButton(
                                      icon: const FaIcon(FontAwesomeIcons.apple, color: Colors.white, size: 22),
                                      backgroundColor: Colors.black,
                                      onTap: () {},
                                    ),
                                    
                                    // Google Login Button
                                    _buildSocialLoginButton(
                                      icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white, size: 20),
                                      backgroundColor: const Color(0xFFEA4335),
                                      onTap: () {},
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Animation overlays
                  if (_isLoading)
                    Positioned(
                      child: Container(
                        width: 120,
                        height: 120,
                        child: RiveAnimation.asset(
                          app_assets.checkRiv,
                          onInit: _onCheckRiveInit,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: Container(
                        width: 500,
                        height: 500,
                        alignment: Alignment.center,
                        child: Transform.scale(
                          scale: 3,
                          child: RiveAnimation.asset(
                            app_assets.confettiRiv,
                            onInit: _onConfettiRiveInit,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Close button
                  Positioned(
                    bottom: -24,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => widget.closeModal!(),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF333333),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper method for social login buttons
  Widget _buildSocialLoginButton({
    required Widget icon,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }
}

// Common style for Auth Input fields
InputDecoration authInputStyle(String fieldType) {
  final bool isEmail = fieldType == "email";
  
  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    hintText: isEmail ? "your.email@example.com" : "••••••••••••",
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF5E5CE6), width: 1.5),
    ),
    contentPadding: const EdgeInsets.all(16),
    prefixIcon: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FaIcon(
        isEmail ? FontAwesomeIcons.envelope : FontAwesomeIcons.lock,
        size: 18,
        color: const Color(0xFF666666),
      ),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 50),
  );
}
