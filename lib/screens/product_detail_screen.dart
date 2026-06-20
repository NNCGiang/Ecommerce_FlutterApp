import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/ecommerce_provider.dart';
import '../services/auth_provider.dart';
import 'reviews_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedSize;
  String _selectedColor = 'Black';
  int _currentImageIndex = 0;

  // Gallery items with color metadata from DB
  List<Map<String, dynamic>> _galleryItems = [];
  List<String> _availableColors = [];

  // PageController to sync carousel with color selection
  late PageController _pageController;

  // Recommended products state
  List<dynamic> _recommendations = [];
  bool _loadingRecommendations = true;

  // Expansion tiles state
  bool _showShippingInfo = false;
  bool _showSupportInfo = false;

  final List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initGalleryAndColors();
    _loadRecommendations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EcommerceProvider>().loadReviews(widget.product['id']?.toString() ?? '');
    });
  }

  /// Parse galleryItems from product data and build the available color list.
  void _initGalleryAndColors() {
    final raw = widget.product['galleryItems'];
    if (raw != null && raw is List && raw.isNotEmpty) {
      _galleryItems = raw
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      // Build unique, ordered color list (skip empty strings)
      final seen = <String>{};
      for (final item in _galleryItems) {
        final color = item['color'] as String?;
        if (color != null && color.isNotEmpty && seen.add(color)) {
          _availableColors.add(color);
        }
      }
    }
    // Fallback if DB has no colors yet
    if (_availableColors.isEmpty) {
      _availableColors = ['Black', 'White', 'Red', 'Blue', 'Grey'];
    }
    _selectedColor = _availableColors.first;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    try {
      final currentId = widget.product['id']?.toString() ?? '';
      
      List<dynamic> dbProducts = [];
      try {
        dbProducts = await ApiService.getPublishedProducts();
      } catch (e) {
        debugPrint('Failed to load products from API: $e');
      }

      // Merge API products and local mock products to guarantee variety
      List<dynamic> allProducts = [...dbProducts];
      
      // Add local mock products (ensure they have unique IDs so we can filter duplicates)
      final List<Map<String, dynamic>> mockProducts = [
        {
          'id': 'a0000000-0000-0000-0000-000000000001',
          'productName': 'Evening Dress',
          'productType': 'Dress',
          'salePrice': 12.00,
          'comparePrice': 15.00,
          'thumbnail': 'assets/images/hong.png',
        },
        {
          'id': 'a0000000-0000-0000-0000-000000000002',
          'productName': 'Sport Dress',
          'productType': 'Dress',
          'salePrice': 19.00,
          'comparePrice': 22.00,
          'thumbnail': 'assets/images/xam.png',
        },
        {
          'id': 'a0000000-0000-0000-0000-000000000003',
          'productName': 'T-Shirt Stripes',
          'productType': 'T-Shirt',
          'salePrice': 15.00,
          'thumbnail': 'assets/images/do.png',
        },
        {
          'id': 'a0000000-0000-0000-0000-000000000004',
          'productName': 'Classic Shirt',
          'productType': 'Shirt',
          'salePrice': 25.00,
          'thumbnail': 'assets/images/trangjean.png',
        },
        {
          'id': 'a0000000-0000-0000-0000-000000000005',
          'productName': 'Sport Shirt',
          'productType': 'Dress',
          'salePrice': 14.00,
          'comparePrice': 16.00,
          'thumbnail': 'assets/images/shop5.png',
        },
        {
          'id': 'a0000000-0000-0000-0000-000000000006',
          'productName': 'Linen T-Shirt',
          'productType': 'T-Shirt',
          'salePrice': 22.00,
          'thumbnail': 'assets/images/shop6.png',
        },
        {
          'id': 'a0000000-0000-0000-0000-000000000021',
          'productName': 'Crop Top Basic',
          'productType': 'Tops',
          'salePrice': 12.00,
          'comparePrice': 18.00,
          'thumbnail': 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f',
        },
        {
          'id': 'a0000000-0000-0000-0000-000000000022',
          'productName': 'Lace Crochet Blouse',
          'productType': 'Tops',
          'salePrice': 28.00,
          'comparePrice': 35.00,
          'thumbnail': 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b',
        },
        {
          'id': 'a0000000-0000-0000-0000-000000000023',
          'productName': 'Off-Shoulder Knit Top',
          'productType': 'Tops',
          'salePrice': 24.00,
          'comparePrice': 30.00,
          'thumbnail': 'https://images.unsplash.com/photo-1603252109303-2751441dd157',
        },
        {
          'id': 'a0000000-0000-0000-0000-000000000024',
          'productName': 'Casual Linen Camisole',
          'productType': 'Tops',
          'salePrice': 16.00,
          'comparePrice': 22.00,
          'thumbnail': 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f',
        },
        {
          'id': 'a0000000-0000-0000-0000-000000000025',
          'productName': 'Ruffle Sleeve Top',
          'productType': 'Tops',
          'salePrice': 22.00,
          'comparePrice': 28.00,
          'thumbnail': 'https://images.unsplash.com/photo-1496747611176-843222e1e57c',
        },
        {
          'id': 'a0000000-0000-0000-0000-000000000026',
          'productName': 'Satin Cowl Neck Cami',
          'productType': 'Tops',
          'salePrice': 26.00,
          'comparePrice': 35.00,
          'thumbnail': 'https://images.unsplash.com/photo-1485968579580-b6d095142e6e',
        },
        {
          'id': 'a0000000-0000-0000-0000-000000000027',
          'productName': 'Ribbed Mock Neck Top',
          'productType': 'Tops',
          'salePrice': 18.00,
          'comparePrice': 25.00,
          'thumbnail': 'https://images.unsplash.com/photo-1509631179647-0177331693ae',
        },
        {
          'id': 'a0000000-0000-0000-0000-000000000028',
          'productName': 'Floral Print Chiffon Top',
          'productType': 'Tops',
          'salePrice': 25.00,
          'comparePrice': 32.00,
          'thumbnail': 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b',
        },
        {
          'id': 'a0000000-0000-0000-0000-000000000029',
          'productName': 'Puff Sleeve Square Neck',
          'productType': 'Tops',
          'salePrice': 23.00,
          'comparePrice': 30.00,
          'thumbnail': 'https://images.unsplash.com/photo-1554412933-514a83d2f3c8',
        },
        {
          'id': 'a0000000-0000-0000-0000-000000000030',
          'productName': 'Striped Linen Henley',
          'productType': 'Tops',
          'salePrice': 20.00,
          'comparePrice': 26.00,
          'thumbnail': 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d',
        },
      ];

      // Add mock products that aren't already in allProducts
      for (final mock in mockProducts) {
        final mockId = mock['id']?.toString() ?? '';
        final exists = allProducts.any((p) => p['id']?.toString() == mockId);
        if (!exists) {
          allProducts.add(mock);
        }
      }

      // Filter out the current product
      List<dynamic> filtered = allProducts.where((p) => p['id']?.toString() != currentId).toList();

      // Shuffle to make it random
      filtered.shuffle();

      // Select exactly up to 10 items
      if (filtered.length > 10) {
        filtered = filtered.sublist(0, 10);
      }

      if (mounted) {
        setState(() {
          _recommendations = filtered;
          _loadingRecommendations = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
      if (mounted) {
        setState(() => _loadingRecommendations = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ecommerce = context.watch<EcommerceProvider>();
    final productId = widget.product['id']?.toString() ?? '';
    final isFav = ecommerce.isFavorite(productId);
    final ratingStats = ecommerce.getProductRatingStats(productId);
    
    final double salePrice = (widget.product['salePrice'] as num?)?.toDouble() ?? 0.0;
    final double? comparePrice = (widget.product['comparePrice'] as num?)?.toDouble();
    final String name = widget.product['productName'] ?? '';
    final String type = widget.product['productType'] ?? 'Dress';
    final String description = widget.product['productDescription'] ?? 
        widget.product['shortDescription'] ?? 
        'No description available for this product.';
    final String? thumbnail = widget.product['thumbnail'];
    final List<dynamic>? dbImages = widget.product['images'];
    final List<String> productImages = _getProductImages(thumbnail, dbImages, name);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(duration: const Duration(seconds: 3), content: Text('Product link copied to clipboard!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── PRODUCT IMAGE CAROUSEL ──
            Stack(
              children: [
                Container(
                  height: 400,
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: Hero(
                    tag: 'product-img-$productId',
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: productImages.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                          // Sync selected color when user swipes manually
                          if (_galleryItems.isNotEmpty && index < _galleryItems.length) {
                            final color = _galleryItems[index]['color'] as String?;
                            if (color != null && color.isNotEmpty) {
                              _selectedColor = color;
                            }
                          }
                        });
                      },
                      itemBuilder: (context, index) {
                        return _buildProductImage(productImages[index]);
                      },
                    ),
                  ),
                ),
                if (productImages.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        productImages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentImageIndex == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index
                                ? const Color(0xFFE94560)
                                : Colors.black26,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── SELECTION ROW (SIZE & COLOR) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Size selector dropdown button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showSizeSelectionBottomSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedSize == null ? 'Size' : 'Size: $_selectedSize',
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Color selector dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedColor,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 14),
                          isExpanded: true,
                          items: _availableColors.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedColor = val);
                              // Animate carousel to the image matching this color
                              final idx = _galleryItems.indexWhere(
                                (g) => (g['color'] as String?) == val,
                              );
                              if (idx != -1) {
                                _pageController.animateToPage(
                                  idx,
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeInOut,
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Favorite Icon
                  GestureDetector(
                    onTap: () {
                      final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
                      if (isLoggedIn) {
                        ecommerce.toggleFavorite(widget.product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(!isFav ? 'Added to favorites!' : 'Removed from favorites!'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng đăng nhập để lưu yêu thích'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? const Color(0xFFE94560) : Colors.grey,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── BRAND NAME & DETAILS ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (comparePrice != null && comparePrice > salePrice) ...[
                        Text(
                          _formatPrice(comparePrice),
                          style: const TextStyle(
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatPrice(salePrice),
                          style: const TextStyle(
                            color: Color(0xFFE94560),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ] else ...[
                        Text(
                          _formatPrice(salePrice),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── RATING & REVIEWS SUMMARY ROW ──
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewsScreen(productId: productId, productName: name),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    ...List.generate(5, (index) {
                      final average = ratingStats['average'] as double;
                      if (index < average.floor()) {
                        return const Icon(Icons.star, color: Colors.amber, size: 16);
                      } else if (index == average.floor() && (average - average.floor()) >= 0.5) {
                        return const Icon(Icons.star_half, color: Colors.amber, size: 16);
                      } else {
                        return const Icon(Icons.star_border, color: Colors.amber, size: 16);
                      }
                    }),
                    const SizedBox(width: 6),
                    Text(
                      '(${ratingStats['total']})',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── DESCRIPTION ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── ADD TO CART BUTTON (SCROLLABLE) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _handleAddToCart(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94560),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ADD TO CART',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 0.5),

            // ── SHIPPING INFO EXPANDABLE ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text(
                    'Shipping info',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                  trailing: Icon(
                    _showShippingInfo ? Icons.keyboard_arrow_down : Icons.chevron_right,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    setState(() {
                      _showShippingInfo = !_showShippingInfo;
                    });
                  },
                ),
                if (_showShippingInfo)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      'Standard delivery: 3-4 business days. Free shipping on orders over 50\$. Return or exchange within 30 days of purchase.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                    ),
                  ),
              ],
            ),
            const Divider(height: 1, thickness: 0.5),

            // ── SUPPORT EXPANDABLE ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text(
                    'Support',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                  trailing: Icon(
                    _showSupportInfo ? Icons.keyboard_arrow_down : Icons.chevron_right,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    setState(() {
                      _showSupportInfo = !_showSupportInfo;
                    });
                  },
                ),
                if (_showSupportInfo)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      'Need help? Contact our support via live chat, email (support@ct1shop.com) or phone (1900-1234). Support hours: 8:00 AM - 10:00 PM.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                    ),
                  ),
              ],
            ),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 24),

            // ── RECOMMENDATIONS LIST WRAPPER ──
            Container(
              color: const Color(0xFFF9F9F9), // Slightly greyish background
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── RECOMMENDATIONS HEADER ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'You can also like this',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          '${_recommendations.length} items',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── RECOMMENDATIONS LIST ──
                  _loadingRecommendations
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
                      : _recommendations.isEmpty
                          ? const SizedBox.shrink()
                          : SizedBox(
                              height: 290,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _recommendations.length,
                                itemBuilder: (context, index) {
                                  return _recommendationCard(_recommendations[index]);
                                },
                              ),
                            ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _recommendationCard(Map<String, dynamic> product) {
    final double salePrice = (product['salePrice'] as num?)?.toDouble() ?? 0.0;
    final double? comparePrice = (product['comparePrice'] as num?)?.toDouble();

    int discountPercent = 0;
    bool isSale = comparePrice != null && comparePrice > salePrice;
    if (isSale) {
      discountPercent = (((comparePrice - salePrice) / comparePrice) * 100).round();
    }

    final String? thumbnail = product['thumbnail'];
    final String name = product['productName'] ?? '';
    final String type = product['productType'] ?? 'Dress';

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and badges container
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 160,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildProductImage(thumbnail),
                  ),
                ),
                // Badge Top Left (Sale / New)
                Positioned(
                  top: 8,
                  left: 8,
                  child: isSale
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE94560),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '-$discountPercent%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                // Favorite floating heart icon
                Positioned(
                  bottom: -15,
                  right: 0,
                  child: Consumer<EcommerceProvider>(
                    builder: (context, ecommerceProvider, child) {
                      final isFavRec = ecommerceProvider.isFavorite(product['id']?.toString() ?? '');
                      return GestureDetector(
                        onTap: () {
                          if (context.read<AuthProvider>().isLoggedIn) {
                            ecommerceProvider.toggleFavorite(product);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                duration: const Duration(seconds: 3),
                                content: Text('Vui lòng đăng nhập để lưu yêu thích'),
                              ),
                            );
                          }
                        },
                        child: Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              isFavRec ? Icons.favorite : Icons.favorite_border,
                              color: isFavRec ? const Color(0xFFE94560) : Colors.grey,
                              size: 18,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),

            // Star ratings row
            Row(
              children: [
                ...List.generate(5, (index) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 13,
                )),
                const SizedBox(width: 4),
                const Text(
                  '(10)',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Sub-description
            Text(
              type,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Product Name
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Price section
            Row(
              children: [
                if (isSale) ...[
                  Text(
                    _formatPrice(comparePrice),
                    style: const TextStyle(
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatPrice(salePrice),
                    style: const TextStyle(
                      color: Color(0xFFE94560),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ] else ...[
                  Text(
                    _formatPrice(salePrice),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            )
          ],
        ),
      ),
    );
  }

  void _handleAddToCart(BuildContext context) {
    if (_selectedSize == null) {
      _showSizeSelectionBottomSheet(context, andAddToCart: true);
    } else {
      _executeAddToCart(context);
    }
  }

  void _executeAddToCart(BuildContext context) {
    final ecommerce = context.read<EcommerceProvider>();
    final double salePrice = (widget.product['salePrice'] as num?)?.toDouble() ?? 0.0;
    
    ecommerce.addToCart(CartItem(
      productId: widget.product['id']?.toString() ?? '',
      productName: widget.product['productName'] ?? '',
      thumbnail: widget.product['thumbnail'] ?? '',
      size: _selectedSize!,
      color: _selectedColor,
      price: salePrice,
      quantity: 1,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Added to cart: ${widget.product['productName']} (Size $_selectedSize, Color $_selectedColor)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            // Remove the added item
            final index = ecommerce.cartItems.indexWhere((item) =>
                item.productId == widget.product['id']?.toString() &&
                item.size == _selectedSize &&
                item.color == _selectedColor);
            if (index != -1) {
              final quantity = ecommerce.cartItems[index].quantity;
              ecommerce.updateQuantity(index, quantity - 1);
            }
          },
        ),
      ),
    );
  }

  // ── SIZE SELECTION BOTTOM SHEET ──
  void _showSizeSelectionBottomSheet(BuildContext context, {bool andAddToCart = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pill Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[350],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  
                  // Title Select Size
                  const Center(
                    child: Text(
                      'Select size',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Size Choices Grid / Buttons
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _sizes.map((size) {
                      final isSelected = _selectedSize == size;
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            _selectedSize = size;
                          });
                          setState(() {
                            _selectedSize = size;
                          });
                        },
                        child: Container(
                          width: 100,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFE94560) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFE94560) : Colors.black12,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              size,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Size Info list tile
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Size info', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _showSizeInfoDialog(context);
                    },
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 24),

                  // Add to cart inside bottom sheet
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedSize == null) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(duration: const Duration(seconds: 3), content: Text('Please select a size first!')),
                          );
                          return;
                        }
                        Navigator.of(sheetContext).pop();
                        if (andAddToCart) {
                          _executeAddToCart(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE94560),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'ADD TO CART',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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

  void _showSizeInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Size Guide'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('XS: Chest 80-84 cm, Waist 62-66 cm'),
              SizedBox(height: 8),
              Text('S: Chest 84-88 cm, Waist 66-70 cm'),
              SizedBox(height: 8),
              Text('M: Chest 88-92 cm, Waist 70-74 cm'),
              SizedBox(height: 8),
              Text('L: Chest 92-96 cm, Waist 74-78 cm'),
              SizedBox(height: 8),
              Text('XL: Chest 96-100 cm, Waist 78-82 cm'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Color(0xFFE94560))),
            ),
          ],
        );
      },
    );
  }

  List<String> _getProductImages(String? thumbnail, List<dynamic>? dbImages, String name) {
    // Prefer galleryItems (has color metadata) over plain dbImages list
    if (_galleryItems.isNotEmpty) {
      final urls = _galleryItems
          .map((g) => (g['image'] as String? ?? '').trim())
          .where((url) => url.isNotEmpty)
          .toList();
      if (urls.isNotEmpty) return urls;
    }

    if (dbImages != null && dbImages.isNotEmpty) {
      final urls = dbImages.map((e) => e.toString().trim()).where((url) => url.isNotEmpty).toSet().toList();
      if (urls.length >= 3) {
        return urls;
      }
    }
    final String clean = (thumbnail ?? '').trim();
    if (clean.isNotEmpty) {
      if (clean.contains('unsplash.com')) {
        final base = clean.split('?')[0];
        if (base.contains('1515886657613-9f3515b0c78f')) {
          return [
            clean,
            'https://images.unsplash.com/photo-1554568218-0f1715e72254?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1543087903-1ac2ec7aa8c5?auto=format&fit=crop&w=600&q=80',
          ];
        } else if (base.contains('1539109136881-3be0616acf4b')) {
          return [
            clean,
            'https://images.unsplash.com/photo-1607345366928-199ea26cfe3e?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1581044777550-4cfa60707c03?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1525507119028-ed4c629a60a3?auto=format&fit=crop&w=600&q=80',
          ];
        } else if (base.contains('1603252109303-2751441dd157')) {
          return [
            clean,
            'https://images.unsplash.com/photo-1618244972963-dbee1a7edc95?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1608234807905-446585f3c6c6?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?auto=format&fit=crop&w=600&q=80',
          ];
        } else if (base.contains('1541099649105-f69ad21f3246') || base.contains('1512436991641-6745cdb1723f') || base.contains('1609357605129-26f69add5d6e')) {
          return [
            'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1609357605129-26f69add5d6e?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1619119069152-a2b331eb392a?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1551799517-eb8f03cb5e6a?auto=format&fit=crop&w=600&q=80',
          ];
        } else if (base.contains('1496747611176-843222e1e57c')) {
          return [
            clean,
            'https://images.unsplash.com/photo-1509319117193-57bab727e09d?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1605763240000-7e93b172d754?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1562157873-818bc0726f68?auto=format&fit=crop&w=600&q=80',
          ];
        } else if (base.contains('1485968579580-b6d095142e6e')) {
          return [
            clean,
            'https://images.unsplash.com/photo-1518612395370-681c3a6dec7e?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1502301197179-6522b4bce296?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=600&q=80',
          ];
        } else if (base.contains('1509631179647-0177331693ae')) {
          return [
            clean,
            'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1616159840936-0e03885724d5?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1598554747436-c9293d6a588f?auto=format&fit=crop&w=600&q=80',
          ];
        } else if (base.contains('1529139574466-a303027c1d8b')) {
          return [
            clean,
            'https://images.unsplash.com/photo-1584273143981-41c073dfe8f8?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1518310383802-640c2de311b2?auto=format&fit=crop&w=600&q=80',
          ];
        } else if (base.contains('1554412933-514a83d2f3c8')) {
          return [
            clean,
            'https://images.unsplash.com/photo-1604176354204-9268737828e4?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1578587018452-892bacefd3f2?auto=format&fit=crop&w=600&q=80',
          ];
        } else if (base.contains('1490481651871-ab68de25d43d')) {
          return [
            clean,
            'https://images.unsplash.com/photo-1507679799987-c73779587ccf?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?auto=format&fit=crop&w=600&q=80',
            'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?auto=format&fit=crop&w=600&q=80',
          ];
        }
        return [
          clean,
          '$clean?auto=format&fit=crop&w=600&q=80',
          '$clean?auto=format&fit=crop&w=600&q=80&rect=0,50,800,600',
          '$clean?auto=format&fit=crop&w=600&q=80&rect=0,150,800,500',
        ];
      }
      if (clean.contains('hong.png')) {
        return [
          'assets/images/hong.png',
          'assets/images/trang.png',
          'assets/images/den.png',
          'assets/images/do.png',
        ];
      } else if (clean.contains('xam.png')) {
        return [
          'assets/images/xam.png',
          'assets/images/trang.png',
          'assets/images/den.png',
          'assets/images/hong.png',
        ];
      } else if (clean.contains('do.png')) {
        return [
          'assets/images/do.png',
          'assets/images/doden.png',
          'assets/images/trang.png',
          'assets/images/den.png',
        ];
      } else if (clean.contains('trangjean.png')) {
        return [
          'assets/images/trangjean.png',
          'assets/images/dentrang.png',
          'assets/images/setjean.png',
          'assets/images/jean.png',
        ];
      } else if (clean.contains('shop5.png')) {
        return [
          'assets/images/shop5.png',
          'assets/images/shop1.png',
          'assets/images/shop2.png',
          'assets/images/shop3.png',
        ];
      } else if (clean.contains('shop6.png')) {
        return [
          'assets/images/shop6.png',
          'assets/images/shop4.png',
          'assets/images/shop1.png',
          'assets/images/shop2.png',
        ];
      }
      return [clean, clean, clean, clean];
    }
    return [];
  }

  Widget _buildProductImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const Center(child: Icon(Icons.image_outlined, size: 80, color: Colors.grey));
    }
    
    String cleanPath = imagePath.trim();
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return Image.network(
        cleanPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image_outlined, size: 80, color: Colors.grey),
        ),
      );
    } else {
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }
      if (cleanPath.startsWith('\\')) {
        cleanPath = cleanPath.substring(1);
      }
      if (!cleanPath.contains('assets/')) {
        cleanPath = 'assets/images/$cleanPath';
      }
      return Image.asset(
        cleanPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image_outlined, size: 80, color: Colors.grey),
        ),
      );
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0đ';
    double val = 0.0;
    if (price is num) {
      val = price.toDouble();
    } else {
      val = double.tryParse(price.toString()) ?? 0.0;
    }
    if (val < 1000) {
      return '${val.toStringAsFixed(0)}\$';
    }
    final int intVal = val.round();
    final formatted = intVal.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$formattedđ';
  }
}
