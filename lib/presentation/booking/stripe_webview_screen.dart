import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_theme.dart';

class StripeWebViewScreen extends StatefulWidget {
  final String url;

  const StripeWebViewScreen({super.key, required this.url});

  @override
  State<StripeWebViewScreen> createState() => _StripeWebViewScreenState();
}

class _StripeWebViewScreenState extends State<StripeWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            debugPrint('DEBUG [StripeWebView]: Navigating to: $url');

            // Detect our custom deep links or success URLs
            if (url.startsWith('com.rockiesroyal.routes://stripe-redirect') || 
                url.startsWith('https://rockies-royal-success.com')) {
              if (url.contains('status=success')) {
                debugPrint('DEBUG [StripeWebView]: Success detected!');
                Navigator.pop(context, true);
              } else {
                debugPrint('DEBUG [StripeWebView]: Cancel detected.');
                Navigator.pop(context, false);
              }
              return NavigationDecision.prevent;
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
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Secure Payment', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFC5A039)), // App gold color
            ),
        ],
      ),
    );
  }
}
