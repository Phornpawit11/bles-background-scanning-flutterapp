// domain/dio_base/dio_interceptor.dart
import 'package:bearcon_card_app/infrastructure/dio_base/handle_error.dart';
import 'package:dio/dio.dart';

InterceptorsWrapper dioHandler() {
  return InterceptorsWrapper(
    onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
      return handler.next(options);
    },
    onResponse: (Response response, ResponseInterceptorHandler handler) {
      return handler.next(response);
    },
    onError: (DioException error, ErrorInterceptorHandler handler) {
      if (error.requestOptions.extra['disableGlobalError'] != true) {
        handleError(error: error);
      }
      return handler.next(error);
    },
  );
}
