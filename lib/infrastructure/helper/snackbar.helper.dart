import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

class SnackBarHelper {
  static void showError({String title = 'Error', required String message}) {
    if (Get.context == null) return;
    final colorScheme = Get.theme.colorScheme;

    Get.snackbar(
      '',
      '',
      titleText: Text(
        title,
        style: Get.context!.theme.textTheme.bodyLarge!.copyWith(
          color: colorScheme.onError,
        ),
      ),
      messageText: Text(
        _sanitizeMessage(message),
        style: Get.context!.theme.textTheme.bodyMedium!.copyWith(
          color: colorScheme.onError,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      snackPosition: SnackPosition.TOP,
      backgroundColor: colorScheme.error.withValues(alpha: 0.9),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
      icon: Icon(Icons.error_outline, color: colorScheme.onError, size: 25),
    );
  }

  static void showSuccess({String title = 'Success', required String message}) {
    if (Get.context == null) return;
    final colorScheme = Get.theme.colorScheme;

    Get.snackbar(
      '',
      '',
      titleText: Text(
        title,
        style: Get.context!.theme.textTheme.titleMedium!.copyWith(
          color: colorScheme.onPrimary,
        ),
      ),
      messageText: Text(
        _sanitizeMessage(message),
        style: Get.context!.theme.textTheme.bodyMedium!.copyWith(
          color: colorScheme.onPrimary,
        ),
      ),

      snackPosition: SnackPosition.TOP,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      backgroundColor: Colors.green.shade400,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
      icon: Icon(
        Icons.check_circle_outline,
        color: colorScheme.onPrimary,
        size: 25,
      ),
    );
  }

  static void showNormal({String title = 'Info', required String message}) {
    if (Get.context == null) return;
    final colorScheme = Get.theme.colorScheme;

    Get.snackbar(
      '',
      '',
      titleText: Text(
        title,
        style: Get.context!.theme.textTheme.bodyMedium!.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      messageText: Text(
        _sanitizeMessage(message),
        style: Get.context!.theme.textTheme.bodyMedium!.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      snackPosition: SnackPosition.TOP,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      backgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.9,
      ),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
      icon: Icon(Icons.info_outline, color: colorScheme.primary, size: 25),
      boxShadows: [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static String _sanitizeMessage(String message) {
    // List of common raw exception markers
    final rawErrorMarkers = [
      'Exception:',
      'PlatformException(',
      'DioError',
      'DioException',
      'TypeError:',
      'NoSuchMethodError:',
      'SocketException:',
      'HttpException:',
      'FormatException:',
    ];

    for (final marker in rawErrorMarkers) {
      if (message.contains(marker)) {
        return 'common.error_occurred'; // Fallback to localized generic error
      }
    }

    return message;
  }
}
