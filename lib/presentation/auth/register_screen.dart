import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../widgets/app_dialog.dart';
import '../widgets/phone_field.dart';
import '../../core/utils/countries.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _referralController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _referralFocus = FocusNode();

  bool _isLoading = false;
  bool _isDriver = false;
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
    _confirmFocus.addListener(() => setState(() {}));
    _phoneFocus.addListener(() => setState(() {}));
    _referralFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _referralController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _phoneFocus.dispose();
    _referralFocus.dispose();
    super.dispose();
  }

  void _register() async {
    FocusScope.of(context).unfocus();

    if (_passwordController.text != _confirmPasswordController.text) {
      _showDialog('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    final request = RegisterRequest(
      name: _nameController.text.trim(),
      username: _emailController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _isDriver ? 'driver' : 'user',
      referralCode: _referralController.text.trim().isEmpty ? null : _referralController.text.trim(),
    );

    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.register(request);
      if (response.success && mounted) {
        final msg = response.message.toLowerCase().contains('verification required')
            ? 'Membership request sent. Please verify your email.'
            : 'Welcome to Rockies Royal. Please login to continue.';
        _showDialog(msg, isSuccess: true);
      } else if (mounted) {
        _showDialog(response.message);
      }
    } catch (e) {
      if (mounted) _showDialog(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDialog(dynamic error, {bool isSuccess = false}) {
    final String message =
        isSuccess ? error.toString() : ErrorHandler.getReadableError(error);
    AppDialog.show(
      context: context,
      type: isSuccess ? DialogType.success : DialogType.error,
      title: isSuccess ? 'Success' : 'Registration Error',
      message: message,
      primaryButtonText: isSuccess ? 'Sign In' : 'Try Again',
      onPrimaryPressed: () {
        Navigator.pop(context);
        if (isSuccess) context.go('/login');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Back Button ─────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios_new,
                          size: 18.sp, color: AppColors.black),
                      SizedBox(width: 6.w),
                      Text(
                        'Back',
                        style: GoogleFonts.outfit(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Scrollable body ─────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12.h),

                    // Title
                    Text(
                      'Sign up',
                      style: GoogleFonts.outfit(
                        fontSize: 30.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),

                    SizedBox(height: 20.h),
                    _buildRoleToggle(),
                    SizedBox(height: 24.h),

                    // Name
                    _FocusField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      hintText: 'Name',
                    ),

                    SizedBox(height: 16.h),

                    // Email
                    _FocusField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      hintText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),

                    SizedBox(height: 16.h),

                    // Phone Number
                    AppPhoneField(
                      controller: _phoneController,
                    ),

                    SizedBox(height: 16.h),

                    // Password
                    _FocusField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      hintText: 'Password',
                      isPassword: true,
                    ),

                    SizedBox(height: 16.h),

                    // Confirm Password
                    _FocusField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmFocus,
                      hintText: 'Confirm Password',
                      isPassword: true,
                    ),

                    SizedBox(height: 16.h),

                    // Referral Code
                    _FocusField(
                      controller: _referralController,
                      focusNode: _referralFocus,
                      hintText: 'Referral Code (Optional)',
                    ),

                    SizedBox(height: 16.h),

                    // Gender Dropdown
                    _GenderDropdown(
                      value: _selectedGender,
                      onChanged: (val) => setState(() => _selectedGender = val),
                      genders: _genders,
                    ),

                    SizedBox(height: 20.h),

                    // Terms
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.gold, size: 20.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: 'By signing up, you agree to the ',
                              style: GoogleFonts.outfit(
                                color: AppColors.mediumGray,
                                fontSize: 13.sp,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Terms of service',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: ' and ',
                                  style: GoogleFonts.outfit(
                                      color: AppColors.mediumGray),
                                ),
                                TextSpan(
                                  text: 'Privacy policy.',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 28.h),

                    // Sign Up Button
                    _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.gold))
                        : _SignUpButton(onTap: _register),

                    SizedBox(height: 28.h),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color: AppColors.lightGray, thickness: 0.8)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                          child: Text('or',
                              style: GoogleFonts.outfit(
                                  color: AppColors.mediumGray,
                                  fontSize: 14.sp)),
                        ),
                        Expanded(
                            child: Divider(
                                color: AppColors.lightGray, thickness: 0.8)),
                      ],
                    ),

                    SizedBox(height: 24.h),

                    // Google Button
                    Center(
                      child: _GoogleButton(onTap: () {}),
                    ),

                    SizedBox(height: 32.h),

                    // Sign In Footer
                    Center(
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: GoogleFonts.outfit(
                              color: AppColors.black,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign in',
                                style: GoogleFonts.outfit(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isDriver = false),
              child: Container(
                decoration: BoxDecoration(
                  color: !_isDriver ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: !_isDriver
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                alignment: Alignment.center,
                child: Text(
                  'Passenger',
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: !_isDriver ? FontWeight.w600 : FontWeight.w500,
                    color: !_isDriver ? AppColors.black : AppColors.mediumGray,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isDriver = true),
              child: Container(
                decoration: BoxDecoration(
                  color: _isDriver ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: _isDriver
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                alignment: Alignment.center,
                child: Text(
                  'Chauffeur',
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: _isDriver ? FontWeight.w600 : FontWeight.w500,
                    color: _isDriver ? AppColors.black : AppColors.mediumGray,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Focus-aware Input Field ────────────────────────────────────────────────

class _FocusField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool isPassword;
  final TextInputType keyboardType;

  const _FocusField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_FocusField> createState() => _FocusFieldState();
}

class _FocusFieldState extends State<_FocusField> {
  bool _isFocused = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
  }

  void _onFocus() => setState(() => _isFocused = widget.focusNode.hasFocus);

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _isFocused ? AppColors.gold : const Color(0xFFE0E0E0),
          width: _isFocused ? 1.5 : 1.0,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: widget.keyboardType,
        obscureText: widget.isPassword && _obscure,
        style: GoogleFonts.outfit(color: AppColors.black, fontSize: 15.sp),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: GoogleFonts.outfit(
              color: const Color(0xFFBDBDBD), fontSize: 15.sp),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 14.h),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _isFocused
                        ? AppColors.gold
                        : const Color(0xFFBDBDBD),
                    size: 20.sp,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
        ),
      ),
    );
  }
}


// ── Gender Dropdown ────────────────────────────────────────────────────────

class _GenderDropdown extends StatelessWidget {
  final String? value;
  final List<String> genders;
  final ValueChanged<String?> onChanged;

  const _GenderDropdown({
    required this.value,
    required this.genders,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            'Gender',
            style: GoogleFonts.outfit(
                color: const Color(0xFFBDBDBD), fontSize: 15.sp),
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: const Color(0xFFBDBDBD), size: 22.sp),
          style: GoogleFonts.outfit(color: AppColors.black, fontSize: 15.sp),
          items: genders.map((g) {
            return DropdownMenuItem(
              value: g,
              child: Text(g),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Sign Up Button ─────────────────────────────────────────────────────────

class _SignUpButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SignUpButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(14.r),
        ),
        alignment: Alignment.center,
        child: Text(
          'Sign Up',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Google Button ──────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Image.asset(
          'assets/images/google.png',
          width: 24.w,
          height: 24.w,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
