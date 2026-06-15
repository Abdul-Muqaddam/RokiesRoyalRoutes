import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/countries.dart';

class AppPhoneField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final bool isFocusedInitially;

  const AppPhoneField({
    super.key,
    required this.controller,
    this.hintText,
    this.onChanged,
    this.isFocusedInitially = false,
  });

  @override
  State<AppPhoneField> createState() => _AppPhoneFieldState();
}

class _AppPhoneFieldState extends State<AppPhoneField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  String _countryCode = '+880';
  String _flag = 'bd';

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocus);
    _isFocused = widget.isFocusedInitially;
  }

  void _onFocus() => setState(() => _isFocused = _focusNode.hasFocus);

  @override
  void dispose() {
    _focusNode.removeListener(_onFocus);
    _focusNode.dispose();
    super.dispose();
  }

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text('Select Country',
                  style: GoogleFonts.outfit(
                      fontSize: 16.sp, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ),
            ...countries.map((c) {
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(2.r),
                  child: Image.network('https://flagcdn.com/w40/${c.flag}.png', width: 24.w),
                ),
                title: Text('${c.name} (${c.code})',
                    style: GoogleFonts.outfit(fontSize: 14.sp)),
                onTap: () {
                  setState(() {
                    _countryCode = c.code;
                    _flag = c.flag;
                  });
                  Navigator.pop(context);
                },
              );
            }),
            SizedBox(height: 16.h),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _isFocused ? AppColors.easyRiderYellow : const Color(0xFFE0E0E0),
          width: _isFocused ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Country code selector
          GestureDetector(
            onTap: () => _showCountryPicker(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2.r),
                    child: Image.network('https://flagcdn.com/w40/$_flag.png', width: 24.w, height: 16.h, fit: BoxFit.cover),
                  ),
                  SizedBox(width: 4.w),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18.sp, color: const Color(0xFFBDBDBD)),
                  SizedBox(width: 6.w),
                  Text(
                    _countryCode,
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Phone number input
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.phone,
                onChanged: widget.onChanged,
                style: GoogleFonts.outfit(
                    color: AppColors.black, fontSize: 15.sp),
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'Your mobile number',
                  hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFFBDBDBD), fontSize: 15.sp),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
