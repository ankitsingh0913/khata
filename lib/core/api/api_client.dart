import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

class ApiClient {

  static const String baseUrl = "http://10.0.2.2:8082/api/v1";

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static final Dio _refreshDio = Dio();

  static bool _isRefreshing = false;

  static final List<RequestOptions> _retryQueue = [];

  static Future<void> init() async {

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getAccessToken();

          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
          handler.next(options);
        },

        onError: (error, handler) async {

          if (error.response?.statusCode != 401) {
            return handler.next(error);
          }

          final request = error.requestOptions;
          _retryQueue.add(request);

          if (_isRefreshing) {
            return;
          }

          _isRefreshing = true;

          try {

            final refreshToken = await TokenStorage.getRefreshToken();

            if (refreshToken == null) {
              await TokenStorage.clear();
              return handler.next(error);
            }

            final response = await _refreshDio.post(
              "$baseUrl/auth/refresh",
              data: {
                "refreshToken": refreshToken
              },
            );

            final newAccessToken = response.data["accessToken"];
            await TokenStorage.saveAccessToken(newAccessToken);

            for (final req in _retryQueue) {
              req.headers["Authorization"] = "Bearer $newAccessToken";
              dio.fetch(req);
            }

            _retryQueue.clear();

          } catch (e) {
            await TokenStorage.clear();
          } finally {
            _isRefreshing = false;
          }
        },
      ),
    );
  }
}