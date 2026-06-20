import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import 'login_screen2.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController(text: 'Mr. Muffin');
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  static const String _webClientId =
      '595150033801-m9c352aiutp5ue1pa1kpupgl1i2506nd.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
    serverClientId: _webClientId,
    scopes: ['email', 'profile'],
  );

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(duration: const Duration(seconds: 3), content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(duration: const Duration(seconds: 3), content: Text('Email không hợp lệ')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.register(name, email, password);
    if (!mounted) return;
    
    if (ok) {
      await ApiService.saveAccount(
        email: email,
        fullName: name,
        provider: 'email',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thành công! Đang chuyển sang trang Đăng nhập...'),
          duration: const Duration(seconds: 3),
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen2()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(duration: const Duration(seconds: 3), content: Text(auth.error ?? 'Đăng ký thất bại')),
      );
    }
  }

  Future<void> _googleRegister() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return;

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Không lấy được ID Token từ Google');
      }

      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final ok = await auth.socialLogin(
        provider: 'google',
        token: idToken,
        mode: 'register',
      );
      
      if (!mounted) return;
      
      if (ok) {
        await ApiService.saveAccount(
          email: account.email,
          fullName: account.displayName ?? '',
          provider: 'google',
          avatar: account.photoUrl,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công! Đang chuyển sang trang Đăng nhập...'),
            duration: const Duration(seconds: 3),
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen2()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(duration: const Duration(seconds: 3), content: Text(auth.error ?? 'Đăng ký thất bại')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(duration: const Duration(seconds: 3), content: Text('Lỗi Google: $e')),
      );
    }
  }

  Future<void> _facebookRegister() async {
    try {
      final result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) return;

      final fbToken = result.accessToken?.tokenString;
      if (fbToken == null) {
        throw Exception('Không lấy được Access Token từ Facebook');
      }

      if (!mounted) return;
      final auth = context.read<AuthProvider>();

      final ok = await auth.socialLogin(
        provider: 'facebook',
        token: fbToken,
        mode: 'register',
      );

      if (!mounted) return;

      if (ok) {
        final userData = await FacebookAuth.instance.getUserData();
        await ApiService.saveAccount(
          email: userData['email'] ?? 'facebook_user',
          fullName: userData['name'] ?? '',
          provider: 'facebook',
          avatar: userData['picture']?['data']?['url'],
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công! Đang chuyển sang trang Đăng nhập...'),
            duration: const Duration(seconds: 3),
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen2()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(duration: const Duration(seconds: 3), content: Text(auth.error ?? 'Đăng ký thất bại')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(duration: const Duration(seconds: 3), content: Text('Lỗi Facebook: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nameText = _nameCtrl.text.trim();
    final emailText = _emailCtrl.text.trim();
    final passText = _passCtrl.text;

    final isNameValid = nameText.isNotEmpty;
    final isEmailValid = _isValidEmail(emailText);
    final isPassValid = passText.length >= 6;

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
                'Sign up',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 36),

              // Name field
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
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _nameCtrl,
                  onChanged: (text) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    border: InputBorder.none,
                    suffixIcon: isNameValid
                        ? const Icon(Icons.check, color: Colors.green, size: 20)
                        : null,
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 8),

              // Email field
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
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (text) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    border: InputBorder.none,
                    suffixIcon: emailText.isNotEmpty && isEmailValid
                        ? const Icon(Icons.check, color: Colors.green, size: 20)
                        : null,
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 8),

              // Password field
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
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  onChanged: (text) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    border: InputBorder.none,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        if (passText.isNotEmpty && isPassValid)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.check, color: Colors.green, size: 20),
                          ),
                      ],
                    ),
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 16),

              // Redirect to login link
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen2()),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.black87, fontSize: 14),
                      ),
                      Icon(Icons.arrow_right_alt, color: Color(0xFFDB3022), size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // SIGN UP Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: auth.loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDB3022),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 2,
                    shadowColor: const Color(0xFFDB3022).withOpacity(0.3),
                  ),
                  child: auth.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'SIGN UP',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 56),

              // Social logins
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Or sign up with social account',
                      style: TextStyle(color: Colors.black87, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google button
                        _buildSocialButton(
                          icon: Image.asset('assets/images/gg.png', width: 24, height: 24),
                          onTap: _googleRegister,
                        ),
                        const SizedBox(width: 16),
                        // Facebook button
                        _buildSocialButton(
                          icon: Image.asset('assets/images/fb.png', width: 28, height: 28),
                          onTap: _facebookRegister,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 92,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Center(child: icon),
        ),
      ),
    );
  }
}
