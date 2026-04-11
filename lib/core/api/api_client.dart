import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

class ApiClient {

  static const String baseUrl = "http://10.0.2.2:8082/api/v1";

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),

      validateStatus: (status) {
        return status != null && status < 500;
      },
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
          print("TOKEN SENT -> $token");

          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }

          handler.next(options);
        },

        onResponse: (response, handler) async {

          print("RESPONSE STATUS -> ${response.statusCode}");

          if (response.statusCode == 401 || response.statusCode == 403) {

            print("REFRESH TRIGGERED");

            final refreshToken = await TokenStorage.getRefreshToken();

            if (refreshToken == null) {
              return handler.next(response);
            }

            try {

              final refreshResponse = await _refreshDio.post(
                "$baseUrl/auth/refresh",
                data: {"refreshToken": refreshToken},
              );

              final newAccess = refreshResponse.data["accessToken"] as String?;
              final newRefresh = refreshResponse.data["refreshToken"] as String?;

              if (newAccess == null || newRefresh == null) {
                await TokenStorage.clear();
                return handler.next(response);
              }

              await TokenStorage.saveAccessToken(newAccess);
              await TokenStorage.saveRefreshToken(newRefresh);

              final requestOptions = response.requestOptions;
              requestOptions.headers["Authorization"] = "Bearer $newAccess";

              requestOptions.extra["isRetry"] = true;

              final retryResponse = await _refreshDio.fetch(requestOptions);

              return handler.resolve(retryResponse);

            } catch (e) {

              await TokenStorage.clear();

              return handler.next(response);
            }
          }

          handler.next(response);
        },
      ),
    );
  }
}