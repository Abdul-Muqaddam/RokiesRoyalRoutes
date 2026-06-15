import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ComplainScreen extends StatefulWidget {
  const ComplainScreen({super.key});

  @override
  State<ComplainScreen> createState() => _ComplainScreenState();
}

class _ComplainScreenState extends State<ComplainScreen> {
  String? _selectedReason = 'Vehicle not clean';
  final _complainController = TextEditingController();

  final List<String> _reasons = [
    'Vehicle not clean',
    'Driver behavior',
    'Late arrival',
    'Route issues',
    'Payment issues',
    'Other',
  ];

  @override
  void dispose() {
    _complainController.dispose();
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
          'Complain',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          children: [
            SizedBox(height: 10.h),
            _buildDropdown(brandYellow),
            SizedBox(height: 16.h),
            _buildComplainField(),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: ElevatedButton(
                onPressed: _submitComplain,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandYellow,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text('Submit', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(Color brandYellow) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedReason,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 24.sp),
          items: _reasons.map((reason) {
            return DropdownMenuItem(
              value: reason,
              child: Text(
                reason,
                style: TextStyle(fontSize: 15.sp, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedReason = value),
        ),
      ),
    );
  }

  Widget _buildComplainField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: _complainController,
        maxLines: 6,
        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Write your complain here (minimum 10 characters)',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16.r),
        ),
      ),
    );
  }

  Future<void> _submitComplain() async {
    final complaintText = _complainController.text.trim();
    if (complaintText.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write at least 10 characters')),
      );
      return;
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'testing@admin.com',
      queryParameters: {
        'subject': 'Complain: $_selectedReason - Rockies Royal',
        'body': 'Selected Reason: $_selectedReason\n\nComplaint Details:\n$complaintText',
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch email app')),
        );
      }
    }
  }
}

