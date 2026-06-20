// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
// import 'package:provider/provider.dart';
// import '../services/auth_provider.dart';
// import '../services/api_service.dart';
// import 'home_screen.dart';
// import 'register_screen.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _emailCtrl = TextEditingController();
//   final _passCtrl = TextEditingController();
//   bool _obscure = true;
//   List<Map<String, dynamic>> _savedAccounts = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadSavedAccounts();
//   }

//   Future<void> _loadSavedAccounts() async {
//     final accounts = await ApiService.getSavedAccounts();
//     setState(() {
//       _savedAccounts = accounts;
//     });
//   }

//   // Web client ID của project ct1-shop-20943 (dùng để lấy idToken trên Android gửi lên backend)
//   static const String _webClientId =
//       '595150033801-m9c352aiutp5ue1pa1kpupgl1i2506nd.apps.googleusercontent.com';

//   final GoogleSignIn _googleSignIn = GoogleSignIn(
//     // clientId chỉ dùng trên Web
//     clientId: kIsWeb ? _webClientId : null,
//     // serverClientId = Web client ID → Android SDK dùng để tạo idToken
//     serverClientId: _webClientId,
//     scopes: ['email', 'profile'],
//   );

  
//   Future<void> _loginEmail() async {
//     final auth = context.read<AuthProvider>();
//     final email = _emailCtrl.text.trim();
//     final ok = await auth.login(email, _passCtrl.text);
//     if (!mounted) return;
//     if (ok) {
//       await ApiService.saveAccount(
//         email: email,
//         fullName: auth.user?['fullName'] ?? '',
//         provider: 'email',
//       );
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(duration: const Duration(seconds: 3), content: Text('Đăng nhập thành công!')),
//       );
//       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
//     } else {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: const Duration(seconds: 3), content: Text(auth.error ?? 'Lỗi')));
//     }
//   }

//   Future<void> _loginGoogle() async {
//     try {
//       final account = await _googleSignIn.signIn();
//       if (account == null) return;
      
//       final googleAuth = await account.authentication;
//       final idToken = googleAuth.idToken;
      
//       if (idToken == null) {
//         throw Exception('Không lấy được ID Token từ Google');
//       }

//       if (!mounted) return;
//       final auth = context.read<AuthProvider>();
//       final ok = await auth.socialLogin(
//         provider: 'google',
//         token: idToken,
//         mode: 'login',
//       );
      
//       if (!mounted) return;
      
//       if (ok) {
//         await ApiService.saveAccount(
//           email: account.email,
//           fullName: account.displayName ?? '',
//           provider: 'google',
//           avatar: account.photoUrl,
//         );
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(duration: const Duration(seconds: 3), content: Text('Đăng nhập thành công!')),
//         );
//         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
//       } else {
//         final errMsg = auth.error ?? '';
//         if (errMsg.contains('chưa được đăng ký') || errMsg.contains('chưa đăng ký')) {
//           if (!mounted) return;
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Tài khoản chưa được đăng ký! Đang chuyển sang trang Đăng ký...'),
//               duration: Duration(seconds: 2),
//             ),
//           );
//           await Future.delayed(const Duration(seconds: 2));
//           if (!mounted) return;
//           Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())).then((_) {
//             _loadSavedAccounts(); // Reload list accounts sau khi quay lại từ register
//           });
//         } else {
//           if (!mounted) return;
//           ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: const Duration(seconds: 3), content: Text(errMsg)));
//         }
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: const Duration(seconds: 3), content: Text('Google lỗi: $e')));
//     }
//   }

//   void _selectSavedAccount(Map<String, dynamic> acc) {
//     if (acc['provider'] == 'google') {
//       _loginGoogle();
//     } else {
//       setState(() {
//         _emailCtrl.text = acc['email'] ?? '';
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(duration: const Duration(seconds: 3), content: Text('Đã chọn tài khoản ${acc['email']}. Vui lòng nhập mật khẩu.')),
//       );
//     }
//   }

