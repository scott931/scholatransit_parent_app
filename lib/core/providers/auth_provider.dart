import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState()) {
    _initializeAuth();
  }

  void _initializeAuth() {
    state = state.copyWith(
      isLoading: true,
      isAuthenticated: _authService.isLoggedIn,
      user: _authService.currentUser,
    );
    state = state.copyWith(isLoading: false);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _authService.login(email, password);

    if (result['success']) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: result['user'],
        error: null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
        error: result['message'],
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _authService.logout();

    if (result['success']) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
        error: null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['message'],
      );
    }
  }

  Future<void> refreshProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _authService.getProfile();

    if (result['success']) {
      state = state.copyWith(
        isLoading: false,
        user: result['user'],
        error: null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['message'],
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
