import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _submitted = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _sendRecoveryLink() {
    setState(() {
      _submitted = true;
    });

    final email = _emailCtrl.text.trim();
    if (!_isValidEmail(email)) {
      return;
    }

    // Email is valid, mock success
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Link Sent'),
        content: Text('A link to reset your password has been sent to $email.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // pop dialog
              Navigator.of(context).pop(); // pop forgot password screen (back to login)
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFFDB3022))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailText = _emailCtrl.text.trim();
    final hasText = emailText.isNotEmpty;
    final isValid = _isValidEmail(emailText);
    final showError = _submitted && !isValid;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Forgot password',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Please, enter your email address. You will receive a link to create a new password via email.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF222222),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              
              // Email input container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                  border: Border.all(
                    color: showError
                        ? const Color(0xFFDB3022)
                        : hasText && isValid
                            ? Colors.grey.shade300
                            : Colors.transparent,
                    width: showError ? 1.5 : 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _emailCtrl,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (text) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: showError ? const Color(0xFFDB3022) : Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    suffixIcon: hasText
                        ? isValid
                            ? const Icon(Icons.check, color: Colors.green, size: 20)
                            : showError
                                ? const Icon(Icons.close, color: Color(0xFFDB3022), size: 20)
                                : null
                        : null,
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              if (showError) ...[
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(
                    'Not a valid email address. Should be name@email.com',
                    style: TextStyle(
                      color: Color(0xFFDB3022),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 36),

              // SEND Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _sendRecoveryLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDB3022),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 2,
                    shadowColor: const Color(0xFFDB3022).withOpacity(0.3),
                  ),
                  child: const Text(
                    'SEND',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
