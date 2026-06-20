import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ecommerce_provider.dart';
import 'add_card_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool _loading = false;

  static const Color _red = Color(0xFFFF3B30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCards();
    });
  }

  Future<void> _loadCards() async {
    setState(() => _loading = true);
    final p = context.read<EcommerceProvider>();
    await p.loadPaymentCards();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _setDefault(String id) async {
    setState(() => _loading = true);
    try {
      await context.read<EcommerceProvider>().setDefaultCard(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(duration: const Duration(seconds: 3), content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa thẻ',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc muốn xóa thẻ này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _loading = true);
    try {
      final p = context.read<EcommerceProvider>();
      await p.deletePaymentCard(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(duration: const Duration(seconds: 3), content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final cards = context.watch<EcommerceProvider>().paymentCards;

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
          'Payment methods',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF3B30)))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Your payment cards',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: cards.isEmpty
                        ? _buildEmpty()
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: cards.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 24),
                            itemBuilder: (_, i) => _buildCreditCard(cards[i]),
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const FractionallySizedBox(
              heightFactor: 0.9,
              child: AddCardScreen(),
            ),
          );
          if (mounted) _loadCards();
        },
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Chưa có thẻ nào',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm thẻ để thanh toán nhanh hơn',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCard(Map<String, dynamic> card) {
    final id = card['id']?.toString() ?? '';
    final brand = (card['brand'] ?? '').toString().toUpperCase();
    final isMC = brand.contains('MASTER') || brand.contains('MC');
    final masked = card['maskedNumber'] ?? card['cardNumber'] ?? '•••• •••• •••• ••••';
    final holder = card['cardHolderName'] ?? 'FULL NAME';
    final expiryMonth = card['expiryMonth'];
    final expiryYear = card['expiryYear'];
    final expiry = (expiryMonth != null && expiryYear != null)
        ? '${expiryMonth.toString().padLeft(2, '0')}/${expiryYear.toString().substring(expiryYear.toString().length > 2 ? expiryYear.toString().length - 2 : 0)}'
        : 'MM/YY';
    final isDefault = card['isDefault'] == true;

    Widget cardWidget = Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isMC
              ? [const Color(0xFF2B2B2B), const Color(0xFF0F0F0F)]
              : [const Color(0xFF8A95A5), const Color(0xFF6C7B90)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Chip decoration
          Positioned(
            top: 24,
            left: 24,
            child: Container(
              width: 40,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFE5C158),
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF3D078), Color(0xFFC59E3F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // chip lines
                  Positioned.fill(
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 3,
                        mainAxisSpacing: 3,
                      ),
                      itemCount: 9,
                      itemBuilder: (_, __) => Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12, width: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Masked number
          Positioned(
            top: 76,
            left: 24,
            right: 24,
            child: Text(
              masked,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
          ),
          // Cardholder Name
          Positioned(
            bottom: 24,
            left: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Card Holder',
                  style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  holder.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Expiry
          Positioned(
            bottom: 24,
            left: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expires',
                  style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  expiry,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Brand Logo
          Positioned(
            bottom: 24,
            right: 24,
            child: isMC
                ? Stack(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEB001B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Positioned(
                        left: 14,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9F0A).withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'VISA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ],
      ),
    );

    // Apply selection border if default
    if (isDefault) {
      cardWidget = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF007AFF), width: 3), // bold blue border
        ),
        child: cardWidget,
      );
    }

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        await _delete(id);
        return false;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cardWidget,
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              if (!isDefault) _setDefault(id);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDefault ? Colors.black : Colors.grey.shade400,
                        width: 2,
                      ),
                      color: isDefault ? Colors.black : Colors.transparent,
                    ),
                    child: isDefault
                        ? const Icon(Icons.check, color: Colors.white, size: 12)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Use as default payment method',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
