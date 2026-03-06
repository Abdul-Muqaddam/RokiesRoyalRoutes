import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import 'change_password_view_model.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModelState = ref.watch(changePasswordViewModelProvider);

    ref.listen(changePasswordViewModelProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString()), backgroundColor: Colors.red),
        );
      } else if (next is AsyncData && previous is AsyncLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Security',
                style: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color, fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24.h),
              _PasswordTextField(
                label: 'Current Password',
                controller: _currentPasswordController,
                obscureText: !_currentPasswordVisible,
                onToggleVisibility: () => setState(() => _currentPasswordVisible = !_currentPasswordVisible),
              ),
              SizedBox(height: 16.h),
              _PasswordTextField(
                label: 'New Password',
                controller: _newPasswordController,
                obscureText: !_newPasswordVisible,
                onToggleVisibility: () => setState(() => _newPasswordVisible = !_newPasswordVisible),
              ),
              SizedBox(height: 16.h),
              _PasswordTextField(
                label: 'Confirm New Password',
                controller: _confirmPasswordController,
                obscureText: !_confirmPasswordVisible,
                onToggleVisibility: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
              ),
              SizedBox(height: 32.h),
              ElevatedButton(
                onPressed: viewModelState is AsyncLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: viewModelState is AsyncLoading ? Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5) : Theme.of(context).colorScheme.primary,
                  minimumSize: Size(double.infinity, 54.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                ),
                child: viewModelState is AsyncLoading
                    ? CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)
                    : Text('Change Password', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changePassword() {
    if (_formKey.currentState!.validate()) {
      ref.read(changePasswordViewModelProvider.notifier).changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
            confirmPassword: _confirmPasswordController.text,
          );
    }
  }
}

class _PasswordTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleVisibility;

  const _PasswordTextField({
    required this.label,
    required this.controller,
    required this.obscureText,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12.sp),
        ),
        SizedBox(height: 4.h),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.secondary, size: 18.w),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Theme.of(context).colorScheme.secondary,
                size: 18.w,
              ),
              onPressed: onToggleVisibility,
            ),
            filled: true,
            fillColor: AppColors.lightGray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14.sp, fontWeight: FontWeight.w500),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
        ),
      ],
    );
  }
}
