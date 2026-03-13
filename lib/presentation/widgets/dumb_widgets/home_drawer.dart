import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// เมนูหลักด้านข้าง (Drawer)
class HomeDrawer extends StatelessWidget {
  final String version;
  final bool isDarkMode;
  final String currentLanguage;
  final VoidCallback onManageDeviceModels;
  final VoidCallback onBackgroundLogs;
  final VoidCallback onChangeLanguage;
  final ValueChanged<bool> onThemeToggled;

  const HomeDrawer({
    super.key,
    required this.version,
    required this.isDarkMode,
    required this.currentLanguage,
    required this.onManageDeviceModels,
    required this.onBackgroundLogs,
    required this.onChangeLanguage,
    required this.onThemeToggled,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Drawer(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _HomeDrawerHeader(),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.memory_rounded, color: cs.primary),
            title: Text(
              'manage_device_models'.tr,
              style: textTheme.titleMedium?.copyWith(
                color: cs.onSurface,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
            onTap: onManageDeviceModels,
          ),
          ListTile(
            leading: Icon(Icons.receipt_long_outlined, color: cs.primary),
            title: Text(
              'background_logs'.tr,
              style: textTheme.titleMedium?.copyWith(
                color: cs.onSurface,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
            onTap: onBackgroundLogs,
          ),
          ListTile(
            leading: Icon(Icons.language_rounded, color: cs.primary),
            title: Text(
              'language'.tr,
              style: textTheme.titleMedium?.copyWith(
                color: cs.onSurface,
              ),
            ),
            subtitle: Text(
              currentLanguage,
              style: textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            onTap: onChangeLanguage,
          ),
          SwitchListTile(
            secondary: Icon(Icons.dark_mode_rounded, color: cs.primary),
            title: Text(
              'dark_mode'.tr,
              style: textTheme.titleMedium?.copyWith(
                color: cs.onSurface,
              ),
            ),
            value: isDarkMode,
            onChanged: onThemeToggled,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'app_name'.tr,
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'version'.trParams({'version': version}),
                  style: textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.3),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeDrawerHeader extends StatelessWidget {
  const _HomeDrawerHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DrawerHeader(
      decoration: BoxDecoration(
        color: cs.primary,
        gradient: LinearGradient(
          colors: [
            cs.primary,
            cs.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.onPrimary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bluetooth_searching_rounded,
              color: cs.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'The Dot',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onPrimary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// **Widgetbook UseCase**: ทดสอบเมนูหลัก
@widgetbook.UseCase(
  name: 'Default',
  type: HomeDrawer,
  path: '[Home]/HomeDrawer',
)
Widget homeDrawerUseCase(BuildContext context) {
  return HomeDrawer(
    version: context.knobs.string(label: 'Version', initialValue: '1.0.0'),
    isDarkMode: context.knobs.boolean(label: 'Is Dark Mode', initialValue: false),
    currentLanguage: context.knobs.list(
      label: 'Language',
      options: ['English', 'ภาษาไทย'],
      initialOption: 'English',
    ),
    onManageDeviceModels: () {},
    onBackgroundLogs: () {},
    onChangeLanguage: () {},
    onThemeToggled: (val) {},
  );
}
