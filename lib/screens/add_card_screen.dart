import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/ecommerce_provider.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  String _brand = 'VISA';
  bool _isDefault = false;
  bool _loading = false;

  static const Color _red = Color(0xFFFF3B30);

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Top Drag Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Title
            const Center(
              child: Text(
                'Add new card',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Card Preview ──
                      _buildCardPreview(),
                      const SizedBox(height: 28),

                      // ── Brand Toggle ──
                      _buildLabel('Card brand'),
                      const SizedBox(height: 8),
                      _buildBrandToggle(),
                      const SizedBox(height: 20),

                      // ── Card Number ──
                      _buildLabel('Card number'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _numberCtrl,
                        hint: '0000 0000 0000 0000',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _CardNumberFormatter(),
                          LengthLimitingTextInputFormatter(19),
                        ],
                        validator: (v) {
                          final digits = v?.replaceAll(' ', '') ?? '';
                          if (digits.length < 16) return 'Vui lòng nhập đủ 16 số';
                          return null;
                        },
                        prefixIcon: const Icon(Icons.credit_card,
                            color: Colors.grey, size: 20),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // ── Name ──
                      _buildLabel('Name on card'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _nameCtrl,
                        hint: 'JOHN DOE',
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Vui lòng nhập tên chủ thẻ';
                          }
                          return null;
                        },
                        prefixIcon: const Icon(Icons.person_outline,
                            color: Colors.grey, size: 20),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // ── Expiry & CVV ──
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Expiry date'),
                                const SizedBox(height: 8),
                                _buildField(
                                  controller: _expiryCtrl,
                                  hint: 'MM/YY',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    _ExpiryFormatter(),
                                    LengthLimitingTextInputFormatter(5),
                                  ],
                                  validator: (v) {
                                    if (v == null || v.length < 5) {
                                      return 'MM/YY không hợp lệ';
                                    }
                                    return null;
                                  },
                                  prefixIcon: const Icon(Icons.calendar_today,
                                      color: Colors.grey, size: 18),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('CVV'),
                                const SizedBox(height: 8),
                                _buildField(
                                  controller: _cvvCtrl,
                                  hint: '•••',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  obscureText: true,
                                  validator: (v) {
                                    if (v == null || v.length < 3) {
                                      return 'CVV không hợp lệ';
                                    }
                                    return null;
                                  },
                                  prefixIcon: const Icon(Icons.lock_outline,
                                      color: Colors.grey, size: 18),
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
                              const Text(
                                  'Set as default payment method',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
            // ── Add Card Button ──
            Padding(
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
                    shadowColor: _red.withValues(alpha: 0.4),
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
                          'ADD CARD',
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
          ],
        ),
      ),
    );
  }

  // ── Card Preview ─────────────────────────────────────────

  Widget _buildCardPreview() {
    final isMC = _brand == 'MASTERCARD';
    final number = _numberCtrl.text.isEmpty
        ? '•••• •••• •••• ••••'
        : _numberCtrl.text.padRight(19, '•');
    final name =
        _nameCtrl.text.isEmpty ? 'FULL NAME' : _nameCtrl.text.toUpperCase();
    final expiry =
        _expiryCtrl.text.isEmpty ? 'MM/YY' : _expiryCtrl.text;

    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isMC
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [const Color(0xFF1A1F71), const Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _brand,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2),
                    ),
                    if (isMC)
                      Stack(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEB001B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Positioned(
                            left: 12,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF79E1B)
                                    .withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      const Text(
                        'VISA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 2,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                // Card number
                Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                // Holder & expiry
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CARD HOLDER',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 9)),
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('EXPIRES',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 9)),
                        Text(expiry,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Brand Toggle ─────────────────────────────────────────

  Widget _buildBrandToggle() {
    return Row(
      children: ['VISA', 'MASTERCARD'].map((b) {
        final isSelected = _brand == b;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _brand = b),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: b == 'VISA'
                  ? const EdgeInsets.only(right: 8)
                  : EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? _red : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(10),
                color: isSelected ? _red.withValues(alpha: 0.06) : Colors.white,
              ),
              child: Center(
                child: Text(
                  b,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isSelected ? _red : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Field Helpers ─────────────────────────────────────────

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? prefixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: prefixIcon,
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

    final digits = _numberCtrl.text.replaceAll(' ', '');
    final expiryParts = _expiryCtrl.text.split('/');
    if (expiryParts.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(duration: const Duration(seconds: 3), content: Text('Ngày hết hạn không hợp lệ')),
      );
      return;
    }
    final month = int.tryParse(expiryParts[0]) ?? 0;
    final yearShort = int.tryParse(expiryParts[1]) ?? 0;
    final year = yearShort < 100 ? 2000 + yearShort : yearShort;

    setState(() => _loading = true);
    try {
      final p = context.read<EcommerceProvider>();
      await p.addPaymentCard(
            cardHolderName: _nameCtrl.text.trim(),
            cardNumber: digits,
            brand: _brand,
            expiryMonth: month,
            expiryYear: year,
            isDefault: _isDefault,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              duration: const Duration(seconds: 3),content: Text('Lỗi thêm thẻ: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Input Formatters ───────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return newValue.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length >= 3) {
      final str = '${digits.substring(0, 2)}/${digits.substring(2)}';
      return newValue.copyWith(
        text: str,
        selection: TextSelection.collapsed(offset: str.length),
      );
    }
    return newValue;
  }
}
