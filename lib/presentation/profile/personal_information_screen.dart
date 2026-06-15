import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_models.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../widgets/app_dialog.dart';
import '../widgets/phone_field.dart';
import 'personal_information_view_model.dart';

class PersonalInformationScreen extends ConsumerStatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  ConsumerState<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends ConsumerState<PersonalInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _bioController;
  late TextEditingController _nicknameController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _websiteController = TextEditingController();
    _nicknameController = TextEditingController();
  }

  void _initializeControllers(UserDto user) {
    if (_isInitialized) return;
    _nameController.text = user.name;
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _phoneController.text = user.phone;
    _websiteController.text = user.website;
    _nicknameController.text = user.nickname;
    _isInitialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    final viewModelState = ref.watch(personalInformationViewModelProvider);

    // Listen to view model state for success/error handling
    ref.listen(personalInformationViewModelProvider, (previous, next) {
      if (next is AsyncError) {
        AppDialog.show(
          context: context,
          type: DialogType.error,
          title: 'Update Failed',
          message: next.error.toString().contains('42501') 
            ? 'Permission denied. You likely need to run the RLS policies in your Supabase SQL editor to allow profile updates.'
            : next.error.toString(),
        );
      } else if (next is AsyncData && previous is AsyncLoading) {
        // Force re-initialization from the updated provider data next time it changes
        _isInitialized = false;
        
        AppDialog.show(
          context: context,
          type: DialogType.success,
          title: 'Success',
          message: 'Profile updated successfully!',
          autoDismissDuration: const Duration(seconds: 2),
          onPrimaryPressed: () {
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Go back to previous screen
          },
        );
      }
    });

    // Listen to user profile changes and update controllers
    ref.listen(userProfileProvider, (previous, next) {
      next.whenData((user) {
        if (!_isInitialized) {
          _initializeControllers(user);
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: userAsync.when(
        data: (user) {
          // Fallback initialization if it hasn't happened yet
          if (!_isInitialized) {
            _initializeControllers(user);
          }
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Details',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14.sp, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 16.h),
                  _InfoTextField(
                    label: 'Email Address (Read Only)',
                    controller: TextEditingController(text: user.email),
                    icon: Icons.email_outlined,
                    readOnly: true,
                  ),
                  SizedBox(height: 16.h),
                  _InfoTextField(
                    label: 'First Name',
                    controller: _firstNameController,
                    icon: Icons.person_outline,
                  ),
                  SizedBox(height: 16.h),
                  _InfoTextField(
                    label: 'Last Name',
                    controller: _lastNameController,
                    icon: Icons.person_outline,
                  ),
                  SizedBox(height: 16.h),
                  _InfoTextField(
                    label: 'Display Name (Full Name)',
                    controller: _nameController,
                    icon: Icons.person_outline,
                    onChanged: (val) {
                      // Automatically try to fill first/last if empty
                      if (val.contains(' ') && _firstNameController.text.isEmpty && _lastNameController.text.isEmpty) {
                        final parts = val.split(' ');
                        _firstNameController.text = parts.first;
                        _lastNameController.text = parts.last;
                      }
                    },
                  ),
                  SizedBox(height: 16.h),
                  _InfoTextField(
                    label: 'Nickname',
                    controller: _nicknameController,
                    icon: Icons.face_outlined,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Phone Number',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  AppPhoneField(
                    controller: _phoneController,
                  ),
                  SizedBox(height: 16.h),
                  _InfoTextField(
                    label: 'Website',
                    controller: _websiteController,
                    icon: Icons.language_outlined,
                  ),
                  SizedBox(height: 32.h),
                  ElevatedButton(
                    onPressed: viewModelState is AsyncLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                      minimumSize: Size(double.infinity, 54.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                    ),
                    child: viewModelState is AsyncLoading
                        ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onSecondary)
                        : Text('Save Changes', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      ref.read(personalInformationViewModelProvider.notifier).updateProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        name: _nameController.text,
        nickname: _nicknameController.text,
        phone: _phoneController.text,
        website: _websiteController.text,
      );
    }
  }
}

class _InfoTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool readOnly;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const _InfoTextField({
    required this.label,
    required this.controller,
    required this.icon,
    this.readOnly = false,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 14.sp,
            color: readOnly ? Colors.grey : AppColors.black,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 20.w),
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }
}
