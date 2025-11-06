import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _token;
  String? _refreshToken;
  User? _currentUser;

  String? get token => _token;
  String? get refreshToken => _refreshToken;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _token != null && _currentUser != null;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConfig.authTokenKey);
    _refreshToken = prefs.getString(AppConfig.refreshTokenKey);

    final userJson = prefs.getString(AppConfig.userProfileKey);
    if (userJson != null) {
      _currentUser = User.fromJson(jsonDecode(userJson));
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.loginEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _token = data['access_token'];
        _refreshToken = data['refresh_token'];
        _currentUser = User.fromJson(data['user']);

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConfig.authTokenKey, _token!);
        await prefs.setString(AppConfig.refreshTokenKey, _refreshToken!);
        await prefs.setString(
          AppConfig.userProfileKey,
          jsonEncode(_currentUser!.toJson()),
        );

        return {
          'success': true,
          'message': 'Login successful',
          'user': _currentUser,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      if (_token != null) {
        await http.post(
          Uri.parse('${AppConfig.baseUrl}${AppConfig.logoutEndpoint}'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
        );
      }

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConfig.authTokenKey);
      await prefs.remove(AppConfig.refreshTokenKey);
      await prefs.remove(AppConfig.userProfileKey);

      _token = null;
      _refreshToken = null;
      _currentUser = null;

      return {'success': true, 'message': 'Logout successful'};
    } catch (e) {
      return {'success': false, 'message': 'Logout error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> refreshAuthToken() async {
    if (_refreshToken == null) {
      return {'success': false, 'message': 'No refresh token available'};
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.refreshTokenEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _token = data['access_token'];
        _refreshToken = data['refresh_token'];

        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConfig.authTokenKey, _token!);
        await prefs.setString(AppConfig.refreshTokenKey, _refreshToken!);

        return {'success': true, 'message': 'Token refreshed successfully'};
      } else {
        // Refresh failed, logout user
        await logout();
        return {
          'success': false,
          'message': 'Token refresh failed, please login again',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Token refresh error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    if (_token == null) {
      return {'success': false, 'message': 'No authentication token'};
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.profileEndpoint}'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = User.fromJson(data);

        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          AppConfig.userProfileKey,
          jsonEncode(_currentUser!.toJson()),
        );

        return {
          'success': true,
          'message': 'Profile loaded successfully',
          'user': _currentUser,
        };
      } else {
        return {'success': false, 'message': 'Failed to load profile'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Profile error: ${e.toString()}'};
    }
  }

  Map<String, String> getAuthHeaders() {
    return {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
    };
  }
}
