import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  int _selectedIndex = 0;

  final List<Map<String, String>> _languages = [
    {'name': 'English', 'native': 'English', 'flag': 'us'},
    {'name': 'Hindi', 'native': 'Hindi', 'flag': 'in'},
    {'name': 'Arabic', 'native': 'Arabic', 'flag': 'ae'},
    {'name': 'French', 'native': 'French', 'flag': 'fr'},
    {'name': 'German', 'native': 'German', 'flag': 'de'},
    {'name': 'Portuguese', 'native': 'Portuguese', 'flag': 'pt'},
    {'name': 'Turkish', 'native': 'Turkish', 'flag': 'tr'},
    {'name': 'Dutch', 'native': 'Nederlands', 'flag': 'nl'},
  ];

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
          'Change Language',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                final lang = _languages[index];

                return _buildLanguageCard(index, lang, isSelected, brandYellow);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.w),
            child: SizedBox(
              width: double.infinity,
              height: 54.h,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandYellow,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text('Save', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(int index, Map<String, String> lang, bool isSelected, Color brandYellow) {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? brandYellow : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: Image.network(
                'https://flagcdn.com/w80/${lang['flag']}.png',
                width: 44.w,
                height: 32.h,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang['name']!,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black87 : Colors.black54,
                    ),
                  ),
                  Text(
                    lang['native']!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.black26,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20.r,
              height: 20.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? brandYellow : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14.r, color: brandYellow)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
