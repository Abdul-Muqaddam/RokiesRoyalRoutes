import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum DialogType { success, error, info, warning }

class AppDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;
  final IconData? icon;
  final Color? iconColor;
  final DialogType type;

  const AppDialog({
    super.key,
    required this.title,
    required this.message,
    this.primaryButtonText = 'OK',
    this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.icon,
    this.iconColor,
    this.type = DialogType.info,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String? primaryButtonText = 'OK',
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    IconData? icon,
    Color? iconColor,
    DialogType type = DialogType.info,
    Duration? autoDismissDuration,
  }) {
    final dialog = showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => AppDialog(
        title: title,
        message: message,
        primaryButtonText: primaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        secondaryButtonText: secondaryButtonText,
        onSecondaryPressed: onSecondaryPressed,
        icon: icon,
        iconColor: iconColor,
        type: type,
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );

    if (autoDismissDuration != null) {
      Timer(autoDismissDuration, () {
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    }

    return dialog;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Determine colors based on type or provided overrides
    final effectiveIconColor = iconColor ?? _getDefaultColor(colorScheme);
    final effectiveIcon = icon ?? _getDefaultIcon();
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(32.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Icon Header
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    effectiveIconColor.withValues(alpha: 0.2),
                    effectiveIconColor.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                effectiveIcon,
                color: effectiveIconColor,
                size: 42.w,
              ),
            ),
            SizedBox(height: 24.h),
            
            // Text Content
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),
            
            // Buttons
            Column(
              children: [
                ElevatedButton(
                  onPressed: onPrimaryPressed ?? () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                    minimumSize: Size(double.infinity, 54.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                    elevation: 0,
                  ),
                  child: Text(
                    primaryButtonText!,
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                ),
                if (secondaryButtonText != null) ...[
                  SizedBox(height: 12.h),
                  TextButton(
                    onPressed: onSecondaryPressed ?? () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      minimumSize: Size(double.infinity, 50.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                    ),
                    child: Text(
                      secondaryButtonText!,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getDefaultColor(ColorScheme colorScheme) {
    switch (type) {
      case DialogType.success:
        return Colors.green;
      case DialogType.error:
        return Colors.redAccent;
      case DialogType.warning:
        return Colors.redAccent;
      case DialogType.info:
        return colorScheme.secondary;
    }
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case DialogType.success:
        return Icons.check_circle_outline;
      case DialogType.error:
        return Icons.error_outline;
      case DialogType.warning:
        return Icons.warning_amber_rounded;
      case DialogType.info:
        return Icons.info_outline;
    }
  }
}
