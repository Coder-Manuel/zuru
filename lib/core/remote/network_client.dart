import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

enum NetworkDioClientType { supabase, global }

class NetworkClient {
  static final Map<String, String> _headers = {
    'Content-Type': 'application/json;charset=UTF-8',
  };

  static Dio dioClient({
    required String baseUrl,
    List<Interceptor> interceptors = const [],
  }) {
    Dio dio = Dio();
    dio.options.baseUrl = baseUrl;
    dio.options.headers = _headers;
    dio.options.followRedirects = true;
    dio.options.contentType = 'application/json;charset=UTF-8';
    dio.options.responseType = ResponseType.json;
    dio.options.validateStatus = (s) => s != null && s >= 200 && s < 300;

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          responseBody: true,
          error: true,
          requestHeader: true,
          responseHeader: false,
          request: false,
          requestBody: true,
        ),
      );
    }

    if (interceptors.isNotEmpty) {
      dio.interceptors.addAll(interceptors);
    }

    if (kDebugMode && !kIsWeb) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () =>
          HttpClient()
            ..badCertificateCallback =
                (X509Certificate cert, String host, int port) => true;
    }

    return dio;
  }
}
