import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/preferences_manager.dart';
import '../widgets/app_dialog.dart';
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
      AppDialog.show(
        context: context,
        title: 'Input Required',
        message: 'Please enter both username and password',
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
          AppDialog.show(
            context: context,
            title: 'Login Failed',
            message: response.message.isNotEmpty ? response.message : 'Invalid credentials',
          );
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        AppDialog.show(
          context: context,
          title: 'Login Failed',
          message: 'Invalid credentials',
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialog.show(
          context: context,
          title: 'Login Failed',
          message: 'Invalid credentials',
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_passwordVisible,
        style: TextStyle(color: AppColors.white, fontSize: 15.sp),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14.sp),
          contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          border: InputBorder.none,
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 16.w, right: 12.w),
            child: SvgPicture.asset(
              iconAsset, 
              colorFilter: ColorFilter.mode(AppColors.gold.withOpacity(0.8), BlendMode.srcIn), 
              width: 20.w,
            ),
          ),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(
              _passwordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 20.sp,
            ),
            onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
          ) : null,
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
          Image.asset(
            'assets/images/login_bg.png',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                  Colors.black,
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 28.w),
              child: Column(
                children: [
                  SizedBox(height: 60.h),
                  Column(
                    children: [
                      Text(
                        'ADMIN PANEL',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      Text(
                        'ROCKIES ROYAL ROUTES',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.gold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 60.h),
                  
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32.r),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: EdgeInsets.all(32.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(32.r),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Admin Login',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Access secure administrative controls',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                            SizedBox(height: 32.h),

                            _buildTextField(controller: _usernameController, label: 'Username', iconAsset: 'assets/icons/ic_user.svg'),
                            SizedBox(height: 16.h),
                            _buildTextField(controller: _passwordController, label: 'Password', iconAsset: 'assets/icons/ic_lock.svg', isPassword: true),
                            
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (val) => setState(() => _rememberMe = val ?? false),
                                    activeColor: AppColors.gold,
                                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                GestureDetector(
                                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                                  child: Text('Remember me', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13.sp)),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: 32.h),

                            _isLoading 
                              ? Center(child: CircularProgressIndicator(color: AppColors.gold))
                              : Container(
                                  height: 56.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16.r),
                                    gradient: LinearGradient(
                                      colors: [AppColors.gold, Color(0xFFB8860B)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.gold.withOpacity(0.4),
                                        blurRadius: 20,
                                        offset: Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                                    ),
                                    child: Text(
                                      'LOGIN', 
                                      style: TextStyle(
                                        fontSize: 16.sp, 
                                        fontWeight: FontWeight.bold, 
                                        color: Colors.black,
                                        letterSpacing: 1.5,
                                      )
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Back to Passenger/Driver Login',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13.sp),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
