import 'package:flutter/material.dart';
import 'api_service.dart';

class CartItem {
  final String? id; // database CardItem UUID
  final String productId;
  final String productName;
  final String thumbnail;
  final String size;
  final String color;
  final double price;
  int quantity;

  CartItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.thumbnail,
    required this.size,
    required this.color,
    required this.price,
    required this.quantity,
  });
}

class ProductReview {
  final String? id; // database Review UUID
  final String author;
  final String? authorEmail;
  final String avatar;
  final double rating;
  final String date;
  final String content;
  final List<String> photos;
  int helpfulCount;
  bool isHelpful;

  ProductReview({
    this.id,
    required this.author,
    this.authorEmail,
    required this.avatar,
    required this.rating,
    required this.date,
    required this.content,
    required this.photos,
    this.helpfulCount = 0,
    this.isHelpful = false,
  });
}

class EcommerceProvider with ChangeNotifier {
  List<CartItem> _cartItems = [];
  Map<String, List<ProductReview>> _reviews = {};
  Map<String, dynamic>? _activePromo;
  List<dynamic> _activePromosList = [];
  List<dynamic> _myReviews = [];

  List<CartItem> get cartItems => _cartItems;
  Map<String, dynamic>? get activePromo => _activePromo;
  List<dynamic> get activePromosList => _activePromosList;
  List<dynamic> get myReviews => _myReviews;

