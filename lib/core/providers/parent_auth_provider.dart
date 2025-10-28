import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/parent_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../config/app_config.dart';
import '../config/api_endpoints.dart';

class ParentAuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final Parent? parent;
  final String? error;
  final int? otpId;
  final String? registrationEmail;

  const ParentAuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.parent,
    this.error,
    this.otpId,
    this.registrationEmail,
  });

  ParentAuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    Parent? parent,
    String? error,
    int? otpId,
    String? registrationEmail,
  }) {
    return ParentAuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      parent: parent ?? this.parent,
      error: error,
      otpId: otpId ?? this.otpId,
      registrationEmail: registrationEmail ?? this.registrationEmail,
    );
  }
}

class ParentAuthNotifier extends StateNotifier<ParentAuthState> {
  bool _isCheckingAuth = false;

  ParentAuthNotifier() : super(const ParentAuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    if (_isCheckingAuth) {
      print('🔐 DEBUG: Parent auth check already in progress, skipping...');
      return;
    }

    _isCheckingAuth = true;
    print('🔐 DEBUG: Checking parent authentication status...');

    try {
      final token = StorageService.getAuthToken();
      final parentId = StorageService.getInt('parent_id');

      print('🔐 DEBUG: Token exists: ${token != null}');
      print('🔐 DEBUG: Parent ID: $parentId');

      if (token != null && parentId != null) {
        print('🔐 DEBUG: Found existing parent auth, loading profile...');
        await _loadParentProfile();
      } else {
        print('🔐 DEBUG: No parent authentication found - user needs to login');
      }
    } finally {
      _isCheckingAuth = false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🔐 DEBUG: Starting parent login for email: $email');

      // Clear any existing tokens before login
      await StorageService.clearAuthTokens();

      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig
            .loginEndpoint, // '/users/login/' (baseUrl already includes /api/v1)
        data: {'email': email, 'password': password, 'source': 'mobile'},
      );

      print('🔐 DEBUG: Parent login response - Success: ${response.success}');
      print('🔐 DEBUG: Parent login response - Error: ${response.error}');
      print('🔐 DEBUG: Parent login response - Data: ${response.data}');

      if (response.success && response.data != null) {
        final data = response.data!;
        print('🔐 DEBUG: Parent login successful, processing response data');

        int? otpId;
        if (data['otp_id'] is int) {
          otpId = data['otp_id'] as int;
        } else {
          final delivery = data['delivery_methods'];
          if (delivery is Map && delivery['email'] is Map) {
            final emailMethod = delivery['email'] as Map;
            if (emailMethod['otp_id'] is int) {
              otpId = emailMethod['otp_id'] as int;
              print('🔐 DEBUG: Found otp_id in delivery_methods: $otpId');
            }
          }
        }

        if (otpId != null) {
          state = state.copyWith(
            isLoading: false,
            otpId: otpId,
            registrationEmail: email,
          );
          print('🔐 DEBUG: OTP required for parent login');
          return true;
        }

        // Handle successful login
        if (data['tokens'] != null && data['parent'] != null) {
          final tokens = data['tokens'] as Map<String, dynamic>;
          final parentData = data['parent'] as Map<String, dynamic>;

          // Save tokens
          await StorageService.saveAuthToken(tokens['access'] as String);
          await StorageService.saveRefreshToken(tokens['refresh'] as String);

          // Save parent data
          final parent = Parent.fromJson(parentData);
          await StorageService.saveUserProfile(parent.toJson());
          await StorageService.setInt('parent_id', parent.id);

          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            parent: parent,
            error: null,
          );

          print('🔐 DEBUG: Parent login completed successfully');
          return true;
        }
      }

