import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ecommerce_provider.dart';
import '../services/auth_provider.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isGridView = false;
  String _selectedCategory = 'All';
  String _sortOrder = 'none'; // 'none', 'low_to_high', 'high_to_low'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthProvider>().isLoggedIn) {
        context.read<EcommerceProvider>().loadFavorites();
      }
    });
  }

  // Helper to format prices in USD or VND
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
    final formatted = intVal.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), 
      (m) => '${m[1]}.'
    );
    return '$formattedđ';
  }

  // Get mock brand name to fit design aesthetics in screenshots
  String _getBrandName(String productName) {
    final lower = productName.toLowerCase();
    if (lower.contains('shirt')) return 'LIME';
    if (lower.contains('violeta') || lower.contains('dress')) return 'Mango';
    if (lower.contains('stripe')) return 'Zara';
    if (lower.contains('crop')) return 'ASOS';
    return 'Oliver';
  }

  @override
  Widget build(BuildContext context) {
    final ecommerce = context.watch<EcommerceProvider>();
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;

    if (!isLoggedIn) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Vui lòng đăng nhập để xem danh sách yêu thích',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    final favorites = ecommerce.favorites;

    // 1. Extract dynamic categories
    final categories = ['All'];
    for (var item in favorites) {
      final type = item['productType'] ?? '';
      if (type.isNotEmpty && !categories.contains(type)) {
        categories.add(type);
      }
    }

    // 2. Filter favorites
    var filteredList = favorites.where((item) {
      if (_selectedCategory == 'All') return true;
      return item['productType'] == _selectedCategory;
    }).toList();

    // 3. Sort favorites
    if (_sortOrder == 'low_to_high') {
      filteredList.sort((a, b) {
        final priceA = (a['salePrice'] as num?)?.toDouble() ?? 0.0;
        final priceB = (b['salePrice'] as num?)?.toDouble() ?? 0.0;
        return priceA.compareTo(priceB);
      });
    } else if (_sortOrder == 'high_to_low') {
      filteredList.sort((a, b) {
        final priceA = (a['salePrice'] as num?)?.toDouble() ?? 0.0;
        final priceB = (b['salePrice'] as num?)?.toDouble() ?? 0.0;
        return priceB.compareTo(priceA);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _isGridView 
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              centerTitle: true,
              title: const Text(
                'Favorites',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black87),
                  tooltip: 'Search',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  ),
                ),
              ],
            )
          : null, // Title is inside body when List layout is selected, matching standard iOS design.
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title for List View
            if (!_isGridView)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Favorites',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.black87, size: 28),
                      tooltip: 'Search',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      ),
                    ),
                  ],
                ),
              ),

            // Horizontal Chips
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, idx) {
                  final cat = categories[idx];
                  final isSelected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat);
                        }
                      },
                      selectedColor: const Color(0xFF222222),
                      backgroundColor: Colors.white,
                      elevation: isSelected ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Filters, Sort, Grid/List Toggles row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Filters
                    InkWell(
                      onTap: () {},
                      child: Row(
                        children: [
                          const Icon(Icons.filter_list, size: 20, color: Colors.black87),
                          const SizedBox(width: 4),
                          const Text(
                            'Filters',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    // Sorting
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (_sortOrder == 'none') {
                            _sortOrder = 'low_to_high';
                          } else if (_sortOrder == 'low_to_high') {
                            _sortOrder = 'high_to_low';
                          } else {
                            _sortOrder = 'none';
                          }
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            _sortOrder == 'low_to_high' 
                                ? Icons.arrow_upward 
                                : _sortOrder == 'high_to_low' 
                                    ? Icons.arrow_downward 
                                    : Icons.swap_vert, 
                            size: 18, 
                            color: Colors.black87
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _sortOrder == 'low_to_high' 
                                ? 'Price: low to high' 
                                : _sortOrder == 'high_to_low' 
                                    ? 'Price: high to low' 
                                    : 'Sort by',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    // List/Grid Toggle
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        _isGridView ? Icons.grid_view_sharp : Icons.list,
                        color: Colors.black87,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _isGridView = !_isGridView);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Content
            Expanded(
              child: filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE94560).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite_border,
                              size: 64,
                              color: Color(0xFFE94560),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No Favorites Found',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try adding items or selecting different categories.',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : _isGridView
                      ? _buildGridView(filteredList, ecommerce)
                      : _buildListView(filteredList, ecommerce),
            ),
          ],
        ),
      ),
    );
  }

  // ─── LIST VIEW LAYOUT ───────────────────────────────
  Widget _buildListView(List<dynamic> list, EcommerceProvider ecommerce) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final String name = item['productName'] ?? '';
        final String brand = _getBrandName(name);
        
        final double salePrice = (item['salePrice'] as num?)?.toDouble() ?? 0.0;
        final double? comparePrice = (item['comparePrice'] as num?)?.toDouble();
        final int quantity = item['quantity'] ?? 0;
        final bool isOutOfStock = quantity <= 0;

        int discountPercent = 0;
        if (comparePrice != null && comparePrice > salePrice) {
          discountPercent = (((comparePrice - salePrice) / comparePrice) * 100).round();
        }

        final ratingStats = ecommerce.getProductRatingStats(item['id']?.toString() ?? '');
        final double avgRating = ratingStats['average'];
        final int totalReviews = ratingStats['total'];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Stack(
            children: [
              // Navigation trigger
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: item),
                    ),
                  );
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image
                    Stack(
                      children: [
                        Container(
                          width: 105,
                          height: 115,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                            child: _buildProductImage(item['thumbnail']),
                          ),
                        ),
                        // Sale / Discount badge on Image
                        if (discountPercent > 0)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
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
                            ),
                          ),
                        // OUT OF STOCK overlay on image
                        if (isOutOfStock)
                          Container(
                            width: 105,
                            height: 115,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Product info
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 8, right: 36),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              brand,
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Attributes Color & Size
                            Text(
                              'Color: Blue   Size: L', // Mock matching mockup
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            ),
                            const SizedBox(height: 6),
                            // Rating Row
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  return Icon(
                                    index < avgRating.round() ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 13,
                                  );
                                }),
                                const SizedBox(width: 4),
                                Text(
                                  '($totalReviews)',
                                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Price
                            Row(
                              children: [
                                if (comparePrice != null && comparePrice > salePrice) ...[
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
                            ),
                            if (isOutOfStock) ...[
                              const SizedBox(height: 6),
                              const Text(
                                'Sorry, this item is currently sold out',
                                style: TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Close / Delete 'x' Button on Top Right
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () {
                    ecommerce.toggleFavorite(item);
                  },
                ),
              ),

              // Red Add to Cart Button floating bottom right (Only if in stock)
              if (!isOutOfStock)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () {
                      ecommerce.addToCart(CartItem(
                        productId: item['id']?.toString() ?? '',
                        productName: name,
                        thumbnail: item['thumbnail'] ?? '',
                        size: 'L', // default size
                        color: 'Blue', // default color
                        price: salePrice,
                        quantity: 1,
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã thêm vào giỏ hàng thành công!'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE94560),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_bag,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                )
              else
                // Gray Out of Stock shopping bag button
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── GRID VIEW LAYOUT ───────────────────────────────
  Widget _buildGridView(List<dynamic> list, EcommerceProvider ecommerce) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.52,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final item = list[index];
        final String name = item['productName'] ?? '';
        final String brand = _getBrandName(name);

        final double salePrice = (item['salePrice'] as num?)?.toDouble() ?? 0.0;
        final double? comparePrice = (item['comparePrice'] as num?)?.toDouble();
        final int quantity = item['quantity'] ?? 0;
        final bool isOutOfStock = quantity <= 0;

        int discountPercent = 0;
        if (comparePrice != null && comparePrice > salePrice) {
          discountPercent = (((comparePrice - salePrice) / comparePrice) * 100).round();
        }

        final ratingStats = ecommerce.getProductRatingStats(item['id']?.toString() ?? '');
        final double avgRating = ratingStats['average'];
        final int totalReviews = ratingStats['total'];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: item),
                        ),
                      );
                    },
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        child: _buildProductImage(item['thumbnail']),
                      ),
                    ),
                  ),

                  // Sale / Discount badge on Image
                  if (discountPercent > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
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
                      ),
                    ),

                  // Close / Delete 'x' Button
                  Positioned(
                    top: 2,
                    right: 2,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                      onPressed: () {
                        ecommerce.toggleFavorite(item);
                      },
                    ),
                  ),

                  // Red Add to Cart Button floating on image bottom-right
                  if (!isOutOfStock)
                    Positioned(
                      bottom: -15,
                      right: 8,
                      child: InkWell(
                        onTap: () {
                          ecommerce.addToCart(CartItem(
                            productId: item['id']?.toString() ?? '',
                            productName: name,
                            thumbnail: item['thumbnail'] ?? '',
                            size: 'L',
                            color: 'Blue',
                            price: salePrice,
                            quantity: 1,
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã thêm vào giỏ hàng thành công!'),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE94560),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(
                            Icons.shopping_bag,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    )
                  else
                    // Gray Out of Stock shopping bag button
                    Positioned(
                      bottom: -15,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(
                          Icons.shopping_bag,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),

                  // OUT OF STOCK overlay & text on top of image
                  if (isOutOfStock) ...[
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Text(
                        'Sorry, this item is currently sold out',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Product Info Below Image
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rating Row
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < avgRating.round() ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 13,
                            );
                          }),
                          const SizedBox(width: 4),
                          Text(
                            '($totalReviews)',
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        brand,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
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
                      const SizedBox(height: 2),
                      Text(
                        'Color: Blue  Size: L',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      // Price
                      Row(
                        children: [
                          if (comparePrice != null && comparePrice > salePrice) ...[
                            Text(
                              _formatPrice(comparePrice),
                              style: const TextStyle(
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatPrice(salePrice),
                              style: const TextStyle(
                                color: Color(0xFFE94560),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ] else ...[
                            Text(
                              _formatPrice(salePrice),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Image loading helper
  Widget _buildProductImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const Center(child: Icon(Icons.image_outlined, size: 36, color: Colors.grey));
    }
    
    String cleanPath = imagePath.trim();
    
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return Image.network(
        cleanPath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey),
          );
        },
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
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey),
          );
        },
      );
    }
  }
}
