import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';

class LeaveFeedbackScreen extends StatefulWidget {
  final List<dynamic> items;
  const LeaveFeedbackScreen({super.key, required this.items});

  @override
  State<LeaveFeedbackScreen> createState() => _LeaveFeedbackScreenState();
}

class _LeaveFeedbackScreenState extends State<LeaveFeedbackScreen> {
  final Map<String, double> _ratings = {}; // Map of productId -> rating
  final Map<String, TextEditingController> _controllers = {}; // Map of productId -> TextEditingController
  final Map<String, List<XFile>> _selectedFiles = {}; // Map of productId -> list of local files
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize rating and controllers for each product
    for (var item in widget.items) {
      final productId = (item['productId'] ?? '').toString();
      if (productId.isNotEmpty) {
        _ratings[productId] = 0.0;
        _controllers[productId] = TextEditingController();
        _selectedFiles[productId] = [];
      }
    }
  }

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final activeReviews = widget.items.where((item) {
      final pId = (item['productId'] ?? '').toString();
      final rating = _ratings[pId] ?? 0.0;
      return rating > 0.0;
    }).toList();

    if (activeReviews.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn số sao đánh giá cho ít nhất một sản phẩm!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthProvider>();
      final user = auth.user;
      final authorName = user?['fullName'] ?? 'Anonymous';

      for (var item in activeReviews) {
        final pId = (item['productId'] ?? '').toString();
        final rating = _ratings[pId] ?? 0.0;
        final comment = _controllers[pId]?.text.trim() ?? '';

        final List<String> photoUrls = [];
        final localFiles = _selectedFiles[pId] ?? [];
        for (var file in localFiles) {
          try {
            final bytes = await file.readAsBytes();
            final url = await ApiService.uploadReviewFile(bytes, file.name);
            photoUrls.add(url);
          } catch (uploadError) {
            debugPrint('Error uploading file ${file.name}: $uploadError');
            throw Exception('Không thể tải file ${file.name} lên server: $uploadError');
          }
        }

        await ApiService.addReview(
          productId: pId,
          author: authorName,
          rating: rating,
          content: comment.isEmpty ? 'Tuyệt vời!' : comment,
          photos: photoUrls,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi đánh giá thành công! Cảm ơn ý kiến của bạn.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi đánh giá: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Leave Feedback',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isSubmitting
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF3B30)))
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.items.length,
                      itemBuilder: (context, index) {
                        final item = widget.items[index];
                        final pId = (item['productId'] ?? '').toString();
                        final name = item['productName'] ?? '';
                        final size = item['size'] ?? 'L';
                        final color = item['color'] ?? 'Gray';
                        final thumbnail = item['thumbnail'];
                        final rating = _ratings[pId] ?? 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product info row
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey.shade100,
                                      child: _buildProductImage(thumbnail),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Size: $size  Color: $color',
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Star rating selector
                              const Text(
                                'Đánh giá số sao:',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: List.generate(5, (starIdx) {
                                  final starValue = starIdx + 1.0;
                                  final isLit = rating >= starValue;
                                  return IconButton(
                                    icon: Icon(
                                      isLit ? Icons.star : Icons.star_border,
                                      color: isLit ? Colors.amber : Colors.grey.shade400,
                                      size: 32,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _ratings[pId] = starValue;
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  );
                                }),
                              ),
                              const SizedBox(height: 12),

                              // Feedback Text Field
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9F9F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                child: TextField(
                                  controller: _controllers[pId],
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'Nhận xét về sản phẩm này...',
                                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                    border: InputBorder.none,
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Photo attachments row
                              SizedBox(
                                height: 72,
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showAttachmentPicker(context, pId),
                                      child: Container(
                                        height: 64,
                                        width: 64,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade300),
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
                                              'Add media',
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
                                        itemCount: _selectedFiles[pId]?.length ?? 0,
                                        itemBuilder: (context, fileIdx) {
                                          final file = _selectedFiles[pId]![fileIdx];
                                          final isVid = _isVideoFile(file);
                                          return Container(
                                            margin: const EdgeInsets.only(right: 8),
                                            height: 64,
                                            width: 64,
                                            decoration: BoxDecoration(
                                              color: isVid ? Colors.black87 : Colors.grey[200],
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: Stack(
                                              children: [
                                                Positioned.fill(
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: isVid
                                                        ? const Center(
                                                            child: Icon(
                                                              Icons.play_circle_fill,
                                                              color: Colors.white,
                                                              size: 28,
                                                            ),
                                                          )
                                                        : Image.file(
                                                            File(file.path),
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (_, __, ___) => const Center(
                                                              child: Icon(Icons.broken_image, size: 20, color: Colors.grey),
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 2,
                                                  right: 2,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        _selectedFiles[pId]?.removeAt(fileIdx);
                                                      });
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.black.withOpacity(0.6),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      padding: const EdgeInsets.all(2),
                                                      child: const Icon(
                                                        Icons.close,
                                                        color: Colors.white,
                                                        size: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Action Buttons
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF3B30),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: _submitFeedback,
                        child: const Text(
                          'SUBMIT FEEDBACK',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  bool _isVideoFile(XFile file) {
    final p = file.path.toLowerCase();
    return p.endsWith('.mp4') ||
        p.endsWith('.mov') ||
        p.endsWith('.avi') ||
        p.endsWith('.mkv') ||
        p.endsWith('.webm') ||
        p.endsWith('.3gp');
  }

  void _showAttachmentPicker(BuildContext context, String pId) {
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
                  try {
                    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
                    if (photo != null) {
                      setState(() {
                        _selectedFiles[pId]?.add(photo);
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
                leading: const Icon(Icons.videocam, color: Color(0xFFFF3B30)),
                title: const Text('Quay video mới (Record Video)'),
                onTap: () async {
                  Navigator.of(pickerContext).pop();
                  try {
                    final XFile? video = await picker.pickVideo(source: ImageSource.camera);
                    if (video != null) {
                      setState(() {
                        _selectedFiles[pId]?.add(video);
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
                leading: const Icon(Icons.photo_library, color: Color(0xFFFF3B30)),
                title: const Text('Chọn ảnh từ thư viện (Gallery Images)'),
                onTap: () async {
                  Navigator.of(pickerContext).pop();
                  try {
                    final List<XFile>? images = await picker.pickMultiImage();
                    if (images != null && images.isNotEmpty) {
                      setState(() {
                        _selectedFiles[pId]?.addAll(images);
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
                leading: const Icon(Icons.video_collection, color: Color(0xFFFF3B30)),
                title: const Text('Chọn video từ thư viện (Gallery Video)'),
                onTap: () async {
                  Navigator.of(pickerContext).pop();
                  try {
                    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
                    if (video != null) {
                      setState(() {
                        _selectedFiles[pId]?.add(video);
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

  Widget _buildProductImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const Center(child: Icon(Icons.image_outlined, size: 24, color: Colors.grey));
    }
    String cleanPath = imagePath.trim();
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return Image.network(
        cleanPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image, size: 24, color: Colors.grey)),
      );
    } else if (cleanPath.contains('assets/')) {
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }
      return Image.asset(
        cleanPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image, size: 24, color: Colors.grey)),
      );
    } else {
      // It's a server uploaded path like "/uploads/xxx.png"
      final fullUrl = ApiService.getFullImageUrl(cleanPath);
      return Image.network(
        fullUrl,
        headers: const {'ngrok-skip-browser-warning': 'true'},
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image, size: 24, color: Colors.grey)),
      );
    }
  }
}
