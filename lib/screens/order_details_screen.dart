import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/ecommerce_provider.dart';
import 'leave_feedback_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _FavoritesSyncHelper {
  // Helper to resolve brand name dynamically to match design mockup
  static String getBrandName(String productName) {
    final lower = productName.toLowerCase();
    if (lower.contains('shirt')) return 'LIME';
    if (lower.contains('violeta') || lower.contains('dress')) return 'Mango';
    if (lower.contains('stripe')) return 'Zara';
    if (lower.contains('crop')) return 'ASOS';
    return 'Oliver';
  }
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  String? _error;
  bool _isCancelling = false;

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() {
        _isCancelling = true;
      });

      await ApiService.cancelOrder(widget.orderId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully!'), backgroundColor: Colors.green),
        );
        // Refresh details
        _fetchOrderDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel order: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final order = await ApiService.getOrder(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(dateTime);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ecommerce = context.watch<EcommerceProvider>();

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F9F9),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF3B30))),
      );
    }

    if (_error != null || _order == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Order Details', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error: ${_error ?? "Order details not found"}', style: const TextStyle(color: Colors.red)),
          ),
        ),
      );
    }

    final order = _order!;
    final orderId = order['id'] ?? '';
    final date = _formatDateTime(order['createdAt']);
    final tracking = order['trackingNumber'] ?? 'N/A';
    final status = (order['statusName'] ?? 'PENDING').toString();
    final items = order['items'] as List? ?? [];
    
    // Total calculation
    final double itemsTotal = (order['total'] as num?)?.toDouble() ?? 0.0;
    final double deliveryFee = (order['deliveryFee'] as num?)?.toDouble() ?? 0.0;
    final String deliveryMethod = order['deliveryMethod'] ?? 'FedEx';
    
    double discount = 0.0;
    String discountText = '0%';
    if (order['couponId'] != null) {
      discount = itemsTotal * 0.10;
      discountText = '10%, Personal promo code';
    }

    final double totalAmount = itemsTotal - discount + deliveryFee;

    // Retrieve address details from Provider
    final addrId = order['shippingAddressId']?.toString();
    final addr = ecommerce.addresses.firstWhere(
      (a) => a['id']?.toString() == addrId,
      orElse: () => null,
    );
    final String addressText = addr != null
        ? '${addr['addressLine1'] ?? ''}, ${addr['city'] ?? ''}, ${addr['state'] ?? ''} ${addr['zipCode'] ?? ''}, ${addr['country'] ?? ''}'
        : '3 Newbridge Court, Chino Hills, CA 91709, United States';

    // Retrieve payment card details from Provider
    final cardId = order['paymentCardId']?.toString();
    final paymentCard = ecommerce.paymentCards.firstWhere(
      (c) => c['id']?.toString() == cardId,
      orElse: () => null,
    );
    final String cardText = paymentCard != null
        ? '${paymentCard['brand'] ?? 'Card'} **** **** **** ${paymentCard['maskedNumber'] != null && paymentCard['maskedNumber'].length >= 4 ? paymentCard['maskedNumber'].substring(paymentCard['maskedNumber'].length - 4) : '3947'}'
        : 'Mastercard **** **** **** 3947';

    Color statusColor = Colors.grey;
    String displayStatus = 'Processing';
    if (status.toUpperCase() == 'DELIVERED') {
      statusColor = Colors.green;
      displayStatus = 'Delivered';
    } else if (status.toUpperCase() == 'CANCELLED') {
      statusColor = Colors.red;
      displayStatus = 'Cancelled';
    }

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
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black, size: 26),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // Order meta header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order №$orderId',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                      ),
                      Text(
                        date,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('Tracking number: ', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                          Text(
                            tracking,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black),
                          ),
                        ],
                      ),
                      Text(
                        displayStatus,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Items Count
                  Text(
                    '${items.length} items',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                  ),
                  const SizedBox(height: 12),

                  // List of Items
                  ...items.map((item) {
                    final String name = item['productName'] ?? '';
                    final String brand = _FavoritesSyncHelper.getBrandName(name);
                    final String color = item['color'] ?? 'Gray';
                    final String size = item['size'] ?? 'L';
                    final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
                    final int qty = (item['quantity'] as num?)?.toInt() ?? 1;
                    final String? thumbnail = item['thumbnail'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          // Thumbnail Image
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                            child: Container(
                              width: 80,
                              height: 110,
                              color: Colors.grey.shade100,
                              child: _buildProductImage(thumbnail),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Text Details
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    brand,
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text('Color: ', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                      Text(color, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w500)),
                                      const SizedBox(width: 16),
                                      Text('Size: ', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                      Text(size, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text('Units: ', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                      Text('$qty', style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Price
                          Padding(
                            padding: const EdgeInsets.only(right: 16, left: 8),
                            child: Text(
                              '${(price * qty).toStringAsFixed(0)}\$',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),

                  // Order Information
                  const Text(
                    'Order information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                  ),
                  const SizedBox(height: 16),

                  // Shipping Address Row
                  _buildOrderInfoRow('Shipping Address:', addressText),
                  const SizedBox(height: 14),
                  // Payment Method Row
                  _buildOrderInfoRow('Payment method:', cardText),
                  const SizedBox(height: 14),
                  // Delivery Method Row
                  _buildOrderInfoRow('Delivery method:', '$deliveryMethod, 3 days, ${deliveryFee.toStringAsFixed(0)}\$'),
                  const SizedBox(height: 14),
                  // Discount Row
                  _buildOrderInfoRow('Discount:', discountText),
                  const SizedBox(height: 14),
                  // Total Amount Row
                  _buildOrderInfoRow('Total Amount:', '${totalAmount.toStringAsFixed(0)}\$', isTotal: true),
                ],
              ),
            ),
            
            // Reorder and Leave Feedback / Cancel Buttons Row
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        ),
                        onPressed: () {
                          // Perform re-order: add items back to cart
                          for (var item in items) {
                            ecommerce.addToCart(CartItem(
                              productId: item['productId']?.toString() ?? '',
                              productName: item['productName'] ?? '',
                              thumbnail: item['thumbnail'] ?? '',
                              size: item['size'] ?? 'L',
                              color: item['color'] ?? 'Gray',
                              price: (item['price'] as num?)?.toDouble() ?? 0.0,
                              quantity: (item['quantity'] as num?)?.toInt() ?? 1,
                            ));
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Items added to cart!'), backgroundColor: Colors.green),
                          );
                        },
                        child: const Text(
                          'Reorder',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  if (status.toUpperCase() == 'DELIVERED' ||
                      status.toUpperCase() == 'PENDING' ||
                      status.toUpperCase() == 'PROCESSING') ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF3B30),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                          ),
                          onPressed: _isCancelling
                              ? null
                              : () {
                                  if (status.toUpperCase() == 'DELIVERED') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => LeaveFeedbackScreen(items: items),
                                      ),
                                    );
                                  } else {
                                    _cancelOrder();
                                  }
                                },
                          child: _isCancelling
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  status.toUpperCase() == 'DELIVERED'
                                      ? 'Leave feedback'
                                      : 'Cancel order',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoRow(String label, String value, {bool isTotal = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
              color: isTotal ? const Color(0xFFFF3B30) : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const Center(child: Icon(Icons.image_outlined, size: 24, color: Colors.grey));
    }
    
    String cleanPath = imagePath.trim();
    
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return Image.network(
        cleanPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image, size: 24, color: Colors.grey)),
      );
    } else if (cleanPath.contains('assets/')) {
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }
      return Image.asset(
        cleanPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image, size: 24, color: Colors.grey)),
      );
    } else {
      // It's a server uploaded path like "/uploads/xxx.png"
      final fullUrl = ApiService.getFullImageUrl(cleanPath);
      return Image.network(
        fullUrl,
        headers: const {'ngrok-skip-browser-warning': 'true'},
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image, size: 24, color: Colors.grey)),
      );
    }
  }
}
