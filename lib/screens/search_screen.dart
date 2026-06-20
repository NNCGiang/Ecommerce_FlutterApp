import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'product_detail_screen.dart';

// ─── Search flow states ────────────────────────────────────────────────────────
enum _SearchState {
  landing,      // Screen 1: Visual search landing
  photoPreview, // Screen 2: Full screen image preview
  cropMode,     // Screen 3: Crop overlay
  loading,      // Screen 4: Finding similar results...
  textResults,  // Text search results grid
  imageResults, // Image search results grid
  error,        // Error state
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  // ── State ───────────────────────────────────────────────────────────────────
  _SearchState _state = _SearchState.landing;
  XFile? _pickedImage;
  List<dynamic> _results = [];
  String _errorMessage = '';
  String _currentQuery = '';
  String? _matchedType;
  Size _displaySize = Size.zero;
  String _selectedClothingTag = 'shirt';

  // ── Text search ─────────────────────────────────────────────────────────────
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _queryFocus = FocusNode();
  Timer? _debounce;
  bool _showTextSearch = false;

  // ── Animation for loading icon ───────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // ── Crop box drag state ──────────────────────────────────────────────────────
  Rect _cropRect = const Rect.fromLTWH(40, 80, 280, 360);
  bool _isDraggingCrop = false;
  Offset _dragStart = Offset.zero;
  Rect _cropRectStart = Rect.zero;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    _queryFocus.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _goBack() {
    switch (_state) {
      case _SearchState.photoPreview:
        setState(() { _state = _SearchState.landing; _pickedImage = null; });
      case _SearchState.cropMode:
        setState(() => _state = _SearchState.photoPreview);
      case _SearchState.loading:
        setState(() => _state = _SearchState.landing);
      case _SearchState.imageResults:
      case _SearchState.textResults:
        setState(() {
          _state = _SearchState.landing;
          _pickedImage = null;
          _results = [];
          _currentQuery = '';
          _queryController.clear();
          _showTextSearch = false;
        });
      case _SearchState.error:
        setState(() {
          _state = _SearchState.landing;
          _errorMessage = '';
          _pickedImage = null;
        });
      case _SearchState.landing:
        Navigator.pop(context);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1080,
      );
      if (picked == null) return;
      if (!mounted) return;
      setState(() {
        _pickedImage = picked;
        _state = _SearchState.photoPreview;
        // Reset crop rect
        _cropRect = const Rect.fromLTWH(40, 80, 280, 360);
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not open camera/gallery. Please try again.';
          _state = _SearchState.error;
        });
      }
    }
  }

  Future<void> _runImageSearch() async {
    if (_pickedImage == null) return;
    setState(() => _state = _SearchState.loading);
    try {
      final bytes = await _pickedImage!.readAsBytes();
      Uint8List uploadBytes = bytes;
      if (_displaySize.width > 0 && _displaySize.height > 0) {
        try {
          uploadBytes = await _cropImage(bytes, _cropRect, _displaySize);
        } catch (e) {
          // Fallback to original if crop fails
        }
      }
      final data = await ApiService.searchByImage(uploadBytes, 'cropped_${_selectedClothingTag}_${_pickedImage!.name}');
      if (!mounted) return;
      setState(() {
        _results = (data['results'] as List?) ?? [];
        _matchedType = data['matchedType'] as String?;
        _state = _SearchState.imageResults;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _state = _SearchState.error;
      });
    }
  }

  Future<Uint8List> _cropImage(Uint8List originalBytes, Rect cropRect, Size displaySize) async {
    final codec = await ui.instantiateImageCodec(originalBytes);
    final frame = await codec.getNextFrame();
    final ui.Image originalImage = frame.image;

    final double origW = originalImage.width.toDouble();
    final double origH = originalImage.height.toDouble();

    final double displayW = displaySize.width;
    final double displayH = displaySize.height;

    final double displayAspect = displayW / displayH;
    final double imageAspect = origW / origH;

    double scale;
    double dx = 0;
    double dy = 0;

    if (imageAspect > displayAspect) {
      scale = displayH / origH;
      dx = (displayW - origW * scale) / 2;
    } else {
      scale = displayW / origW;
      dy = (displayH - origH * scale) / 2;
    }

    final double actualLeft = (cropRect.left - dx) / scale;
    final double actualTop = (cropRect.top - dy) / scale;
    final double actualWidth = cropRect.width / scale;
    final double actualHeight = cropRect.height / scale;

    final double cropLeft = actualLeft.clamp(0.0, origW);
    final double cropTop = actualTop.clamp(0.0, origH);
    final double cropW = actualWidth.clamp(1.0, origW - cropLeft);
    final double cropH = actualHeight.clamp(1.0, origH - cropTop);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..filterQuality = FilterQuality.high;

    canvas.drawImageRect(
      originalImage,
      Rect.fromLTWH(cropLeft, cropTop, cropW, cropH),
      Rect.fromLTWH(0, 0, cropW, cropH),
      paint,
    );

    final picture = recorder.endRecording();
    final croppedImage = await picture.toImage(cropW.round(), cropH.round());
    final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  String _estimateClothingType(Rect cropRect, Size displaySize) {
    if (displaySize.width <= 0 || displaySize.height <= 0) return 'shirt';

    final double centerY = cropRect.center.dy / displaySize.height;
    final double heightRatio = cropRect.height / displaySize.height;
    final double widthRatio = cropRect.width / displaySize.width;
    final double aspectRatio = cropRect.width / cropRect.height;

    // 1. Shoes: bottom part of the body
    if (centerY > 0.78 || (cropRect.bottom / displaySize.height > 0.85 && heightRatio < 0.28)) {
      return 'shoes';
    }

    // 2. Full Dress: occupies a large vertical span of the screen
    if (heightRatio > 0.55 && centerY > 0.3 && centerY < 0.7) {
      return 'dress';
    }

    // 3. Lower body: Jeans / Pants or Dress / Skirt
    if (centerY > 0.48) {
      if (aspectRatio > 0.75) {
        return 'dress'; // Matches skirts, dresses
      } else {
        return 'jeans'; // Matches pants, trousers, jeans
      }
    }

    // 4. Upper body: Jacket or Shirt
    if (heightRatio > 0.35 || widthRatio > 0.7) {
      return 'jacket';
    }

    return 'shirt';
  }

  void _initializeCropTag() {
    if (_pickedImage == null) return;
    final name = _pickedImage!.name.toLowerCase();
    String? found;
    // Check key in clothing keywords
    for (var entry in {
      'shirt': ['shirt', 'blouse', 'top', 'tshirt', 't-shirt', 'polo'],
      'jeans': ['jean', 'pant', 'trouser', 'denim', 'slack', 'chino', 'legging'],
      'dress': ['dress', 'gown', 'skirt', 'frock', 'sundress', 'maxi', 'midi'],
      'jacket': ['jacket', 'coat', 'outerwear', 'blazer', 'cardigan', 'hoodie', 'sweater'],
      'shoes': ['shoe', 'sneaker', 'boot', 'sandal', 'heel', 'loafer', 'flat'],
      'bag': ['bag', 'purse', 'handbag', 'tote', 'backpack', 'clutch'],
    }.entries) {
      for (var kw in entry.value) {
        if (name.contains(kw)) {
          found = entry.key;
          break;
        }
      }
      if (found != null) break;
    }

    if (found != null) {
      _selectedClothingTag = found;
    } else {
      _selectedClothingTag = _estimateClothingType(_cropRect, _displaySize);
    }
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() { _results = []; _currentQuery = ''; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _performTextSearch(value.trim());
    });
  }

  Future<void> _performTextSearch(String query) async {
    setState(() {
      _currentQuery = query;
      _state = _SearchState.loading;
      _pickedImage = null;
    });
    try {
      final data = await ApiService.searchProducts(query);
      if (!mounted) return;
      setState(() {
        _results = (data['results'] as List?) ?? [];
        _state = _SearchState.textResults;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _state = _SearchState.error;
      });
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildCurrentState(),
      ),
    );
  }

  Widget _buildCurrentState() {
    switch (_state) {
      case _SearchState.landing:
        return _buildLanding();
      case _SearchState.photoPreview:
        return _buildPhotoPreview();
      case _SearchState.cropMode:
        return _buildCropMode();
      case _SearchState.loading:
        return _buildLoading();
      case _SearchState.textResults:
      case _SearchState.imageResults:
        return _buildResults();
      case _SearchState.error:
        return _buildError();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SCREEN 1: Visual Search Landing
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildLanding() {
    final size = MediaQuery.of(context).size;
    return Stack(
      key: const ValueKey('landing'),
      children: [
        // Full screen background image
        SizedBox.expand(
          child: Image.asset(
            'assets/images/backroundSearch.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        // Grey overlay covering the background image (lớp mờ xám)
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        // Main content in a Column using Positioned.fill and SafeArea
        Positioned.fill(
          child: SafeArea(
            child: Column(
              children: [
                // AppBar portion
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      onPressed: _goBack,
                    ),
                    Expanded(
                      child: _showTextSearch
                          ? _buildInlineSearchField()
                          : const Text(
                              'Visual search',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    // Search toggle icon
                    IconButton(
                      icon: Icon(
                        _showTextSearch ? Icons.close : Icons.search,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _showTextSearch = !_showTextSearch;
                          if (_showTextSearch) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _queryFocus.requestFocus();
                            });
                          } else {
                            _queryController.clear();
                            _queryFocus.unfocus();
                            _results = [];
                            _currentQuery = '';
                          }
                        });
                      },
                    ),
                  ],
                ),
                // Centered content (Text and Buttons grouped together)
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Description text
                            const Text(
                              'Search for an outfit by\ntaking a photo or uploading\nan image',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                                shadows: [
                                  Shadow(color: Colors.black87, blurRadius: 12, offset: Offset(0, 2)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 36),
                            // TAKE A PHOTO button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () => _pickImage(ImageSource.camera),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE94560),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: const Text(
                                  'TAKE A PHOTO',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            // UPLOAD AN IMAGE button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                onPressed: () => _pickImage(ImageSource.gallery),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: const Text(
                                  'UPLOAD AN IMAGE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Inline text search results overlay
        if (_showTextSearch && (_results.isNotEmpty || _currentQuery.isNotEmpty))
          _buildInlineResultsOverlay(size),
      ],
    );
  }

  Widget _buildInlineSearchField() {
    return TextField(
      controller: _queryController,
      focusNode: _queryFocus,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: const InputDecoration(
        hintText: 'Search clothing...',
        hintStyle: TextStyle(color: Colors.white54),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 8),
      ),
      textInputAction: TextInputAction.search,
      onChanged: _onTextChanged,
      onSubmitted: (v) {
        if (v.trim().isNotEmpty) _performTextSearch(v.trim());
      },
    );
  }

  Widget _buildInlineResultsOverlay(Size size) {
    return Positioned(
      top: kToolbarHeight + MediaQuery.of(context).padding.top + 4,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: Colors.black.withValues(alpha: 0.92),
        child: _results.isEmpty
            ? const Center(
                child: Text(
                  'No results found',
                  style: TextStyle(color: Colors.white60, fontSize: 15),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _results.length,
                itemBuilder: (context, i) => _buildProductCard(_results[i], darkMode: true),
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SCREEN 2: Full Screen Photo Preview ("Search by taking a photo")
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildPhotoPreview() {
    return Scaffold(
      key: const ValueKey('photoPreview'),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: _goBack,
        ),
        title: const Text(
          'Search by taking a photo',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Image container
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey.shade900,
              child: _pickedImage != null
                  ? (kIsWeb
                      ? Image.network(_pickedImage!.path, fit: BoxFit.cover)
                      : Image.file(File(_pickedImage!.path), fit: BoxFit.cover))
                  : const Center(
                      child: Text(
                        'No image selected',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ),
            ),
          ),
          // White Bottom Bar matching mockup
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flash button (mock)
                IconButton(
                  icon: const Icon(Icons.flash_on, color: Colors.black87, size: 26),
                  onPressed: () {
                    // Flash toggle placeholder
                  },
                ),
                // Camera / Confirm button (Red circle with white camera icon)
                GestureDetector(
                  onTap: () {
                    _initializeCropTag();
                    setState(() => _state = _SearchState.cropMode);
                  },
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE94560), // Red color from mockup
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                // Refresh / Retake button
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black87, size: 26),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ─────────────────────────────────────────────────────────────────────────────
  // SCREEN 3: Crop the item
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildCropMode() {
    return Stack(
      key: const ValueKey('crop'),
      children: [
        // Full screen image
        Positioned.fill(
          child: _pickedImage != null
              ? (kIsWeb
                  ? Image.network(_pickedImage!.path, fit: BoxFit.cover)
                  : Image.file(File(_pickedImage!.path), fit: BoxFit.cover))
              : Container(color: Colors.grey.shade900),
        ),
        // Dark overlay around crop rect (simple approach: 4 rects)
        _buildCropOverlay(),
        // AppBar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  onPressed: _goBack,
                ),
                const Expanded(
                  child: Text(
                    'Crop the item',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
        // AI Detected Tags horizontal bar
        Positioned(
          bottom: 120, // Nằm trên nút tìm kiếm khoảng 80px
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AI detected hint text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.psychology, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'AI Detected: ${_selectedClothingTag.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Tags horizontal scroll list
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    'shirt',
                    'jeans',
                    'dress',
                    'jacket',
                    'shoes',
                    'bag'
                  ].map((tag) {
                    final isSelected = _selectedClothingTag == tag;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(
                          tag.toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFFE94560),
                        backgroundColor: Colors.black54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFFE94560) : Colors.white24,
                            width: 1,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedClothingTag = tag;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        // Red search button at bottom center
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _runImageSearch,
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFE94560),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x66E94560),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.search, color: Colors.white, size: 30),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCropOverlay() {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      _displaySize = Size(w, h);
      final crop = _cropRect;
      return Stack(
        children: [
          // Dark overlay using CustomPainter
          Positioned.fill(
            child: GestureDetector(
              onPanStart: (details) {
                // Check if inside crop rect
                if (crop.contains(details.localPosition)) {
                  setState(() {
                    _isDraggingCrop = true;
                    _dragStart = details.localPosition;
                    _cropRectStart = _cropRect;
                  });
                }
              },
              onPanUpdate: (details) {
                if (_isDraggingCrop) {
                  final delta = details.localPosition - _dragStart;
                  setState(() {
                    _cropRect = _cropRectStart.translate(delta.dx, delta.dy);
                    // clamp
                    if (_cropRect.left < 0) _cropRect = _cropRect.translate(-_cropRect.left, 0);
                    if (_cropRect.top < 0) _cropRect = _cropRect.translate(0, -_cropRect.top);
                    if (_cropRect.right > w) _cropRect = _cropRect.translate(w - _cropRect.right, 0);
                    if (_cropRect.bottom > h) _cropRect = _cropRect.translate(0, h - _cropRect.bottom);
                  });
                }
              },
              onPanEnd: (_) => setState(() => _isDraggingCrop = false),
              child: CustomPaint(
                painter: _CropOverlayPainter(cropRect: _cropRect),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          // Corner handles with drag resize capability
          _cornerHandle(pos: _cropRect.topLeft, isTop: true, isLeft: true, maxWidth: w, maxHeight: h),
          _cornerHandle(pos: _cropRect.topRight, isTop: true, isLeft: false, maxWidth: w, maxHeight: h),
          _cornerHandle(pos: _cropRect.bottomLeft, isTop: false, isLeft: true, maxWidth: w, maxHeight: h),
          _cornerHandle(pos: _cropRect.bottomRight, isTop: false, isLeft: false, maxWidth: w, maxHeight: h),
        ],
      );
    });
  }

  Widget _cornerHandle({
    required Offset pos,
    required bool isTop,
    required bool isLeft,
    required double maxWidth,
    required double maxHeight,
  }) {
    // 36x36 tap area centered on the corner
    return Positioned(
      left: pos.dx - 18,
      top: pos.dy - 18,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          setState(() {
            double left = _cropRect.left;
            double top = _cropRect.top;
            double right = _cropRect.right;
            double bottom = _cropRect.bottom;

            final dx = details.delta.dx;
            final dy = details.delta.dy;

            if (isLeft) {
              left = (left + dx).clamp(0.0, right - 50.0);
            } else {
              right = (right + dx).clamp(left + 50.0, maxWidth);
            }

            if (isTop) {
              top = (top + dy).clamp(0.0, bottom - 50.0);
            } else {
              bottom = (bottom + dy).clamp(top + 50.0, maxHeight);
            }

            _cropRect = Rect.fromLTRB(left, top, right, bottom);
          });
        },
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black26, width: 1),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SCREEN 4: Finding similar results...
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildLoading() {
    return Scaffold(
      key: const ValueKey('loading'),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black87),
                onPressed: _goBack,
              ),
            ),
            const Spacer(),
            // Animated search icon
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE0E6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search, color: Color(0xFFE94560), size: 42),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Finding similar\nresults...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111111),
                height: 1.35,
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Results Grid
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildResults() {
    final isImage = _state == _SearchState.imageResults;
    return Scaffold(
      key: const ValueKey('results'),
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black87),
          onPressed: _goBack,
        ),
        title: Text(
          isImage
              ? (_matchedType != null ? 'Results for: $_matchedType' : 'Visual Search Results')
              : 'Results for "$_currentQuery"',
          style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                '${_results.length} items',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: _results.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    isImage ? 'No matching items found' : 'No results for "$_currentQuery"',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _results.length,
              itemBuilder: (context, i) => _buildProductCard(_results[i]),
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Error
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Scaffold(
      key: const ValueKey('error'),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black87),
          onPressed: _goBack,
        ),
        title: const Text('Search', style: TextStyle(color: Colors.black87)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE0E6),
                  borderRadius: BorderRadius.circular(36),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFE94560), size: 38),
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Color(0xFF555555), height: 1.5),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _goBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE94560),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
                ),
                child: const Text('Try again', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Product Card
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildProductCard(dynamic product, {bool darkMode = false}) {
    final name = product['productName']?.toString() ?? '';
    final price = (product['salePrice'] as num?)?.toDouble() ?? 0.0;
    final comparePrice = (product['comparePrice'] as num?)?.toDouble();
    final thumbnail = product['thumbnail']?.toString() ?? '';
    final tags = (product['tags'] as List?)?.map((t) => t.toString()).toList() ?? [];
    final isSale = comparePrice != null && price < comparePrice;
    final isNew = tags.contains('NEW');

    final cardBg = darkMode ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = darkMode ? Colors.white : const Color(0xFF1A1A2E);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product as Map<String, dynamic>),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: darkMode ? 0.3 : 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 170,
                    width: double.infinity,
                    child: _buildProductImage(thumbnail),
                  ),
                  if (isSale || isNew)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSale ? const Color(0xFFE94560) : const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isSale ? 'SALE' : 'NEW',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '\$${price.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE94560)),
                      ),
                      if (isSale) ...[
                        const SizedBox(width: 6),
                        Text(
                          '\$${comparePrice.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String thumbnail) {
    if (thumbnail.isEmpty) {
      return Container(color: Colors.grey.shade200, child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 36));
    }
    if (thumbnail.startsWith('http')) {
      return Image.network(
        thumbnail,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200, child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 36)),
      );
    }
    return Image.asset(
      thumbnail,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200, child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 36)),
    );
  }
}

