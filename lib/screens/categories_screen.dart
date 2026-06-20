import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/ecommerce_provider.dart';
import '../services/auth_provider.dart';
import 'product_detail_screen.dart';
import 'filter_screen.dart';
import 'search_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final String? initialTag;
  const CategoriesScreen({super.key, this.initialTag});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  List<dynamic> _rootCategories = [];   // Women / Men / Kids
  List<dynamic> _allCategories = [];    // All categories
  bool _loading = true;

  // Navigation flow states
  int _currentDepth = 0; // 0: Main Categories, 1: Subcategories List, 2: Products List
  Map<String, dynamic>? _selectedRootCategory;
  Map<String, dynamic>? _selectedCategory; // Clothes / Shoes / Accessories / New
  Map<String, dynamic>? _selectedSubCategory; // Tops / Pants / etc.
  List<dynamic> _products = [];
  bool _loadingProducts = false;

  // Catalog state variables
  bool _isListView = true;
  String _currentSort = 'lowest_to_high';
  String _selectedChip = 'All';

  Map<String, dynamic> _activeFilter = {
    'minPrice': 0.0,
    'maxPrice': 300.0,
    'selectedColors': <String>[],
    'selectedSizes': <String>[],
    'selectedCategory': 'All',
    'selectedBrands': <String>[],
  };

  String _getCategoryAssetPath(String title) {
    if (_selectedRootCategory == null) {
      if (title == 'New') return 'assets/images/jean.png';
      if (title == 'Clothes') return 'assets/images/trangjean.png';
      if (title == 'Shoes') return 'assets/images/giay.png';
      return 'assets/images/vong.png';
    }
    final rootName = (_selectedRootCategory!['categoryName'] ?? '').toLowerCase();
    if (rootName.contains('women')) {
      if (title == 'New') return 'assets/images/jean.png';
      if (title == 'Clothes') return 'assets/images/trangjean.png';
      if (title == 'Shoes') return 'assets/images/giay.png';
      return 'assets/images/vong.png';
    } else if (rootName.contains('men')) {
      if (title == 'New') return 'assets/images/men1.png';
      if (title == 'Clothes') return 'assets/images/men2.png';
      if (title == 'Shoes') return 'assets/images/men3.png';
      return 'assets/images/men4.png';
    } else if (rootName.contains('kids') || rootName.contains('kid')) {
      if (title == 'New') return 'assets/images/kid1.png';
      if (title == 'Clothes') return 'assets/images/kid2.png';
      if (title == 'Shoes') return 'assets/images/kid3.png';
      return 'assets/images/kid4.png';
    }
    if (title == 'New') return 'assets/images/jean.png';
    if (title == 'Clothes') return 'assets/images/trangjean.png';
    if (title == 'Shoes') return 'assets/images/giay.png';
    return 'assets/images/vong.png';
  }

  String _getProductGender(Map<String, dynamic> product) {
    final name = (product['productName'] as String? ?? '').toLowerCase();
    final pid = (product['id'] as String? ?? '').toLowerCase();
    final sku = (product['sku'] as String? ?? '').toUpperCase();

    if (name.contains('women')) {
      return 'women';
    } else if (name.contains('kids') || name.contains('kid')) {
      return 'kids';
    } else if (name.contains('men') || name.contains("men's")) {
      return 'men';
    }

    if (pid.startsWith('a0')) {
      return 'women';
    } else if (pid.startsWith('a3')) {
      return 'kids';
    } else if (pid.startsWith('a4')) {
      if (sku.contains('KID')) {
        return 'kids';
      } else if (sku.contains('MEN')) {
        return 'men';
      } else if (sku.contains('WMN') || sku.contains('WOM')) {
        return 'women';
      }
    }
    return 'women'; // Fallback
  }

  bool _isProductInRootCategory(Map<String, dynamic> product, String rootId) {
    if (_selectedRootCategory == null) return true;
    final rootName = (_selectedRootCategory!['categoryName'] ?? '').toString().toLowerCase();
    final gender = _getProductGender(product);
    
    if (rootName.contains('women')) {
      return gender == 'women';
    } else if (rootName.contains('men')) {
      return gender == 'men';
    } else if (rootName.contains('kid') || rootName.contains('kids')) {
      return gender == 'kids';
    }
    return true;
  }

  Map<String, dynamic> _enrichProduct(Map<String, dynamic> prod) {
    final name = (prod['productName'] as String? ?? '').toLowerCase();

    // Map unique Brand based on names/ids
    String brand = 'adidas';
    if (name.contains('crop')) {
      brand = 'Blend';
    } else if (name.contains('lace') || name.contains('crochet')) {
      brand = 'Boutique Moschino';
    } else if (name.contains('shoulder') || name.contains('knit')) {
      brand = 'Red Valentino';
    } else if (name.contains('camisole') || name.contains('linen cami') || name.contains('linen camisole')) {
      brand = 's.Oliver';
    } else if (name.contains('ruffle') || name.contains('bèo')) {
      brand = 'Naf Naf';
    } else if (name.contains('satin') || name.contains('cowl')) {
      brand = 'Diesel';
    } else if (name.contains('mock') || name.contains('lọ')) {
      brand = 'Champion';
    } else if (name.contains('floral') || name.contains('voan')) {
      brand = 'Jack & Jones';
    } else if (name.contains('puff') || name.contains('phồng')) {
      brand = 'adidas Originals';
    } else if (name.contains('evening') || name.contains('dress')) {
      brand = 'Dorothy Perkins';
    } else if (name.contains('sport') && name.contains('dress')) {
      brand = 'Mango';
    } else if (name.contains('stripe')) {
      brand = 'adidas';
    } else if (name.contains('classic')) {
      brand = 'Mango';
    } else if (name.contains('sport') && name.contains('shirt')) {
      brand = 'Dorothy Perkins';
    } else if (name.contains('linen t-shirt')) {
      brand = 'Blend';
    }

    // Map unique colors list
    List<String> colors = ['White', 'Black'];
    if (name.contains('evening') || name.contains('hong.png')) {
      colors = ['Red', 'White', 'Black', 'Taupe'];
    } else if (name.contains('sport dress') || name.contains('xam.png')) {
      colors = ['Navy', 'White', 'Black', 'Beige'];
    } else if (name.contains('stripe') || name.contains('do.png')) {
      colors = ['Red', 'White', 'Black'];
    } else if (name.contains('classic shirt') || name.contains('trangjean.png')) {
      colors = ['White', 'Navy'];
    } else if (name.contains('crop') || name.contains('basic')) {
      colors = ['Beige', 'White', 'Black'];
    } else if (name.contains('lace') || name.contains('crochet')) {
      colors = ['White', 'Taupe'];
    } else if (name.contains('cowl') || name.contains('satin')) {
      colors = ['Black', 'Navy', 'Red'];
    } else if (name.contains('floral') || name.contains('voan')) {
      colors = ['Taupe', 'Beige', 'Red'];
    }

    // Map sizes
    List<String> sizes = ['XS', 'S', 'M', 'L', 'XL'];
    if (name.contains('crop') || name.contains('satin')) {
      sizes = ['S', 'M', 'L'];
    } else if (name.contains('crochet') || name.contains('evening')) {
      sizes = ['XS', 'S', 'M', 'L'];
    }

    return {
      ...prod,
      'brand': brand,
      'colors': colors,
      'sizes': sizes,
    };
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final roots = await ApiService.getRootCategories();
      final all = await ApiService.getAllCategories();
      
      // Sort roots: Women, Men, Kids
      roots.sort((a, b) {
        final aName = (a['categoryName'] as String).toLowerCase();
        final bName = (b['categoryName'] as String).toLowerCase();
        if (aName.contains('women')) return -1;
        if (bName.contains('women')) return 1;
        if (aName.contains('men') && !aName.contains('women')) return -1;
        if (bName.contains('men') && !bName.contains('women')) return 1;
        return 0;
      });

      if (mounted) {
        setState(() {
          _rootCategories = roots;
          _allCategories = all;
          _selectedRootCategory = roots.isNotEmpty ? roots[0] : null;
          
          _tabController = TabController(length: roots.length, vsync: this);
          _tabController!.addListener(() {
            if (!_tabController!.indexIsChanging) {
              setState(() {
                _selectedRootCategory = _rootCategories[_tabController!.index];
                _currentDepth = 0; // Reset depth when changing tabs
                _selectedChip = 'All';
              });
            }
          });
          
          _loading = false;
        });
        
        if (widget.initialTag != null) {
          _applyInitialTag();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void didUpdateWidget(covariant CategoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTag != oldWidget.initialTag && widget.initialTag != null) {
      _applyInitialTag();
    }
  }

  void _applyInitialTag() {
    final tag = widget.initialTag!;
    setState(() {
      _selectedCategory = {'categoryName': tag, 'id': '${tag.toLowerCase()}_tag_bypass'};
      _selectedSubCategory = null;
      _currentDepth = 2;
    });
    _loadTaggedProducts(tag);
  }

  void _selectTag(String tag) {
    setState(() {
      _selectedCategory = {'categoryName': tag, 'id': '${tag.toLowerCase()}_tag_bypass'};
      _selectedSubCategory = null;
      _currentDepth = 2;
    });
    _loadTaggedProducts(tag);
  }

  Future<void> _loadTaggedProducts(String tag) async {
    setState(() {
      _loadingProducts = true;
      _products = [];
    });

    try {
      final items = await ApiService.getProductsByTag(tag);
      final rootId = _selectedRootCategory?['id'];
      final filtered = items.where((p) {
        if (rootId == null) return true;
        return _isProductInRootCategory(p, rootId);
      }).toList();
      final enriched = filtered.map((e) => _enrichProduct(Map<String, dynamic>.from(e))).toList();
      if (mounted) {
        setState(() {
          _products = enriched;
          _loadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingProducts = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadProducts(String categoryId) async {
    setState(() {
      _loadingProducts = true;
      _products = [];
    });

    try {
      List<dynamic> items;
      final isClothesParent = categoryId == 'c0000000-0000-0000-0000-000000000010' ||
                             categoryId == 'c0000000-0000-0000-0000-000000000011' ||
                             categoryId == 'c0000000-0000-0000-0000-000000000013' ||
                             categoryId == 'c0000000-0000-0000-0000-000000000012';

      if (categoryId.contains('_mock') || isClothesParent) {
        final rootId = _selectedRootCategory?['id'];
        final allProducts = await ApiService.getPublishedProducts();
        
        List<dynamic> filteredByRoot = allProducts;
        if (rootId != null) {
          filteredByRoot = allProducts.where((p) => _isProductInRootCategory(p, rootId)).toList();
        }

        if (_selectedSubCategory != null) {
          final String subName = (_selectedSubCategory!['categoryName'] ?? '').toLowerCase();
          items = filteredByRoot.where((p) {
            final name = (p['productName'] as String? ?? '').toLowerCase();
            final type = (p['productType'] as String? ?? '').toLowerCase();
            
            if (subName == 'tops') {
              return name.contains('top') || type.contains('top');
            }
            String searchKeyword = subName;
            if (searchKeyword.endsWith('s') && searchKeyword.length > 3) {
              searchKeyword = searchKeyword.substring(0, searchKeyword.length - 1);
            }
            return name.contains(searchKeyword) ||
                   type.contains(searchKeyword) ||
                   name.contains(subName) ||
                   type.contains(subName);
          }).toList();
        } else {
          // "VIEW ALL ITEMS" fallback for parent category
          final String catName = (_selectedCategory?['categoryName'] ?? '').toLowerCase();
          if (catName.contains('shoes') || catName.contains('shoe')) {
            items = filteredByRoot.where((p) {
              final name = (p['productName'] as String? ?? '').toLowerCase();
              final type = (p['productType'] as String? ?? '').toLowerCase();
              final keywords = [
                'shoe', 'heel', 'sandal', 'boot', 'sneaker', 'clog', 'giay',
                'oxford', 'derby', 'loafer', 'trainer', 'tennis', 'running shoe',
                'slip-on', 'slipper', 'canvas shoe', 'school shoe', 'sport shoe',
                'mary jane', 'wedge', 'espadrille', 'platform'
              ];
              return keywords.any((k) => name.contains(k) || type.contains(k));
            }).toList();
          } else if (catName.contains('accessories') || catName.contains('accessory')) {
            items = filteredByRoot.where((p) {
              final name = (p['productName'] as String? ?? '').toLowerCase();
              final type = (p['productType'] as String? ?? '').toLowerCase();
              final keywords = [
                'necklace', 'choker', 'earring', 'ring', 'bracelet', 'watch', 
                'bag', 'wallet', 'sunglass', 'brooch', 'clutch', 'keychain', 'vong',
                'belt', 'cufflink', 'tie clip', 'scarf', 'backpack', 'crossbody',
                'messenger', 'cap', 'hat', 'hair clip', 'glove'
              ];
              return keywords.any((k) => name.contains(k) || type.contains(k));
            }).toList();
          } else {
            // For Clothes parent category, filter out shoes and accessories!
            items = filteredByRoot.where((p) {
              final name = (p['productName'] as String? ?? '').toLowerCase();
              final type = (p['productType'] as String? ?? '').toLowerCase();
              
              final isShoe = name.contains('shoe') || name.contains('heel') || name.contains('sandal') || name.contains('boot') || name.contains('sneaker') || name.contains('clog') || type.contains('shoe');
              final isAccessory = name.contains('necklace') || name.contains('choker') || name.contains('earring') || name.contains('ring') || name.contains('bracelet') || name.contains('watch') || name.contains('bag') || name.contains('wallet') || name.contains('sunglass') || name.contains('brooch') || name.contains('clutch') || name.contains('keychain') || name.contains('belt') || name.contains('hair clip') || name.contains('backpack');
              
              return !isShoe && !isAccessory;
            }).toList();
          }
        }
      } else {
        items = await ApiService.getProductsByCategory(categoryId);
      }

      final enriched = items.map((e) => _enrichProduct(Map<String, dynamic>.from(e))).toList();
      if (mounted) {
        setState(() {
          _products = enriched;
          _loadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingProducts = false;
        });
      }
    }
  }

  Future<void> _loadNewProducts(String rootCategoryName) async {
    setState(() {
      _loadingProducts = true;
      _products = [];
    });

    try {
      final items = await ApiService.getProductsByTag('NEW');
      final rootId = _selectedRootCategory?['id'];
      final filtered = items.where((p) {
        if (rootId == null) return false;
        return _isProductInRootCategory(p, rootId);
      }).toList();
      final enriched = filtered.map((e) => _enrichProduct(Map<String, dynamic>.from(e))).toList();

      if (mounted) {
        setState(() {
          _products = enriched;
          _loadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingProducts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Categories', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFE94560))),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_currentDepth > 0) {
          setState(() {
            if (_selectedCategory != null && _selectedCategory!['id']?.toString().endsWith('_tag_bypass') == true) {
              _currentDepth = 0;
              _selectedCategory = null;
            } else {
              _currentDepth--;
            }
            if (_currentDepth < 2) {
              _selectedChip = 'All';
            }
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    String titleText = 'Categories';
    if (_currentDepth == 1 && _selectedCategory != null) {
      titleText = _selectedCategory!['categoryName'] ?? 'Categories';
    } else if (_currentDepth == 2) {
      titleText = ''; // Empty title for depth 2 to match mockup (title rendered in body)
    }

    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: _currentDepth == 0 || _currentDepth == 2 ? 0 : 2,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 18),
        onPressed: () {
          if (_currentDepth > 0) {
            setState(() {
              if (_selectedCategory != null && _selectedCategory!['id']?.toString().endsWith('_tag_bypass') == true) {
                _currentDepth = 0;
                _selectedCategory = null;
              } else {
                _currentDepth--;
              }
              if (_currentDepth < 2) {
                _selectedChip = 'All';
              }
            });
          } else {
            // When at depth 0, pressing back goes back to home page tab (index 0) in HomeScreen Scaffold
            // We can find parent state or use a default pop logic. Pop is standard.
            Navigator.of(context).pop();
          }
        },
      ),
      title: Text(
        titleText,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black87),
          tooltip: 'Search',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
        )
      ],
    );
  }

  Widget _buildBody() {
    switch (_currentDepth) {
      case 0:
        return _buildMainCategoriesView();
      case 1:
        return _buildSubCategoriesListView();
      case 2:
        return _buildCategoryProductsGridView();
      default:
        return _buildMainCategoriesView();
    }
  }

  // --- Depth 0: Tab layout with main horizontal cards (New, Clothes, Shoes, Accessories) ---
  Widget _buildMainCategoriesView() {
    if (_tabController == null || _selectedRootCategory == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Tab bar Women / Men / Kids
        Container(
          color: Colors.white,
          width: double.infinity,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.black87,
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFE94560),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: const TextStyle(fontSize: 15),
            tabs: _rootCategories.map((c) => Tab(text: c['categoryName'])).toList(),
          ),
        ),
        
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Red Banner: SUMMER SALES
                GestureDetector(
                  onTap: () => _selectTag('SALE'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE94560),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE94560).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Column(
                      children: const [
                        Text(
                          'SUMMER SALES',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Up to 50% off',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Main division cards: New, Clothes, Shoes, Accessories
                _buildRootDivisionCard(
                  title: 'New',
                  assetPath: _getCategoryAssetPath('New'),
                  onTap: () {
                    setState(() {
                      _selectedCategory = {'categoryName': 'New', 'id': 'new_tag_bypass'};
                      _selectedSubCategory = null;
                      _currentDepth = 2;
                    });
                    _loadNewProducts(_selectedRootCategory!['categoryName']);
                  },
                ),
                
                _buildRootCategoryCard(
                  title: 'Clothes',
                  assetPath: _getCategoryAssetPath('Clothes'),
                ),
                
                _buildRootCategoryCard(
                  title: 'Shoes',
                  assetPath: _getCategoryAssetPath('Shoes'),
                ),
                
                _buildRootCategoryCard(
                  title: 'Accessories',
                  assetPath: _getCategoryAssetPath('Accessories'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRootDivisionCard({
    required String title,
    required String assetPath,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    height: 100,
                    alignment: Alignment.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRootCategoryCard({
    required String title,
    required String assetPath,
  }) {
    // Find category dynamically
    final rootId = _selectedRootCategory!['id'];
    var category = _allCategories.firstWhere(
      (c) => c['parentId'] == rootId && (c['categoryName'] as String).toLowerCase() == title.toLowerCase(),
      orElse: () => null,
    );

    category ??= {
      'id': '${rootId}_${title.toLowerCase()}_mock',
      'parentId': rootId,
      'categoryName': title,
      'categoryDescription': '$title category',
      'active': true,
    };

    return _buildRootDivisionCard(
      title: title,
      assetPath: assetPath,
      onTap: () {
        setState(() {
          _selectedCategory = category;
          _currentDepth = 1;
        });
      },
    );
  }

  // --- Depth 1: Vertical list of subcategories with red VIEW ALL ITEMS button (Categories 2) ---
  Widget _buildSubCategoriesListView() {
    if (_selectedCategory == null) return const SizedBox.shrink();

    // Filter subcategories belonging to selected category
    final parentId = _selectedCategory!['id'];
    final rootName = (_selectedRootCategory?['categoryName'] ?? '').toLowerCase();
    final catName = (_selectedCategory!['categoryName'] ?? '').toLowerCase();

    List<dynamic> subCategories = _allCategories.where((c) => c['parentId'] == parentId).toList();

    // Men: remove Dresses, inject Shoes & Accessories fallbacks
    if (rootName == 'men' || (rootName.contains('men') && !rootName.contains('women'))) {
      subCategories.removeWhere((c) {
        final name = (c['categoryName'] as String? ?? '').toLowerCase();
        return name == 'dresses' || name == 'dress';
      });

      if (catName.contains('shoes')) {
        final List<String> menShoeSubCats = [
          'Tops', 'Sneakers', 'Running Shoes', 'Oxford Shoes', 'Derby Shoes',
          'Sandals', 'Work Boots', 'Tennis Shoes'
        ];
        if (subCategories.isEmpty) {
          subCategories = menShoeSubCats.map((name) => {
            'id': '${parentId}_${name.toLowerCase().replaceAll(' ', '_')}_mock',
            'parentId': parentId,
            'categoryName': name,
            'categoryDescription': "Men's Shoe Subcategory",
            'active': true,
          }).toList();
        }
      } else if (catName.contains('accessories')) {
        final List<String> menAccSubCats = [
          'Tops', 'Watches', 'Necklaces', 'Cufflinks', 'Tie Clips', 'Belts',
          'Wallets', 'Scarves', 'Backpacks', 'Crossbody Bags', 'Messenger Bags',
          'Keychains'
        ];
        if (subCategories.isEmpty) {
          subCategories = menAccSubCats.map((name) => {
            'id': '${parentId}_${name.toLowerCase().replaceAll(' ', '_')}_mock',
            'parentId': parentId,
            'categoryName': name,
            'categoryDescription': "Men's Accessories Subcategory",
            'active': true,
          }).toList();
        }
      }
    }

    // Kids: inject Shoes & Accessories fallbacks
    if (rootName.contains('kid')) {
      if (catName.contains('shoes')) {
        final List<String> kidShoeSubCats = [
          'Tops', 'Sneakers', 'School Shoes', 'Sandals', 'Slip-ons', 'Boots',
          'Trainers', 'Sports Shoes', 'Canvas Shoes', 'Mary Janes', 'Slippers'
        ];
        if (subCategories.isEmpty) {
          subCategories = kidShoeSubCats.map((name) => {
            'id': '${parentId}_${name.toLowerCase().replaceAll(' ', '_')}_mock',
            'parentId': parentId,
            'categoryName': name,
            'categoryDescription': "Kids' Shoe Subcategory",
            'active': true,
          }).toList();
        }
      } else if (catName.contains('accessories')) {
        final List<String> kidAccSubCats = [
          'Tops', 'Caps', 'Hats', 'Backpacks', 'Bags', 'Sunglasses', 'Watches',
          'Hair Clips', 'Scarves', 'Gloves', 'Keychains', 'Necklaces'
        ];
        if (subCategories.isEmpty) {
          subCategories = kidAccSubCats.map((name) => {
            'id': '${parentId}_${name.toLowerCase().replaceAll(' ', '_')}_mock',
            'parentId': parentId,
            'categoryName': name,
            'categoryDescription': "Kids' Accessories Subcategory",
            'active': true,
          }).toList();
        }
      }
    }

    // Women: inject Shoes & Accessories fallbacks
    if (rootName.contains('women')) {
      if (catName.contains('shoes')) {
        final List<String> shoeSubCats = [
          'Tops', 'Heels', 'Sandals', 'Wedges', 'Espadrilles', 'Loafers', 
          'Sneakers', 'Running Shoes', 'Ankle Boots', 'Platform Shoes', 
          'Mary Janes', 'Oxford Shoes', 'Clogs'
        ];
        if (subCategories.isEmpty) {
          subCategories = shoeSubCats.map((name) => {
            'id': '${parentId}_${name.toLowerCase().replaceAll(' ', '_')}_mock',
            'parentId': parentId,
            'categoryName': name,
            'categoryDescription': "Women's Shoe Subcategory",
            'active': true,
          }).toList();
        }
      } else if (catName.contains('accessories')) {
        final List<String> accSubCats = [
          'Tops', 'Necklaces', 'Chokers', 'Earrings', 'Bracelets', 'Rings', 
          'Watches', 'Brooches', 'Sunglasses', 'Handbags', 'Bags', 'Clutches', 
          'Wallets', 'Keychains'
        ];
        if (subCategories.isEmpty) {
          subCategories = accSubCats.map((name) => {
            'id': '${parentId}_${name.toLowerCase().replaceAll(' ', '_')}_mock',
            'parentId': parentId,
            'categoryName': name,
            'categoryDescription': "Women's Accessories Subcategory",
            'active': true,
          }).toList();
        }
      }
    }

    // Move "Tops" to the first position
    subCategories.sort((a, b) {
      final nameA = (a['categoryName'] as String? ?? '').toLowerCase();
      final nameB = (b['categoryName'] as String? ?? '').toLowerCase();
      if (nameA == 'tops') return -1;
      if (nameB == 'tops') return 1;
      return 0;
    });

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // View all items red button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedSubCategory = null;
                    _currentDepth = 2;
                  });
                  _loadProducts(parentId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'VIEW ALL ITEMS',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 12),
            child: Text(
              'Choose category',
              style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),

          subCategories.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Không có danh mục con',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: subCategories.length,
                  itemBuilder: (context, index) {
                    final sub = subCategories[index];
                    final String subName = sub['categoryName'] ?? '';
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: Text(
                            subName,
                            style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w400),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedSubCategory = sub;
                              _currentDepth = 2;
                            });
                            _loadProducts(sub['id']);
                          },
                        ),
                        const Divider(height: 1, thickness: 0.5, color: Colors.black12),
                      ],
                    );
                  },
                ),
        ],
      ),
    );
  }

  // --- Depth 2: GridView or ListView display of products with large headers and horizontal scrollable pills ---
  Widget _buildCategoryProductsGridView() {
    if (_loadingProducts) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)));
    }

    // Determine category title
    String titleText = 'Items';
    if (_selectedSubCategory != null) {
      titleText = _selectedSubCategory!['categoryName'] ?? 'Items';
    } else if (_selectedCategory != null) {
      titleText = _selectedCategory!['categoryName'] ?? 'Items';
    }
    
    // Convert e.g. "Tops" to "Women's tops" for a nice display
    String displayTitle = titleText;
    if (titleText.toLowerCase() == 'tops' && _selectedRootCategory != null) {
      displayTitle = "${_selectedRootCategory!['categoryName']}'s tops";
    }

    // Apply filtering based on active filter state
    List<dynamic> filtered = _products;

    // Price range filter
    final double minFilterPrice = (_activeFilter['minPrice'] as num?)?.toDouble() ?? 0.0;
    final double maxFilterPrice = (_activeFilter['maxPrice'] as num?)?.toDouble() ?? 300.0;
    filtered = filtered.where((p) {
      final double price = (p['salePrice'] as num?)?.toDouble() ?? 0.0;
      return price >= minFilterPrice && price <= maxFilterPrice;
    }).toList();

    // Colors filter
    final List<String> selColors = List<String>.from(_activeFilter['selectedColors'] ?? []);
    if (selColors.isNotEmpty) {
      filtered = filtered.where((p) {
        final List<String> prodColors = List<String>.from(p['colors'] ?? []);
        return prodColors.any((c) => selColors.contains(c));
      }).toList();
    }

    // Sizes filter
    final List<String> selSizes = List<String>.from(_activeFilter['selectedSizes'] ?? []);
    if (selSizes.isNotEmpty) {
      filtered = filtered.where((p) {
        final List<String> prodSizes = List<String>.from(p['sizes'] ?? []);
        return prodSizes.any((s) => selSizes.contains(s));
      }).toList();
    }

    // Category filter
    final String selCategory = _activeFilter['selectedCategory'] ?? 'All';
    if (selCategory != 'All') {
      filtered = filtered.where((p) {
        final String rootCat = _selectedRootCategory?['categoryName'] ?? '';
        return rootCat.toLowerCase() == selCategory.toLowerCase() ||
               (p['productType']?.toString() ?? '').toLowerCase() == selCategory.toLowerCase();
      }).toList();
    }

    // Brands filter
    final List<String> selBrands = List<String>.from(_activeFilter['selectedBrands'] ?? []);
    if (selBrands.isNotEmpty) {
      filtered = filtered.where((p) {
        final String brand = p['brand'] ?? '';
        return selBrands.contains(brand);
      }).toList();
    }

    // Apply filtering based on selected chip (subcategory pill)
    if (_selectedChip.toLowerCase() != 'all') {
      filtered = filtered.where((p) {
        final name = (p['productName'] as String? ?? '').toLowerCase();
        final type = (p['productType'] as String? ?? '').toLowerCase();
        final chip = _selectedChip.toLowerCase();
        // If tag page, match dynamically extracted type
        if (_selectedCategory != null && _selectedCategory!['id']?.toString().endsWith('_tag_bypass') == true) {
          return type == chip || type.contains(chip) || name.contains(chip);
        }
        // Match specific types
        if (chip == 't-shirts') {
          return name.contains('t-shirt') || type.contains('t-shirt') || type.contains('shirt');
        } else if (chip == 'crop tops') {
          return name.contains('crop') || type.contains('crop');
        } else if (chip == 'sleeveless') {
          return name.contains('cami') || name.contains('camisole') || type.contains('cami') || type.contains('camisole');
        } else if (chip == 'shirts') {
          return name.contains('shirt') && !name.contains('t-shirt');
        } else if (chip == 'blouses') {
          return name.contains('blouse') || type.contains('blouse');
        }
        return name.contains(chip) || type.contains(chip);
      }).toList();
    }

    // Apply sorting
    final List<dynamic> sorted = List.from(filtered);
    if (_currentSort == 'lowest_to_high') {
      sorted.sort((a, b) => ((a['salePrice'] as num?)?.toDouble() ?? 0.0)
          .compareTo((b['salePrice'] as num?)?.toDouble() ?? 0.0));
    } else if (_currentSort == 'highest_to_low') {
      sorted.sort((a, b) => ((b['salePrice'] as num?)?.toDouble() ?? 0.0)
          .compareTo((a['salePrice'] as num?)?.toDouble() ?? 0.0));
    } else if (_currentSort == 'newest') {
      sorted.sort((a, b) => (b['id']?.toString() ?? '').compareTo(a['id']?.toString() ?? ''));
    } else if (_currentSort == 'rating') {
      sorted.sort((a, b) => (b['id']?.toString() ?? '').compareTo(a['id']?.toString() ?? ''));
    } else if (_currentSort == 'popular') {
      sorted.sort((a, b) => (a['productName']?.toString() ?? '').compareTo(b['productName']?.toString() ?? ''));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Big Title
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 12),
          child: Text(
            displayTitle,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF222222),
              letterSpacing: -0.5,
            ),
          ),
        ),

        // Horizontal Chips Row
        _buildChipsRow(),

        // Toolbar: Filters, Sorting, and Grid/List Toggle
        Container(
          color: const Color(0xFFF9F9F9),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Filters Button
              InkWell(
                onTap: _navigateToFilterScreen,
                child: Row(
                  children: const [
                    Icon(Icons.filter_list, size: 20, color: Colors.black87),
                    SizedBox(width: 6),
                    Text(
                      'Filters',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
              ),

              // Sorting Button
              InkWell(
                onTap: _showSortByBottomSheet,
                child: Row(
                  children: [
                    const Icon(Icons.swap_vert, size: 20, color: Colors.black87),
                    const SizedBox(width: 4),
                    Text(
                      _currentSort == 'lowest_to_high'
                          ? 'Price: lowest to high'
                          : _currentSort == 'highest_to_low'
                              ? 'Price: highest to low'
                              : _currentSort == 'newest'
                                  ? 'Newest'
                                  : _currentSort == 'popular'
                                      ? 'Popular'
                                      : 'Customer review',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
              ),

              // Grid/List Toggle Button
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(_isListView ? Icons.grid_view : Icons.view_list, size: 22, color: Colors.black87),
                onPressed: () {
                  setState(() {
                    _isListView = !_isListView;
                  });
                },
              ),
            ],
          ),
        ),

        // Products grid or list view
        Expanded(
          child: sorted.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Chưa có sản phẩm nào.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ),
                )
              : _isListView
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: sorted.length,
                      itemBuilder: (context, index) {
                        return _buildProductListCard(sorted[index]);
                      },
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.52,
                      ),
                      itemCount: sorted.length,
                      itemBuilder: (context, index) {
                        return _buildProductGridCard(sorted[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildChipsRow() {
    final String catName = _selectedSubCategory != null 
        ? (_selectedSubCategory!['categoryName'] ?? '') 
        : (_selectedCategory != null ? (_selectedCategory!['categoryName'] ?? '') : 'Items');

    List<String> chips = ['All'];
    if (_selectedCategory != null && _selectedCategory!['id']?.toString().endsWith('_tag_bypass') == true) {
      final Set<String> types = {};
      for (var p in _products) {
        final String? t = p['productType']?.toString().trim();
        if (t != null && t.isNotEmpty) {
          String formatted = t;
          if (t.length > 1) {
            formatted = t[0].toUpperCase() + t.substring(1);
          } else {
            formatted = t.toUpperCase();
          }
          types.add(formatted);
        }
      }
      final sortedTypes = types.toList()..sort();
      chips.addAll(sortedTypes);
    } else if (catName.toLowerCase().contains('top')) {
      chips = ['All', 'T-shirts', 'Crop tops', 'Sleeveless', 'Shirts', 'Blouses'];
    } else if (catName.toLowerCase().contains('jean')) {
      chips = ['All', 'Skinny', 'Ripped', 'Wide leg', 'Classic', 'Light wash'];
    } else if (catName.toLowerCase().contains('jacket')) {
      chips = ['All', 'Leather', 'Bomber', 'Windbreaker', 'Parka', 'Hoodie'];
    } else {
      chips = ['All', 'Newest', 'Tops', 'Bottoms', 'Sale', 'Trending'];
    }

    return Container(
      height: 34,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        itemBuilder: (context, index) {
          final label = chips[index];
          final isSelected = _selectedChip.toLowerCase() == label.toLowerCase();
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedChip = label;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF222222) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductListCard(Map<String, dynamic> product) {
    final double salePrice = (product['salePrice'] as num?)?.toDouble() ?? 0.0;
    final double? comparePrice = (product['comparePrice'] as num?)?.toDouble();

    int discountPercent = 0;
    if (comparePrice != null && comparePrice > salePrice) {
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
        height: 120,
        margin: const EdgeInsets.only(bottom: 16),
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              // Product Image on the left
              Container(
                width: 110,
                height: 120,
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
                  child: _buildProductImage(thumbnail),
                ),
              ),
              // Product Details on the right
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Subtitle / Brand
                      Text(
                        type,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Rating
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
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Price Row
                      Row(
                        children: [
                          if (comparePrice != null) ...[
                            Text(
                              _formatPrice(comparePrice),
                              style: const TextStyle(
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatPrice(salePrice),
                              style: const TextStyle(
                                color: Color(0xFFE94560),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ] else ...[
                            Text(
                              _formatPrice(salePrice),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
          
          // Discount badge
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

          // Quick Add to Cart Button
          Positioned(
            bottom: -8,
            right: 50,
            child: GestureDetector(
              onTap: () {
                _showSelectSizeBottomSheet(context, product);
              },
              child: Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE94560),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE94560).withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),

          // Favorite Button (White circular badge floating at bottom right)
          Positioned(
            bottom: -8,
            right: 8,
            child: Consumer<EcommerceProvider>(
              builder: (context, ecommerce, child) {
                final isFav = ecommerce.isFavorite(product['id']?.toString() ?? '');
                return GestureDetector(
                  onTap: () {
                    if (context.read<AuthProvider>().isLoggedIn) {
                      ecommerce.toggleFavorite(product);
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
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? const Color(0xFFE94560) : Colors.grey,
                        size: 18,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  Future<void> _navigateToFilterScreen() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => FilterScreen(activeFilter: _activeFilter),
      ),
    );
    if (result != null) {
      setState(() {
        _activeFilter = result;
      });
    }
  }

  void _showSortByBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Center(
                      child: Text(
                        'Sort by',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSortOptionTile(context, setSheetState, 'Popular', 'popular'),
                  _buildSortOptionTile(context, setSheetState, 'Newest', 'newest'),
                  _buildSortOptionTile(context, setSheetState, 'Customer review', 'rating'),
                  _buildSortOptionTile(context, setSheetState, 'Price: lowest to high', 'lowest_to_high'),
                  _buildSortOptionTile(context, setSheetState, 'Price: highest to low', 'highest_to_low'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortOptionTile(BuildContext context, StateSetter setSheetState, String title, String val) {
    final isSelected = _currentSort == val;
    return InkWell(
      onTap: () {
        setSheetState(() {
          _currentSort = val;
        });
        setState(() {
          _currentSort = val;
        });
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        color: isSelected ? const Color(0xFFE94560) : Colors.transparent,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  void _showSelectSizeBottomSheet(BuildContext context, Map<String, dynamic> product) {
    String? localSelectedSize;
    final List<String> sizes = List<String>.from(product['sizes'] ?? ['XS', 'S', 'M', 'L', 'XL']);

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
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: sizes.map((size) {
                      final isSelected = localSelectedSize == size;
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            localSelectedSize = size;
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
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (localSelectedSize == null) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(duration: const Duration(seconds: 3), content: Text('Please select a size first!')),
                          );
                          return;
                        }
                        Navigator.of(sheetContext).pop();
                        _executeAddToCart(context, product, localSelectedSize!);
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

  void _executeAddToCart(BuildContext context, Map<String, dynamic> product, String size) {
    final ecommerce = context.read<EcommerceProvider>();
    final double salePrice = (product['salePrice'] as num?)?.toDouble() ?? 0.0;
    
    ecommerce.addToCart(CartItem(
      productId: product['id']?.toString() ?? '',
      productName: product['productName'] ?? '',
      thumbnail: product['thumbnail'] ?? '',
      size: size,
      color: 'Black', // Default fallback color
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
                'Added to cart: ${product['productName']} (Size $size)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildProductGridCard(Map<String, dynamic> product) {
    final double salePrice = (product['salePrice'] as num?)?.toDouble() ?? 0.0;
    final double? comparePrice = (product['comparePrice'] as num?)?.toDouble();

    int discountPercent = 0;
    if (comparePrice != null && comparePrice > salePrice) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Image & Badge Stack
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 160,
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
            // Discount percentage badge
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
            // Quick Add to Cart Button
            Positioned(
              bottom: -15,
              right: 40,
              child: GestureDetector(
                onTap: () {
                  _showSelectSizeBottomSheet(context, product);
                },
                child: Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE94560),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE94560).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            // Favorite Button
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
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? const Color(0xFFE94560) : Colors.grey,
                          size: 18,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Rating
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

        // Brand / Type
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

        // Title
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

        // Price Row
        Row(
          children: [
            if (comparePrice != null) ...[
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
  );
}

  Widget _buildProductImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const Center(child: Icon(Icons.image_outlined, size: 48, color: Colors.grey));
    }

    String cleanPath = imagePath.trim();
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return Image.network(
        cleanPath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey)),
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
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey)),
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
