import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/ecommerce_provider.dart';
import '../services/auth_provider.dart';

class ReviewsScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const ReviewsScreen({super.key, required this.productId, required this.productName});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  bool _filterWithPhoto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EcommerceProvider>().loadReviews(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ecommerce = context.watch<EcommerceProvider>();
    final reviews = ecommerce.getReviewsForProduct(widget.productId);
    final stats = ecommerce.getProductRatingStats(widget.productId);
    
    final auth = context.watch<AuthProvider>();
    final currentUserEmail = auth.user?['email'];
    ProductReview? myReview;
    if (auth.isLoggedIn && currentUserEmail != null) {
      for (var r in reviews) {
        if (r.authorEmail != null && r.authorEmail == currentUserEmail) {
          myReview = r;
          break;
        }
      }
    }

    final double average = stats['average'] as double;
    final int totalRatings = stats['total'] as int;
    final Map<int, int> starsCount = Map<int, int>.from(stats['starsCount'] ?? {});

    // Filter reviews list
    final displayedReviews = _filterWithPhoto
        ? reviews.where((r) => r.photos.isNotEmpty).toList()
        : reviews;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Rating and reviews',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── RATINGS BREAKDOWN CONTAINER ──
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Average and rating count
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            average.toString(),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalRatings ratings',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Rating bars distribution
                    Expanded(
                      flex: 8,
                      child: Column(
                        children: List.generate(5, (index) {
                          int starLevel = 5 - index;
                          int count = starsCount[starLevel] ?? 0;
                          double percentage = totalRatings > 0 ? count / totalRatings : 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                // Stars Icons Row for this level
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: List.generate(5, (starIdx) {
                                    return Icon(
                                      Icons.star,
                                      color: starIdx < starLevel ? Colors.amber : Colors.transparent,
                                      size: 12,
                                    );
                                  }),
                                ),
                                const SizedBox(width: 8),
                                // Progress Bar
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: percentage,
                                      backgroundColor: Colors.grey[100],
                                      color: const Color(0xFFE94560),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Count label
                                SizedBox(
                                  width: 16,
                                  child: Text(
                                    count.toString(),
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── FILTERS SECTION (COUNT & WITH PHOTO CHECKBOX) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${reviews.length} reviews',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _filterWithPhoto = !_filterWithPhoto;
                        });
                      },
                      child: Row(
                        children: [
                          Checkbox(
                            value: _filterWithPhoto,
                            activeColor: const Color(0xFF222222),
                            onChanged: (val) {
                              setState(() {
                                _filterWithPhoto = val ?? false;
                              });
                            },
                          ),
                          const Text(
                            'With photo',
                            style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── REVIEWS LIST ──
              Expanded(
                child: displayedReviews.isEmpty
                    ? const Center(
                        child: Text(
                          'No reviews found.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: displayedReviews.length,
                        itemBuilder: (context, index) {
                          final review = displayedReviews[index];
                          final int origIdx = reviews.indexOf(review);
                          return _buildReviewCard(review, origIdx);
                        },
                      ),
              ),
            ],
          ),

          // ── WRITE A REVIEW FLOATING ACTION BUTTON ──
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                final currentAuth = context.read<AuthProvider>();
                if (!currentAuth.isLoggedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng đăng nhập trước khi viết đánh giá!'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                _showWriteReviewBottomSheet(context, existingReview: myReview);
              },
              backgroundColor: const Color(0xFFE94560),
              icon: Icon(myReview != null ? Icons.edit_note : Icons.edit, color: Colors.white),
              label: Text(
                myReview != null ? 'Edit my review' : 'Write a review',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ProductReview review, int originalIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Date
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: review.avatar.startsWith('assets/')
                    ? AssetImage(review.avatar)
                    : const AssetImage('assets/images/avata1.png') as ImageProvider,
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.author,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(5, (starIdx) {
                          return Icon(
                            Icons.star,
                            color: starIdx < review.rating ? Colors.amber : Colors.grey[300],
                            size: 13,
                          );
                        }),
                        const Spacer(),
                        Text(
                          review.date,
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Content
          Text(
            review.content,
            style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 12),

          // Photos Row (if any)
          if (review.photos.isNotEmpty) ...[
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: review.photos.length,
                itemBuilder: (context, idx) {
                  final photo = review.photos[idx];
                  final isVid = isVideo(photo);
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 100,
                    decoration: BoxDecoration(
                      color: isVid ? Colors.black87 : Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                      image: isVid
                          ? null
                          : DecorationImage(
                              image: photo.startsWith('assets/')
                                  ? AssetImage(photo) as ImageProvider
                                  : NetworkImage(
                                      ApiService.getFullImageUrl(photo),
                                      headers: const {'ngrok-skip-browser-warning': 'true'},
                                    ),
                              fit: BoxFit.cover,
                            ),
                    ),
                    child: isVid
                        ? Center(
                            child: Icon(
                              Icons.play_circle_fill,
                              color: Colors.white.withOpacity(0.9),
                              size: 36,
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Thumbs Up Helpful Button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Helpful', style: TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(width: 4),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  review.isHelpful ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                  color: review.isHelpful ? const Color(0xFFE94560) : Colors.grey,
                  size: 16,
                ),
                onPressed: () {
                  context.read<EcommerceProvider>().toggleHelpful(widget.productId, originalIndex);
                },
              ),
              const SizedBox(width: 4),
              Text(
                '(${review.helpfulCount})',
                style: TextStyle(
                  color: review.isHelpful ? const Color(0xFFE94560) : Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool isVideo(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.mp4') ||
        p.endsWith('.mov') ||
        p.endsWith('.avi') ||
        p.endsWith('.mkv') ||
        p.endsWith('.webm') ||
        p.endsWith('.3gp');
  }

  void _showAttachmentPicker(BuildContext context, StateSetter setSheetState, List<XFile> selectedFiles) {
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
                leading: const Icon(Icons.photo_camera, color: Color(0xFFE94560)),
                title: const Text('Chụp ảnh mới (Take Photo)'),
                onTap: () async {
                  Navigator.of(pickerContext).pop();
                  try {
                    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
                    if (photo != null) {
                      setSheetState(() {
                        selectedFiles.add(photo);
                      });
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi chụp ảnh: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Color(0xFFE94560)),
                title: const Text('Quay video mới (Record Video)'),
                onTap: () async {
                  Navigator.of(pickerContext).pop();
                  try {
                    final XFile? video = await picker.pickVideo(source: ImageSource.camera);
                    if (video != null) {
                      setSheetState(() {
                        selectedFiles.add(video);
                      });
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi quay video: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFFE94560)),
                title: const Text('Chọn ảnh từ thư viện (Gallery Images)'),
                onTap: () async {
                  Navigator.of(pickerContext).pop();
                  try {
                    final List<XFile>? images = await picker.pickMultiImage();
                    if (images != null && images.isNotEmpty) {
                      setSheetState(() {
                        selectedFiles.addAll(images);
                      });
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi chọn ảnh: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_collection, color: Color(0xFFE94560)),
                title: const Text('Chọn video từ thư viện (Gallery Video)'),
                onTap: () async {
                  Navigator.of(pickerContext).pop();
                  try {
                    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
                    if (video != null) {
                      setSheetState(() {
                        selectedFiles.add(video);
                      });
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi chọn video: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── WRITE A REVIEW BOTTOM SHEET ──
  void _showWriteReviewBottomSheet(BuildContext context, {ProductReview? existingReview}) {
    double selectedRating = existingReview?.rating ?? 0;
    final reviewTextController = TextEditingController(text: existingReview?.content ?? '');
    List<String> existingUrls = existingReview != null ? List<String>.from(existingReview.photos) : [];
    List<XFile> selectedFiles = [];
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pill handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Title
                    const Text(
                      'What is you rate?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Rating Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (idx) {
                        final val = idx + 1;
                        final isActive = val <= selectedRating;
                        return IconButton(
                          iconSize: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isActive ? Icons.star : Icons.star_border,
                            color: isActive ? Colors.amber : Colors.grey[400],
                          ),
                          onPressed: () {
                            setSheetState(() {
                              selectedRating = val.toDouble();
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Prompt text
                    const Text(
                      'Please share your opinion\nabout the product',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),

                    // Text Area input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: TextField(
                        controller: reviewTextController,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Your review',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Photo attachments row
                    SizedBox(
                      height: 72,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              _showAttachmentPicker(sheetContext, setSheetState, selectedFiles);
                            },
                            child: Container(
                              height: 64,
                              width: 64,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    color: Colors.black54,
                                    size: 20,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Add photos',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: existingUrls.length + selectedFiles.length,
                              itemBuilder: (context, index) {
                                if (index < existingUrls.length) {
                                  final photo = existingUrls[index];
                                  final isVid = isVideo(photo);
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    height: 64,
                                    width: 64,
                                    decoration: BoxDecoration(
                                      color: isVid ? Colors.black87 : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      image: isVid
                                          ? null
                                          : DecorationImage(
                                              image: photo.startsWith('assets/')
                                                  ? AssetImage(photo) as ImageProvider
                                                  : NetworkImage(
                                                      ApiService.getFullImageUrl(photo),
                                                      headers: const {'ngrok-skip-browser-warning': 'true'},
                                                    ),
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    child: Stack(
                                      children: [
                                        if (isVid)
                                          Center(
                                            child: Icon(
                                              Icons.play_circle_fill,
                                              color: Colors.white.withOpacity(0.8),
                                              size: 24,
                                            ),
                                          ),
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: GestureDetector(
                                            onTap: () {
                                              setSheetState(() {
                                                existingUrls.removeAt(index);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close, color: Colors.white, size: 10),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  );
                                } else {
                                  final fileIdx = index - existingUrls.length;
                                  final file = selectedFiles[fileIdx];
                                  final isVid = isVideo(file.name);
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    height: 64,
                                    width: 64,
                                    decoration: BoxDecoration(
                                      color: isVid ? Colors.black87 : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      image: isVid
                                          ? null
                                          : DecorationImage(
                                              image: kIsWeb
                                                  ? NetworkImage(file.path)
                                                  : FileImage(File(file.path)) as ImageProvider,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    child: Stack(
                                      children: [
                                        if (isVid)
                                          Center(
                                            child: Icon(
                                              Icons.play_circle_fill,
                                              color: Colors.white.withOpacity(0.8),
                                              size: 24,
                                            ),
                                          ),
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: GestureDetector(
                                            onTap: () {
                                              setSheetState(() {
                                                selectedFiles.removeAt(fileIdx);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close, color: Colors.white, size: 10),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SEND REVIEW Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: isUploading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
                          : ElevatedButton(
                              onPressed: () async {
                                if (selectedRating == 0) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    const SnackBar(content: Text('Please select a star rating!')),
                                  );
                                  return;
                                }
                                if (reviewTextController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    const SnackBar(content: Text('Please write your review feedback!')),
                                  );
                                  return;
                                }

                                setSheetState(() {
                                  isUploading = true;
                                });

                                try {
                                  // 1. Tải các ảnh mới chọn lên backend
                                  List<String> uploadedUrls = [];
                                  for (var file in selectedFiles) {
                                    final bytes = await file.readAsBytes();
                                    final url = await ApiService.uploadReviewFile(bytes, file.name);
                                    uploadedUrls.add(url);
                                  }

                                  final finalPhotos = [...existingUrls, ...uploadedUrls];

                                  if (existingReview != null) {
                                    // 2.a Gọi API cập nhật đánh giá
                                    await context.read<EcommerceProvider>().updateReview(
                                      productId: widget.productId,
                                      reviewId: existingReview.id!,
                                      rating: selectedRating,
                                      content: reviewTextController.text.trim(),
                                      photos: finalPhotos,
                                    );
                                  } else {
                                    // 2.b Tạo đối tượng review mới và gửi lên
                                    final now = DateTime.now();
                                    final months = [
                                      'January', 'February', 'March', 'April', 'May', 'June',
                                      'July', 'August', 'September', 'October', 'November', 'December'
                                    ];
                                    final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';

                                    final newReview = ProductReview(
                                      author: 'Me',
                                      avatar: 'assets/images/avata1.png',
                                      rating: selectedRating,
                                      date: dateStr,
                                      content: reviewTextController.text.trim(),
                                      photos: finalPhotos,
                                      helpfulCount: 0,
                                      isHelpful: false,
                                    );

                                    await context.read<EcommerceProvider>().addReview(widget.productId, newReview);
                                  }
                                  
                                  if (context.mounted) {
                                    Navigator.of(sheetContext).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(existingReview != null
                                            ? 'Thank you! Your review has been updated.'
                                            : 'Thank you! Your review has been submitted.'),
                                        backgroundColor: const Color(0xFF2E7D32),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                                      SnackBar(
                                        content: Text(existingReview != null
                                            ? 'Lỗi cập nhật đánh giá: $e'
                                            : 'Lỗi gửi đánh giá: $e'),
                                      ),
                                    );
                                  }
                                } finally {
                                  setSheetState(() {
                                    isUploading = false;
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE94560),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                existingReview != null ? 'UPDATE REVIEW' : 'SEND REVIEW',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
