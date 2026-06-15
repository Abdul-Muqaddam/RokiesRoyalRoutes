import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/countries.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  
  String _countryCode = '+880';
  String _countryFlag = 'bd';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandYellow = Color(0xFFDC423D);

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
          'Contact Us',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            SizedBox(height: 10.h),
            Text(
              'Contact us for Rockies Royal',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Text(
              'Address',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            Text(
              'House# 72, Road# 21, Banani, Dhaka-1213\n(near Banani Bidyaniketon School & College,\nbeside University of South Asia)',
              style: TextStyle(fontSize: 13.sp, color: Colors.black45, height: 1.5),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Text(
              'Call : 13301 (24/7)',
              style: TextStyle(fontSize: 14.sp, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            Text(
              'Email : support@rockiesroyal.com',
              style: TextStyle(fontSize: 14.sp, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            Text(
              'Send Message',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            _buildTextField('Name', _nameController),
            SizedBox(height: 16.h),
            _buildTextField('Email', _emailController),
            SizedBox(height: 16.h),
            _buildPhoneField(),
            SizedBox(height: 16.h),
            _buildTextField('Write your text', _messageController, maxLines: 5),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message sent successfully!')),
                  );
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandYellow,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text('Send Message', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
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
            ...countries.map((c) => ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(2.r),
                child: Image.network('https://flagcdn.com/w40/${c.flag}.png', width: 30.w),
              ),
              title: Text(c.name),
              trailing: Text(c.code, style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                setState(() {
                  _countryCode = c.code;
                  _countryFlag = c.flag;
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
}
