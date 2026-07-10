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

/// dio 래퍼: `{data,error}` 봉투 언래핑 + JWT 주입 + 401 처리.
class ApiClient {
  final Dio _dio;
  final TokenStore _tokens;
  void Function()? onUnauthorized;

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
    ));
  }

  Dio get raw => _dio;
  TokenStore get tokens => _tokens;

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
  Future<List<int>> getBytes(String path, {Map<String, dynamic>? query}) async {
    final res = await _dio.get<List<int>>(
      path,
      queryParameters: query,
      options: Options(responseType: ResponseType.bytes),
    );
    if (res.statusCode == 401) {
      onUnauthorized?.call();
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
      onUnauthorized?.call();
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
