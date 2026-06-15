import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../widgets/app_dialog.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _isDriver = false;

  @override
  void initState() {
    super.initState();
    _usernameFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final response = _isDriver
          ? await repo.driverLogin(
              _usernameController.text.trim(), _passwordController.text)
          : await repo.login(
              _usernameController.text.trim(), _passwordController.text);

      if (response.success && mounted) {
        if (_isDriver) {
          context.go('/driver-home');
        } else {
          context.go('/home');
        }
      } else if (mounted) {
        _showErrorDialog(response.message);
      }
    } catch (e) {
      if (mounted) _showErrorDialog(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(dynamic error, {bool isSuccess = false}) {
    final String message =
        isSuccess ? error.toString() : ErrorHandler.getReadableError(error);
    AppDialog.show(
      context: context,
      type: isSuccess ? DialogType.success : DialogType.error,
      title: isSuccess ? 'Success' : 'Action Required',
      message: message,
      primaryButtonText: isSuccess ? 'OK' : 'Try Again',
      onPrimaryPressed: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Back Button ────────────────────────────
                SizedBox(height: 16.h),
                GestureDetector(
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

                SizedBox(height: 48.h),

                // ── Title ──────────────────────────────────
                Text(
                  'Sign in',
                  style: GoogleFonts.outfit(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),

                SizedBox(height: 20.h),
                _buildRoleToggle(),
                SizedBox(height: 24.h),

                // ── Email Field ────────────────────────────
                _InputField(
                  controller: _usernameController,
                  focusNode: _usernameFocus,
                  hintText: 'Email or Phone Number',
                ),

                SizedBox(height: 20.h),

                // ── Password Field ─────────────────────────
                _InputField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  hintText: 'Enter Your Password',
                  isPassword: true,
                  obscureText: !_passwordVisible,
                  onSuffixTap: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                ),

                SizedBox(height: 12.h),

                // ── Forget Password ────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => context.push('/forgot-password'),
                    child: Text(
                      'Forget password?',
                      style: GoogleFonts.outfit(
                        color: Colors.redAccent,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 40.h),

                // ── Sign In Button ─────────────────────────
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.gold))
                    : _SignInButton(onTap: _login),

                SizedBox(height: 36.h),

                // ── Divider ────────────────────────────────
                Row(
                  children: [
                    Expanded(
                        child: Divider(
                            color: AppColors.lightGray, thickness: 0.8)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      child: Text(
                        'or',
                        style: GoogleFonts.outfit(
                            color: AppColors.mediumGray, fontSize: 14.sp),
                      ),
                    ),
                    Expanded(
                        child: Divider(
                            color: AppColors.lightGray, thickness: 0.8)),
                  ],
                ),

                SizedBox(height: 28.h),

                // ── Google Button ──────────────────────────
                Center(
                  child: _SocialButton(
                    imagePath: 'assets/images/google.png',
                    onTap: () {},
                  ),
                ),

                SizedBox(height: 40.h),

                // ── Sign Up Link ───────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => context.push('/register'),
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: GoogleFonts.outfit(
                          color: AppColors.mediumGray,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
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

// ── Reusable Input Field ─────────────────────────────────────────────────────

class _InputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onSuffixTap;

  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.isPassword = false,
    this.obscureText = false,
    this.onSuffixTap,
  });

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
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
        obscureText: widget.obscureText,
        style: GoogleFonts.outfit(
          color: AppColors.black,
          fontSize: 15.sp,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: GoogleFonts.outfit(
            color: const Color(0xFFBDBDBD),
            fontWeight: FontWeight.w400,
            fontSize: 15.sp,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 14.h),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    widget.obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _isFocused ? AppColors.gold : const Color(0xFFBDBDBD),
                    size: 20.sp,
                  ),
                  onPressed: widget.onSuffixTap,
                )
              : null,
        ),
      ),
    );
  }
}

// ── Sign In Button ─────────────────────────────────────────────────────────

class _SignInButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SignInButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: constraints.maxWidth,
            height: 56.h,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(12.r),
            ),
            alignment: Alignment.center,
            child: Text(
              'Sign In',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Social Button ──────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final String imagePath;
  final VoidCallback onTap;
  const _SocialButton({required this.imagePath, required this.onTap});

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
          imagePath,
          width: 24.w,
          height: 24.w,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _AnimateIn extends StatelessWidget {
  final Widget child;
  final int delay;

  const _AnimateIn({required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
