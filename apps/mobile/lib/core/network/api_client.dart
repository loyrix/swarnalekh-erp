import 'package:dio/dio.dart';

class ApiClient {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );
  static String? _authToken;

  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: _normalizeBaseUrl(_configuredBaseUrl),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
      ),
    );

    // Response interceptor — unwrap standard { success, data } format
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          } else {
            options.headers.remove('Authorization');
          }

          if (options.data is FormData) {
            options.headers.remove('Content-Type');
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          // API wraps responses as { success: true, data: {...} }
          if (response.data is Map && response.data['success'] == true) {
            response.data = response.data['data'];
          }
          handler.next(response);
        },
        onError: (error, handler) {
          // Extract message from API error response
          if (error.response?.data is Map) {
            final message = error.response?.data['message'] ?? 'Unknown error';
            error = DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              message: message.toString(),
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  void setAuthToken(String token) {
    _authToken = token;
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _authToken = null;
    dio.options.headers.remove('Authorization');
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
