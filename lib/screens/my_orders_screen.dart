import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'order_details_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  String _activeTab = 'Delivered'; // 'Delivered', 'Processing', 'Cancelled'
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final orders = await ApiService.getOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Map backend status names to our tab categories
  bool _filterOrder(dynamic order) {
    final status = (order['statusName'] ?? 'PENDING').toString().toUpperCase();
    if (_activeTab == 'Delivered') {
      return status == 'DELIVERED';
    } else if (_activeTab == 'Processing') {
      return status == 'PENDING' || status == 'PROCESSING';
    } else {
      return status == 'CANCELLED';
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
    final filtered = _orders.where(_filterOrder).toList();

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
            icon: const Icon(Icons.search, color: Colors.black, size: 26),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'My Orders',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            const SizedBox(height: 12),
            // Horizontal Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['Delivered', 'Processing', 'Cancelled'].map((tab) {
                  final isSelected = _activeTab == tab;
                  return GestureDetector(
                    onTap: () => setState(() => _activeTab = tab),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),
            
            // Orders List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchOrders,
                color: const Color(0xFFFF3B30),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: const Color(0xFFFF3B30)))
                    : _error != null
                        ? Center(child: Text('Error loading orders: $_error', style: const TextStyle(color: Colors.red)))
                        : filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No $_activeTab orders found',
                                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final order = filtered[index];
                                  final orderId = order['id'] ?? '';
                                  final date = _formatDateTime(order['createdAt']);
                                  final tracking = order['trackingNumber'] ?? 'N/A';
                                  final total = (order['total'] as num?)?.toDouble() ?? 0.0;
                                  final items = order['items'] as List? ?? [];
                                  
                                  int qty = 0;
                                  for (var item in items) {
                                    qty += (item['quantity'] as num?)?.toInt() ?? 0;
                                  }

                                  final statusName = (order['statusName'] ?? 'PENDING').toString();
                                  Color statusColor = Colors.grey;
                                  String displayStatus = 'Processing';
                                  if (statusName.toUpperCase() == 'DELIVERED') {
                                    statusColor = Colors.green;
                                    displayStatus = 'Delivered';
                                  } else if (statusName.toUpperCase() == 'CANCELLED') {
                                    statusColor = Colors.red;
                                    displayStatus = 'Cancelled';
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Order №$orderId',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              date,
                                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Text('Tracking number: ', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                                            Text(
                                              tracking,
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Text('Quantity: ', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                                                Text(
                                                  '$qty',
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text('Total Amount: ', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                                                Text(
                                                  '${total.toStringAsFixed(0)}\$',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Details button
                                            SizedBox(
                                              height: 36,
                                              child: OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(color: Colors.black),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => OrderDetailsScreen(orderId: orderId),
                                                    ),
                                                  );
                                                },
                                                child: const Text(
                                                  'Details',
                                                  style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            // Status
                                            Text(
                                              displayStatus,
                                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