      // Handle login failure
      final errorMessage = response.error ?? 'Login failed';
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: errorMessage,
      );

      print('🔐 DEBUG: Parent login failed: $errorMessage');
      return false;
    } catch (e) {
      print('🔐 DEBUG: Parent login error: $e');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: 'Login failed: $e',
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    if (state.otpId == null) {
      state = state.copyWith(error: 'No OTP session found');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.verifyOtpLoginEndpoint, // '/users/verify-otp/login/'
        data: {'otp_id': state.otpId, 'otp_code': otp},
      );

      if (response.success && response.data != null) {
        final data = response.data!;

        print('🔐 DEBUG: OTP verification response received');
        print('🔐 DEBUG: Response data keys: ${data.keys.toList()}');
        print('🔐 DEBUG: Response success: ${data['success']}');
        print('🔐 DEBUG: Response message: ${data['message']}');

        // Save tokens if present
        final tokens = data['tokens'];
        print('🔐 DEBUG: Tokens object type: ${tokens.runtimeType}');
        print('🔐 DEBUG: Tokens object: $tokens');
        if (tokens is Map<String, dynamic>) {
          final access = tokens['access'] as String?;
          final refresh = tokens['refresh'] as String?;

          print('🔐 DEBUG: Saving authentication tokens...');
          print(
            '🔐 Access token: ${access != null ? "Present (${access.length} chars)" : "Missing"}',
          );
          print(
            '🔐 Refresh token: ${refresh != null ? "Present (${refresh.length} chars)" : "Missing"}',
          );

          if (access != null) {
            await StorageService.saveAuthToken(access);
            print('🔐 DEBUG: Access token saved successfully');

            // Verify token was saved
            final savedToken = StorageService.getAuthToken();
            if (savedToken == access) {
              print('✅ DEBUG: Token verification successful - token matches');
            } else {
              print(
                '❌ DEBUG: Token verification failed - saved token does not match',
              );
            }
          } else {
            print('⚠️ DEBUG: No access token in response!');
          }

          if (refresh != null) {
            await StorageService.saveRefreshToken(refresh);
            print('🔐 DEBUG: Refresh token saved successfully');

            // Verify refresh token was saved
            final savedRefreshToken = StorageService.getRefreshToken();
            if (savedRefreshToken == refresh) {
              print(
                '✅ DEBUG: Refresh token verification successful - token matches',
              );
            } else {
              print(
                '❌ DEBUG: Refresh token verification failed - saved token does not match',
              );
            }
          } else {
            print('⚠️ DEBUG: No refresh token in response!');
          }
        } else {
          print('⚠️ DEBUG: No tokens object in response!');
          print('🔐 DEBUG: Response data keys: ${data.keys.toList()}');
        }

        // Accept either 'parent' or 'user' object
        final parentObj = data['parent'];
        final userObj = data['user'];
        print(
          '🔐 DEBUG: Parent object: ${parentObj != null ? "Present" : "Missing"}',
        );
        print(
          '🔐 DEBUG: User object: ${userObj != null ? "Present" : "Missing"}',
        );

        Map<String, dynamic>? profileMap;
        if (parentObj is Map<String, dynamic>) {
          profileMap = parentObj;
          print('🔐 DEBUG: Using parent object for profile');
        } else if (userObj is Map<String, dynamic>) {
          profileMap = userObj;
          print('🔐 DEBUG: Using user object for profile');
        } else {
          print('⚠️ DEBUG: No valid profile object found!');
        }

        if (profileMap != null) {
          print('🔐 DEBUG: Processing user profile...');
          print('🔐 DEBUG: Profile keys: ${profileMap.keys.toList()}');

          final parent = _parentFromUserLike(profileMap);
          print('🔐 DEBUG: Parent created with ID: ${parent.id}');
          print('🔐 DEBUG: Parent email: ${parent.email}');
          print(
            '🔐 DEBUG: Parent name: ${parent.firstName} ${parent.lastName}',
          );

          // Persist
          await StorageService.saveUserProfile(parent.toJson());
          await StorageService.setInt('parent_id', parent.id);
          print('🔐 DEBUG: User profile saved successfully');

          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            parent: parent,
            error: null,
            otpId: null,
            registrationEmail: null,
          );

          print('🔐 DEBUG: Parent OTP verification completed successfully');
          return true;
        }
      }

      final errorMessage = response.error ?? 'OTP verification failed';
      state = state.copyWith(isLoading: false, error: errorMessage);

      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'OTP verification failed: $e',
      );
      return false;
    }
  }

  Future<void> _loadParentProfile() async {
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.profileEndpoint, // '/users/me/'
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        print('🔍 DEBUG: Raw API response for parent profile:');
        print('  - Response keys: ${data.keys.toList()}');
        print('  - Phone field: ${data['phone']}');
        print('  - Address field: ${data['address']}');
        print('  - Emergency contact: ${data['emergency_contact']}');
        print('  - Emergency phone: ${data['emergency_phone']}');

        // Handle either direct profile map or nested { user: {...} }
        final userMap = (data['user'] is Map<String, dynamic>)
            ? data['user'] as Map<String, dynamic>
            : data;

        print('🔍 DEBUG: User map keys: ${userMap.keys.toList()}');
        print('🔍 DEBUG: User map phone: ${userMap['phone']}');
        print('🔍 DEBUG: User map address: ${userMap['address']}');

        final parent = _parentFromUserLike(userMap);
        print('🔍 DEBUG: Parsed parent data:');
        print('  - Phone: "${parent.phone}" (length: ${parent.phone.length})');
        print(
          '  - Address: "${parent.address}" (null: ${parent.address == null})',
        );
        print(
          '  - Emergency Contact: "${parent.emergencyContact}" (null: ${parent.emergencyContact == null})',
        );
        print(
          '  - Emergency Phone: "${parent.emergencyPhone}" (null: ${parent.emergencyPhone == null})',
        );

        state = state.copyWith(
          isAuthenticated: true,
          parent: parent,
          error: null,
        );
        print('🔐 DEBUG: Parent profile loaded successfully');
      } else {
        print('🔐 DEBUG: Failed to load parent profile: ${response.error}');
        await logout();
      }
    } catch (e) {
      print('🔐 DEBUG: Error loading parent profile: $e');
      await logout();
    }
  }

  Future<void> logout() async {
    try {
      // Call logout endpoint
      await ApiService.post(AppConfig.logoutEndpoint); // '/users/logout/'
    } catch (e) {
      print('🔐 DEBUG: Logout API call failed: $e');
    }

    // Clear local storage
    await StorageService.clearAuthTokens();
    await StorageService.clearUserProfile();
    await StorageService.remove('parent_id');

    state = const ParentAuthState();
    print('🔐 DEBUG: Parent logout completed');
  }

  Future<void> refreshParentProfile() async {
    if (!state.isAuthenticated) return;
    await _loadParentProfile();
  }

  /// Refresh the authentication token using the refresh token
  Future<bool> refreshToken() async {
    try {
      print('🔄 DEBUG: Attempting to refresh parent authentication token...');

      final refreshToken = StorageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        print('🔄 DEBUG: No refresh token available');
        return false;
      }

      print('🔄 DEBUG: Attempting token refresh...');
      print('🔄 DEBUG: Refresh token length: ${refreshToken.length}');
      print(
        '🔄 DEBUG: Refresh token preview: ${refreshToken.substring(0, 20)}...',
      );

      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.refreshTokenEndpoint,
        data: {'refresh': refreshToken},
      );

      print('🔄 DEBUG: Token refresh response - Success: ${response.success}');
      print('🔄 DEBUG: Token refresh response - Error: ${response.error}');
      print(
        '🔄 DEBUG: Token refresh response - Status Code: ${response.statusCode}',
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        // Handle both possible response formats
        final newAccessToken =
            data['access'] as String? ??
            data['accessToken'] as String? ??
            data['access_token'] as String?;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await StorageService.saveAuthToken(newAccessToken);
          print('🔄 DEBUG: Parent token refreshed successfully');
          return true;
        } else {
          print('🔄 DEBUG: No valid access token in refresh response');
        }
      }

      print('🔄 DEBUG: Token refresh failed - user needs to login again');
      return false;
    } catch (e) {
      print('🔄 DEBUG: Token refresh error: $e');
      return false;
    }
  }

  /// Check if token is expired and handle accordingly
  Future<bool> checkTokenExpiration() async {
    try {
      final token = StorageService.getAuthToken();
      if (token == null || token.isEmpty) {
        print('⏰ DEBUG: No token found, user needs to login');
        return false;
      }

      // Try to make a simple API call to check if token is still valid
      final response = await ApiService.get<Map<String, dynamic>>(
        ApiEndpoints.profile,
      );

      if (response.success) {
        print('⏰ DEBUG: Token is still valid');
        return true;
      } else if (response.error?.contains('401') == true ||
          response.error?.contains('token') == true) {
        print('⏰ DEBUG: Token appears to be expired, attempting refresh...');

        // Try to refresh the token
        final refreshSuccess = await refreshToken();
        if (refreshSuccess) {
          print('⏰ DEBUG: Token refreshed successfully');
          return true;
        } else {
          print('⏰ DEBUG: Token refresh failed, user needs to login');
          // Clear invalid tokens
          await StorageService.clearAuthTokens();
          state = const ParentAuthState();
          return false;
        }
      }

      return false;
    } catch (e) {
      print('⏰ DEBUG: Token expiration check error: $e');
      return false;
    }
  }

  /// Proactively refresh token before it expires
  Future<void> scheduleTokenRefresh() async {
    // This could be called periodically to refresh tokens
    // For now, we'll check token validity on each API call
    await checkTokenExpiration();
  }
}

