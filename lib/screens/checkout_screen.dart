import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ecommerce_provider.dart';
import 'shipping_addresses_screen.dart';
import 'payment_methods_screen.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;
  String _selectedDelivery = 'FedEx';

  static const Color _red = Color(0xFFFF3B30);

  final List<Map<String, dynamic>> _deliveryOptions = [
    {'name': 'FedEx', 'price': 15.0, 'days': '3-5 days', 'logo': '📦'},
    {'name': 'DHL', 'price': 18.0, 'days': '2-4 days', 'logo': '🚚'},
    {'name': 'USPS', 'price': 10.0, 'days': '5-7 days', 'logo': '📮'},
  ];

  double get _deliveryFee {
    return (_deliveryOptions.firstWhere(
      (o) => o['name'] == _selectedDelivery,
      orElse: () => _deliveryOptions.first,
    )['price'] as double);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EcommerceProvider>();
      provider.loadAddresses();
      provider.loadPaymentCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EcommerceProvider>();
    final addr = provider.defaultAddress;
    final card = provider.defaultCard;
    final subtotal = provider.cartSubtotal;
    final promo = provider.activePromo;
    double discount = 0;
    if (promo != null) {
      final percent = (promo['discountPercent'] as num?)?.toDouble() ?? 0;
      discount = subtotal * percent / 100;
    }
    final total = subtotal - discount + _deliveryFee;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 8),

          // ── Shipping Address ──
          _buildSectionTitle('Shipping address'),
          const SizedBox(height: 12),
          _buildAddressCard(addr, () async {
            final p = context.read<EcommerceProvider>();
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShippingAddressesScreen()),
            );
            if (mounted) p.loadAddresses();
          }),
          const SizedBox(height: 20),

          // ── Payment ──
          _buildSectionTitle('Payment'),
          const SizedBox(height: 12),
          _buildPaymentCard(card, () async {
            final p = context.read<EcommerceProvider>();
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
            );
            if (mounted) p.loadPaymentCards();
          }),
          const SizedBox(height: 20),

          // ── Delivery Method ──
          _buildSectionTitle('Delivery method'),
          const SizedBox(height: 12),
          _buildDeliveryOptions(),
          const SizedBox(height: 20),

          // ── Order Items ──
          _buildSectionTitle('My bag (${provider.cartItems.length} items)'),
          const SizedBox(height: 12),
          ...provider.cartItems.map((item) => _buildCartItem(item)),
          const SizedBox(height: 20),

          // ── Price Summary ──
          _buildPriceSummary(subtotal, discount, total),
          const SizedBox(height: 24),

          // ── Submit Button ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
                shadowColor: _red.withValues(alpha: 0.4),
              ),
              onPressed: _isLoading ? null : _submitOrder,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'SUBMIT ORDER',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildAddressCard(
      Map<String, dynamic>? addr, VoidCallback onTap) {
    if (addr == null) {
      return _buildEmptyCard(
        icon: Icons.add_location_alt_outlined,
        label: 'Add shipping address',
        onTap: onTap,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  addr['fullName'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    addr['addressLine1'],
                    addr['city'],
                    addr['state'],
                    addr['zipCode'],
                    addr['country'],
                  ]
                      .where((s) => s != null && s.toString().isNotEmpty)
                      .join(', '),
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Change',
              style: TextStyle(
                  color: Color(0xFFFF3B30), fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(
      Map<String, dynamic>? card, VoidCallback onTap) {
    if (card == null) {
      return _buildEmptyCard(
        icon: Icons.credit_card,
        label: 'Add payment method',
        onTap: onTap,
      );
    }
    final brand = (card['brand'] ?? '').toString().toUpperCase();
    final masked = card['maskedNumber'] ?? card['cardNumber'] ?? '•••• •••• •••• ••••';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(4),
            child: Center(
              child: Text(
                brand == 'MASTERCARD' || brand.contains('MASTER') ? 'MC' : 'VISA',
                style: TextStyle(
                  color: brand == 'MASTERCARD' || brand.contains('MASTER') ? const Color(0xFFEB001B) : const Color(0xFF1A1F71),
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              masked,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Change',
              style: TextStyle(
                  color: Color(0xFFFF3B30), fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
              color: const Color(0xFFFF3B30).withValues(alpha: 0.3),
              width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFF3B30), size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                  color: Color(0xFFFF3B30), fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios,
                color: Color(0xFFFF3B30), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryOptions() {
    return Row(
      children: _deliveryOptions.asMap().entries.map((entry) {
        final opt = entry.value;
        final isSelected = _selectedDelivery == opt['name'];
        final isLast = entry.key == _deliveryOptions.length - 1;
        
        Widget logoWidget;
        if (opt['name'] == 'FedEx') {
          logoWidget = RichText(
            text: const TextSpan(
              children: [
                TextSpan(text: 'Fed', style: TextStyle(color: Color(0xFF4D148C), fontWeight: FontWeight.w900, fontSize: 14)),
                TextSpan(text: 'Ex', style: TextStyle(color: Color(0xFFFF6600), fontWeight: FontWeight.w900, fontSize: 14)),
              ],
            ),
          );
        } else if (opt['name'] == 'DHL') {
          logoWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFCC00),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Text(
              'DHL',
              style: TextStyle(color: Color(0xFFD00000), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: -0.5),
            ),
          );
        } else { // USPS
          logoWidget = RichText(
            text: const TextSpan(
              children: [
                TextSpan(text: 'USPS ', style: TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.w900, fontSize: 13, fontStyle: FontStyle.italic)),
                TextSpan(text: '★', style: TextStyle(color: Color(0xFFE01934), fontSize: 10)),
              ],
            ),
          );
        }

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedDelivery = opt['name']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: isLast ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF3B30)
                      : Colors.transparent,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 24, child: Center(child: logoWidget)),
                  const SizedBox(height: 8),
                  Text(
                    '\$${(opt['price'] as double).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    opt['days'],
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.thumbnail.startsWith('http')
                ? Image.network(
                    item.thumbnail,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderImage(),
                  )
                : _placeholderImage(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.color}  ·  Size ${item.size}  ·  Qty ${item.quantity}',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey.shade200,
      child: Icon(Icons.image, color: Colors.grey.shade400),
    );
  }

  Widget _buildPriceSummary(
      double subtotal, double discount, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _priceRow('Order:', subtotal),
          if (discount > 0) _priceRow('Promo discount:', -discount, color: Colors.green),
          _priceRow('Delivery:', _deliveryFee),
          const SizedBox(height: 16),
          _priceRow('Summary:', total, bold: true, size: 16),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount,
      {bool bold = false, double size = 14, Color? color}) {
    final isMinus = amount < 0;
    final textColor = bold ? Colors.black : (color ?? Colors.grey.shade600);
    final valueColor = bold ? Colors.black : (color ?? Colors.black87);
    final labelStyle = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.w500,
      fontSize: size,
      color: textColor,
    );
    final valueStyle = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.w600,
      fontSize: size,
      color: valueColor,
    );
    final valueStr = isMinus
        ? '-\$${amount.abs().toStringAsFixed(2)}'
        : '\$${amount.toStringAsFixed(2)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          Text(valueStr, style: valueStyle),
        ],
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (!mounted) return;
    final provider = context.read<EcommerceProvider>();
    if (provider.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(duration: const Duration(seconds: 3), content: Text('Giỏ hàng đang trống!')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await provider.placeOrder(
        deliveryMethod: _selectedDelivery,
        deliveryFee: _deliveryFee,
      );
      await provider.loadCart();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),content: Text('Lỗi đặt hàng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
