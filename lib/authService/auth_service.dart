import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    return 'https://ars-live.onrender.com';
  }

  static Future<Map<String, dynamic>> getProfile({bool retry = true})
  async {
    try {

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.get(
        Uri.parse("$baseUrl/profile"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {

        return {
          "success": true,
          "data": data,
        };

      } else if (response.statusCode == 401 && retry) {

        final isRefreshSuccess = await refreshToken();
        if (isRefreshSuccess) {
          return await getProfile(retry: false);
        }
        return {
          "success": false,
          "message": "Session expired",
        };

      } else {

        return {
          "success": false,
          "message": data["message"],
        };

      }

    } catch (e) {

      return {
        "success": false,
        "message": e.toString(),
      };

    }
  }

  static Future<bool> refreshToken()
  async {
    try {
      await GoogleSignIn.instance.signOut();

      final prefs = await SharedPreferences.getInstance();

      final refreshToken = prefs.getString("refreshToken");

      final response = await http.post(

        Uri.parse("$baseUrl/refresh"),

        headers: {
          "Content-Type": "application/json",
        },

        body: jsonEncode({
          "refreshToken": refreshToken,
        }),

      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {

        final newAccessToken = data["accessToken"];

        await prefs.setString(
          "token",
          newAccessToken,
        );

        return true;

      }

      return false;

    } catch (e) {

      return false;

    }
  }

  static Future<Map<String, dynamic>> loginWithGoogle()
  async {
    try {
        final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final idToken = googleAuth.idToken;

        if (idToken == null) {
          return {
            "success": false,
            "message": "Failed to get Google token",
          };
        }

        final response = await http.post(
          Uri.parse("$baseUrl/google-login"),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "idToken": idToken,
          }),
        );

        final data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          return {
            "success": true,
            "data": data,
          };
        } else {
          return {
            "success": false,
            "message": data["message"],
          };
        }

    } catch (e) {

      if (e.toString().contains('canceled') || e.toString().contains('cancelled')) {
        return {
          "success": false,
          "message": "Google sign in cancelled",
        };
      }
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getUsers()
  async {
    try {

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.get(
        Uri.parse("$baseUrl/users"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {

        return {
          "success": true,
          "users": data["users"],
        };

      }

      return {
        "success": false,
        "message": data["message"],
      };

    } catch (e) {

      return {
        "success": false,
        "message": e.toString(),
      };

    }
  }

  static Future<Map<String, dynamic>> loginWithGoogleToken(String idToken)
  async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/google-login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"idToken": idToken}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data["message"]};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getMessages(String receiverId)
  async {

    try {

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.get(
        Uri.parse("$baseUrl/messages/$receiverId"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {

        return {
          "success": true,
          "messages": data["messages"],
        };

      }

      return {
        "success": false,
        "message": data["message"],
      };

    } catch (e) {

      return {
        "success": false,
        "message": e.toString(),
      };

    }

  }
}