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

  static Future<void> init() async {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getAccessToken();

          print("TOKEN USED: $token");

          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            try{
              final refreshToken = await TokenStorage.getRefreshToken();
              final response = await Dio().post(
                "http://10.0.2.2:8082/api/v1/auth/refresh",
                data: {
                  "refreshToken": refreshToken
                },
              );

              final newAccessToken = response.data["accessToken"];
              await TokenStorage.saveAccessToken(newAccessToken);

              error.requestOptions.headers["Authorization"] =
              "Bearer $newAccessToken";

              final retry = await Dio().fetch(error.requestOptions);

              return handler.resolve(retry);
            }catch (e){
              TokenStorage.clear();
              return handler.next(error);
            }
          }
        }
      ),
    );
  }
}