// ─── Crop Overlay Painter ────────────────────────────────────────────────────
class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  _CropOverlayPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final darkPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);

    // Draw dark overlay in 4 regions around the crop rect
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, cropRect.top), darkPaint);
    canvas.drawRect(Rect.fromLTWH(0, cropRect.top, cropRect.left, cropRect.height), darkPaint);
    canvas.drawRect(Rect.fromLTWH(cropRect.right, cropRect.top, size.width - cropRect.right, cropRect.height), darkPaint);
    canvas.drawRect(Rect.fromLTWH(0, cropRect.bottom, size.width, size.height - cropRect.bottom), darkPaint);

    // Draw white border around crop rect
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(cropRect, borderPaint);

    // Draw corner accent lines (thicker)
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square;

    const cornerLen = 24.0;
    // Top-left
    canvas.drawLine(cropRect.topLeft, cropRect.topLeft + const Offset(cornerLen, 0), cornerPaint);
    canvas.drawLine(cropRect.topLeft, cropRect.topLeft + const Offset(0, cornerLen), cornerPaint);
    // Top-right
    canvas.drawLine(cropRect.topRight, cropRect.topRight + const Offset(-cornerLen, 0), cornerPaint);
    canvas.drawLine(cropRect.topRight, cropRect.topRight + const Offset(0, cornerLen), cornerPaint);
    // Bottom-left
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft + const Offset(cornerLen, 0), cornerPaint);
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft + const Offset(0, -cornerLen), cornerPaint);
    // Bottom-right
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight + const Offset(-cornerLen, 0), cornerPaint);
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight + const Offset(0, -cornerLen), cornerPaint);
  }

  @override
  bool shouldRepaint(_CropOverlayPainter old) => old.cropRect != cropRect;
}
