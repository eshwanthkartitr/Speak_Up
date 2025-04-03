import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import 'package:flutter_samples/rive_app/theme.dart';
import 'package:flutter_samples/rive_app/assets.dart' as app_assets;
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

  late SMITrigger _successAnim;
  late SMITrigger _errorAnim;
  late SMITrigger _confettiAnim;

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _onCheckRiveInit(Artboard artboard) {
    final controller =
        StateMachineController.fromArtboard(artboard, "State Machine 1");
    artboard.addController(controller!);
    _successAnim = controller.findInput<bool>("Check") as SMITrigger;
    _errorAnim = controller.findInput<bool>("Error") as SMITrigger;
  }

  void _onConfettiRiveInit(Artboard artboard) {
    final controller =
        StateMachineController.fromArtboard(artboard, "State Machine 1");
    artboard.addController(controller!);
    _confettiAnim =
        controller.findInput<bool>("Trigger explosion") as SMITrigger;
  }

  void login() {
    setState(() {
      _isLoading = true;
    });

    bool isEmailValid = _emailController.text.trim().isNotEmpty;
    bool isPassValid = _passController.text.trim().isNotEmpty;
    bool isValid = isEmailValid && isPassValid;

    Future.delayed(const Duration(seconds: 1), () {
      isValid ? _successAnim.fire() : _errorAnim.fire();
    });

    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isLoading = false;
      });
      if (isValid) _confettiAnim.fire();
    });

    if (isValid) {
      Future.delayed(const Duration(seconds: 4), () {
        widget.closeModal!();
        _emailController.text = "";
        _passController.text = "";
      });
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
                                  "Access to 240+ hours of content. Learn design and code, by building real apps with React and Swift.",
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
                                    child: const Row(
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
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: RiveAnimation.asset(
                          app_assets.checkRiv,
                          onInit: _onCheckRiveInit,
                        ),
                      ),
                    ),
                    
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: SizedBox(
                        width: 500,
                        height: 500,
                        child: Transform.scale(
                          scale: 3,
                          child: RiveAnimation.asset(
                            app_assets.confettiRiv,
                            onInit: _onConfettiRiveInit,
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
