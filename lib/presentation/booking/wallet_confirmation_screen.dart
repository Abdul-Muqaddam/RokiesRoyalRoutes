import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/user_repository_impl.dart';
import 'booking_view_model.dart';

class WalletConfirmationScreen extends ConsumerWidget {
  final double amount;
  final VoidCallback onConfirm;

  const WalletConfirmationScreen({
    super.key,
    required this.amount,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    const Color brandYellow = Color(0xFFDC423D);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Wallet Payment',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        centerTitle: true,
      ),
      body: userAsync.when(
        data: (user) {
          final currentBalance = user.walletBalance;
          final remainingBalance = currentBalance - amount;
          final isInsufficient = currentBalance < amount;

          return Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Summary',
                  style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Please confirm the deduction from your wallet.',
                  style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                ),
                SizedBox(height: 40.h),
                
                _buildBalanceRow('Current Balance', currentBalance, Colors.black87),
                SizedBox(height: 16.h),
                _buildBalanceRow('Booking Amount', -amount, Colors.redAccent),
                SizedBox(height: 16.h),
                const Divider(),
                SizedBox(height: 16.h),
                _buildBalanceRow(
                  'Remaining Balance', 
                  remainingBalance, 
                  isInsufficient ? Colors.red : Colors.green,
                  isBold: true
                ),
                
                const Spacer(),
                
                if (isInsufficient)
                  Container(
                    padding: EdgeInsets.all(16.r),
                    margin: EdgeInsets.only(bottom: 24.h),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Insufficient funds. Please top up your wallet to proceed.',
                            style: TextStyle(color: Colors.red[700], fontSize: 13.sp, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: isInsufficient ? () => context.push('/wallet') : onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isInsufficient ? Colors.black87 : brandYellow,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      elevation: 0,
                    ),
                    child: Text(
                      isInsufficient ? 'Top Up Wallet' : 'Confirm & Pay',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black38, fontSize: 14.sp, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: brandYellow)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildBalanceRow(String label, double val, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.sp, 
            color: Colors.black87, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal
          ),
        ),
        Text(
          '${val < 0 ? '-' : ''}\$${val.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18.sp, 
            color: color, 
            fontWeight: FontWeight.bold
          ),
        ),
      ],
    );
  }
}
