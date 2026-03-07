import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/app_color_provider.dart';
import '../../data/providers/app_config_provider.dart';

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
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _updateControllers();
  }

  void _updateControllers() {
    final config = ref.read(appConfigProvider);
    _accentHexController.text = config.accentColor;
    _primaryHexController.text = config.primaryColor;
    _textHexController.text = config.textColor;
    _highlightTextHexController.text = config.highlightTextColor;
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

  Future<void> _applyColor(String text, String? Function(String) validator, Future<void> Function(String) setter, String colorName) async {
    if (_isUpdating) return;
    
    final error = validator(text);
    if (error != null) {
      setState(() {
        if (colorName == 'Accent') _accentErrorMessage = error;
        if (colorName == 'Primary') _primaryErrorMessage = error;
        if (colorName == 'Text') _textErrorMessage = error;
        if (colorName == 'Highlight') _highlightTextErrorMessage = error;
      });
      return;
    }

    // Clear previous errors if fixed
    setState(() {
      if (colorName == 'Accent') _accentErrorMessage = null;
      if (colorName == 'Primary') _primaryErrorMessage = null;
      if (colorName == 'Text') _textErrorMessage = null;
      if (colorName == 'Highlight') _highlightTextErrorMessage = null;
    });

    setState(() => _isUpdating = true);
    try {
      // 1. Await the specific provider update (syncs to local prefs & state)
      await setter(text);
      
      // 2. Create the global config from the NOW-UPDATED local providers
      final newConfig = ref.read(appConfigProvider.notifier).createConfigFromLocal();
      
      // 3. Push to backend & re-fetch to ensure everything is perfect
      await ref.read(appConfigProvider.notifier).updateConfig(newConfig);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$colorName color updated and synced with cloud!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sync $colorName color: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _applyAccentColor() => _applyColor(_accentHexController.text, _validateHex, (val) => ref.read(appColorProvider.notifier).updateColor(val), 'Accent');
  void _applyPrimaryColor() => _applyColor(_primaryHexController.text, _validateHex, (val) => ref.read(appPrimaryColorProvider.notifier).updateColor(val), 'Primary');
  void _applyTextColor() => _applyColor(_textHexController.text, _validateHex, (val) => ref.read(appTextColorProvider.notifier).updateColor(val), 'Text');
  void _applyHighlightTextColor() => _applyColor(_highlightTextHexController.text, _validateHex, (val) => ref.read(appHighlightTextColorProvider.notifier).updateColor(val), 'Highlight');

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
                  'assets/icons/ic_customization.svg',
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

    // Listen to global config changes (e.g. from fetchConfig) and update controllers
    ref.listen(appConfigProvider, (previous, next) {
      if (previous != next) {
        _updateControllers();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Customize App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              setState(() => _isUpdating = true);
              try {
                await ref.read(appConfigProvider.notifier).fetchConfig();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Configuration refreshed from cloud!')),
                  );
                }
              } finally {
                if (mounted) setState(() => _isUpdating = false);
              }
            },
            tooltip: 'Refresh from Cloud',
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Theme Customization',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Enter hex codes to personalize your app theme',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
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
                    SizedBox(height: 20.h),
                    _ProfileScreenCustomizationComponent(accentColor: accentColor),
                    SizedBox(height: 20.h),
                    ...List.generate(4, (index) => Column(
                      children: [
                        _BookingStepCard(stepNumber: index + 1, accentColor: accentColor),
                        if (index < 3) SizedBox(height: 20.h),
                      ],
                    )),
                  ],
                ),
              ),
            ),
          ),
          if (_isUpdating)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
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
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
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
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
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

class _BookingStepCard extends StatelessWidget {
  final int stepNumber;
  final Color accentColor;
  const _BookingStepCard({required this.stepNumber, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    String stepName = '';
    String stepDesc = '';
    switch (stepNumber) {
      case 1: 
        stepName = 'Location Selection';
        stepDesc = 'Customize fields and recent/saved places.';
        break;
      case 2:
        stepName = 'Schedule Picking';
        stepDesc = 'Customize date/time grids and labels.';
        break;
      case 3:
        stepName = 'Vehicle Choice';
        stepDesc = 'Customize filters and vehicle cards.';
        break;
      case 4:
        stepName = 'Checkout Summary';
        stepDesc = 'Customize personal details and payment section.';
        break;
    }

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
            'Booking Step $stepNumber Customization',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            stepName,
            style: TextStyle(fontSize: 14.sp, color: accentColor, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            stepDesc,
            style: TextStyle(fontSize: 12.sp, color: AppColors.mediumGray),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => context.push('/booking-step-$stepNumber-customization'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              minimumSize: Size(double.infinity, 48.h),
            ),
            child: Text(
              'Customize Step $stepNumber',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
