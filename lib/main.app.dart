import 'package:bearcon_card_app/generated/locales.g.dart';
import 'package:bearcon_card_app/infrastructure/navigation/navigation.dart';
import 'package:bearcon_card_app/infrastructure/theme/app_theme.dart';
import 'package:bearcon_card_app/presentation/loading/controllers/loading.controller.dart';
import 'package:bearcon_card_app/presentation/loading/loading.screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

class Main extends StatelessWidget {
  final String initialRoute;

  const Main({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return GetMaterialApp(
          initialRoute: initialRoute,
          getPages: Nav.routes,
          darkTheme: AppTheme.dark,
          theme: AppTheme.light,
          themeMode: ThemeMode.system,
          translationsKeys: AppTranslation.translations,
          locale: Get.deviceLocale,
          fallbackLocale: const Locale('th', 'TH'),
          builder: (context, child) {
            return Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    if (FocusScope.of(context).hasFocus) {
                      FocusScope.of(context).unfocus();
                    }
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  child: child!,
                ),
                Obx(() {
                  final loadingController = Get.find<LoadingController>();
                  return loadingController.isLoading.value
                      ? const LoadingScreen()
                      : const SizedBox.shrink();
                }),
              ],
            );
          },
        );
      },
    );
  }
}
