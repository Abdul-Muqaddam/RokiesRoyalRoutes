import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'forgot_password_view_model.dart';

class ForgotPasswordScreen extends ConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(forgotPasswordViewModelProvider.notifier);
    final state = ref.watch(forgotPasswordViewModelProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.network(
            'https://storage.googleapis.com/uxpilot-auth.appspot.com/f83471f3ec-dc37248d325e8dbe5c12.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: Theme.of(context).colorScheme.primary),
          ),
          
          // Overlay
          Container(color: Colors.black.withOpacity(0.6)),
          
          SafeArea(
            child: Column(
              children: [
                // Back Button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.w, top: 8.h),
                    child: IconButton(
                      onPressed: () {
                        ref.read(forgotPasswordViewModelProvider.notifier).resetState();
                        context.pop();
                      },
                      icon: const Icon(Icons.chevron_left, color: AppColors.white, size: 32),
                    ),
                  ),
                ),
                
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Enter your email to reset your password',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: 48.h),
                          
                          // Email Field
                          TextField(
                            onChanged: viewModel.onEmailChanged,
                            style: const TextStyle(color: AppColors.white),
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
                              filled: true,
                              fillColor: AppColors.inputFillColor,
                              prefixIcon: Padding(
                                padding: EdgeInsets.all(12.w),
                                child: SvgPicture.asset(
                                  'assets/icons/ic_email.svg',
                                  colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.secondary, BlendMode.srcIn),
                                  width: 24.w,
                                  height: 24.w,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: const BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                              ),
                            ),
                          ),
                          
                          if (viewModel.successMessage != null) ...[
                            SizedBox(height: 16.h),
                            Text(
                              viewModel.successMessage!,
                              style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 13.sp),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          
                          if (viewModel.error != null) ...[
                            SizedBox(height: 16.h),
                            Text(
                              viewModel.error!,
                              style: TextStyle(color: Colors.redAccent, fontSize: 13.sp),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          
                          SizedBox(height: 32.h),
                          
                          state.when(
                            data: (_) => ElevatedButton(
                              onPressed: viewModel.forgotPassword,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              ),
                              child: Text(
                                'Submit',
                                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                              ),
                            ),
                            loading: () => Center(
                              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary),
                            ),
                            error: (err, _) => ElevatedButton(
                              onPressed: viewModel.forgotPassword,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              ),
                              child: Text(
                                'Submit',
                                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 32.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
