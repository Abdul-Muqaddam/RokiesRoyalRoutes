import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/preferences_manager.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both username and password')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final response = await ref.read(authRepositoryProvider).adminLogin(username, password);
      
      if (mounted) {
        if (response.success) {
          if (_rememberMe) {
            ref.read(preferencesManagerProvider).saveAdminRememberMe(true);
          }
          context.pushReplacement('/customization');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message.isNotEmpty ? response.message : 'Invalid credentials')),
          );
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        String errorMessage = 'Invalid credentials';
        
        // Try to get the error message from the response data if available
        if (e.response != null && e.response?.data != null) {
          final data = e.response?.data;
          if (data is Map<String, dynamic> && data.containsKey('message')) {
            errorMessage = data['message'].toString();
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: Invalid credentials')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
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
                            const Spacer(),
                            Text('Admin Login', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: AppColors.white), textAlign: TextAlign.center),
                            SizedBox(height: 8.h),
                            Text('Log in to continue to the admin panel', style: TextStyle(fontSize: 14.sp, color: Colors.white70), textAlign: TextAlign.center),
                            SizedBox(height: 48.h),

                            _buildTextField(controller: _usernameController, label: 'Username', iconAsset: 'assets/icons/ic_user.svg'),
                            SizedBox(height: 16.h),
                            _buildTextField(controller: _passwordController, label: 'Password', iconAsset: 'assets/icons/ic_lock.svg', isPassword: true),
                            
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Theme(
                                  data: Theme.of(context).copyWith(unselectedWidgetColor: Colors.white70),
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (val) => setState(() => _rememberMe = val ?? false),
                                    activeColor: Theme.of(context).colorScheme.secondary,
                                    checkColor: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                                  child: Text('Remember me', style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: 24.h),

                            ElevatedButton(
                                  onPressed: _isLoading ? () {} : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 16.h),
                                    backgroundColor: Theme.of(context).colorScheme.secondary,
                                    foregroundColor: Theme.of(context).colorScheme.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                  ),
                                  child: _isLoading 
                                      ? SizedBox(height: 20.h, width: 20.h, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary))
                                      : Text('Login', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
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