  int get cartCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  double get cartSubtotal {
    return _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  double get cartTotal {
    final sub = cartSubtotal;
    if (_activePromo != null) {
      final discountPercent = (_activePromo!['discountPercent'] as num?)?.toDouble() ?? 0.0;
      return sub * (1.0 - discountPercent / 100.0);
    }
    return sub;
  }

  // ─── CART DATABASE ACTIONS ───────────────────────────

  Future<void> loadCart() async {
    try {
      final data = await ApiService.getCart();
      final List<dynamic> itemsJson = data['items'] ?? [];
      _cartItems = itemsJson.map((item) {
        return CartItem(
          id: item['id']?.toString(),
          productId: item['productId']?.toString() ?? '',
          productName: item['productName'] ?? '',
          thumbnail: item['thumbnail'] ?? '',
          size: item['size'] ?? 'M',
          color: item['color'] ?? 'Black',
          price: (item['price'] as num?)?.toDouble() ?? 0.0,
          quantity: item['quantity'] ?? 1,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cart from db: $e');
    }
  }

  Future<void> addToCart(CartItem item) async {
    try {
      await ApiService.addToCart(
        productId: item.productId,
        quantity: item.quantity,
        size: item.size,
        color: item.color,
      );
      await loadCart();
    } catch (e) {
      debugPrint('Error adding to cart: $e');
    }
  }

  Future<void> updateQuantity(int index, int newQuantity) async {
    if (index >= 0 && index < _cartItems.length) {
      final item = _cartItems[index];
      if (item.id == null) return;
      try {
        if (newQuantity <= 0) {
          await ApiService.removeCartItem(itemId: item.id!);
        } else {
          await ApiService.updateCartItem(itemId: item.id!, quantity: newQuantity);
        }
        await loadCart();
      } catch (e) {
        debugPrint('Error updating quantity: $e');
      }
    }
  }

  Future<void> removeFromCart(int index) async {
    if (index >= 0 && index < _cartItems.length) {
      final item = _cartItems[index];
      if (item.id == null) return;
      try {
        await ApiService.removeCartItem(itemId: item.id!);
        await loadCart();
      } catch (e) {
        debugPrint('Error removing from cart: $e');
      }
    }
  }

  Future<void> clearCart() async {
    try {
      // Deletes items sequentially from the backend DB
      for (var item in _cartItems) {
        if (item.id != null) {
          await ApiService.removeCartItem(itemId: item.id!);
        }
      }
      removePromoCode();
      await loadCart();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
    }
  }

  // ─── PROMO CODES DATABASE ACTIONS ────────────────────

  Future<void> loadActivePromos() async {
    try {
      final list = await ApiService.getActivePromos();
      _activePromosList = list;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading active promos: $e');
    }
  }

  Future<bool> applyPromoCode(String code) async {
    try {
      final data = await ApiService.validatePromo(code);
      _activePromo = data;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error applying promo code: $e');
      rethrow;
    }
  }

  void removePromoCode() {
    _activePromo = null;
    notifyListeners();
  }

  // ─── REVIEWS DATABASE ACTIONS ────────────────────────

  List<ProductReview> getReviewsForProduct(String productId) {
    return _reviews[productId] ?? [];
  }

  Future<void> loadReviews(String productId) async {
    try {
      final list = await ApiService.getReviews(productId);
      
      // If db has no reviews, save seed reviews to database first so page isn't blank
      if (list.isEmpty) {
        final token = await ApiService.getToken();
        if (token != null) {
          await _seedInitialReviews(productId);
          return;
        }
      }

      _reviews[productId] = list.map((r) {
        String dateStr = 'Recent';
        if (r['createdAt'] != null) {
          try {
            final parsed = DateTime.parse(r['createdAt']);
            final months = [
              'January', 'February', 'March', 'April', 'May', 'June',
              'July', 'August', 'September', 'October', 'November', 'December'
            ];
            dateStr = '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
          } catch (_) {}
        }
        return ProductReview(
          id: r['id']?.toString(),
          author: r['author'] ?? 'Anonymous',
          authorEmail: r['authorEmail']?.toString(),
          avatar: r['avatar'] ?? 'assets/images/avata1.png',
          rating: (r['rating'] as num?)?.toDouble() ?? 5.0,
          date: dateStr,
          content: r['content'] ?? '',
          photos: List<String>.from(r['photos'] ?? []),
          helpfulCount: r['helpfulCount'] ?? 0,
          isHelpful: false,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    }
  }

  Future<void> _seedInitialReviews(String productId) async {
    try {
      final initialReviews = [
        {
          'author': 'Helene Moore',
          'rating': 5.0,
          'content': 'The dress is great! Very classy and comfortable. It fit perfectly! I\'m 5\'7" and 130 pounds. I am a 34B chest. This dress would be too long for those who are shorter but could be hemmed. I wouldn\'t recommend it for those big chested as I am smaller chested and it fit me perfectly. The underarms were not too wide and the dress was made well.',
          'photos': <String>[],
        },
        {
          'author': 'Kim Shine',
          'rating': 4.0,
          'content': 'I loved this dress so much as soon as I tried it on I knew I had to buy it in another color. I am 5\'3" about 155lbs and I carry all my weight in my upper body. When I put it on I felt like it thinned me out and I got so many compliments.',
          'photos': ['assets/images/cmt1.png', 'assets/images/cmt2.png'],
        },
        {
          'author': 'Matilda Brown',
          'rating': 4.0,
          'content': 'Good material and fit. Very beautiful color. Perfect dress for dinner dates. I got it on sale, which makes it even better value for money. Highly recommended!',
          'photos': <String>[],
        }
      ];

      for (var r in initialReviews) {
        await ApiService.addReview(
          productId: productId,
          author: r['author'] as String,
          rating: r['rating'] as double,
          content: r['content'] as String,
          photos: r['photos'] as List<String>,
        );
      }
      // Reload from db
      final list = await ApiService.getReviews(productId);
      _reviews[productId] = list.map((r) {
        return ProductReview(
          id: r['id']?.toString(),
          author: r['author'] ?? 'Anonymous',
          authorEmail: r['authorEmail']?.toString(),
          avatar: r['avatar'] ?? 'assets/images/avata1.png',
          rating: (r['rating'] as num?)?.toDouble() ?? 5.0,
          date: 'June 5, 2019',
          content: r['content'] ?? '',
          photos: List<String>.from(r['photos'] ?? []),
          helpfulCount: r['helpfulCount'] ?? 0,
          isHelpful: false,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error seeding initial reviews: $e');
    }
  }

  Future<void> addReview(String productId, ProductReview review) async {
    try {
      await ApiService.addReview(
        productId: productId,
        author: review.author,
        rating: review.rating,
        content: review.content,
        photos: review.photos,
      );
      await loadReviews(productId);
    } catch (e) {
      debugPrint('Error adding review to db: $e');
      rethrow;
    }
  }

  Future<void> updateReview({
    required String productId,
    required String reviewId,
    required double rating,
    required String content,
    required List<String> photos,
  }) async {
    try {
      await ApiService.updateReview(
        reviewId: reviewId,
        rating: rating,
        content: content,
        photos: photos,
      );
      await loadReviews(productId);
    } catch (e) {
      debugPrint('Error updating review on db: $e');
      rethrow;
    }
  }

  Future<void> toggleHelpful(String productId, int index) async {
    final list = _reviews[productId];
    if (list != null && index >= 0 && index < list.length) {
      final review = list[index];
      if (review.id == null) return;
      try {
        await ApiService.toggleReviewHelpful(review.id!);
        await loadReviews(productId);
      } catch (e) {
        debugPrint('Error toggling helpful review on db: $e');
      }
    }
  }

  // Get statistics for reviews
  Map<String, dynamic> getProductRatingStats(String productId) {
    final reviewsList = getReviewsForProduct(productId);
    if (reviewsList.isEmpty) {
      return {
        'average': 4.3, // Mock fallback average if no database comments yet
        'total': 0,
        'starsCount': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0}
      };
    }

    double sum = 0;
    Map<int, int> starsCount = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var r in reviewsList) {
      sum += r.rating;
      int rounded = r.rating.round();
      if (rounded >= 1 && rounded <= 5) {
        starsCount[rounded] = (starsCount[rounded] ?? 0) + 1;
      }
    }

    double average = double.parse((sum / reviewsList.length).toStringAsFixed(1));
    return {
      'average': average,
      'total': reviewsList.length,
      'starsCount': starsCount
    };
  }

  // ─── FAVORITES DATABASE ACTIONS ──────────────────────
  List<dynamic> _favorites = [];
  Set<String> _favoriteProductIds = {};

  List<dynamic> get favorites => _favorites;
  Set<String> get favoriteProductIds => _favoriteProductIds;

  Future<void> loadFavorites() async {
    try {
      final list = await ApiService.getFavorites();
      _favorites = list;
      _favoriteProductIds = list.map((item) => (item['id'] ?? '').toString()).toSet();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> toggleFavorite(Map<String, dynamic> product) async {
    final String productId = (product['id'] ?? '').toString();
    if (productId.isEmpty) return;

    try {
      if (_favoriteProductIds.contains(productId)) {
        await ApiService.removeFavorite(productId);
        _favoriteProductIds.remove(productId);
        _favorites.removeWhere((item) => (item['id'] ?? '').toString() == productId);
      } else {
        await ApiService.addFavorite(productId);
        _favoriteProductIds.add(productId);
        _favorites.add(product);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  bool isFavorite(String productId) {
    return _favoriteProductIds.contains(productId);
  }

  // ─── SHIPPING ADDRESSES ──────────────────────────────────
  List<dynamic> _addresses = [];
  List<dynamic> get addresses => _addresses;

  Future<void> loadAddresses() async {
    try {
      _addresses = await ApiService.getAddresses();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading addresses: $e');
    }
  }

  Future<void> addAddress({
    required String fullName,
    required String phoneNumber,
    required String addressLine1,
    required String city,
    required String state,
    required String zipCode,
    required String country,
    bool isDefault = false,
  }) async {
    await ApiService.addAddress(
      fullName: fullName,
      phoneNumber: phoneNumber,
      addressLine1: addressLine1,
      city: city,
      state: state,
      zipCode: zipCode,
      country: country,
      isDefault: isDefault,
    );
    await loadAddresses();
  }

  Future<void> setDefaultAddress(String id) async {
    await ApiService.setDefaultAddress(id);
    await loadAddresses();
  }

  Future<void> deleteAddress(String id) async {
    await ApiService.deleteAddress(id);
    await loadAddresses();
  }

  Map<String, dynamic>? get defaultAddress {
    try {
      if (_addresses.isEmpty) return null;
      final def = _addresses.firstWhere(
        (a) => a['isDefault'] == true,
        orElse: () => _addresses.first,
      );
      return def as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ─── PAYMENT CARDS ────────────────────────────────────────
  List<dynamic> _paymentCards = [];
  List<dynamic> get paymentCards => _paymentCards;

  Future<void> loadPaymentCards() async {
    try {
      _paymentCards = await ApiService.getPaymentCards();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading payment cards: $e');
    }
  }

  Future<void> addPaymentCard({
    required String cardHolderName,
    required String cardNumber,
    required String brand,
    required int expiryMonth,
    required int expiryYear,
    bool isDefault = false,
  }) async {
    await ApiService.addPaymentCard(
      cardHolderName: cardHolderName,
      cardNumber: cardNumber,
      brand: brand,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      isDefault: isDefault,
    );
    await loadPaymentCards();
  }

  Future<void> setDefaultCard(String id) async {
    await ApiService.setDefaultCard(id);
    await loadPaymentCards();
  }

  Future<void> deletePaymentCard(String id) async {
    await ApiService.deletePaymentCard(id);
    await loadPaymentCards();
  }

  Map<String, dynamic>? get defaultCard {
    try {
      if (_paymentCards.isEmpty) return null;
      final def = _paymentCards.firstWhere(
        (c) => c['isDefault'] == true,
        orElse: () => _paymentCards.first,
      );
      return def as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ─── PLACE ORDER ──────────────────────────────────────────
  Future<Map<String, dynamic>> placeOrder({
    String? deliveryMethod,
    double? deliveryFee,
  }) async {
    final addr = defaultAddress;
    final card = defaultCard;
    final promoId = _activePromo?['id']?.toString();
    final result = await ApiService.placeOrder(
      shippingAddressId: addr?['id']?.toString(),
      paymentCardId: card?['id']?.toString(),
      couponId: promoId,
      deliveryMethod: deliveryMethod,
      deliveryFee: deliveryFee,
    );
    removePromoCode();
    return result;
  }

  // ─── MY REVIEWS ───────────────────────────────────────────
  Future<void> loadMyReviews() async {
    try {
      _myReviews = await ApiService.getMyReviews();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading my reviews: $e');
    }
  }
}

