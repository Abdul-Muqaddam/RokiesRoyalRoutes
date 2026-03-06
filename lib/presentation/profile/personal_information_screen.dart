import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_models.dart';
import '../../data/repositories/user_repository_impl.dart';
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

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProfileProvider).value;
    _nameController = TextEditingController(text: user?.name ?? '');
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _websiteController = TextEditingController(text: user?.website ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _nicknameController = TextEditingController(text: user?.nickname ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _bioController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    final viewModelState = ref.watch(personalInformationViewModelProvider);

    ref.listen(personalInformationViewModelProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString()), backgroundColor: Colors.red),
        );
      } else if (next is AsyncData && previous is AsyncLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: userAsync.when(
        data: (user) => SingleChildScrollView(
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
                  label: 'Username',
                  controller: TextEditingController(text: user.email.split('@').first), // Placeholder if username not in DTO
                  icon: Icons.person_outline,
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
                  label: 'Display Name',
                  controller: _nameController,
                  icon: Icons.person_outline,
                ),
                SizedBox(height: 16.h),
                _InfoTextField(
                  label: 'Email Address',
                  controller: TextEditingController(text: user.email),
                  icon: Icons.email_outlined,
                  readOnly: true,
                ),
                SizedBox(height: 16.h),
                _InfoTextField(
                  label: 'Nickname',
                  controller: _nicknameController,
                  icon: Icons.face_outlined,
                ),
                SizedBox(height: 16.h),
                _InfoTextField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  icon: Icons.phone_outlined,
                ),
                SizedBox(height: 16.h),
                _InfoTextField(
                  label: 'Website',
                  controller: _websiteController,
                  icon: Icons.language_outlined,
                ),
                SizedBox(height: 16.h),
                _InfoTextField(
                  label: 'Bio',
                  controller: _bioController,
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),
                SizedBox(height: 32.h),
                ElevatedButton(
                  onPressed: viewModelState is AsyncLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: Size(double.infinity, 54.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                  ),
                  child: viewModelState is AsyncLoading
                      ? CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)
                      : Text('Save Changes', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 15.sp, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
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
        bio: _bioController.text,
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

  const _InfoTextField({
    required this.label,
    required this.controller,
    required this.icon,
    this.readOnly = false,
    this.maxLines = 1,
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
          readOnly: readOnly,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 18.w),
            filled: true,
            fillColor: AppColors.lightGray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
          style: TextStyle(
            color: readOnly ? Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5) : Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
