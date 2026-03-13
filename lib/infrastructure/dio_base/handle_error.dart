// domain/handle/handle_error.dart
// ignore_for_file: constant_pattern_never_matches_value_type

import 'package:bearcon_card_app/infrastructure/helper/snackbar.helper.dart';
import 'package:bearcon_card_app/utils/dio.key.dart';
import 'package:dio/dio.dart';

Future handleError({required DioException error}) async {
  switch (error.type) {
    case DioExceptionType.cancel:
      return SnackBarHelper.showError(
        title: 'handle_error.server_connection_error_title',
        message: 'handle_error.cancel_request',
      );

    case DioExceptionType.connectionTimeout:
      return SnackBarHelper.showError(
        title: 'handle_error.server_connection_error_title',
        message: 'handle_error.connection_timeout',
      );

    case DioExceptionType.receiveTimeout:
      return SnackBarHelper.showError(
        title: 'handle_error.receive_data_error_title',
        message: 'handle_error.receive_timeout',
      );

    case DioExceptionType.sendTimeout:
      return SnackBarHelper.showError(
        title: 'handle_error.send_data_error_title',
        message: 'handle_error.send_timeout',
      );

    case DioExceptionType.connectionError:
      if (error.requestOptions.extra["retries"] == DioKeys.retries) {
        return SnackBarHelper.showError(
          title: 'handle_error.connection_lost_title',
          message: 'handle_error.no_internet_connection',
        );
      }
    case DioExceptionType.badResponse:
      // Note: 401 is handled above
      return SnackBarHelper.showError(
        title: 'handle_error.data_format_error_title',
        message: 'handle_error.invalid_data',
      );
    case DioExceptionType.badCertificate:
      return SnackBarHelper.showError(
        title: 'handle_error.data_format_error_title',
        message: 'handle_error.check_connection',
      );
    default:
      return SnackBarHelper.showError(
        title: 'handle_error.cannot_connect_server_title',
        message: 'handle_error.please_try_again',
      );
  }
}
