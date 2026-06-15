import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import 'forgot_password_view_model.dart';

class ForgotPasswordScreen extends ConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(forgotPasswordViewModelProvider.notifier);
    final state = ref.watch(forgotPasswordViewModelProvider);
    final currentStep = viewModel.currentStep;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Back Button ────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: GestureDetector(
                onTap: () {
                  if (currentStep == ForgotPasswordStep.email) {
                    viewModel.resetState();
                    context.pop();
                  } else if (currentStep == ForgotPasswordStep.otp) {
                    viewModel.goToStep(ForgotPasswordStep.email);
                  } else if (currentStep == ForgotPasswordStep.newPassword) {
                    viewModel.goToStep(ForgotPasswordStep.otp);
                  } else {
                    viewModel.resetState();
                    context.pop();
                  }
                },
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

            // ── Step Content ────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStepContent(context, ref, currentStep, viewModel, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    WidgetRef ref,
    ForgotPasswordStep step,
    ForgotPasswordViewModel viewModel,
    AsyncValue<void> state,
  ) {
    switch (step) {
      case ForgotPasswordStep.email:
        return _EmailStep(viewModel: viewModel, state: state);
      case ForgotPasswordStep.otp:
        return _OtpStep(viewModel: viewModel, state: state);
      case ForgotPasswordStep.newPassword:
        return _NewPasswordStep(viewModel: viewModel, state: state);
      case ForgotPasswordStep.success:
        return _SuccessStep();
    }
  }
}

// ── Email Step ─────────────────────────────────────────────────────────────

class _EmailStep extends StatelessWidget {
  final ForgotPasswordViewModel viewModel;
  final AsyncValue<void> state;

