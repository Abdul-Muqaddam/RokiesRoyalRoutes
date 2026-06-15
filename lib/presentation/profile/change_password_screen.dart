import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_dialog.dart';
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
    const Color brandYellow = Color(0xFFDC423D);

    ref.listen(changePasswordViewModelProvider, (previous, next) {
      if (next is AsyncError) {
        AppDialog.show(
          context: context,
          type: DialogType.error,
          title: 'Update Failed',
          message: next.error.toString(),
        );
      } else if (next is AsyncData && previous is AsyncLoading) {
        AppDialog.show(
          context: context,
          type: DialogType.success,
          title: 'Success',
          message: 'Password changed successfully!',
          autoDismissDuration: const Duration(seconds: 2),
          onPrimaryPressed: () {
            Navigator.pop(context); // Close dialog
            context.pop(); // Go back
          },
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 80.w,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Row(
            children: [
              SizedBox(width: 20.w),
              Icon(Icons.arrow_back_ios, color: Colors.black87, size: 18.sp),
              Text(
                'Back',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          'Change Password',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(height: 20.h),
              _buildPasswordField(
                hint: 'Old Password',
                controller: _currentPasswordController,
                visible: _currentPasswordVisible,
                onToggle: () => setState(() => _currentPasswordVisible = !_currentPasswordVisible),
              ),
              SizedBox(height: 16.h),
              _buildPasswordField(
                hint: 'New Password',
                controller: _newPasswordController,
                visible: _newPasswordVisible,
                onToggle: () => setState(() => _newPasswordVisible = !_newPasswordVisible),
              ),
              SizedBox(height: 16.h),
              _buildPasswordField(
                hint: 'Confirm Password',
                controller: _confirmPasswordController,
                visible: _confirmPasswordVisible,
                onToggle: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: ElevatedButton(
                  onPressed: viewModelState is AsyncLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandYellow,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: viewModelState is AsyncLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Save', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String hint,
    required TextEditingController controller,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !visible,
        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          suffixIcon: IconButton(
            icon: Icon(
              visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.black38,
              size: 20.sp,
            ),
            onPressed: onToggle,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $hint';
          }
          return null;
        },
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
