import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  bool _salesNotify = true;
  bool _newArrivalsNotify = false;
  bool _deliveryStatusNotify = false;
  bool _isSaving = false;

  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _repeatPassCtrl = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureRepeat = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text = user['fullName'] ?? '';
      _dobCtrl.text = user['dateOfBirth'] ?? '';
      _salesNotify = user['salesNotify'] ?? true;
      _newArrivalsNotify = user['newArrivalsNotify'] ?? false;
      _deliveryStatusNotify = user['deliveryStatusNotify'] ?? false;
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateSettings(
      fullName: _nameCtrl.text.trim(),
      dateOfBirth: _dobCtrl.text.trim(),
      salesNotify: _salesNotify,
      newArrivalsNotify: _newArrivalsNotify,
      deliveryStatusNotify: _deliveryStatusNotify,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Settings saved successfully!' : (auth.error ?? 'Failed to save settings')),
        duration: const Duration(seconds: 3),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  void _showPasswordChangeBottomSheet() {
    _oldPassCtrl.clear();
    _newPassCtrl.clear();
    _repeatPassCtrl.clear();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9F9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pull handler
                  Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Password Change',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 24),
                  
                  // Old Password Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _oldPassCtrl,
                      obscureText: _obscureOld,
                      decoration: InputDecoration(
                        labelText: 'Old Password',
                        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureOld ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                          onPressed: () => setSheetState(() => _obscureOld = !_obscureOld),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Forgot password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Forgot password redirection coming soon!')),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // New Password Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _newPassCtrl,
                      obscureText: _obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                          onPressed: () => setSheetState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Repeat New Password Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _repeatPassCtrl,
                      obscureText: _obscureRepeat,
                      decoration: InputDecoration(
                        labelText: 'Repeat New Password',
                        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureRepeat ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                          onPressed: () => setSheetState(() => _obscureRepeat = !_obscureRepeat),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final oldP = _oldPassCtrl.text;
                        final newP = _newPassCtrl.text;
                        final repeatP = _repeatPassCtrl.text;

                        if (oldP.isEmpty || newP.isEmpty || repeatP.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        if (newP != repeatP) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('New passwords do not match'), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        final auth = context.read<AuthProvider>();
                        final ok = await auth.changePassword(oldPassword: oldP, newPassword: newP);
                        
                        if (!context.mounted) return;
                        
                        if (ok) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password changed successfully!'), backgroundColor: Colors.green),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(auth.error ?? 'Failed to change password'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      child: const Text(
                        'SAVE PASSWORD',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF3B30)))
                : const Icon(Icons.check, color: Color(0xFFFF3B30), size: 26),
            onPressed: _isSaving ? null : _saveSettings,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 24),
            // Personal Information
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 12),
            
            // Full Name Input
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full name',
                  labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date of birth Input
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _dobCtrl,
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: InputBorder.none,
                  hintText: 'dd/MM/yyyy',
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Password Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Password',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                GestureDetector(
                  onTap: _showPasswordChangeBottomSheet,
                  child: const Text(
                    'Change',
                    style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                readOnly: true,
                obscureText: true,
                controller: TextEditingController(text: '123456'),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Notifications Section
            const Text(
              'Notifications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 12),
            
            // Sales Notification
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sales', style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
                Switch(
                  value: _salesNotify,
                  activeColor: Colors.green,
                  onChanged: (v) {
                    setState(() => _salesNotify = v);
                    _saveSettings();
                  },
                ),
              ],
            ),
            const Divider(height: 1, color: Colors.black12),
            
            // New arrivals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New arrivals', style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
                Switch(
                  value: _newArrivalsNotify,
                  activeColor: Colors.green,
                  onChanged: (v) {
                    setState(() => _newArrivalsNotify = v);
                    _saveSettings();
                  },
                ),
              ],
            ),
            const Divider(height: 1, color: Colors.black12),
            
            // Delivery status changes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery status changes', style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
                Switch(
                  value: _deliveryStatusNotify,
                  activeColor: Colors.green,
                  onChanged: (v) {
                    setState(() => _deliveryStatusNotify = v);
                    _saveSettings();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
