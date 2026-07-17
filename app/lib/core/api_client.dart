import 'package:dio/dio.dart';
import 'env.dart';
import 'token_store.dart';

/// 백엔드가 던지는 { error: { code, message } } 를 앱 예외로.
class ApiException implements Exception {
  final String code;
  final String message;
  final int? status;
  ApiException(this.code, this.message, [this.status]);
  @override
  String toString() => message;
}

/// dio 래퍼: `{data,error}` 봉투 언래핑 + JWT 주입 + 401 자동 리프레시.
///
/// 401 처리:
///  - 요청이 401 을 받으면 저장된 리프레시 토큰으로 `POST /auth/refresh` 를
///    호출해 새 액세스+리프레시를 받고, 원 요청을 1회 재시도한다.
///  - 동시에 여러 요청이 401 을 받아도 리프레시는 **1회로 합류**한다(single-flight).
///  - 리프레시 실패(리프레시 없음/만료/재사용 감지) 시에만 강제 로그아웃 콜백.
class ApiClient {
  final Dio _dio;
  final TokenStore _tokens;
  void Function()? onUnauthorized;

  /// 진행 중인 리프레시(single-flight). null 이면 진행 중 아님.
  Future<bool>? _refreshing;

  ApiClient({TokenStore? tokens, Dio? dio})
      : _tokens = tokens ?? TokenStore(),
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: Env.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'content-type': 'application/json'},
              // 4xx/5xx 도 예외로 던지지 않고 우리가 언래핑 처리
              validateStatus: (_) => true,
            )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokens.read();
        if (token != null && token.isNotEmpty) {
          options.headers['authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) async {
        // 401 이고, 재시도 대상이면 리프레시 후 원 요청 1회 재시도.
        if (response.statusCode == 401 &&
            _shouldTryRefresh(response.requestOptions)) {
          final ok = await _refreshOnce();
          if (ok) {
            final opts = response.requestOptions;
            opts.extra['__retried'] = true;
            final token = await _tokens.read();
            if (token != null && token.isNotEmpty) {
              opts.headers['authorization'] = 'Bearer $token';
            }
            try {
              final retried = await _dio.fetch<dynamic>(opts);
              handler.resolve(retried);
              return;
            } catch (_) {
              // 재시도 실패 → 원래 401 그대로 전달
            }
          } else {
            // 리프레시 실패 시에만 강제 로그아웃.
            onUnauthorized?.call();
          }
        }
        handler.next(response);
      },
    ));
  }

  Dio get raw => _dio;
  TokenStore get tokens => _tokens;

  /// 이 요청에 대해 리프레시를 시도해도 되는가.
  ///  - 이미 재시도한 요청(무한 루프 방지) 제외
  ///  - 인증 엔드포인트(/auth/*) 자체는 제외(재귀 방지)
  bool _shouldTryRefresh(RequestOptions options) {
    if (options.extra['__retried'] == true) return false;
    final path = options.path;
    if (path.contains('/auth/refresh') ||
        path.contains('/auth/phone') ||
        path.contains('/auth/kakao') ||
        path.contains('/auth/logout')) {
      return false;
    }
    return true;
  }

  /// 리프레시를 single-flight 로 실행한다. 진행 중이면 그 Future 에 합류.
  Future<bool> _refreshOnce() {
    final existing = _refreshing;
    if (existing != null) return existing;
    final future = _performRefresh();
    _refreshing = future;
    future.whenComplete(() {
      _refreshing = null;
    });
    return future;
  }

  /// 저장된 리프레시 토큰으로 새 토큰을 받아 저장한다. 성공 여부 반환.
  Future<bool> _performRefresh() async {
    final refresh = await _tokens.readRefresh();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await _dio.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );
      if (res.statusCode == 200) {
        final body = res.data;
        final data = (body is Map && body['data'] is Map)
            ? body['data'] as Map
            : (body is Map ? body : const {});
        final newAccess = data['accessToken']?.toString();
        final newRefresh = data['refreshToken']?.toString();
        if (newAccess != null && newAccess.isNotEmpty) {
          await _tokens.writeTokens(newAccess, newRefresh);
          return true;
        }
      }
    } catch (_) {
      // 네트워크 등 → 실패로 간주
    }
    return false;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _unwrap(_dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body}) =>
      _unwrap(_dio.post(path, data: body));

  Future<dynamic> patch(String path, {Object? body}) =>
      _unwrap(_dio.patch(path, data: body));

  Future<dynamic> delete(String path) => _unwrap(_dio.delete(path));

  /// multipart 업로드(서류/사진). JWT 는 인터셉터가 주입, 봉투 언래핑.
  Future<dynamic> postMultipart(String path, FormData form) =>
      _unwrap(_dio.post(path, data: form));

  /// 인증 헤더가 붙은 GET 으로 PDF 등 바이너리를 받는다(인증 blob).
  /// 401 자동 리프레시·재시도는 인터셉터가 처리하므로, 여기서는 실패만 판정.
  Future<List<int>> getBytes(String path, {Map<String, dynamic>? query}) async {
    final res = await _dio.get<List<int>>(
      path,
      queryParameters: query,
      options: Options(responseType: ResponseType.bytes),
    );
    if (res.statusCode == 401) {
      throw ApiException('UNAUTHORIZED', '로그인이 필요합니다.', 401);
    }
    if (res.statusCode == null || res.statusCode! >= 400) {
      throw ApiException('HTTP_${res.statusCode}', '파일을 불러오지 못했습니다.',
          res.statusCode);
    }
    return res.data ?? const [];
  }

  Future<dynamic> _unwrap(Future<Response<dynamic>> future) async {
    late Response<dynamic> res;
    try {
      res = await future;
    } on DioException catch (e) {
      throw ApiException('NETWORK', '서버에 연결할 수 없습니다. (${e.type.name})');
    }
    final status = res.statusCode ?? 0;
    if (status == 401) {
      // 인터셉터가 이미 리프레시 시도 후에도 401 이면 로그아웃 필요.
      throw ApiException('UNAUTHORIZED', '로그인이 필요합니다.', 401);
    }
    final data = res.data;
    if (data is Map) {
      if (data['error'] != null) {
        final err = data['error'];
        throw ApiException(
          (err is Map ? err['code'] : null)?.toString() ?? 'ERROR',
          (err is Map ? err['message'] : null)?.toString() ?? '요청을 처리하지 못했습니다.',
          status,
        );
      }
      if (data.containsKey('data')) return data['data'];
    }
    if (status >= 400) {
      throw ApiException('HTTP_$status', '요청을 처리하지 못했습니다. ($status)', status);
    }
    return data;
  }
}
