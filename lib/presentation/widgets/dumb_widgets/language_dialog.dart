import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// ไดอะล็อกสำหรับเลือกภาษา
class LanguageDialog extends StatelessWidget {
  final String selectedLangCode;
  final Function(String langCode, String countryCode) onLanguageSelected;
  final VoidCallback onCancel;

  const LanguageDialog({
    super.key,
    required this.selectedLangCode,
    required this.onLanguageSelected,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.language_rounded,
                  color: cs.primary,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'change_language'.tr,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 24),
            _buildLanguageOption(
              context: context,
              title: '🇺🇸 English',
              langCode: 'en',
              countryCode: 'US',
            ),
            const SizedBox(height: 12),
            _buildLanguageOption(
              context: context,
              title: '🇹🇭 ภาษาไทย',
              langCode: 'th',
              countryCode: 'TH',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'cancel'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String title,
    required String langCode,
    required String countryCode,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = selectedLangCode == langCode;
          
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onLanguageSelected(langCode, countryCode),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? cs.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? cs.primary.withValues(alpha: 0.3)
                  : cs.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? cs.primary : cs.onSurface,
                      ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: cs.primary, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// **Widgetbook UseCase**: ทดสอบไดอะล็อกเปลี่ยนภาษา
@widgetbook.UseCase(
  name: 'Default',
  type: LanguageDialog,
  path: '[Home]/LanguageDialog',
)
Widget languageDialogUseCase(BuildContext context) {
  return LanguageDialog(
    selectedLangCode: context.knobs.list(
      label: 'Selected Language',
      options: ['en', 'th'],
      initialOption: 'en',
    ),
    onLanguageSelected: (l, c) {},
    onCancel: () {},
  );
}
