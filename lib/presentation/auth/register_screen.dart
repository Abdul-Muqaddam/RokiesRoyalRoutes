import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../core/theme/app_theme.dart';

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
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  void _register() async {
    FocusScope.of(context).unfocus();
    
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match', style: TextStyle(color: AppColors.white)), backgroundColor: Colors.red)
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    final request = RegisterRequest(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    
    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.register(request);
      if (response.success && mounted) {
        context.go('/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message, style: const TextStyle(color: AppColors.white)), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString(), style: const TextStyle(color: AppColors.white)), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String iconAsset,
    bool isPassword = false,
    bool isConfirmPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    bool obscure = false;
    if (isPassword) {
      obscure = !_passwordVisible;
    } else if (isConfirmPassword) {
      obscure = !_confirmPasswordVisible;
    }
    
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: AppColors.inputFillColor,
        prefixIcon: Padding(
          padding: EdgeInsets.all(12.w),
          child: SvgPicture.asset(iconAsset, colorFilter: const ColorFilter.mode(AppColors.gold, BlendMode.srcIn), width: 24.w, height: 24.w),
        ),
        suffixIcon: (isPassword || isConfirmPassword) ? IconButton(
          icon: SvgPicture.asset(
            (isPassword ? _passwordVisible : _confirmPasswordVisible) 
                ? 'assets/icons/ic_eye.svg' 
                : 'assets/icons/ic_eye_off.svg',
            colorFilter: const ColorFilter.mode(AppColors.gold, BlendMode.srcIn),
            width: 24.w, height: 24.w,
          ),
          onPressed: () {
            setState(() {
              if (isPassword) {
                _passwordVisible = !_passwordVisible;
              } else {
                _confirmPasswordVisible = !_confirmPasswordVisible;
              }
            });
          },
        ) : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.gold),
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
            'https://storage.googleapis.com/uxpilot-auth.appspot.com/95454c7c78-e74374d6e8bc6d12792c.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: AppColors.navy), // fallback
          ),
          Container(color: Colors.black.withValues(alpha: 0.6)), // Overlay
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
                            const Spacer(),
                            Text('Create Account', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: AppColors.white), textAlign: TextAlign.center),
                            SizedBox(height: 8.h),
                            Text('Sign up to get started', style: TextStyle(fontSize: 14.sp, color: Colors.white70), textAlign: TextAlign.center),
                            SizedBox(height: 48.h),

                            _buildTextField(controller: _nameController, label: 'Name', iconAsset: 'assets/icons/ic_user.svg'),
                            SizedBox(height: 16.h),
                            _buildTextField(controller: _emailController, label: 'Email', iconAsset: 'assets/icons/ic_email.svg', keyboardType: TextInputType.emailAddress),
                            SizedBox(height: 16.h),
                            _buildTextField(controller: _passwordController, label: 'Password', iconAsset: 'assets/icons/ic_lock.svg', isPassword: true),
                            SizedBox(height: 16.h),
                            _buildTextField(controller: _confirmPasswordController, label: 'Confirm Password', iconAsset: 'assets/icons/ic_lock.svg', isConfirmPassword: true),
                            
                            SizedBox(height: 40.h),

                            _isLoading 
                              ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                              : ElevatedButton(
                                  onPressed: _register,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 16.h),
                                    backgroundColor: AppColors.gold,
                                    foregroundColor: AppColors.navy,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                  ),
                                  child: Text('Register', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                                ),
                            SizedBox(height: 24.h),
                  
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Already have an account? ", style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
                                GestureDetector(
                                  onTap: () => context.pop(), // pop back to login
                                  child: Text('Login', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                                )
                              ],
                            ),
                            const Spacer(),
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
