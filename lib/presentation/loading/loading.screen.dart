import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/loading.controller.dart';

class LoadingScreen extends GetView<LoadingController> {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isLoading.value) return const SizedBox.shrink();

      return Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // 1. Subtle Glassmorphism Background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                child: Container(
                  color:
                      context.theme.colorScheme.surface.withValues(alpha: 0.7),
                ),
              ),
            ),

            // 2. Minimalist Content
            Center(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutExpo,
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 15 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Minimalist Line Loader
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.theme.colorScheme.primary
                              .withValues(alpha: 0.8),
                        ),
                        backgroundColor: context.theme.colorScheme.primary
                            .withValues(alpha: 0.05),
                      ),
                    ),

                    if (controller.title.value.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Text(
                        controller.title.value,
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                          color: context.theme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Text(
                      controller.title.value.isEmpty
                          ? "Loading..."
                          : controller.title.value,
                      style: context.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        letterSpacing: 2.0,
                        color: context.theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
