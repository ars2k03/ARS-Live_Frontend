import 'package:ars_live/mediaSize/size.dart';
import 'package:ars_live/screen/phone_number/phone_number.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../authService/auth_service.dart';
import 'Login_Screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  late String phoneNumber="";

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    await Future.delayed(const Duration(seconds: 2));

    if (token == null) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );

      return;
    }

    final success = await _loadProfile();

    if (!mounted) return;

    if (success) {
      if(phoneNumber.isNotEmpty){
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(),
          ),
        );
      }else{
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const PhoneVerificationScreen(),
          ),
        );
      }
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  Future<bool> _loadProfile() async {
    try {
      final response = await AuthService.getProfile();

      if (response["success"] == true) {
        final user = response["data"]["user"];

        phoneNumber = user["phoneNumber"] ?? "";
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("Profile Error: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              Container(
                padding: const EdgeInsets.all(24),

                child: Image.asset(
                  'assets/images/splash_logo.png',
                  width: context.w * .45,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "ARS Live",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                )
              ),

              const SizedBox(height: 8),

              Text(
                "Real-time Communication Platform",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                  color: Colors.white70,
                ),
              ),

              const Spacer(),

              SizedBox(
                width: 35,
                height: 35,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Loading...",
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}