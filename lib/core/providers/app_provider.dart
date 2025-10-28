import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final appVersionProvider = Provider<String>((ref) => '1.0.0');

final isOnlineProvider = StateProvider<bool>((ref) => true);

final loadingProvider = StateProvider<bool>((ref) => false);

final errorProvider = StateProvider<String?>((ref) => null);

void clearError(WidgetRef ref) {
  ref.read(errorProvider.notifier).state = null;
}

void setLoading(WidgetRef ref, bool loading) {
  ref.read(loadingProvider.notifier).state = loading;
}

void setError(WidgetRef ref, String? error) {
  ref.read(errorProvider.notifier).state = error;
}