//   Future<void> _loginFacebook() async {
//     try {
//       final result = await FacebookAuth.instance.login();

//       if (result.status != LoginStatus.success) {
//         return;
//       }

//       final fbToken = result.accessToken?.tokenString;
//       if (fbToken == null) {
//         throw Exception('Không lấy được Access Token từ Facebook');
//       }

//       if (!mounted) return;
//       final auth = context.read<AuthProvider>();

//       final ok = await auth.socialLogin(
//         provider: 'facebook',
//         token: fbToken,
//         mode: 'login',
//       );

//       if (!mounted) return;

//       if (ok) {
//         final userData = await FacebookAuth.instance.getUserData();
//         await ApiService.saveAccount(
//           email: userData['email'] ?? 'facebook_user',
//           fullName: userData['name'] ?? '',
//           provider: 'facebook',
//           avatar: userData['picture']?['data']?['url'],
//         );

//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(duration: const Duration(seconds: 3), content: Text('Đăng nhập thành công!')),
//         );
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => const HomeScreen(),
//           ),
//         );
//       } else {
//         final errMsg = auth.error ?? '';
//         if (errMsg.contains('chưa được đăng ký') || errMsg.contains('chưa đăng ký')) {
//           if (!mounted) return;
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Tài khoản chưa được đăng ký! Đang chuyển sang trang Đăng ký...'),
//               duration: Duration(seconds: 2),
//             ),
//           );
//           await Future.delayed(const Duration(seconds: 2));
//           if (!mounted) return;
//           Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())).then((_) {
//             _loadSavedAccounts();
//           });
//         } else {
//           if (!mounted) return;
//           ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: const Duration(seconds: 3), content: Text(errMsg)));
//         }
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(duration: const Duration(seconds: 3), content: Text('Facebook lỗi: $e')),
//       );
//     }
//   }
//   @override
//   Widget build(BuildContext context) {
//     final auth = context.watch<AuthProvider>();

//     return Scaffold(
//       backgroundColor: const Color(0xFF1A1A2E),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const SizedBox(height: 48),
//               const Text('Đăng Nhập', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
//               const SizedBox(height: 8),
//               const Text('Chào mừng trở lại!', style: TextStyle(color: Colors.white60)),
//               const SizedBox(height: 40),

//               _buildSavedAccounts(),

//               // Email field
//               TextField(
//                 controller: _emailCtrl,
//                 style: const TextStyle(color: Colors.white),
//                 keyboardType: TextInputType.emailAddress,
//                 decoration: _inputDeco('Email', Icons.email_outlined),
//               ),
//               const SizedBox(height: 16),

//               // Password field
//               TextField(
//                 controller: _passCtrl,
//                 obscureText: _obscure,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: _inputDeco('Mật khẩu', Icons.lock_outline).copyWith(
//                   suffixIcon: IconButton(
//                     icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
//                     onPressed: () => setState(() => _obscure = !_obscure),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // Login button
//               ElevatedButton(
//                 onPressed: auth.loading ? null : _loginEmail,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFE94560),
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//                 child: auth.loading
//                     ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                     : const Text('Đăng Nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
//               ),
//               const SizedBox(height: 24),

//               // Divider
//               const Row(children: [
//                 Expanded(child: Divider(color: Colors.white24)),
//                 Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('hoặc', style: TextStyle(color: Colors.white54))),
//                 Expanded(child: Divider(color: Colors.white24)),
//               ]),
//               const SizedBox(height: 24),

//               // Google button
//               OutlinedButton.icon(
//                 onPressed: auth.loading ? null : _loginGoogle,
//                 icon: Image.network('https://www.google.com/favicon.ico', width: 20, height: 20),
//                 label: const Text('Đăng nhập với Google', style: TextStyle(color: Colors.white)),
//                 style: OutlinedButton.styleFrom(
//                   side: const BorderSide(color: Colors.white24),
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//               ),
//               const SizedBox(height: 12),

