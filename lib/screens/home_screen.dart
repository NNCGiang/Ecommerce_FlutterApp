import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../services/ecommerce_provider.dart';
import 'categories_screen.dart';
import 'login_screen2.dart';
import 'product_detail_screen.dart';
import 'favorites_screen.dart';
import 'checkout_screen.dart';
import 'my_orders_screen.dart';
import 'settings_screen.dart';
import 'shipping_addresses_screen.dart';
import 'payment_methods_screen.dart';
import 'search_screen.dart';
import 'promocodes_screen.dart';
import 'my_reviews_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNav = 0;
  List<dynamic> _saleProducts = [];
  List<dynamic> _newProducts = [];
  bool _loadingSale = true;
  bool _loadingNew = true;
  String? _initialCategoryTag;

  final List<Map<String, String>> _bannerItems = [
    {
      'image': 'assets/images/fash.png',
      'title': 'Fashion\nsale',
    },
    {
      'image': 'assets/images/anh1.png',
      'title': 'Street\nclothes',
    },
    {
      'image': 'assets/images/anh2.png',
      'title': 'New\ncollection',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthProvider>().isLoggedIn) {
        final ep = context.read<EcommerceProvider>();
        ep.loadCart();
        ep.loadFavorites();
        ep.loadAddresses();
        ep.loadPaymentCards();
        ep.loadMyReviews();
        ep.loadActivePromos();
      }
    });
  }

  void _navigateToTag(String tag) {
    setState(() {
      _initialCategoryTag = tag;
      _currentNav = 1;
    });
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _loadingSale = true;
      _loadingNew = true;
    });

    // Tải sản phẩm SALE từ database
    try {
      final sale = await ApiService.getProductsByTag('SALE');
      for (var p in sale) {
        debugPrint('SALE Product: ${p['productName']}, Thumbnail path in Postgres: "${p['thumbnail']}"');
      }
      if (mounted) {
        setState(() {
          _saleProducts = sale;
          _loadingSale = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading SALE products: $e');
      if (mounted) setState(() => _loadingSale = false);
    }

    // Tải sản phẩm NEW từ database
    try {
      final newItems = await ApiService.getProductsByTag('NEW');
      for (var p in newItems) {
        debugPrint('NEW Product: ${p['productName']}, Thumbnail path in Postgres: "${p['thumbnail']}"');
      }
      if (mounted) {
        setState(() {
          _newProducts = newItems;
          _loadingNew = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading NEW products: $e');
      if (mounted) setState(() => _loadingNew = false);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen2()));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final ecommerce = context.watch<EcommerceProvider>();
    final cartCount = ecommerce.cartCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(user),
      body: Stack(
        children: [
          _buildBody(user),
          if (_currentNav == 0)
            Positioned(
              top: 0,
              right: 12,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white, size: 28),
                  tooltip: 'Search',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNav,
        onTap: (i) {
          setState(() {
            _currentNav = i;
            _initialCategoryTag = null;
          });
          if (i == 2 && context.read<AuthProvider>().isLoggedIn) {
            context.read<EcommerceProvider>().loadCart();
          }
          if (i == 3 && context.read<AuthProvider>().isLoggedIn) {
            context.read<EcommerceProvider>().loadFavorites();
          }
        },
        selectedItemColor: const Color(0xFFE94560),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text(cartCount.toString()),
              isLabelVisible: cartCount > 0,
              backgroundColor: const Color(0xFFE94560),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            activeIcon: Badge(
              label: Text(cartCount.toString()),
              isLabelVisible: cartCount > 0,
              backgroundColor: const Color(0xFFE94560),
              child: const Icon(Icons.shopping_bag),
            ),
            label: 'Bag',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar(Map<String, dynamic>? user) {
    if (_currentNav == 0 || _currentNav == 1 || _currentNav == 3) {
      return null;
    }
    if (_currentNav == 4) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black, size: 26),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      );
    }
    String titleText = 'CT1 Shop';
    if (_currentNav == 2) titleText = 'My Bag';
    if (_currentNav == 3) titleText = 'My Favorites';

    return AppBar(
      backgroundColor: const Color(0xFF1A1A2E),
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titleText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          if (user != null && _currentNav == 0)
            Text(
              'Xin chào, ${user['fullName'] ?? ''}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          tooltip: 'Search',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(Map<String, dynamic>? user) {
    switch (_currentNav) {
      case 0:
        return _buildHome();
      case 1:
        return CategoriesScreen(initialTag: _initialCategoryTag);
      case 2:
        return _buildBag();
      case 3:
        return const FavoritesScreen();
      case 4:
        return _buildProfile(user);
      default:
        return _buildHome();
    }
  }

  Widget _buildHome() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Carousel Banner (auto-sliding with check buttons) ──
          _buildCarouselBanner(),
          const SizedBox(height: 24),

          // ── Sale Section ──
          _buildProductListSection(
            title: 'Sale',
            subtitle: 'Super summer sale',
            products: _saleProducts,
            isLoading: _loadingSale,
            isSale: true,
          ),
          const SizedBox(height: 24),

          // ── New Section ──
          _buildProductListSection(
            title: 'New',
            subtitle: 'You\'ve never seen it before!',
            products: _newProducts,
            isLoading: _loadingNew,
            isSale: false,
          ),
          const SizedBox(height: 24),

          // ── Collection Grid (Main 3 layout) ──
          _buildMain3Grid(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCarouselBanner() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 380,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        viewportFraction: 1.0,
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
      ),
      items: _bannerItems.map((item) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(item['image']!),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.65),
                    ],
                  ),
                ),
                padding: const EdgeInsets.only(left: 18, bottom: 28, right: 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 130,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {
                          final title = item['title']?.toLowerCase() ?? '';
                          if (title.contains('sale')) {
                            _navigateToTag('SALE');
                          } else if (title.contains('new')) {
                            _navigateToTag('NEW');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE94560),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFFE94560).withOpacity(0.4),
                        ),
                        child: const Text(
                          'Check',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildMain3Grid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner 1: New Collection
        GestureDetector(
          onTap: () => _navigateToTag('NEW'),
          child: Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: const DecorationImage(
                image: AssetImage('assets/images/setjean.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(24),
              alignment: Alignment.centerLeft,
              child: const Text(
                'New collection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Split Grid (Left: Summer Sale & Black, Right: Men's Hoodies)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column
              Expanded(
                child: Column(
                  children: [
                    // Summer Sale Card
                    GestureDetector(
                      onTap: () => _navigateToTag('SALE'),
                      child: Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Summer\nsale',
                          style: TextStyle(
                            color: Color(0xFFE94560),
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Black Card
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/den.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.65),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.bottomLeft,
                        child: const Text(
                          'Black',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Right Column
              Expanded(
                child: Container(
                  height: 322, // 110 + 12 + 200
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/vangto.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Men\'s\nhoodies',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductListSection({
    required String title,
    required String subtitle,
    required List<dynamic> products,
    required bool isLoading,
    required bool isSale,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _initialCategoryTag = isSale ? 'SALE' : 'NEW';
                    _currentNav = 1;
                  });
                },
                child: const Text(
                  'View all',
                  style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 290,
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
              : products.isEmpty
                  ? const Center(
                      child: Text(
                        'Chưa có sản phẩm',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return _productCardHorizontal(products[index], isSale);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _productCardHorizontal(Map<String, dynamic> product, bool isSale) {
    final double salePrice = (product['salePrice'] as num?)?.toDouble() ?? 0.0;
    final double? comparePrice = (product['comparePrice'] as num?)?.toDouble();

    int discountPercent = 0;
    if (isSale && comparePrice != null && comparePrice > salePrice) {
      discountPercent = (((comparePrice - salePrice) / comparePrice) * 100).round();
    }

    final String? thumbnail = product['thumbnail'];
    final String name = product['productName'] ?? '';
    final String type = product['productType'] ?? 'Dress';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
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
                child: isSale && discountPercent > 0
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
                    : (!isSale
                        ? Container(
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
                          )
                        : const SizedBox.shrink()),
              ),
              // Favorite circular icon floating at the bottom right
              Positioned(
                bottom: -15,
                right: 0,
                child: Consumer<EcommerceProvider>(
                  builder: (context, ecommerce, child) {
                    final isFav = ecommerce.isFavorite(product['id']?.toString() ?? '');
                    return GestureDetector(
                      onTap: () {
                        if (context.read<AuthProvider>().isLoggedIn) {
                          ecommerce.toggleFavorite(product);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(duration: const Duration(seconds: 3), content: Text('Vui lòng đăng nhập để lưu yêu thích')),
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
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? const Color(0xFFE94560) : Colors.grey,
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

          // Sub-description (product type / brand)
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
              fontSize: 15,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Price section
          Row(
            children: [
              if (isSale && comparePrice != null) ...[
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

  Widget _buildProductImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const Center(child: Icon(Icons.image_outlined, size: 48, color: Colors.grey));
    }
    
    // Trim spaces and normalize
    String cleanPath = imagePath.trim();
    
    // Check if Postgres database stores standard web URL
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return Image.network(
        cleanPath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading network image: "$cleanPath", Error: $error');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey),
                const SizedBox(height: 4),
                const Text('Network Err', style: TextStyle(fontSize: 8, color: Colors.grey)),
              ],
            ),
          );
        },
      );
    } else {
      // Clean leading slashes for local assets
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }
      if (cleanPath.startsWith('\\')) {
        cleanPath = cleanPath.substring(1);
      }
      
      // If it is just a filename, prepend assets folder
      if (!cleanPath.contains('assets/')) {
        cleanPath = 'assets/images/$cleanPath';
      }
      
      return Image.asset(
        cleanPath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading asset image: "$cleanPath", Error: $error');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey),
                const SizedBox(height: 4),
                Text(cleanPath.split('/').last, style: const TextStyle(fontSize: 8, color: Colors.grey)),
              ],
            ),
          );
        },
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
    
    // Nếu giá trị nhỏ hơn 1000 (như hạt mầm SQL là 12.00, 15.00 đô la), hiển thị dạng USD ($)
    if (val < 1000) {
      return '${val.toStringAsFixed(0)}\$';
    }
    
    // Ngược lại hiển thị chuẩn tiền Việt VND (đ)
    final int intVal = val.round();
    final formatted = intVal.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$formattedđ';
  }

  Widget _buildAvatarImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const CircleAvatar(
        radius: 36,
        backgroundImage: AssetImage('assets/images/avata1.png'),
        backgroundColor: Colors.transparent,
      );
    }

    String cleanPath = imagePath.trim();
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return CircleAvatar(
        radius: 36,
        backgroundImage: NetworkImage(cleanPath, headers: const {'ngrok-skip-browser-warning': 'true'}),
        backgroundColor: Colors.grey[200],
      );
    } else if (cleanPath.startsWith('/uploads/') || cleanPath.contains('/uploads/')) {
      final fullUrl = ApiService.getFullImageUrl(cleanPath);
      return CircleAvatar(
        radius: 36,
        backgroundImage: NetworkImage(fullUrl, headers: const {'ngrok-skip-browser-warning': 'true'}),
        backgroundColor: Colors.grey[200],
      );
    } else {
      if (!cleanPath.contains('assets/')) {
        cleanPath = 'assets/images/$cleanPath';
      }
      return CircleAvatar(
        radius: 36,
        backgroundImage: AssetImage(cleanPath),
        backgroundColor: Colors.grey[200],
      );
    }
  }

  bool _isAvatarUploading = false;

  Future<void> _changeAvatar() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (pickerContext) {
        final picker = ImagePicker();
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Color(0xFFFF3B30)),
                title: const Text('Chụp ảnh mới (Take Photo)'),
                onTap: () async {
                  Navigator.of(pickerContext).pop();
                  final XFile? photo = await picker.pickImage(source: ImageSource.camera);
                  if (photo != null) {
                    _uploadAvatar(photo);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFFFF3B30)),
                title: const Text('Chọn ảnh từ thư viện (Upload Image)'),
                onTap: () async {
                  Navigator.of(pickerContext).pop();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    _uploadAvatar(image);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadAvatar(XFile file) async {
    try {
      setState(() {
        _isAvatarUploading = true;
      });

      // Show temporary loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF3B30)),
        ),
      );

      final bytes = await file.readAsBytes();
      final String uploadedUrl = await ApiService.uploadReviewFile(bytes, file.name);

      if (mounted) {
        // Pop the loading dialog
        Navigator.of(context).pop();

        final success = await context.read<AuthProvider>().updateSettings(avatarUrl: uploadedUrl);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật avatar thành công!'), backgroundColor: Colors.green),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi đồng bộ avatar với database'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Try to pop the loading dialog if it is showing
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải avatar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAvatarUploading = false;
        });
      }
    }
  }

  Widget _buildProfile(Map<String, dynamic>? user) {
    final String name = user?['fullName'] ?? 'Guest User';
    final String email = user?['email'] ?? 'guest@example.com';
    final ecommerce = context.watch<EcommerceProvider>();

    final int addrCount = ecommerce.addresses.length;
    final String addrSub = addrCount == 1 ? '1 address' : '$addrCount addresses';

    String cardSub = 'No payment cards';
    if (ecommerce.paymentCards.isNotEmpty) {
      final defaultCard = ecommerce.defaultCard;
      if (defaultCard != null) {
        final brand = defaultCard['brand'] ?? 'Card';
        final masked = defaultCard['maskedNumber'] ?? '';
        final last4 = masked.length >= 4 ? masked.substring(masked.length - 4) : '';
        cardSub = '$brand **$last4';
      } else {
        final firstCard = ecommerce.paymentCards.first;
        final brand = firstCard['brand'] ?? 'Card';
        final masked = firstCard['maskedNumber'] ?? '';
        final last4 = masked.length >= 4 ? masked.substring(masked.length - 4) : '';
        cardSub = '$brand **$last4';
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My profile',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          // User profile card
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  final auth = context.read<AuthProvider>();
                  if (auth.isLoggedIn) {
                    _changeAvatar();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng đăng nhập để thay đổi avatar!')),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFF3B30), width: 1.5),
                  ),
                  child: _buildAvatarImage(user?['avatarUrl']?.toString()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 28),

          // Menu sections
          _buildProfileMenuItem(
            title: 'My Orders',
            subtitle: 'Already have 12 orders',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
              );
            },
          ),
          const Divider(height: 1, color: Colors.black12),
          _buildProfileMenuItem(
            title: 'Shipping addresses',
            subtitle: addrSub,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShippingAddressesScreen()),
              );
            },
          ),
          const Divider(height: 1, color: Colors.black12),
          _buildProfileMenuItem(
            title: 'Payment methods',
            subtitle: cardSub,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
              );
            },
          ),
          const Divider(height: 1, color: Colors.black12),
          _buildProfileMenuItem(
            title: 'Promocodes',
            subtitle: 'You have special promocodes',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PromocodesScreen()),
              );
            },
          ),
          const Divider(height: 1, color: Colors.black12),
          _buildProfileMenuItem(
            title: 'My reviews',
            subtitle: 'Reviews for ${ecommerce.myReviews.length} items',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
              );
            },
          ),
          const Divider(height: 1, color: Colors.black12),
          _buildProfileMenuItem(
            title: 'Settings',
            subtitle: 'Notifications, password',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 36),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.white, size: 20),
              label: const Text(
                'LOG OUT',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
          ),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildBag() {
    final ecommerce = context.watch<EcommerceProvider>();
    final cartItems = ecommerce.cartItems;
    final double subtotal = ecommerce.cartSubtotal;
    final promo = ecommerce.activePromo;
    double discount = 0;
    if (promo != null) {
      final percent = (promo['discountPercent'] as num?)?.toDouble() ?? 0.0;
      discount = subtotal * percent / 100.0;
    }
    final total = subtotal - discount;

    if (cartItems.isEmpty) {
      return Center(
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
                Icons.shopping_bag_outlined,
                size: 64,
                color: Color(0xFFE94560),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Bag is Empty',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Go back to shop and add items to your bag!',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index];
              return Container(
                height: 110,
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
                child: Row(
                  children: [
                    // Product image
                    Container(
                      width: 100,
                      height: 110,
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
                        child: GestureDetector(
                          onTap: () {
                            final Map<String, dynamic> productMap = {
                              'id': item.productId,
                              'productName': item.productName,
                              'thumbnail': item.thumbnail,
                              'salePrice': item.price,
                            };
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(product: productMap),
                              ),
                            );
                          },
                          child: _buildProductImage(item.thumbnail),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Item details
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          final Map<String, dynamic> productMap = {
                                            'id': item.productId,
                                            'productName': item.productName,
                                            'thumbnail': item.thumbnail,
                                            'salePrice': item.price,
                                          };
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ProductDetailScreen(product: productMap),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          item.productName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onSelected: (value) {
                                        if (value == 'fav') {
                                          final Map<String, dynamic> productMap = {
                                            'id': item.productId,
                                            'productName': item.productName,
                                            'thumbnail': item.thumbnail,
                                            'salePrice': item.price,
                                          };
                                          ecommerce.toggleFavorite(productMap);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Đã cập nhật yêu thích!'),
                                              duration: Duration(seconds: 3),
                                            ),
                                          );
                                        } else if (value == 'delete') {
                                          ecommerce.removeFromCart(index);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'fav',
                                          child: Text('Add to favorites', style: TextStyle(fontSize: 13)),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete from the list', style: TextStyle(fontSize: 13)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Size: ${item.size}  Color: ${item.color}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ),
                            // Price and Quantity controls
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        ecommerce.updateQuantity(index, item.quantity - 1);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.remove, size: 14, color: Colors.black54),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        item.quantity.toString(),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        ecommerce.updateQuantity(index, item.quantity + 1);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add, size: 14, color: Colors.black54),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Text(
                                    _formatPrice(item.price * item.quantity),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFFE94560),
                                    ),
                                  ),
                                ),
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
          ),
        ),
        
        // Checkout summary panel
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, -4),
              )
            ],
          ),
          child: Column(
            children: [
              // Promo Code Input Box
              if (ecommerce.activePromo == null)
                GestureDetector(
                  onTap: () => _showPromoBottomSheet(context, ecommerce),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Enter your promo code',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        ),
                        Container(
                          height: 36,
                          width: 36,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ecommerce.activePromo!['code'] ?? '',
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          ecommerce.removePromoCode();
                        },
                        child: const Icon(Icons.close, color: Colors.grey, size: 20),
                      ),
                    ],
                  ),
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total amount:',
                    style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    _formatPrice(total),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CheckoutScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94560),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'CHECK OUT',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPromoBottomSheet(BuildContext context, EcommerceProvider ecommerce) {
    ecommerce.loadActivePromos();
    final TextEditingController sheetPromoCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 60,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Text input for promo
                  TextField(
                    controller: sheetPromoCtrl,
                    decoration: InputDecoration(
                      hintText: 'Enter your promo code',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      suffixIcon: GestureDetector(
                        onTap: () async {
                          final code = sheetPromoCtrl.text.trim();
                          if (code.isNotEmpty) {
                            try {
                              final success = await ecommerce.applyPromoCode(code);
                              if (success && context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Áp dụng mã giảm giá thành công!'),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Mã giảm giá không hợp lệ: $e'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Your Promo Codes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Promos list
                  Consumer<EcommerceProvider>(
                    builder: (context, provider, child) {
                      final promos = provider.activePromosList.isNotEmpty
                          ? provider.activePromosList
                          : [
                              {
                                'code': 'mypromocode2020',
                                'discountPercent': 10,
                                'description': 'Personal offer',
                                'daysRemaining': 6
                              },
                              {
                                'code': 'summer2020',
                                'discountPercent': 15,
                                'description': 'Summer Sale',
                                'daysRemaining': 23
                              },
                              {
                                'code': 'personal2020',
                                'discountPercent': 22,
                                'description': 'Personal offer',
                                'daysRemaining': 6
                              },
                            ];

                      return Column(
                        children: promos.map<Widget>((promo) {
                          final int pct = (promo['discountPercent'] as num?)?.toInt() ?? 0;
                          final String code = promo['code'] ?? '';
                          final String desc = promo['description'] ?? '';
                          final int days = (promo['daysRemaining'] as num?)?.toInt() ?? (promo['days_remaining'] as num?)?.toInt() ?? 0;
                          
                          // Determine color/design based on pct
                          Color badgeColor = const Color(0xFFFF3B30); // Default red
                          if (pct == 15) {
                            badgeColor = const Color(0xFFFF9500); // Orange / beachy vibe
                          } else if (pct == 22) {
                            badgeColor = const Color(0xFF1A1A2E); // Black/Navy
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            height: 80,
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
                            child: Row(
                              children: [
                                // Left badge
                                Container(
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      bottomLeft: Radius.circular(8),
                                    ),
                                  ),
                                  child: Center(
                                    child: RichText(
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '$pct',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const TextSpan(
                                            text: '%\noff',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              height: 1.1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        desc,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        code,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$days days remaining',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Apply button
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF3B30),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      minimumSize: const Size(64, 30),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    onPressed: () async {
                                      try {
                                        final success = await ecommerce.applyPromoCode(code);
                                        if (success && context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Áp dụng mã giảm giá thành công!'),
                                              duration: Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Lỗi: $e'),
                                              backgroundColor: Colors.red,
                                              duration: const Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text(
                                      'Apply',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
