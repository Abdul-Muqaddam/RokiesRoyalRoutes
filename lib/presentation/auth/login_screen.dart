import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _rememberMe = false;

  void _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.login(_usernameController.text.trim(), _passwordController.text);
      if (response.success && mounted) {
        context.go('/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message, style: TextStyle(color: AppColors.white)), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString(), style: TextStyle(color: AppColors.white)), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String iconAsset,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !_passwordVisible,
      style: const TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
        filled: true,
        fillColor: AppColors.inputFillColor,
        prefixIcon: Padding(
          padding: EdgeInsets.all(12.w),
          child: SvgPicture.asset(iconAsset, colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.secondary, BlendMode.srcIn), width: 24.w, height: 24.w),
        ),
        suffixIcon: isPassword ? IconButton(
          icon: SvgPicture.asset(
            _passwordVisible ? 'assets/icons/ic_eye.svg' : 'assets/icons/ic_eye_off.svg',
            colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.secondary, BlendMode.srcIn),
            width: 24.w, height: 24.w,
          ),
          onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
        ) : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://storage.googleapis.com/uxpilot-auth.appspot.com/f83471f3ec-dc37248d325e8dbe5c12.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: Theme.of(context).colorScheme.primary), // fallback
          ),
          Container(color: Colors.black.withOpacity(0.6)), // Overlay
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Spacer(), // Replaces top SizedBox to push content down properly
                            Text('Welcome Back', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: AppColors.white), textAlign: TextAlign.center),
                            SizedBox(height: 8.h),
                            Text('Sign in to continue', style: TextStyle(fontSize: 14.sp, color: Colors.white70), textAlign: TextAlign.center),
                            SizedBox(height: 48.h),

                            _buildTextField(controller: _usernameController, label: 'Username', iconAsset: 'assets/icons/ic_user.svg'),
                            SizedBox(height: 16.h),
                            _buildTextField(controller: _passwordController, label: 'Password', iconAsset: 'assets/icons/ic_lock.svg', isPassword: true),
                            
                            SizedBox(height: 16.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Theme(
                                        data: Theme.of(context).copyWith(unselectedWidgetColor: Colors.white54),
                                        child: SizedBox(
                                          width: 24.w,
                                          height: 24.w,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: (val) => setState(() => _rememberMe = val ?? false),
                                            activeColor: Theme.of(context).colorScheme.secondary,
                                            checkColor: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Flexible(
                                        child: Text(
                                          'Remember Me', 
                                          style: TextStyle(color: AppColors.white, fontSize: 13.sp),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.push('/forgot-password'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot Password?', 
                                    style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 13.sp, fontWeight: FontWeight.w600),
                                  ),
                                )
                              ],
                            ),
                            SizedBox(height: 32.h),

                            _isLoading 
                              ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary))
                              : ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 16.h),
                                    backgroundColor: Theme.of(context).colorScheme.secondary,
                                    foregroundColor: Theme.of(context).colorScheme.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                  ),
                                  child: Text('Login', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                                ),
                            SizedBox(height: 24.h),
                  
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Don't have an account? ", style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
                                GestureDetector(
                                  onTap: () => context.push('/register'),
                                  child: Text('Sign Up', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                                )
                              ],
                            ),
                            const Spacer(), // Balances the spacer at the top
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
