import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../services/ecommerce_provider.dart';
import 'categories_screen.dart';
import 'login_screen2.dart';
import 'product_detail_screen.dart';
import 'favorites_screen.dart';

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
        context.read<EcommerceProvider>().loadCart();
        context.read<EcommerceProvider>().loadFavorites();
      }
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
      body: _buildBody(user),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNav,
        onTap: (i) {
          setState(() => _currentNav = i);
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
    if (_currentNav == 1 || _currentNav == 3) {
      return null;
    }
    if (_currentNav == 4) {
      return AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('My Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
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
    );
  }

  Widget _buildBody(Map<String, dynamic>? user) {
    switch (_currentNav) {
      case 0:
        return _buildHome();
      case 1:
        return const CategoriesScreen();
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
                        onPressed: () {},
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
        Container(
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
                    Container(
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
                onTap: () {},
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
                height: 180,
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
                            const SnackBar(content: Text('Vui lòng đăng nhập để lưu yêu thích')),
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

  Widget _buildProfile(Map<String, dynamic>? user) {
    final String name = user?['fullName'] ?? 'Guest User';
    final String email = user?['email'] ?? 'guest@example.com';
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User profile card
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE94560), width: 2),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: const AssetImage('assets/images/avata1.png'),
                  backgroundColor: Colors.grey[200],
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
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 32),

          // Menu sections
          _buildProfileMenuItem(
            title: 'My Orders',
            subtitle: 'Already have 12 orders',
            onTap: () {},
          ),
          const Divider(height: 1, color: Colors.black12),
          _buildProfileMenuItem(
            title: 'Shipping addresses',
            subtitle: '3 addresses',
            onTap: () {},
          ),
          const Divider(height: 1, color: Colors.black12),
          _buildProfileMenuItem(
            title: 'Payment methods',
            subtitle: 'Visa  **34',
            onTap: () {},
          ),
          const Divider(height: 1, color: Colors.black12),
          _buildProfileMenuItem(
            title: 'Settings',
            subtitle: 'Notifications, password',
            onTap: () {},
          ),
          const SizedBox(height: 48),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'LOG OUT',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                elevation: 2,
                shadowColor: const Color(0xFFE94560).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                        child: _buildProductImage(item.thumbnail),
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
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                                      onPressed: () {
                                        ecommerce.removeFromCart(index);
                                      },
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total amount:',
                    style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    _formatPrice(subtotal),
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
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Checkout Success'),
                          content: const Text('Thank you for your order! Your purchase was processed successfully.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                ecommerce.clearCart();
                              },
                              child: const Text('Great!', style: TextStyle(color: Color(0xFFE94560))),
                            )
                          ],
                        );
                      },
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
}
