import 'package:dio/dio.dart';
import '../session/session_manager.dart';

/// Mirrors `src/api/utils.js`:
///
///   const baseUrl = process.env.REACT_APP_API_URL;
///   window.baseUrl = baseUrl;
///   export default baseUrl;
///
/// React's `.env` had:
///   REACT_APP_API_URL=http://localhost:8081
///
/// For Flutter this must be supplied at build/run time instead of baked in,
/// since there's no `.env`/webpack env-substitution step. Pass it with:
///   flutter run --dart-define=API_BASE_URL=http://localhost:8081
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8081',
  );
}

/// Thin wrapper around Dio that mirrors how the React code called axios
/// throughout the app, e.g.:
///
///   axios.get(`${baseUrl}/item/viewAll`, { headers: { Authorization: token } })
///   axios.post(`${baseUrl}/login`, formData, { headers: {...} })
///
/// Every authenticated call in the React app manually attached
/// `Authorization: token` (note: NOT "Bearer <token>" - the raw token string
/// is sent, matching the backend's expectation). This client attaches that
/// same header automatically via an interceptor so feature code doesn't have
/// to repeat it on every call, while preserving the exact same header value.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SessionManager.instance.token;
          if (token != null) {
            // React sent the raw token as Authorization header value
            // (no "Bearer " prefix) - see login.js / GlobalStateProvider.js.
            options.headers['Authorization'] = token;
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // Central place to hook in the same "Some Error Occurred" style
          // global handling that index.js did with window.onerror /
          // unhandledrejection + SweetAlert2. UI layer decides how to
          // surface this (see AppException below).
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  Dio get dio => _dio;
}

/// Normalizes Dio errors the same way the React code inspected
/// `error.response.status` / `error.response.data` in try/catch blocks.
class ApiException implements Exception {
  ApiException(this.statusCode, this.data, this.message);
  final int? statusCode;
  final dynamic data;
  final String message;

  factory ApiException.fromDioException(DioException e) {
    return ApiException(
      e.response?.statusCode,
      e.response?.data,
      e.message ?? 'Network error',
    );
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
