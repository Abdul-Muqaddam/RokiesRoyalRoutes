import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordScreen extends ConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: const Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Reset Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Enter your email to receive a password reset link.'),
            SizedBox(height: 24),
            TextField(decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            SizedBox(height: 24),
            ElevatedButton(onPressed: null, child: Text('Send Reset Link')) // disabled stub
          ],
        ),
      ),
    );
  }
}
