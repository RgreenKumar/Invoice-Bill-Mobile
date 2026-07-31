import 'package:dio/dio.dart';
import '../session/session_manager.dart';

/// Normalizes an id coming from decoded JSON (or a route path parameter)
/// into the clean path segment a `/{id}`-style endpoint expects.
///
/// JSON numbers decode in Dart as `int` when the source literal has no
/// decimal point, but some backends serialize numeric ids as e.g. `68.0`
/// - which would decode as a `double` and, if interpolated straight into
/// a URL, produce `/updateBill/68.0` instead of `/updateBill/68`. Route
/// matchers that expect a purely-numeric segment reject that with a
/// generic "no matching endpoint"-style error that looks identical to a
/// genuinely wrong path. This strips a trailing `.0` so a whole-number
/// id always round-trips as a plain integer string, regardless of
/// whether it arrived as `int`, `double`, or already a `String`.
String idParam(dynamic id) {
  if (id is num) {
    return id == id.roundToDouble() ? id.toInt().toString() : id.toString();
  }
  final s = id.toString();
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

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
        // NOTE: deliberately no default Content-Type here (see interceptor
        // below) - see the comment there for why.
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
          // axios only ever sets Content-Type: application/json when a
          // request actually carries a JSON body (POST/PUT/PATCH with
          // `data`). A bare Dio BaseOptions.headers entry, by contrast,
          // attaches that header to *every* request regardless of method -
          // including GET/DELETE calls that have no body at all, such as
          // `/downloadBill/{id}`. Several backends run a body-parsing
          // filter keyed off Content-Type that chokes on
          // "Content-Type: json" with zero bytes of body. Mirror axios
          // exactly: only attach JSON Content-Type when this request
          // actually has a body - and never for FormData (file upload)
          // requests, which need their own multipart boundary Content-Type
          // that Dio sets itself; leave those untouched exactly as before.
          if (options.data != null && options.data is! FormData) {
            options.headers['Content-Type'] = 'application/json';
          } else if (options.data == null) {
            options.headers.remove('Content-Type');
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
