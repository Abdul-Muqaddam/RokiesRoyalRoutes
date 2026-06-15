import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/models/user_models.dart';
import '../../core/utils/countries.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _selectedGender = 'Male';
  bool _isLoading = false;
  String _countryCode = '+880';
  String _countryFlag = 'bd';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final user = await ref.read(userProfileProvider.future);
    if (mounted) {
      setState(() {
        _nameController.text = user.name;
        _emailController.text = user.email;
        _phoneController.text = user.phone;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(userRepositoryProvider);
      final request = UpdateProfileRequest(
        name: _nameController.text,
        phone: _phoneController.text,
      );
      
      final response = await repository.updateProfile(request);
      if (response.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        ref.invalidate(userProfileProvider);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    const Color brandYellow = Color(0xFFDC423D);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 15.h),
            _buildTopAppBar(context),
            SizedBox(height: 15.h),
            Expanded(
              child: userAsync.when(
                data: (user) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(24.r),
                  child: Column(
                    children: [
                      _buildAvatarSection(user, brandYellow),
                      SizedBox(height: 32.h),
                      _buildTextField('Full Name', _nameController, Icons.person_outline),
                      SizedBox(height: 16.h),
                      _buildTextField('Email', _emailController, Icons.email_outlined, enabled: false),
                      SizedBox(height: 16.h),
                      _buildPhoneField(brandYellow),
                      SizedBox(height: 16.h),
                      _buildGenderDropdown(),
                      SizedBox(height: 16.h),
                      _buildTextField('Address', _addressController, Icons.location_on_outlined),
                      SizedBox(height: 32.h),
                      _buildUpdateButton(brandYellow),
                      SizedBox(height: 120.h),
                    ],
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator(color: brandYellow)),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(Icons.menu, onTap: () => Scaffold.of(context).openDrawer()),
          Text(
            'Edit Profile',
            style: TextStyle(color: Colors.black, fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 42.w), // Balance for centering
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEA),
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 20.sp),
      ),
    );
  }

  Widget _buildAvatarSection(UserDto user, Color brandYellow) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120.r,
              height: 120.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: brandYellow, width: 2),
                image: user.avatarUrl.isNotEmpty
                    ? DecorationImage(image: NetworkImage(user.avatarUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: user.avatarUrl.isEmpty
                  ? Icon(Icons.person, size: 60.r, color: Colors.grey[200])
                  : null,
            ),
            Positioned(
              bottom: 4.r,
              right: 4.r,
              child: Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: brandYellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(Icons.edit_outlined, size: 14.r, color: Colors.white),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Text(
          user.name,
          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, IconData icon, {bool enabled = true}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: TextStyle(fontSize: 15.sp, color: enabled ? Colors.black87 : Colors.grey),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 20.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
      ),
    );
  }

  Widget _buildPhoneField(Color brandYellow) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showCountryPicker(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2.r),
                    child: Image.network('https://flagcdn.com/w40/$_countryFlag.png', width: 24.w, height: 16.h, fit: BoxFit.cover),
                  ),
                  SizedBox(width: 4.w),
                  Icon(Icons.keyboard_arrow_down, size: 16.sp, color: Colors.black54),
                  SizedBox(width: 4.w),
                ],
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Your mobile number',
                prefixText: '$_countryCode ',
                prefixStyle: TextStyle(color: Colors.black87, fontSize: 15.sp, fontWeight: FontWeight.w500),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.r),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text('Select Country', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            SizedBox(height: 20.h),
            ...countries.map((c) => _buildCountryItem(c.name, c.code, c.flag)),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryItem(String name, String code, String flag) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(2.r),
        child: Image.network('https://flagcdn.com/w40/$flag.png', width: 30.w),
      ),
      title: Text(name, style: TextStyle(fontSize: 15.sp)),
      trailing: Text(code, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
      onTap: () {
        setState(() {
          _countryCode = code;
          _countryFlag = flag;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGender,
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          elevation: 2,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 20.sp),
          items: ['Male', 'Female', 'Other'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: TextStyle(fontSize: 15.sp, color: Colors.black87, fontWeight: FontWeight.w500)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedGender = val!),
        ),
      ),
    );
  }

  Widget _buildUpdateButton(Color brandYellow) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleUpdate,
        style: ElevatedButton.styleFrom(
          backgroundColor: brandYellow,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(width: 20.r, height: 20.r, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text('Update', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
