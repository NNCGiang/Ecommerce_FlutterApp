import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Thay bằng URL ngrok của bạn
  static const String baseUrl =
      'https://simplify-stony-crestless.ngrok-free.dev/api';

  // Headers hỗ trợ tránh trang cảnh báo ngrok
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  static const Map<String, String> _getHeaders = {
    'ngrok-skip-browser-warning': 'true',
  };

  // ─── AUTH ────────────────────────────────────────────

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({'fullName': fullName, 'email': email, 'password': password}),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String token,
    required String mode,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/social'),
      headers: _headers,
      body: jsonEncode({
        'provider': provider,
        'token': token,
        'mode': mode,
      }),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final res = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        ..._getHeaders,
        'Authorization': 'Bearer $token',
      },
    );
    return _handle(res);
  }

  // ─── PRODUCTS ────────────────────────────────────────

  static Future<List<dynamic>> getProductsByTag(String tagName) async {
    final res = await http.get(Uri.parse('$baseUrl/products?tag=$tagName'), headers: _getHeaders);
    return jsonDecode(res.body) as List;
  }

  static Future<List<dynamic>> getPublishedProducts() async {
    final res = await http.get(Uri.parse('$baseUrl/products'), headers: _getHeaders);
    return jsonDecode(res.body) as List;
  }

  static Future<List<dynamic>> getProductsByCategory(String categoryId) async {
    final res = await http.get(Uri.parse('$baseUrl/products?categoryId=$categoryId'), headers: _getHeaders);
    return jsonDecode(res.body) as List;
  }

  // ─── CATEGORIES ──────────────────────────────────────

  static Future<List<dynamic>> getRootCategories() async {
    final res = await http.get(Uri.parse('$baseUrl/categories/roots'), headers: _getHeaders);
    return jsonDecode(res.body) as List;
  }

  static Future<List<dynamic>> getAllCategories() async {
    final res = await http.get(Uri.parse('$baseUrl/categories/active'), headers: _getHeaders);
    return jsonDecode(res.body) as List;
  }

  // ─── TAGS ────────────────────────────────────────────

  static Future<List<dynamic>> getAllTags() async {
    final res = await http.get(Uri.parse('$baseUrl/tags'), headers: _getHeaders);
    return jsonDecode(res.body) as List;
  }

  // ─── HELPERS ─────────────────────────────────────────

  static Map<String, dynamic> _handle(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw Exception(body['message'] ?? 'Lỗi server: ${res.statusCode}');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<void> saveAccount({
    required String email,
    required String fullName,
    required String provider,
    String? avatar,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final listStr = prefs.getString('saved_accounts') ?? '[]';
    final List<dynamic> listJson = jsonDecode(listStr);
    
    listJson.removeWhere((item) => item['email'] == email);
    
    listJson.insert(0, {
      'email': email,
      'fullName': fullName,
      'provider': provider,
      'avatar': avatar,
    });
    
    if (listJson.length > 5) {
      listJson.removeLast();
    }
    
    await prefs.setString('saved_accounts', jsonEncode(listJson));
  }

  static Future<List<Map<String, dynamic>>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final listStr = prefs.getString('saved_accounts') ?? '[]';
    final List<dynamic> listJson = jsonDecode(listStr);
    return listJson.cast<Map<String, dynamic>>();
  }

  static Future<void> removeSavedAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final listStr = prefs.getString('saved_accounts') ?? '[]';
    final List<dynamic> listJson = jsonDecode(listStr);
    listJson.removeWhere((item) => item['email'] == email);
    await prefs.setString('saved_accounts', jsonEncode(listJson));
  }

  // ─── CART DATABASE APIS ──────────────────────────────

  static Future<Map<String, dynamic>> getCart() async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final res = await http.get(
      Uri.parse('$baseUrl/cart'),
      headers: {
        ..._getHeaders,
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> addToCart({
    required String productId,
    required int quantity,
    required String size,
    required String color,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final res = await http.post(
      Uri.parse('$baseUrl/cart'),
      headers: {
        ..._headers,
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'productId': productId,
        'quantity': quantity,
        'size': size,
        'color': color,
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateCartItem({
    required String itemId,
    required int quantity,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final res = await http.put(
      Uri.parse('$baseUrl/cart/$itemId'),
      headers: {
        ..._headers,
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'quantity': quantity,
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> removeCartItem({
    required String itemId,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final res = await http.delete(
      Uri.parse('$baseUrl/cart/$itemId'),
      headers: {
        ..._getHeaders,
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(res.body);
  }

  // ─── FAVORITES DATABASE APIS ─────────────────────────

  static Future<List<dynamic>> getFavorites() async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final res = await http.get(
      Uri.parse('$baseUrl/favorites'),
      headers: {
        ..._getHeaders,
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(res.body) as List;
  }

  static Future<Map<String, dynamic>> addFavorite(String productId) async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final res = await http.post(
      Uri.parse('$baseUrl/favorites/$productId'),
      headers: {
        ..._headers,
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> removeFavorite(String productId) async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final res = await http.delete(
      Uri.parse('$baseUrl/favorites/$productId'),
      headers: {
        ..._getHeaders,
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(res.body);
  }

  // ─── REVIEWS DATABASE APIS ───────────────────────────

  // Đường dẫn review backend. Chạy chung cổng với backend chính (cổng 8080)
  static const String reviewBaseUrl = baseUrl;

  static String getFullImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('assets/')) {
      return path; // Local assets
    }
    // Bỏ /api ở cuối để lấy domain gốc của server
    String serverRoot = reviewBaseUrl.replaceAll('/api', '');
    if (kIsWeb) {
      final uriBase = Uri.base;
      if (uriBase.host == 'localhost' || uriBase.host == '127.0.0.1') {
        serverRoot = 'http://localhost:8080';
      }
    }
    return '$serverRoot$path';
  }

  static Future<List<dynamic>> getReviews(String productId) async {
    final res = await http.get(
      Uri.parse('$reviewBaseUrl/reviews?productId=$productId'),
      headers: _getHeaders,
    );
    return jsonDecode(res.body) as List;
  }

  static Future<Map<String, dynamic>> addReview({
    required String productId,
    required String author,
    required double rating,
    required String content,
    required List<String> photos,
  }) async {
    final token = await getToken();
    final headers = {
      ..._headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final res = await http.post(
      Uri.parse('$reviewBaseUrl/reviews'),
      headers: headers,
      body: jsonEncode({
        'productId': productId,
        'author': author,
        'avatar': 'assets/images/avata1.png',
        'rating': rating,
        'content': content,
        'photos': photos,
      }),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> updateReview({
    required String reviewId,
    required double rating,
    required String content,
    required List<String> photos,
  }) async {
    final token = await getToken();
    final headers = {
      ..._headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final res = await http.put(
      Uri.parse('$reviewBaseUrl/reviews/$reviewId'),
      headers: headers,
      body: jsonEncode({
        'rating': rating,
        'content': content,
        'photos': photos,
      }),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> deleteReview(String reviewId) async {
    final token = await getToken();
    final headers = {
      ..._getHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final res = await http.delete(
      Uri.parse('$reviewBaseUrl/reviews/$reviewId'),
      headers: headers,
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> toggleReviewHelpful(String reviewId) async {
    final res = await http.post(
      Uri.parse('$reviewBaseUrl/reviews/$reviewId/helpful'),
      headers: _getHeaders,
    );
    return jsonDecode(res.body);
  }

  static Future<String> uploadReviewFile(List<int> bytes, String filename) async {
    final token = await getToken();
    final uri = Uri.parse('$reviewBaseUrl/reviews/upload');
    final request = http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['ngrok-skip-browser-warning'] = 'true';

    final extension = filename.split('.').last.toLowerCase();
    String type = 'image';
    String subtype = extension;
    if (extension == 'mp4' || extension == 'mov' || extension == 'avi' || extension == 'mkv' || extension == '3gp') {
      type = 'video';
      if (extension == 'mov') subtype = 'quicktime';
    } else if (extension == 'jpg' || extension == 'jpeg') {
      subtype = 'jpeg';
    } else if (extension == 'png') {
      subtype = 'png';
    } else if (extension == 'gif') {
      subtype = 'gif';
    } else {
      subtype = 'octet-stream';
    }

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
      contentType: MediaType(type, subtype),
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      return body['url'] as String; // Ví dụ: /uploads/abc-xyz.mp4
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Lỗi tải tệp lên: ${response.statusCode}');
    }
  }

  // ─── PROMO CODES DATABASE APIS ──────────────────────

  static Future<List<dynamic>> getActivePromos() async {
    final res = await http.get(
      Uri.parse('$baseUrl/promos'),
      headers: _getHeaders,
    );
    return jsonDecode(res.body) as List;
  }

  static Future<Map<String, dynamic>> validatePromo(String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/promos/validate'),
      headers: _headers,
      body: jsonEncode({'code': code}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Mã giảm giá không hợp lệ hoặc đã hết hạn');
    }
  }

  // ─── SHIPPING ADDRESSES ────────────────────────────────

  static Future<List<dynamic>> getAddresses() async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final res = await http.get(
      Uri.parse('$baseUrl/addresses'),
      headers: {..._getHeaders, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List;
    }
    throw Exception('Lỗi tải địa chỉ: ${res.statusCode}');
  }

  static Future<Map<String, dynamic>> addAddress({
    required String fullName,
    required String phoneNumber,
    required String addressLine1,
    required String city,
    required String state,
    required String zipCode,
    required String country,
    bool isDefault = false,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final res = await http.post(
      Uri.parse('$baseUrl/addresses'),
      headers: {..._headers, 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'addressLine1': addressLine1,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'country': country,
        'isDefault': isDefault,
      }),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> setDefaultAddress(String id) async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final res = await http.put(
      Uri.parse('$baseUrl/addresses/$id/default'),
      headers: {..._getHeaders, 'Authorization': 'Bearer $token'},
    );
    return _handle(res);
  }

  static Future<void> deleteAddress(String id) async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    await http.delete(
      Uri.parse('$baseUrl/addresses/$id'),
      headers: {..._getHeaders, 'Authorization': 'Bearer $token'},
    );
  }

  // ─── PAYMENT CARDS ─────────────────────────────────────

  static Future<List<dynamic>> getPaymentCards() async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final res = await http.get(
      Uri.parse('$baseUrl/payment-cards'),
      headers: {..._getHeaders, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List;
    }
    throw Exception('Lỗi tải thẻ: ${res.statusCode}');
  }

  static Future<Map<String, dynamic>> addPaymentCard({
    required String cardHolderName,
    required String cardNumber,
    required String brand,
    required int expiryMonth,
    required int expiryYear,
    bool isDefault = false,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final res = await http.post(
      Uri.parse('$baseUrl/payment-cards'),
      headers: {..._headers, 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'cardHolderName': cardHolderName,
        'cardNumber': cardNumber,
        'brand': brand,
        'expiryMonth': expiryMonth,
        'expiryYear': expiryYear,
        'isDefault': isDefault,
      }),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> setDefaultCard(String id) async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final res = await http.put(
      Uri.parse('$baseUrl/payment-cards/$id/default'),
      headers: {..._getHeaders, 'Authorization': 'Bearer $token'},
    );
    return _handle(res);
  }

  static Future<void> deletePaymentCard(String id) async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    await http.delete(
      Uri.parse('$baseUrl/payment-cards/$id'),
      headers: {..._getHeaders, 'Authorization': 'Bearer $token'},
    );
  }

  // ─── PLACE ORDER ───────────────────────────────────────

  static Future<Map<String, dynamic>> placeOrder({
    String? shippingAddressId,
    String? paymentCardId,
    String? couponId,
    String? deliveryMethod,
    double? deliveryFee,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final body = <String, dynamic>{};
    if (shippingAddressId != null) body['shippingAddressId'] = shippingAddressId;
    if (paymentCardId != null) body['paymentCardId'] = paymentCardId;
    if (couponId != null) body['couponId'] = couponId;
    if (deliveryMethod != null) body['deliveryMethod'] = deliveryMethod;
    if (deliveryFee != null) body['deliveryFee'] = deliveryFee;
    final res = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {..._headers, 'Authorization': 'Bearer $token'},
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  // ─── USER SETTINGS & ORDERS ───────────────────────────

  static Future<Map<String, dynamic>> updateProfileSettings({
    String? fullName,
    String? dateOfBirth,
    bool? salesNotify,
    bool? newArrivalsNotify,
    bool? deliveryStatusNotify,
    String? avatarUrl,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth;
    if (salesNotify != null) body['salesNotify'] = salesNotify;
    if (newArrivalsNotify != null) body['newArrivalsNotify'] = newArrivalsNotify;
    if (deliveryStatusNotify != null) body['deliveryStatusNotify'] = deliveryStatusNotify;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;

    final res = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: {..._headers, 'Authorization': 'Bearer $token'},
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final res = await http.put(
      Uri.parse('$baseUrl/users/me/password'),
      headers: {..._headers, 'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );
    return _handle(res);
  }

  static Future<List<dynamic>> getOrders() async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final res = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: {..._getHeaders, 'Authorization': 'Bearer $token'},
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List;
    }
    throw Exception('Lỗi tải đơn hàng: ${res.statusCode}');
  }

  static Future<Map<String, dynamic>> getOrder(String orderId) async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final res = await http.get(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: {..._getHeaders, 'Authorization': 'Bearer $token'},
    );
    return _handle(res);
  }

  // ─── SEARCH ────────────────────────────────────────────

  /// Text search: GET /api/search?q=keyword
  static Future<Map<String, dynamic>> searchProducts(String keyword) async {
    final encodedQ = Uri.encodeQueryComponent(keyword);
    final res = await http.get(
      Uri.parse('$baseUrl/search?q=$encodedQ'),
      headers: _getHeaders,
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    final body = jsonDecode(res.body);
    throw Exception(body['message'] ?? 'Search failed: ${res.statusCode}');
  }

  /// Image/visual search: POST /api/search/image (multipart)
  static Future<Map<String, dynamic>> searchByImage(
    List<int> imageBytes,
    String filename,
  ) async {
    final uri = Uri.parse('$baseUrl/search/image');
    final request = http.MultipartRequest('POST', uri);
    request.headers['ngrok-skip-browser-warning'] = 'true';

    final ext = filename.split('.').last.toLowerCase();
    String subtype = 'jpeg';
    if (ext == 'png') subtype = 'png';
    if (ext == 'gif') subtype = 'gif';
    if (ext == 'webp') subtype = 'webp';

    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: filename,
      contentType: MediaType('image', subtype),
    ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? 'Visual search failed: ${response.statusCode}');
  }

  static Future<List<dynamic>> getMyReviews() async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final res = await http.get(
      Uri.parse('$reviewBaseUrl/reviews/my-reviews'),
      headers: {
        ..._getHeaders,
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List;
    }
    throw Exception('Lỗi tải đánh giá: ${res.statusCode}');
  }

  static Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    final token = await getToken();
    if (token == null) throw Exception('Chưa đăng nhập');
    final res = await http.put(
      Uri.parse('$baseUrl/orders/$orderId/cancel'),
      headers: {
        ..._headers,
        'Authorization': 'Bearer $token',
      },
    );
    return _handle(res);
  }
}


