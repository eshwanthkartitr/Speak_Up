import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:rive/rive.dart';
import 'package:flutter_samples/rive_app/theme.dart';
import 'package:flutter_samples/rive_app/on_boarding/signin_view.dart';
import 'package:flutter_samples/rive_app/assets.dart' as app_assets;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class OnBoardingView extends StatefulWidget {
  const OnBoardingView({Key? key, this.closeModal}) : super(key: key);

  // Close modal callback for any screen that uses this as a modal
  final Function? closeModal;

  @override
  State<OnBoardingView> createState() => _OnBoardingViewState();
}

class _OnBoardingViewState extends State<OnBoardingView>
    with TickerProviderStateMixin {
  // Animation controller that shows the sign up modal as well as translateY boarding content together
  AnimationController? _signInAnimController;

  // Control touch effect animation for the "Start the Course" button
  late RiveAnimationController _btnController;

  @override
  void initState() {
    super.initState();
    _signInAnimController = AnimationController(
        duration: const Duration(milliseconds: 350),
        upperBound: 1,
        vsync: this);

    _btnController = OneShotAnimation("active", autoplay: false);

    const springDesc = SpringDescription(
      mass: 0.1,
      stiffness: 40,
      damping: 5,
    );

    _btnController.isActiveChanged.addListener(() {
      if (!_btnController.isActive) {
        final springAnim = SpringSimulation(springDesc, 0, 1, 0);
        _signInAnimController?.animateWith(springAnim);
      }
    });
  }

  @override
  void dispose() {
    _signInAnimController?.dispose();
    _btnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Center(
            child: OverflowBox(
              maxWidth: double.infinity,
              child: Transform.translate(
                offset: const Offset(200, 100),
                child: Image.asset(app_assets.spline, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: const RiveAnimation.asset(app_assets.shapesRiv),
        ),
        AnimatedBuilder(
          animation: _signInAnimController!,
          builder: (context, child) {
            return Transform(
                transform: Matrix4.translationValues(
                    0, -50 * _signInAnimController!.value, 0),
                child: child);
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 80, 40, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App name with icon
                  Row(
                    children: const [
                      FaIcon(FontAwesomeIcons.hands, size: 24, color: Color(0xFF444444)),
                      SizedBox(width: 12),
                      Text(
                        "Sign Speak Tamil",
                        style: TextStyle(
                          fontFamily: "Inter",
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF444444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Main headline
                  Container(
                    width: 280,
                    padding: const EdgeInsets.only(bottom: 16),
                    child: const Text(
                      "Break barriers, speak with your hands! ✨",
                      style: TextStyle(
                        fontFamily: "Poppins", 
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                      ),
                      softWrap: true,
                    ),
                  ),
                  
                  // Description
                  Text(
                    "Learn Tamil Sign Language the fun way and convert signs to speech instantly with our innovative technology.",
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontFamily: "Inter",
                      fontSize: 17,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  const Spacer(),
                  
                  // Start Learning Button
                  GestureDetector(
                    child: Container(
                      width: 236,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Stack(children: [
                        RiveAnimation.asset(
                          app_assets.buttonRiv,
                          fit: BoxFit.cover,
                          controllers: [_btnController],
                        ),
                        Center(
                          child: Transform.translate(
                            offset: const Offset(4, 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.waving_hand_sharp),
                                SizedBox(width: 8),
                                Text(
                                  "Start Learning",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: "Inter",
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
                      ]),
                    ),
                    onTap: () {
                      _btnController.isActive = true;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Features text
                  Text(
                    "Access 50+ Tamil Sign Language lessons, real-time translation, interactive practice sessions, and earn certificates as you progress.",
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontFamily: "Inter",
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _signInAnimController!,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                      top: 100 - (_signInAnimController!.value * 180),
                      right: 20,
                      child: child!),
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: Opacity(
                        opacity: 0.4 * _signInAnimController!.value,
                        child: Container(color: RiveAppTheme.shadow),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(
                      0,
                      -MediaQuery.of(context).size.height *
                          (1 - _signInAnimController!.value),
                    ),
                    child: SignInView(
                      closeModal: () {
                        _signInAnimController?.reverse();
                      },
                    ),
                  ),
                ],
              );
            },
            child: SafeArea(
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(36 / 2),
                minSize: 36,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(36 / 2),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  widget.closeModal!();
                },
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
