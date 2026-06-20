import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/ecommerce_provider.dart';

class AddShippingAddressScreen extends StatefulWidget {
  const AddShippingAddressScreen({super.key});

  @override
  State<AddShippingAddressScreen> createState() =>
      _AddShippingAddressScreenState();
}

class _AddShippingAddressScreenState
    extends State<AddShippingAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressLine1Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'Vietnam');

  bool _isDefault = false;
  bool _loading = false;

  static const Color _red = Color(0xFFFF3B30);

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressLine1Ctrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Adding Shipping Address',
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Full Name ──
                      _buildLabel('Full Name *'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _fullNameCtrl,
                        hint: 'Nguyễn Văn An',
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        prefixIcon: Icons.person_outline,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Vui lòng nhập họ tên đầy đủ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Phone ──
                      _buildLabel('Phone Number'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _phoneCtrl,
                        hint: '0901 234 567',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: null,
                      ),
                      const SizedBox(height: 16),

                      // ── Address Line 1 ──
                      _buildLabel('Address Line 1 *'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _addressLine1Ctrl,
                        hint: '123 Lê Lợi, Phường Bến Nghé',
                        keyboardType: TextInputType.streetAddress,
                        prefixIcon: Icons.home_outlined,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Vui lòng nhập địa chỉ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── City & State ──
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('City'),
                                const SizedBox(height: 8),
                                _buildField(
                                  controller: _cityCtrl,
                                  hint: 'Hồ Chí Minh',
                                  keyboardType: TextInputType.text,
                                  prefixIcon: Icons.location_city_outlined,
                                  validator: null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('State/Province'),
                                const SizedBox(height: 8),
                                _buildField(
                                  controller: _stateCtrl,
                                  hint: 'HCM',
                                  keyboardType: TextInputType.text,
                                  prefixIcon: Icons.map_outlined,
                                  validator: null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── ZIP & Country ──
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('ZIP / Postal Code'),
                                const SizedBox(height: 8),
                                _buildField(
                                  controller: _zipCtrl,
                                  hint: '700000',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.markunread_mailbox_outlined,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Country'),
                                const SizedBox(height: 8),
                                _buildField(
                                  controller: _countryCtrl,
                                  hint: 'Vietnam',
                                  keyboardType: TextInputType.text,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  prefixIcon: Icons.flag_outlined,
                                  validator: null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Default checkbox ──
                      InkWell(
                        onTap: () =>
                            setState(() => _isDefault = !_isDefault),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _isDefault
                                        ? _red
                                        : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                  color: _isDefault
                                      ? _red
                                      : Colors.transparent,
                                ),
                                child: _isDefault
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 14)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Use as default shipping address',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Save Button ──
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 2,
                      shadowColor: _red.withOpacity(0.4),
                    ),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'SAVE ADDRESS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Field Builder ─────────────────────────────────────────

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.black87),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: Colors.grey.shade400, size: 20),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  // ── Submit ─────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await context.read<EcommerceProvider>().addAddress(
            fullName: _fullNameCtrl.text.trim(),
            phoneNumber: _phoneCtrl.text.trim(),
            addressLine1: _addressLine1Ctrl.text.trim(),
            city: _cityCtrl.text.trim(),
            state: _stateCtrl.text.trim(),
            zipCode: _zipCtrl.text.trim(),
            country: _countryCtrl.text.trim(),
            isDefault: _isDefault,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              duration: const Duration(seconds: 3),content: Text('Lỗi lưu địa chỉ: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
