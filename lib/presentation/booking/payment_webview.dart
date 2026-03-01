import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';

class PaymentWebView extends StatefulWidget {
  final String url;
  final int bookingId;
  final String paymentType; // 'stripe' or 'paypal'
  final Function(String, int) onSuccess;
  final VoidCallback onCancel;

  const PaymentWebView({
    Key? key,
    required this.url,
    required this.bookingId,
    required this.paymentType,
    required this.onSuccess,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            
            if (widget.paymentType == 'paypal') {
              if (url.contains('paypal-success')) {
                final uri = Uri.parse(url);
                final token = uri.queryParameters['token'];
                final urlBookingId = int.tryParse(uri.queryParameters['booking_id'] ?? '') ?? widget.bookingId;
                
                if (token != null) {
                  widget.onSuccess(token, urlBookingId);
                } else {
                  widget.onCancel();
                }
                return NavigationDecision.prevent;
              }
              if (url.contains('paypal-cancel')) {
                widget.onCancel();
                return NavigationDecision.prevent;
              }
            } else if (widget.paymentType == 'stripe') {
              if (url.contains('booking-success')) {
                final uri = Uri.parse(url);
                final sessionId = uri.queryParameters['session_id'] ?? '';
                widget.onSuccess(sessionId, widget.bookingId);
                return NavigationDecision.prevent;
              }
              if (url.contains('booking-payment') && url.contains('retry=1')) {
                widget.onCancel();
                return NavigationDecision.prevent;
              }
            }
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.paymentType == 'paypal' ? 'PayPal Payment' : 'Complete Payment',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.navy, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
        ],
      ),
    );
  }
}