//               // Facebook button
//               OutlinedButton.icon(
//                 onPressed: auth.loading ? null : _loginFacebook,
//                 icon: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
//                 label: const Text('Đăng nhập với Facebook', style: TextStyle(color: Colors.white)),
//                 style: OutlinedButton.styleFrom(
//                   side: const BorderSide(color: Colors.white24),
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//               ),
//               const SizedBox(height: 32),

//               // Register link
//               Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//                 const Text('Chưa có tài khoản? ', style: TextStyle(color: Colors.white60)),
//                 GestureDetector(
//                   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
//                   child: const Text('Đăng ký', style: TextStyle(color: Color(0xFFE94560), fontWeight: FontWeight.bold)),
//                 ),
//               ]),
//             ],
//           ),
//         ),
//       ),
//     );
//   }


//   Widget _buildSavedAccounts() {
//     if (_savedAccounts.isEmpty) return const SizedBox.shrink();
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Tài khoản đã lưu trên thiết bị',
//           style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 12),
//         SizedBox(
//           height: 90,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: _savedAccounts.length,
//             itemBuilder: (context, index) {
//               final acc = _savedAccounts[index];
//               final email = acc['email'] ?? '';
//               final name = acc['fullName'] ?? '';
//               final provider = acc['provider'] ?? 'email';
//               final avatar = acc['avatar'];

