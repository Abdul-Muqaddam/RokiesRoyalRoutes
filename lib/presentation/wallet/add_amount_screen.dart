import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/booking_repository.dart';
import '../../data/models/booking_models.dart';
import '../../data/services/stripe_service.dart';
import '../../data/services/paypal_service.dart';
import '../../data/repositories/user_repository_impl.dart';
import 'wallet_view_model.dart';

class AddAmountScreen extends ConsumerStatefulWidget {
  const AddAmountScreen({super.key});

  @override
  ConsumerState<AddAmountScreen> createState() => _AddAmountScreenState();
}

class _AddAmountScreenState extends ConsumerState<AddAmountScreen> {
  final TextEditingController _amountController = TextEditingController();
  int _selectedMethodIndex = 0;
  bool _isProcessing = false;

  IconData _getGatewayIcon(String id) {
    switch (id.toLowerCase()) {
      case 'stripe': return Icons.credit_card;
      case 'paypal': return Icons.account_balance_wallet_outlined;
      default: return Icons.payment;
    }
  }

  Future<void> _handlePayment(List<PaymentGateway> filteredGateways) async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final double amount = double.tryParse(amountText) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final selectedGateway = filteredGateways[_selectedMethodIndex];
    
    setState(() => _isProcessing = true);

    try {
      if (selectedGateway.id == 'stripe') {
        final success = await StripeService.processStripePayment(
          context: context,
          totalPrice: amount,
          currency: 'USD',
          bookingId: 'topup_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        if (success) {
          await ref.read(userRepositoryProvider).addWalletBalance(amount);
          
          // Force an immediate refresh and wait for it
          await ref.refresh(userProfileProvider.future);
          await ref.refresh(walletViewModelProvider.future);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Wallet topped up successfully!')),
            );
            context.pop();
          }
        }
      } else if (selectedGateway.id == 'paypal') {
        PaypalService.processPaypalPayment(
          context: context,
          totalPrice: amount,
          currency: 'USD',
          bookingId: 'topup_${DateTime.now().millisecondsSinceEpoch}',
          onSuccess: () async {
            await ref.read(userRepositoryProvider).addWalletBalance(amount);
            
            // Force an immediate refresh and wait for it
            await ref.refresh(userProfileProvider.future);
            await ref.refresh(walletViewModelProvider.future);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wallet topped up successfully!')),
              );
              context.pop();
            }
          },
          onCancel: () {
            setState(() => _isProcessing = false);
          },
          onError: (error) {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('PayPal Error: $error')),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandYellow = Color(0xFFDC423D);
    const Color lightYellow = Color(0xFFFFEBEA);
    final gatewaysAsync = ref.watch(paymentGatewaysProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20.sp),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Amount',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: gatewaysAsync.when(
        data: (gateways) {
          // Filter out wallet and cash for adding money
          final filteredGateways = gateways.where((g) => g.id != 'wallet' && g.id != 'cash').toList();
          
          return Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10.h),
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Enter Amount',
                          hintStyle: TextStyle(color: Colors.grey[300], fontSize: 16.sp),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: const BorderSide(color: brandYellow, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 40),
                        ),
                        child: Text(
                          'Add payment Method',
                          style: TextStyle(
                            color: const Color(0xFF2196F3), 
                            fontSize: 14.sp, 
                            fontWeight: FontWeight.w500
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Select Payment Method',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filteredGateways.length,
                        separatorBuilder: (context, index) => SizedBox(height: 14.h),
                        itemBuilder: (context, index) {
                          final gateway = filteredGateways[index];
                          final isSelected = _selectedMethodIndex == index;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedMethodIndex = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.all(14.r),
                              decoration: BoxDecoration(
                                color: isSelected ? lightYellow : Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: isSelected ? brandYellow : Colors.grey[200]!,
                                  width: isSelected ? 1.2 : 1.0,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: brandYellow.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 54.w,
                                    height: 38.h,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6.r),
                                      border: Border.all(color: Colors.grey[100]!),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _getGatewayIcon(gateway.id), 
                                        size: 24.sp, 
                                        color: isSelected ? brandYellow : Colors.black54
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          gateway.title,
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          gateway.description ?? '',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey[500],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 20.h),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : () => _handlePayment(filteredGateways),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandYellow,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                            disabledBackgroundColor: brandYellow.withOpacity(0.6),
                          ),
                          child: _isProcessing 
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Confirm',
                                style: TextStyle(
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isProcessing)
                Container(
                  color: Colors.black.withOpacity(0.05),
                  child: const Center(child: CircularProgressIndicator(color: brandYellow)),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: brandYellow)),
        error: (err, stack) => Center(child: Text('Error loading gateways: $err')),
      ),
    );
  }
}
