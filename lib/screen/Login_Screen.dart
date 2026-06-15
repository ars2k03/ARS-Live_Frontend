import 'dart:async';
import 'package:ars_live/mediaSize/size.dart';
import 'package:ars_live/screen/phone_number/phone_number.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../authService/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final response = await AuthService.loginWithGoogle();

      if (response["success"] == true) {

        final token = response["data"]["token"];
        final refreshToken = response["data"]["refreshToken"];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);
        await prefs.setString("refreshToken", refreshToken);

        final profile = await AuthService.getProfile();

        final user = profile["data"]["user"];

        if (user["phoneNumber"] != null && user["phoneNumber"].toString().isNotEmpty) {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(),
            ),
          );

        } else {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
              const PhoneVerificationScreen(),
            ),
          );

        }
      } else {
        setState(() {
          _errorMessage = "Something went wrong. Please try again.";
        });
      }
    } catch (e) {

      setState(() {
        _errorMessage = "Google Sign-In failed";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode? Colors.black : Colors.white,

        body: SingleChildScrollView(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),

                      Image.asset(
                        'assets/images/splash_logo.png',
                        width: context.w * 0.35,
                      ),

                      const SizedBox(height: 24),

                      Text(
                        "ARS Live",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "Connect instantly with people around the world.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 40),

                      Lottie.asset(
                        'assets/images/login.json',
                        width: context.w * 0.7,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: isDarkMode? Colors.white : Colors.black,
                          foregroundColor: isDarkMode? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/google.png',
                              height: 22,
                            ),

                            const SizedBox(width: 12),

                            _isLoading
                                ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDarkMode? Colors.white : Colors.black,
                              ),
                            )
                                : const Text(
                              "Continue with Google",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                      const SizedBox(height: 16),

                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.red.withOpacity(.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode
                                ? Colors.white70
                                : Colors.black54,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(
                              text: "By continuing, you agree to our ",
                            ),

                            TextSpan(
                              text: "Terms of Service",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  openUrl(
                                    "https://policies.google.com/",
                                  );
                                },
                            ),

                            const TextSpan(
                              text: " and ",
                            ),

                            TextSpan(
                              text: "Privacy Policy",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  openUrl(
                                    "https://policies.google.com/",
                                  );
                                },
                            ),

                            const TextSpan(text: "."),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
    );
  }
}