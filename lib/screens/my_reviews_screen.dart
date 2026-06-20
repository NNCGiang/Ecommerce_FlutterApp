import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ecommerce_provider.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMyReviews();
  }

  Future<void> _fetchMyReviews() async {
    setState(() => _isLoading = true);
    await context.read<EcommerceProvider>().loadMyReviews();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('MMMM dd, yyyy').format(dateTime);
    } catch (_) {
      return 'Recent';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EcommerceProvider>();
    final reviews = provider.myReviews;

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
          'My reviews',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchMyReviews,
          color: const Color(0xFFFF3B30),
          child: _isLoading && reviews.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF3B30)))
              : reviews.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            '${reviews.length} reviews',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: reviews.length,
                            itemBuilder: (context, index) {
                              final review = reviews[index];
                              return _buildReviewCard(review);
                            },
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No reviews yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Buy items and leave reviews to show them here!',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(dynamic review) {
    final double rating = (review['rating'] as num?)?.toDouble() ?? 5.0;
    final String content = review['content'] ?? '';
    final String date = _formatDate(review['createdAt']);
    final String productName = review['productName'] ?? 'Product';
    final String productThumbnail = review['productThumbnail'] ?? '';
    final photos = review['photos'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product header row
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey.shade100,
                  child: _buildProductImage(productThumbnail),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStars(rating),
                        Text(
                          date,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Content text
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          // Photos row (if any)
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                itemBuilder: (context, idx) {
                  final String imgUrl = photos[idx].toString();
                  return Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade100,
                        child: _buildProductImage(imgUrl),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Color(0xFFFFBA49), size: 16);
        } else if (index < rating && rating - index > 0.1) {
          return const Icon(Icons.star_half, color: Color(0xFFFFBA49), size: 16);
        } else {
          return const Icon(Icons.star_border, color: Colors.grey, size: 16);
        }
      }),
    );
  }

  Widget _buildProductImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const Center(child: Icon(Icons.image_outlined, size: 20, color: Colors.grey));
    }

    String cleanPath = imagePath.trim();

    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return Image.network(
        cleanPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image, size: 20, color: Colors.grey)),
      );
    } else if (cleanPath.contains('assets/')) {
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }
      return Image.asset(
        cleanPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image, size: 20, color: Colors.grey)),
      );
    } else {
      // It's a server uploaded path like "/uploads/xxx.png"
      final fullUrl = ApiService.getFullImageUrl(cleanPath);
      return Image.network(
        fullUrl,
        headers: const {'ngrok-skip-browser-warning': 'true'},
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image, size: 20, color: Colors.grey)),
      );
    }
  }
}