final parentAuthProvider =
    StateNotifierProvider<ParentAuthNotifier, ParentAuthState>((ref) {
      return ParentAuthNotifier();
    });

// Helper to adapt a generic user/parent payload into Parent model
Parent _parentFromUserLike(Map<String, dynamic> json) {
  DateTime parseDate(dynamic v) {
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {}
    }
    return DateTime.now();
  }

  return Parent(
    id: (json['id'] as int?) ?? 0,
    firstName:
        (json['first_name'] as String?) ?? (json['firstName'] as String?) ?? '',
    lastName:
        (json['last_name'] as String?) ?? (json['lastName'] as String?) ?? '',
    email: (json['email'] as String?) ?? '',
    phone:
        (json['phone'] as String?) ?? (json['phone_number'] as String?) ?? '',
    profileImage:
        json['profile_image'] as String? ?? json['profile_picture'] as String?,
    address: (json['address'] as String?) ?? '',
    emergencyContact:
        json['emergency_contact'] as String? ??
        json['emergency_contact_name'] as String?,
    emergencyPhone:
        json['emergency_phone'] as String? ??
        json['emergency_contact_phone'] as String?,
    children: const [],
    createdAt: parseDate(json['created_at']),
    updatedAt: parseDate(json['updated_at']),
  );
}