  const _EmailStep({required this.viewModel, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      key: const ValueKey('email_step'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 32.h),

          // Title
          Text(
            'Verification email or phone number',
            style: GoogleFonts.outfit(
              fontSize: 26.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
              height: 1.3,
            ),
          ),

          SizedBox(height: 40.h),

          // Input
          _MinimalInput(
            hintText: 'Email or phone number',
            onChanged: viewModel.onEmailChanged,
            keyboardType: TextInputType.emailAddress,
          ),

          // Error / Success messages
          _StatusMessages(viewModel: viewModel),

          const Spacer(),

          // Send OTP button pinned to bottom
          _BottomButton(
            label: 'Send OTP',
            isLoading: state.isLoading,
            onTap: viewModel.requestOtp,
          ),

          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}

class _OtpStep extends StatefulWidget {
  final ForgotPasswordViewModel viewModel;
  final AsyncValue<void> state;

  const _OtpStep({required this.viewModel, required this.state});

  @override
  State<_OtpStep> createState() => _OtpStepState();
}

class _OtpStepState extends State<_OtpStep> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      key: const ValueKey('otp_step'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 32.h),

          // Title
          Text(
            'Phone verification',
            style: GoogleFonts.outfit(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 12.h),

          // Subtitle
          Text(
            'Enter your OTP code',
            style: GoogleFonts.outfit(
              fontSize: 15.sp,
              color: const Color(0xFF8B8B8B),
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 40.h),

          // Custom OTP Input
          _CustomOtpInput(
            controller: _otpController,
            focusNode: _focusNode,
            length: 6, // Supabase default OTP length is 6
            onChanged: widget.viewModel.onOtpChanged,
          ),

          SizedBox(height: 24.h),

          // Resend prompt
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive code? ",
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  color: const Color(0xFF5A5A5A),
                ),
              ),
              GestureDetector(
                onTap: widget.state.isLoading ? null : widget.viewModel.requestOtp,
                child: Text(
                  'Resend again',
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    color: const Color(0xFFEBB020),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          _StatusMessages(viewModel: widget.viewModel),

          const Spacer(),

          // Verify Button
          SizedBox(
            width: double.infinity,
            height: 54.h,
            child: ElevatedButton(
              onPressed: widget.state.isLoading ? null : () {
                widget.viewModel.verifyOtp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC423D), // Yellow from mockup
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: widget.state.isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      'Verify',
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}

class _CustomOtpInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final Function(String) onChanged;

  const _CustomOtpInput({
    required this.controller,
    required this.focusNode,
    this.length = 6,
    required this.onChanged,
  });

  @override
  State<_CustomOtpInput> createState() => _CustomOtpInputState();
}

class _CustomOtpInputState extends State<_CustomOtpInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically calculate width to ensure it fits perfectly on all screen sizes
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 48.w; // 24.w padding on each side from parent
    final spacing = 8.w;
    final boxWidth = (availableWidth - (spacing * (widget.length - 1))) / widget.length;
    final boxHeight = boxWidth * 1.15; // Make it slightly taller than wide

    return SizedBox(
      height: boxHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Custom UI Boxes (rendered underneath)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (index) {
              final text = widget.controller.text;
              
              // Box is highlighted ONLY if the textfield is focused AND it's the current target box
              final isFocused = widget.focusNode.hasFocus && 
                                (text.length == index || (index == widget.length - 1 && text.length == widget.length));
              
              final hasValue = text.length > index;

              return Container(
                width: boxWidth, 
                height: boxHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isFocused 
                        ? const Color(0xFFDC423D) 
                        : const Color(0xFFE0E0E0),
                    width: isFocused ? 2.0 : 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  hasValue ? text[index] : '',
                  style: GoogleFonts.outfit(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              );
            }),
          ),
          
          // Invisible TextField overlay to capture all taps and keyboard input natively
          TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            maxLength: widget.length,
            keyboardType: TextInputType.number,
            autofocus: true,
            onChanged: widget.onChanged, // THIS WAS MISSING
            showCursor: false,
            enableInteractiveSelection: false,
            style: const TextStyle(color: Colors.transparent),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}

// ── New Password Step ──────────────────────────────────────────────────────

class _NewPasswordStep extends StatelessWidget {
  final ForgotPasswordViewModel viewModel;
  final AsyncValue<void> state;

  const _NewPasswordStep({required this.viewModel, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      key: const ValueKey('password_step'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 32.h),

          // Title
          Text(
            'Set password',
            style: GoogleFonts.outfit(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 12.h),

          // Subtitle
          Text(
            'Set your password',
            style: GoogleFonts.outfit(
              fontSize: 15.sp,
              color: const Color(0xFF8B8B8B),
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 40.h),

          _MinimalInput(
            hintText: 'Enter Your Password',
            onChanged: viewModel.onNewPasswordChanged,
            isPassword: true,
          ),

          SizedBox(height: 16.h),

          _MinimalInput(
            hintText: 'Confirm Password',
            onChanged: viewModel.onConfirmPasswordChanged,
            isPassword: true,
          ),

          SizedBox(height: 8.h),
          
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Atleast 1 number or a special character',
              style: GoogleFonts.outfit(
                fontSize: 13.sp,
                color: const Color(0xFFAFAFAF), // Lighter gray from mockup
              ),
            ),
          ),

          _StatusMessages(viewModel: viewModel),

          const Spacer(),

          // Register Button (matches mockup exactly)
          SizedBox(
            width: double.infinity,
            height: 54.h,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : viewModel.resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC423D), // Mockup yellow
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: state.isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      'Register',
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}

// ── Success Step ───────────────────────────────────────────────────────────

class _SuccessStep extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      key: const ValueKey('success_step'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),

          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline_rounded,
                color: AppColors.gold, size: 64.r),
          ),

          SizedBox(height: 32.h),

          Text(
            'Password Reset!',
            style: GoogleFonts.outfit(
              fontSize: 26.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 12.h),

          Text(
            'Your password has been reset successfully.\nYou can now log in with your new password.',
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              color: AppColors.mediumGray,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          _BottomButton(
            label: 'Back to Login',
            isLoading: false,
            onTap: () {
              ref.read(forgotPasswordViewModelProvider.notifier).resetState();
              context.go('/login');
            },
          ),

          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}

// ── Reusable Widgets ───────────────────────────────────────────────────────

class _MinimalInput extends StatefulWidget {
  final String hintText;
  final Function(String) onChanged;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextAlign textAlign;
  final double? fontSize;
  final double? letterSpacing;

  const _MinimalInput({
    required this.hintText,
    required this.onChanged,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textAlign = TextAlign.start,
    this.fontSize,
    this.letterSpacing,
  });

  @override
  State<_MinimalInput> createState() => _MinimalInputState();
}

class _MinimalInputState extends State<_MinimalInput> {
  bool _obscure = true;
  final FocusNode _focus = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _isFocused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
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
        focusNode: _focus,
        onChanged: widget.onChanged,
        obscureText: widget.isPassword && _obscure,
        keyboardType: widget.keyboardType,
        textAlign: widget.textAlign,
        style: GoogleFonts.outfit(
          color: AppColors.black,
          fontSize: widget.fontSize ?? 15.sp,
          letterSpacing: widget.letterSpacing,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: GoogleFonts.outfit(
            color: const Color(0xFFBDBDBD),
            fontSize: widget.fontSize ?? 15.sp,
            letterSpacing: widget.letterSpacing,
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
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: _isFocused ? AppColors.gold : const Color(0xFFBDBDBD),
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

class _BottomButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _BottomButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.gold));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: constraints.maxWidth,
            height: 56.h,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(14.r),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusMessages extends StatelessWidget {
  final ForgotPasswordViewModel viewModel;
  const _StatusMessages({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (viewModel.successMessage != null) ...[
          SizedBox(height: 12.h),
          Text(
            viewModel.successMessage!,
            style: GoogleFonts.outfit(
                color: Colors.green, fontSize: 13.sp),
            textAlign: TextAlign.center,
          ),
        ],
        if (viewModel.error != null) ...[
          SizedBox(height: 12.h),
          Text(
            viewModel.error!,
            style: GoogleFonts.outfit(
                color: Colors.redAccent, fontSize: 13.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