//               return Container(
//                 width: 200,
//                 margin: const EdgeInsets.only(right: 12),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withValues(alpha: 0.08),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.white12),
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(12),
//                   child: Material(
//                     color: Colors.transparent,
//                     child: InkWell(
//                       onTap: () => _selectSavedAccount(acc),
//                       child: Stack(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                             child: Row(
//                               children: [
//                                 CircleAvatar(
//                                   radius: 20,
//                                   backgroundImage: avatar != null ? NetworkImage(avatar) : null,
//                                   child: avatar == null
//                                       ? Text(name.isNotEmpty ? name[0].toUpperCase() : email[0].toUpperCase(), style: const TextStyle(color: Colors.white))
//                                       : null,
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Text(
//                                         name.isNotEmpty ? name : email.split('@')[0],
//                                         style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                       Text(
//                                         email,
//                                         style: const TextStyle(color: Colors.white54, fontSize: 11),
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                       const SizedBox(height: 2),
//                                       Row(
//                                         children: [
//                                           Icon(
//                                             provider == 'google' ? Icons.g_mobiledata : Icons.email_outlined,
//                                             size: 14,
//                                             color: provider == 'google' ? Colors.redAccent : Colors.blueAccent,
//                                           ),
//                                           Text(
//                                             provider == 'google' ? 'Google' : 'Email',
//                                             style: TextStyle(
//                                               color: provider == 'google' ? Colors.redAccent : Colors.blueAccent,
//                                               fontSize: 10,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Positioned(
//                             top: 0,
//                             right: 0,
//                             child: IconButton(
//                               icon: const Icon(Icons.close, size: 14, color: Colors.white54),
//                               padding: EdgeInsets.zero,
//                               constraints: const BoxConstraints(),
//                               onPressed: () async {
//                                 await ApiService.removeSavedAccount(email);
//                                 _loadSavedAccounts();
//                               },
//                             ),
//                           )
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
//     labelText: label,
//     labelStyle: const TextStyle(color: Colors.white54),
//     prefixIcon: Icon(icon, color: Colors.white54),
//     enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
//     focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE94560))),
//     filled: true,
//     fillColor: Colors.white10,
//   );
// }
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  // Danh sách tài khoản đã lưu (mock, thay bằng ApiService.getSavedAccounts() nếu cần)
  final List<Map<String, dynamic>> _savedAccounts = [
    // Ví dụ: {'email': 'user@gmail.com', 'fullName': 'Nguyen Van A', 'provider': 'google', 'avatar': null},
  ];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _loginEmail() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(duration: const Duration(seconds: 3), content: Text('Vui lòng nhập email và mật khẩu')),
      );
      return;
    }

    setState(() => _loading = true);

    // TODO: Gọi API đăng nhập thật ở đây
    // final auth = context.read<AuthProvider>();
    // final ok = await auth.login(email, pass);
    await Future.delayed(const Duration(milliseconds: 500)); // Giả lập loading

    setState(() => _loading = false);

    _goHome();
  }

  Future<void> _loginGoogle() async {
    setState(() => _loading = true);

    // TODO: Gọi Google Sign In thật ở đây
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _loading = false);

    _goHome();
  }

  Future<void> _loginFacebook() async {
    setState(() => _loading = true);

    // TODO: Gọi Facebook Login thật ở đây
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _loading = false);

    _goHome();
  }

  void _selectSavedAccount(Map<String, dynamic> acc) {
    _goHome();
  }

  Future<void> _removeSavedAccount(String email) async {
    // TODO: await ApiService.removeSavedAccount(email);
    setState(() {
      _savedAccounts.removeWhere((a) => a['email'] == email);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // Tiêu đề
              const Text(
                'Đăng Nhập',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chào mừng trở lại!',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 40),

              // Tài khoản đã lưu
              _buildSavedAccounts(),
              if (_savedAccounts.isNotEmpty) const SizedBox(height: 24),

              // Email
              TextField(
                controller: _emailCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDeco('Email', Icons.email_outlined),
              ),
              const SizedBox(height: 16),

              // Mật khẩu
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco('Mật khẩu', Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white54,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Nút đăng nhập
              ElevatedButton(
                onPressed: _loading ? null : _loginEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Đăng Nhập',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // Divider
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.white24)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('hoặc', style: TextStyle(color: Colors.white54)),
                  ),
                  Expanded(child: Divider(color: Colors.white24)),
                ],
              ),
              const SizedBox(height: 24),

              // Đăng nhập Google
              OutlinedButton.icon(
                onPressed: _loading ? null : _loginGoogle,
                icon: Image.asset(
                  'assets/images/gg.png',
                  width: 20,
                  height: 20,
                ),
                label: const Text(
                  'Đăng nhập với Google',
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Đăng nhập Facebook
              OutlinedButton.icon(
                onPressed: _loading ? null : _loginFacebook,
                icon: Image.asset(
                  'assets/images/fb.png',
                  width: 20,
                  height: 20,
                ),
                label: const Text(
                  'Đăng nhập với Facebook',
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Link đăng ký
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Chưa có tài khoản? ',
                    style: TextStyle(color: Colors.white60),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text(
                      'Đăng ký',
                      style: TextStyle(
                        color: Color(0xFFE94560),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedAccounts() {
    if (_savedAccounts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tài khoản đã lưu trên thiết bị',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _savedAccounts.length,
            itemBuilder: (context, index) {
              final acc = _savedAccounts[index];
              final email = acc['email'] ?? '';
              final name = acc['fullName'] ?? '';
              final provider = acc['provider'] ?? 'email';
              final avatar = acc['avatar'];

              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _selectSavedAccount(acc),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: avatar != null
                                      ? NetworkImage(avatar)
                                      : null,
                                  child: avatar == null
                                      ? Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : email[0].toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.white),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        name.isNotEmpty
                                            ? name
                                            : email.split('@')[0],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        email,
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            provider == 'google'
                                                ? Icons.g_mobiledata
                                                : Icons.email_outlined,
                                            size: 14,
                                            color: provider == 'google'
                                                ? Colors.redAccent
                                                : Colors.blueAccent,
                                          ),
                                          Text(
                                            provider == 'google'
                                                ? 'Google'
                                                : 'Email',
                                            style: TextStyle(
                                              color: provider == 'google'
                                                  ? Colors.redAccent
                                                  : Colors.blueAccent,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white54,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _removeSavedAccount(email),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE94560)),
        ),
        filled: true,
        fillColor: Colors.white10,
      );
}
