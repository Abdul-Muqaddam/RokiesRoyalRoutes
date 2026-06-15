import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'wallet_view_model.dart';
import '../../data/models/user_models.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletViewModelProvider);
    const Color brandYellow = Color(0xFFDC423D);
    const Color lightYellow = Color(0xFFFFEBEA);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: walletAsync.when(
          data: (state) => RefreshIndicator(
            onRefresh: () => ref.read(walletViewModelProvider.notifier).refresh(),
            color: brandYellow,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15.h),
                  _buildAppBar(context),
                  SizedBox(height: 25.h),
                  _buildAddMoneyButton(context, brandYellow),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBalanceCard(
                          title: 'Available Balance',
                          amount: '\$${state.availableBalance.toStringAsFixed(0)}',
                          borderColor: brandYellow,
                          bgColor: lightYellow,
                          borderWidth: 1.5,
                        ),
                      ),
                      SizedBox(width: 15.w),
                      Expanded(
                        child: _buildBalanceCard(
                          title: 'Total Expend',
                          amount: '\$${state.totalExpend.toStringAsFixed(0)}',
                          borderColor: brandYellow.withOpacity(0.3),
                          bgColor: lightYellow.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30.h),
                  _buildTransactionsHeader(brandYellow),
                  SizedBox(height: 10.h),
                  _buildTransactionList(state.transactions),
                  SizedBox(height: 120.h),
                ],
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator(color: brandYellow)),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCircleButton(Icons.menu, onTap: () => Scaffold.of(context).openDrawer()),
        Row(
          children: [
            _buildCircleButton(Icons.search, onTap: () => context.push('/search')),
            SizedBox(width: 10.w),
            _buildCircleButton(Icons.notifications_none, onTap: () => context.push('/notification')),
          ],
        ),
      ],
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
        ),
        child: Icon(icon, color: Colors.black87, size: 20.sp),
      ),
    );
  }

  Widget _buildAddMoneyButton(BuildContext context, Color color) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        height: 48.h,
        child: OutlinedButton(
          onPressed: () => context.push('/add-amount'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color, width: 1.2),
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
          child: Text(
            'Add Money',
            style: TextStyle(
              color: color,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard({
    required String title,
    required String amount,
    required Color borderColor,
    required Color bgColor,
    double borderWidth = 1.0,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      height: 145.h,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          if (borderWidth > 1.0)
            BoxShadow(
              color: borderColor.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            amount,
            style: TextStyle(
              fontSize: 34.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF222222),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsHeader(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Transactions',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            'See All',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList(List<WalletTransaction> transactions) {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40.h),
          child: Text('No transactions yet', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isCredit = tx.isCredit;
        
        return GestureDetector(
          onTap: () => context.push('/invoice', extra: tx),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFFDC423D).withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: isCredit ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isCredit ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
                      size: 18.sp,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        style: TextStyle(
                          fontSize: 15.sp, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.black87
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        DateFormat('MMM dd, yyyy').format(tx.date),
                        style: TextStyle(
                          fontSize: 11.sp, 
                          color: Colors.black45,
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isCredit ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: isCredit ? const Color(0xFF4CAF50) : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
