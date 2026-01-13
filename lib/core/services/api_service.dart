import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/app_config.dart';
import '../config/api_endpoints.dart';
import '../models/trip_log_model.dart';
import '../models/parent_trip_model.dart';
import 'storage_service.dart';

class ApiService {
  static late Dio _dio;
  static final Connectivity _connectivity = Connectivity();

  static Future<void> init() async {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl, // Use baseUrl without /api/v1/
        connectTimeout: AppConfig.connectionTimeout,
        receiveTimeout: AppConfig.apiTimeout,
        sendTimeout: AppConfig.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(_loggingInterceptor());
    _dio.interceptors.add(_errorInterceptor());
  }

  static Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Only add auth token for non-auth endpoints
        final path = options.path;
        final isAuthEndpoint =
            path.contains('/login/') ||
            path.contains('/register/') ||
            path.contains('/password/reset/') ||
            path.contains('/otp/') ||
            path.contains('/refresh-token/');

        if (!isAuthEndpoint) {
          final token = StorageService.getAuthToken();
          if (token != null && token.isNotEmpty) {
            // Validate token format
            if (token.startsWith('eyJ')) {
              print('✅ API: Valid JWT token format detected');
            } else {
              print(
                '⚠️ API: Token does not have JWT format: ${token.substring(0, 10)}...',
              );
            }

            options.headers['Authorization'] = 'Bearer $token';
            print(
              '🔐 API: Using authentication token for ${options.method} ${options.path}',
            );
            print('🔐 Token length: ${token.length}');
            print('🔐 Token preview: ${token.substring(0, 20)}...');
            print(
              '🔐 Full Authorization header: Bearer ${token.substring(0, 20)}...',
            );
          } else {
            print(
              '⚠️ API: No authentication token found for ${options.method} ${options.path}',
            );
            print('⚠️ This will likely result in 401 Unauthorized');
            print('⚠️ User may need to log in again');
          }
        } else {
          print('🔐 API: Skipping auth for auth endpoint: ${options.path}');
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 errors with automatic token refresh
        if (error.response?.statusCode == 401) {
          print('🔄 API: 401 error detected, attempting token refresh...');

          try {
            // Try to refresh the token
            final refreshToken = StorageService.getRefreshToken();
            if (refreshToken != null && refreshToken.isNotEmpty) {
              print('🔄 API: Attempting token refresh with refresh token...');
              print('🔄 API: Refresh token length: ${refreshToken.length}');
              final refreshResponse = await _dio.post(
                ApiEndpoints.refreshToken,
                data: {'refresh': refreshToken},
              );

              if (refreshResponse.statusCode == 200) {
                final data = refreshResponse.data;
                // Handle both possible response formats
                final newAccessToken =
                    data['access'] as String? ?? data['accessToken'] as String?;

                if (newAccessToken != null && newAccessToken.isNotEmpty) {
                  await StorageService.saveAuthToken(newAccessToken);
                  print(
                    '🔄 API: Token refreshed successfully, retrying original request...',
                  );

                  // Update the original request with new token
                  error.requestOptions.headers['Authorization'] =
                      'Bearer $newAccessToken';

                  // Retry the original request
                  try {
                    final retryResponse = await _dio.fetch(
                      error.requestOptions,
                    );
                    return handler.resolve(retryResponse);
                  } catch (retryError) {
                    print('🔄 API: Retry failed: $retryError');
                  }
                }
              } else {
                print(
                  '🔄 API: Refresh token response not successful - status: ${refreshResponse.statusCode}',
                );
                print(
                  '🔄 API: Refresh token response data: ${refreshResponse.data}',
                );
              }
            } else {
              print('🔄 API: No refresh token available for refresh');
            }
          } catch (refreshError) {
            print('🔄 API: Token refresh failed: $refreshError');
            // If refresh fails, clear tokens to force re-login
            await StorageService.clearAuthTokens();
            print('🔄 API: Cleared auth tokens due to refresh failure');
          }
        }

        handler.next(error);
      },
    );
  }

  static Interceptor _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (AppConfig.enableLogging) {
          print('🚀 API Request: ${options.method} ${options.uri}');
          print('📤 Headers: ${options.headers}');
          print('📤 Data: ${options.data}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (AppConfig.enableLogging) {
          print(
            '✅ API Response: ${response.statusCode} ${response.requestOptions.uri}',
          );
          print('📥 Data: ${response.data}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (AppConfig.enableLogging) {
          final statusCode = error.response?.statusCode;
          final errorType = error.type.toString();
          final errorMessage = error.message ?? 'No error message';
          final responseData = error.response?.data;
          
          print(
            '❌ API Error: ${statusCode ?? "No Status"} ${error.requestOptions.uri}',
          );
          print('❌ Error Type: $errorType');
          print('❌ Error Message: $errorMessage');
          if (responseData != null) {
            print('📥 Response Data: $responseData');
          } else {
            print('📥 Response Data: null (Connection/Network Error)');
          }
          // Log the handled error message for better debugging
          try {
            final handledError = _handleDioError(error);
            print('📥 Handled Error Message: $handledError');
          } catch (e) {
            print('⚠️ Could not generate handled error message: $e');
          }
        }
        handler.next(error);
      },
    );
  }

  static Interceptor _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout) {
          // Handle timeout errors
          final connectivityResult = await _connectivity.checkConnectivity();
          if (connectivityResult.contains(ConnectivityResult.none)) {
            error = DioException(
              requestOptions: error.requestOptions,
              error: 'No internet connection',
              type: DioExceptionType.unknown,
            );
          }
        }
        handler.next(error);
      },
    );
  }

  // Generic HTTP methods
  static Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );

      // Handle type conversion safely
      T data;
      try {
        // Bypass special-case conversions for communication APIs to avoid
        // accidental casting to unrelated models (e.g., TripLogsResponse)
        final reqPath = response.requestOptions.path;
        final isCommunicationApi = reqPath.contains('/communication/');

        if (isCommunicationApi) {
          data = response.data as T;
        } else if (response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;

          // Check if this looks like a TripLogsResponse by checking for required fields
          if (responseData.containsKey('count') &&
              responseData.containsKey('results')) {
            data = TripLogsResponse.fromJson(responseData) as T;
          }
          // Check if this looks like a ParentTrip by checking for required fields
          else if (responseData.containsKey('trip_name') &&
              responseData.containsKey('driver_name')) {
            data = ParentTrip.fromJson(responseData) as T;
          } else {
            // For generic Map<String, dynamic> responses, return as-is
            data = response.data as T;
          }
        } else if (response.data is List<dynamic>) {
          final responseData = response.data as List<dynamic>;
          // Handle List<ParentTrip> case
          if (responseData.isNotEmpty &&
              responseData.first is Map<String, dynamic>) {
            final firstItem = responseData.first as Map<String, dynamic>;
            // Check if this looks like a ParentTrip by checking for required fields
            if (firstItem.containsKey('trip_name') &&
                firstItem.containsKey('driver_name')) {
              final parentTrips = responseData
                  .map(
                    (item) => ParentTrip.fromJson(item as Map<String, dynamic>),
                  )
                  .toList();
              data = parentTrips as T;
            } else {
              data = response.data as T;
            }
          } else {
            data = response.data as T;
          }
        } else {
          data = response.data as T;
        }
      } catch (typeError) {
        print('⚠️ Type conversion error: $typeError');
        print('⚠️ Response data type: ${response.data.runtimeType}');
        print('⚠️ Expected type: T');
        // Fallback: return raw data
        data = response.data as T;
      }

      return ApiResponse<T>.success(data);
    } on DioException catch (e) {
      return ApiResponse<T>.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse<T>.error('Unexpected error: $e');
    }
  }

  static Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResponse<T>.success(response.data, response.statusCode);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      return ApiResponse<T>.error(_handleDioError(e), statusCode);
    } catch (e) {
      return ApiResponse<T>.error('Unexpected error: $e');
    }
  }

  static Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResponse<T>.success(response.data);
    } on DioException catch (e) {
      return ApiResponse<T>.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse<T>.error('Unexpected error: $e');
    }
  }

  static Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResponse<T>.success(response.data);
    } on DioException catch (e) {
      return ApiResponse<T>.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse<T>.error('Unexpected error: $e');
    }
  }

  /// Extracts validation errors from nested error structures
  /// Handles formats like:
  /// - {'field': ['error message']}
  /// - {'field': [ErrorDetail(string='message', code='invalid')]}
  /// - {'field': {'message': 'error'}}
  static String _extractValidationErrors(dynamic errorData) {
    if (errorData is! Map<String, dynamic>) {
      return '';
    }

    final errors = <String>[];
    
    errorData.forEach((field, value) {
      String? errorMessage;
      
      if (value is List && value.isNotEmpty) {
        // Handle list of errors: [ErrorDetail(...)] or ['error message']
        final firstError = value.first;
        if (firstError is Map<String, dynamic>) {
          // ErrorDetail format: {string: 'message', code: 'invalid'}
          errorMessage = firstError['string'] as String? ?? 
                        firstError['message'] as String? ??
                        firstError.toString();
        } else {
          // Simple string list: ['error message']
          errorMessage = firstError.toString();
        }
      } else if (value is Map<String, dynamic>) {
        // Nested error object: {message: 'error'}
        errorMessage = value['string'] as String? ?? 
                      value['message'] as String? ??
                      value.toString();
      } else if (value is String) {
        errorMessage = value;
      }
      
      if (errorMessage != null && errorMessage.isNotEmpty) {
        // Capitalize field name and format error
        final fieldName = field.replaceAll('_', ' ').split(' ').map(
          (word) => word.isEmpty 
            ? word 
            : word[0].toUpperCase() + word.substring(1)
        ).join(' ');
        errors.add('$fieldName: $errorMessage');
      }
    });
    
    return errors.join('\n');
  }

  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        // Handle specific error messages from the API
        if (data is Map<String, dynamic>) {
          // First check for direct message field
          if (data.containsKey('message')) {
            final message = data['message'] as String;
            // If there's also an error field with validation details, append them
            if (data.containsKey('error')) {
              final validationErrors = _extractValidationErrors(data['error']);
              if (validationErrors.isNotEmpty) {
                return '$message\n\n$validationErrors';
              }
            }
            return message;
          }

          // Check for error field with nested structure
          if (data.containsKey('error')) {
            final errorData = data['error'];
            if (errorData is Map<String, dynamic>) {
              // Extract field-specific validation errors
              final validationErrors = _extractValidationErrors(errorData);
              if (validationErrors.isNotEmpty) {
                return validationErrors;
              }
              
              if (errorData.containsKey('non_field_errors')) {
                final nonFieldErrors = errorData['non_field_errors'] as List?;
                if (nonFieldErrors != null && nonFieldErrors.isNotEmpty) {
                  return nonFieldErrors.first.toString();
                }
              }
              // Check for message in error object
              if (errorData.containsKey('message')) {
                return errorData['message'] as String;
              }
            }
            return errorData.toString();
          }

          // Check for detail field (common in some APIs)
          if (data.containsKey('detail')) {
            return data['detail'] as String;
          }
        }

        if (statusCode == 400) {
          return 'Bad request. Please check your input.';
        } else if (statusCode == 401) {
          return 'Invalid credentials. Please check your email and password.';
        } else if (statusCode == 403) {
          return 'Forbidden. You do not have permission to perform this action.';
        } else if (statusCode == 404) {
          return 'Resource not found.';
        } else if (statusCode == 422) {
          return 'Validation error. Please check your input.';
        } else if (statusCode == 500) {
          // Try to extract specific error message from 500 response
          if (data is Map<String, dynamic>) {
            // Check for common error message fields
            if (data.containsKey('message')) {
              return data['message'] as String;
            }
            if (data.containsKey('error')) {
              final errorMsg = data['error'];
              if (errorMsg is String) {
                return errorMsg;
              }
              if (errorMsg is Map<String, dynamic>) {
                final validationErrors = _extractValidationErrors(errorMsg);
                if (validationErrors.isNotEmpty) {
                  return validationErrors;
                }
              }
            }
            if (data.containsKey('detail')) {
              return data['detail'] as String;
            }
          }
          return 'Server error. Please try again later.';
        } else {
          return 'Request failed with status code $statusCode.';
        }
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Connection error. Please check your internet connection.';
      case DioExceptionType.badCertificate:
        return 'Certificate error. Please check your connection.';
      case DioExceptionType.unknown:
        return 'Unknown error occurred. Please try again.';
    }
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse._({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(T data, [int? statusCode]) {
    return ApiResponse._(success: true, data: data, statusCode: statusCode);
  }

  factory ApiResponse.error(String error, [int? statusCode]) {
    return ApiResponse._(success: false, error: error, statusCode: statusCode);
  }
}
