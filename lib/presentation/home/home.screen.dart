import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'controllers/home.controller.dart';
import '../controllers/scan_mode.controller.dart';
import '../widgets/dumb_widgets/scan_mode_badge.dart';
import '../widgets/dumb_widgets/pulsing_search_title.dart';
import '../widgets/dumb_widgets/beacon_section_label.dart';
import '../widgets/dumb_widgets/add_tag_section.dart';
import '../widgets/dumb_widgets/background_service_toggle.dart';
import '../widgets/dumb_widgets/tag_list.dart';
import '../widgets/dumb_widgets/bluetooth_permission_gate.dart';
import '../widgets/dumb_widgets/home_drawer.dart';
import '../widgets/dumb_widgets/language_dialog.dart' as dumb;
import '../../infrastructure/theme/theme.controller.dart';
import '../../infrastructure/navigation/routes.dart';
import '../controllers/language.controller.dart';

void showLanguageDialog() {
  final langController = LanguageController.to;
  Get.dialog(Obx(() => dumb.LanguageDialog(
        selectedLangCode: langController.currentLocale.value.languageCode,
        onLanguageSelected: (l, c) => langController.changeLanguage(l, c),
        onCancel: () => Get.back(),
      )));
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    return Scaffold(
      endDrawer: Obx(() {
        final langController = LanguageController.to;
        final themeController = ThemeController.to;
        final isEn = langController.currentLocale.value.languageCode == 'en';

        return HomeDrawer(
          version: controller.version.value,
          isDarkMode: themeController.isDarkMode.value,
          currentLanguage: isEn ? 'English' : 'ภาษาไทย',
          onManageDeviceModels: () {
            Get.back();
            Get.toNamed(Routes.DEVICEMODELSETTING);
          },
          onBackgroundLogs: () {
            Get.back();
            Get.toNamed(Routes.LOG);
          },
          onChangeLanguage: showLanguageDialog,
          onThemeToggled: (val) => themeController.toggleTheme(val),
        );
      }),
      appBar: _HomeAppBar(controller: controller),
      body: Stack(
        children: [
          _HomeBody(controller: controller),
          Obx(() => BluetoothPermissionGate(
                status: controller.bleStatus.value,
                onRetry: controller.retryBlePermissions,
                onOpenSettings: () async {
                  await openAppSettings();
                  await controller.retryBlePermissions();
                },
              )),
        ],
      ),
    );
  }
}

// ── AppBar ──────────────────────────────────────────────────────────────────

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final HomeController controller;

  const _HomeAppBar({required this.controller});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 20,
      title: Obx(
        () => controller.isScanningForAdd.value
            ? PulsingSearchTitle(
                opacityAnimation: controller.pulseAnimation,
              )
            : Text(
                'app_name_short'.tr,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
              ),
      ),
      centerTitle: true,
      leadingWidth: 40.sp,
      leading: Center(
        child: Obx(() {
          final scanController = Get.put(ScanModeController());
          return ScanModeBadge(mode: scanController.currentMode.value);
        }),
      ),
      actions: [
        Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(Icons.menu, color: cs.onSurface),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ── Body (CustomScrollView) ─────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  final HomeController controller;

  const _HomeBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Collapsing, fading BackgroundServiceToggle
        SliverPersistentHeader(
          pinned: false,
          floating: false,
          delegate: _CollapsingToggleDelegate(
            controller: controller,
            maxExtent: 90,
            minExtent: 0,
          ),
        ),

        // Pinned sticky search bar
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickySearchDelegate(controller: controller),
        ),

        // Section label
        const BeaconSectionLabel(),

        // Tag cards list
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: Obx(() => TagList(
                connectedTags: controller.connectedTags.toList(),
                registeredTags: controller.registeredTags.toList(),
                deviceStates: controller.deviceStates
                    .cast<String, DeviceConnectionState>(),
                onConnect: (mac) => controller.connectToTag(mac),
                onDisconnect: (mac) => controller.disconnectTag(mac),
              )),
        ),
      ],
    );
  }
}

// ── Delegate: pinned sticky search section ──────────────────────────────────

class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  final HomeController controller;

  const _StickySearchDelegate({required this.controller});

  // TextField ~48px + vertical padding (8×2)
  static const double _height = 64;

  @override
  double get maxExtent => _height;

  @override
  double get minExtent => _height;

  @override
  bool shouldRebuild(_StickySearchDelegate old) => false;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Obx(() => AddTagSection(
            textController: controller.macAddressController,
            isScanning: controller.isScanningForAdd.value,
            pulseAnimation: controller.pulseAnimation,
            onAction: controller.isScanningForAdd.value
                ? () => controller.stopAdditionScanning()
                : () => controller.addTag(),
          )),
    );
  }
}

// ── Delegate: fade + collapse the toggle as user scrolls ───────────────────

class _CollapsingToggleDelegate extends SliverPersistentHeaderDelegate {
  final HomeController controller;
  final double maxExtent;
  final double minExtent;

  const _CollapsingToggleDelegate({
    required this.controller,
    required this.maxExtent,
    required this.minExtent,
  });

  @override
  bool shouldRebuild(_CollapsingToggleDelegate old) =>
      old.maxExtent != maxExtent || old.minExtent != minExtent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // progress: 0.0 = expanded, 1.0 = fully collapsed
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final opacity = (1.0 - progress * 1.4).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: OverflowBox(
        alignment: Alignment.topCenter,
        maxHeight: maxExtent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Obx(() => BackgroundServiceToggle(
                isRunning: controller.isServiceRunning.value,
                isToggling: controller.isTogglingService.value,
                onChanged: controller.toggleBackgroundService,
              )),
        ),
      ),
    );
  }
}
