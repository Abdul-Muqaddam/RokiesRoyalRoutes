import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import '../../presentation/booking/stripe_webview_screen.dart';

class StripeService {
  static final _supabase = Supabase.instance.client;

  /// Step 1: Create a Hosted Checkout Session
  static Future<String> createCheckoutSession({
    required int amountInCents,
    required String currency,
    required String bookingId,
  }) async {
    try {
      final secretKey = dotenv.env['STRIPE_SECRET_KEY'];
      if (secretKey == null || secretKey.isEmpty) {
        throw Exception('STRIPE_SECRET_KEY not found in .env file');
      }

      final dio = Dio();
      final response = await dio.post(
        'https://api.stripe.com/v1/checkout/sessions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $secretKey',
            'Content-Type': 'application/x-www-form-urlencoded'
          },
        ),
        data: {
          'mode': 'payment',
          'line_items[0][price_data][currency]': currency.toLowerCase(),
          'line_items[0][price_data][unit_amount]': amountInCents.toString(),
          'line_items[0][price_data][product_data][name]': 'Rockies Royal Booking',
          'line_items[0][quantity]': '1',
          'success_url': 'https://rockies-royal-success.com?status=success&booking_id=$bookingId',
          'cancel_url': 'https://rockies-royal-success.com?status=cancel',
          'metadata[booking_id]': bookingId,
        },
      );

      final checkoutUrl = response.data['url'];
      if (checkoutUrl == null || checkoutUrl.toString().isEmpty) {
        throw Exception('Invalid checkout URL returned from Stripe');
      }

      return checkoutUrl.toString();
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['error'] != null) {
          throw Exception(data['error']['message'] ?? 'Stripe Session Error');
        }
      }
      throw Exception('Failed to create checkout session: $e');
    }
  }

  /// Step 2: Update booking status to 'paid' in Supabase
  static Future<void> markBookingAsPaid(String bookingId) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': 'confirmed', 'payment_status': 'paid'})
          .eq('id', bookingId);
      debugPrint('DEBUG [Stripe]: Booking $bookingId marked as PAID in Supabase.');
    } catch (e) {
      debugPrint('Warning: Could not update booking status: $e');
    }
  }

  /// Full flow: create session → open embedded WebView
  static Future<bool> processStripePayment({
    required BuildContext context,
    required double totalPrice,
    required String currency,
    required String bookingId,
  }) async {
    try {
      final amountInCents = (totalPrice * 100).round();

      debugPrint('DEBUG [Stripe]: Starting Embedded Hosted Checkout Flow...');
      
      // 1. Create the session
      final checkoutUrl = await createCheckoutSession(
        amountInCents: amountInCents,
        currency: currency,
        bookingId: bookingId,
      );

      // 2. Open the embedded WebView
      if (!context.mounted) return false;
      
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => StripeWebViewScreen(url: checkoutUrl),
          fullscreenDialog: true,
        ),
      );

      if (result == true) {
        debugPrint('DEBUG [Stripe]: User returned from WebView with SUCCESS.');
        // 3. Mark booking as paid in DB
        await markBookingAsPaid(bookingId);
        return true;
      } else {
        debugPrint('DEBUG [Stripe]: User cancelled or payment failed in WebView.');
        return false;
      }
    } catch (e) {
      debugPrint('DEBUG [Stripe]: Hosted Checkout Error: $e');
      rethrow;
    }
  }
}
