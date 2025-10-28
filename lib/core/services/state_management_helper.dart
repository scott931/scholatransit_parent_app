// Import for ApiResponse
import 'api_service.dart';

/// Centralized state management helper to eliminate duplicates
class StateManagementHelper {
  /// Create standard loading state
  static T setLoadingState<T>(T state, T Function() copyWith) {
    return copyWith();
  }

  /// Create standard error state
  static T setErrorState<T>(
    T state,
    String error,
    T Function({bool? isLoading, String? error}) copyWith,
  ) {
    return copyWith(isLoading: false, error: error);
  }

  /// Create standard success state
  static T setSuccessState<T>(
    T state,
    T Function({bool? isLoading, String? error}) copyWith,
  ) {
    return copyWith(isLoading: false, error: null);
  }

  /// Handle API response with standard state updates
  static T handleApiResponse<T>(
    T state,
    ApiResponse<Map<String, dynamic>> response,
    T Function({bool? isLoading, String? error}) copyWith,
  ) {
    if (response.success) {
      return copyWith(isLoading: false, error: null);
    } else {
      return copyWith(
        isLoading: false,
        error: response.error ?? 'An unexpected error occurred',
      );
    }
  }

  /// Handle API response with data extraction
  static T handleApiResponseWithData<T, D>(
    T state,
    ApiResponse<Map<String, dynamic>> response,
    D Function(Map<String, dynamic>) fromJson,
    T Function({bool? isLoading, String? error, D? data}) copyWith,
  ) {
    if (response.success && response.data != null) {
      try {
        final data = fromJson(response.data!);
        return copyWith(isLoading: false, error: null, data: data);
      } catch (e) {
        return copyWith(
          isLoading: false,
          error: 'Failed to parse response data: $e',
        );
      }
    } else {
      return copyWith(
        isLoading: false,
        error: response.error ?? 'An unexpected error occurred',
      );
    }
  }

  /// Handle API response with list extraction
  static T handleApiResponseWithList<T, D>(
    T state,
    ApiResponse<Map<String, dynamic>> response,
    D Function(Map<String, dynamic>) fromJson,
    T Function({bool? isLoading, String? error, List<D>? data}) copyWith,
  ) {
    if (response.success && response.data != null) {
      try {
        final data = response.data!;
        final results = data['results'] as List? ?? [];
        final items = results
            .map((item) => fromJson(item as Map<String, dynamic>))
            .toList();
        return copyWith(isLoading: false, error: null, data: items);
      } catch (e) {
        return copyWith(
          isLoading: false,
          error: 'Failed to parse response data: $e',
        );
      }
    } else {
      return copyWith(
        isLoading: false,
        error: response.error ?? 'An unexpected error occurred',
      );
    }
  }
}
