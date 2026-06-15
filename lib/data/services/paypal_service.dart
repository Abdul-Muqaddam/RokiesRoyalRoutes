import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_paypal_payment/flutter_paypal_payment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaypalService {
  static final _supabase = Supabase.instance.client;

  /// Update booking status to 'paid' in Supabase after successful payment
  static Future<void> markBookingAsPaid(String bookingId) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': 'confirmed', 'payment_status': 'paid'})
          .eq('id', bookingId);
      debugPrint('✅ Booking $bookingId marked as paid (PayPal).');
    } catch (e) {
      debugPrint('Warning: Could not update booking status: $e');
    }
  }

  /// Launch the PayPal checkout flow via WebView
  static void processPaypalPayment({
    required BuildContext context,
    required double totalPrice,
    required String currency,
    required String bookingId,
    required VoidCallback onSuccess,
    required VoidCallback onCancel,
    required Function(String) onError,
  }) async {
    final isSandbox = dotenv.env['PAYPAL_MODE']?.toLowerCase() != 'live';
    final clientId = dotenv.env['PAYPAL_CLIENT_ID'];
    final secretKey = dotenv.env['PAYPAL_SECRET_KEY'];

    if (clientId == null || clientId.isEmpty || secretKey == null || secretKey.isEmpty) {
      onError('PayPal credentials missing in .env file. Please check PAYPAL_CLIENT_ID and PAYPAL_SECRET_KEY.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => PaypalCheckoutView(
          sandboxMode: isSandbox,
          clientId: clientId,
          secretKey: secretKey,
          // Explicitly set the note (mapped to note_to_payer) to a safe length
          note: ("Booking $bookingId").length > 100 
              ? ("Booking $bookingId").substring(0, 97) + "..." 
              : "Booking $bookingId",
          onSuccess: (Map params) async {
            debugPrint("PayPal Success: $params");
            await markBookingAsPaid(bookingId);
            if (context.mounted) Navigator.pop(context);
            onSuccess();
          },
          onError: (error) {
            debugPrint("PayPal Error: $error");
            onError(error.toString());
          },
          onCancel: () {
            debugPrint('PayPal Cancelled');
            onCancel();
          },
          transactions: [
            {
              "amount": {
                "total": totalPrice.toStringAsFixed(2),
                "currency": currency,
                "details": {
                  "subtotal": totalPrice.toStringAsFixed(2),
                  "shipping": '0',
                  "shipping_discount": 0
                }
              },
              // Hard truncate description to 100 chars to be safe
              "description": ("Booking $bookingId").length > 100 
                  ? ("Booking $bookingId").substring(0, 97) + "..." 
                  : "Booking $bookingId",
              "item_list": {
                "items": [
                  {
                    "name": "Ride Booking",
                    "quantity": 1,
                    "price": totalPrice.toStringAsFixed(2),
                    "currency": currency
                  }
                ],
              }
            }
          ],
        ),
      ),
    );
  }
}
