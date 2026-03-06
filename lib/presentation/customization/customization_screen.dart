import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/app_color_provider.dart';

class CustomizationScreen extends ConsumerStatefulWidget {
  const CustomizationScreen({super.key});

  @override
  ConsumerState<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends ConsumerState<CustomizationScreen> {
  final _accentHexController = TextEditingController();
  final _primaryHexController = TextEditingController();
  final _textHexController = TextEditingController();
  final _highlightTextHexController = TextEditingController();
  String? _accentErrorMessage;
  String? _primaryErrorMessage;
  String? _textErrorMessage;
  String? _highlightTextErrorMessage;

  @override
  void initState() {
    super.initState();
    final accentColor = ref.read(appColorProvider);
    final primaryColor = ref.read(appPrimaryColorProvider);
    final textColor = ref.read(appTextColorProvider);
    final highlightTextColor = ref.read(appHighlightTextColorProvider);

    _accentHexController.text = _colorToHex(accentColor);
    _primaryHexController.text = _colorToHex(primaryColor);
    _textHexController.text = _colorToHex(textColor);
    _highlightTextHexController.text = _colorToHex(highlightTextColor);
  }

  String _colorToHex(Color color) {
    return color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  }

  @override
  void dispose() {
    _accentHexController.dispose();
    _primaryHexController.dispose();
    _textHexController.dispose();
    _highlightTextHexController.dispose();
    super.dispose();
  }

  String? _validateHex(String text) {
    if (text.contains('#')) return "Do not include the '#' symbol";
    if (text.isEmpty) return "Hex code cannot be empty";
    final hexRegExp = RegExp(r'^([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$');
    if (!hexRegExp.hasMatch(text)) return "Please enter a valid 3 or 6 digit hex code";
    return null;
  }

  void _applyAccentColor() {
    final text = _accentHexController.text;
    final error = _validateHex(text);
    setState(() => _accentErrorMessage = error);
    if (error != null) return;

    ref.read(appColorProvider.notifier).updateColor(text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Accent color updated to #$text!')),
      );
    }
  }

  void _applyPrimaryColor() {
    final text = _primaryHexController.text;
    final error = _validateHex(text);
    setState(() => _primaryErrorMessage = error);
    if (error != null) return;

    ref.read(appPrimaryColorProvider.notifier).updateColor(text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Primary color updated to #$text!')),
      );
    }
  }

  void _applyTextColor() {
    final text = _textHexController.text;
    final error = _validateHex(text);
    setState(() => _textErrorMessage = error);
    if (error != null) return;

    ref.read(appTextColorProvider.notifier).updateColor(text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Text color updated to #$text!')),
      );
    }
  }

  void _applyHighlightTextColor() {
    final text = _highlightTextHexController.text;
    final error = _validateHex(text);
    setState(() => _highlightTextErrorMessage = error);
    if (error != null) return;

    ref.read(appHighlightTextColorProvider.notifier).updateColor(text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Highlight text color updated to #$text!')),
      );
    }
  }

  Widget _buildColorSection({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required String? errorMessage,
    required Color previewColor,
    required Color accentColor,
    required Color textColor,
    required VoidCallback onApply,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  color: previewColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1.5),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary)),
                    Text(subtitle,
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: controller,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
            onChanged: (value) {
              if (errorMessage != null) setState(() {});
            },
            decoration: InputDecoration(
              labelText: 'Hex Code (e.g., FFFFFF)',
              labelStyle: const TextStyle(color: AppColors.mediumGray),
              filled: true,
              fillColor: AppColors.lightGray,
              prefixText: '#',
              prefixStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
              errorText: errorMessage,
              prefixIcon: Padding(
                padding: EdgeInsets.all(12.w),
                child: SvgPicture.asset(
                  'assets/icons/ic_settings.svg',
                  colorFilter:
                      ColorFilter.mode(accentColor, BlendMode.srcIn),
                  width: 24.w,
                  height: 24.w,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: AppColors.dividerGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: accentColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          ElevatedButton(
            onPressed: onApply,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              backgroundColor: accentColor,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
              minimumSize: Size(double.infinity, 48.h),
            ),
            child: Text('Apply',
                style:
                    TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = ref.watch(appColorProvider);
    final primaryColor = ref.watch(appPrimaryColorProvider);
    final textColor = ref.watch(appTextColorProvider);
    final highlightTextColor = ref.watch(appHighlightTextColorProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
                onPressed: () => context.pop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Customize App',
                        style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.displayLarge?.color ??
                                Theme.of(context).colorScheme.primary),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Enter hex codes to personalize your app theme',
                        style: TextStyle(
                            fontSize: 14.sp, color: Theme.of(context).textTheme.bodyMedium?.color),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32.h),

                      // Accent Color Section
                      _buildColorSection(
                        title: 'Accent Color',
                        subtitle: 'Buttons, highlights, icons',
                        controller: _accentHexController,
                        errorMessage: _accentErrorMessage,
                        previewColor: accentColor,
                        accentColor: accentColor,
                        textColor: textColor,
                        onApply: _applyAccentColor,
                      ),
                      SizedBox(height: 20.h),

                      // Primary Color Section
                      _buildColorSection(
                        title: 'Primary Color',
                        subtitle: 'Navigation bar, text, headings',
                        controller: _primaryHexController,
                        errorMessage: _primaryErrorMessage,
                        previewColor: primaryColor,
                        accentColor: accentColor,
                        textColor: textColor,
                        onApply: _applyPrimaryColor,
                      ),
                      SizedBox(height: 20.h),

                      // Text Color Section
                      _buildColorSection(
                        title: 'App Text Color',
                        subtitle: 'Text throughout the entire application',
                        controller: _textHexController,
                        errorMessage: _textErrorMessage,
                        previewColor: textColor,
                        accentColor: accentColor,
                        textColor: textColor,
                        onApply: _applyTextColor,
                      ),
                      SizedBox(height: 20.h),

                      // Highlight Text Color Section
                      _buildColorSection(
                        title: 'Highlighted Text Color',
                        subtitle: 'Text on buttons and highlighted areas',
                        controller: _highlightTextHexController,
                        errorMessage: _highlightTextErrorMessage,
                        previewColor: highlightTextColor,
                        accentColor: accentColor,
                        textColor: textColor,
                        onApply: _applyHighlightTextColor,
                      ),
                      SizedBox(height: 32.h),
                      _HomeScreenCustomizationComponent(accentColor: accentColor),
                SizedBox(height: 32.h),
                _ProfileScreenCustomizationComponent(accentColor: accentColor),
                SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeScreenCustomizationComponent extends StatelessWidget {
  final Color accentColor;
  const _HomeScreenCustomizationComponent({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Home Screen Customization',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Customize layout, banners, and home specific elements.',
            style: TextStyle(fontSize: 12.sp, color: AppColors.mediumGray),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => context.push('/home-customization'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              minimumSize: Size(double.infinity, 48.h),
            ),
            child: Text(
              'Customize Home',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
class _ProfileScreenCustomizationComponent extends StatelessWidget {
  final Color accentColor;
  const _ProfileScreenCustomizationComponent({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Screen Customization',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Customize layout, sections, and items on your profile page.',
            style: TextStyle(fontSize: 12.sp, color: AppColors.mediumGray),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => context.push('/profile-customization'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              minimumSize: Size(double.infinity, 48.h),
            ),
            child: Text(
              'Customize Profile',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
