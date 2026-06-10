import 'package:flutter/material.dart';
import 'brand_filter_screen.dart';

class FilterScreen extends StatefulWidget {
  final Map<String, dynamic> activeFilter;

  const FilterScreen({super.key, required this.activeFilter});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  // Filter state variables
  late RangeValues _priceRange;
  late Set<String> _selectedColors;
  late Set<String> _selectedSizes;
  late String _selectedCategory;
  late Set<String> _selectedBrands;

  // Custom fashion color options with their display colors
  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Black', 'color': Colors.black},
    {'name': 'White', 'color': Colors.white},
    {'name': 'Red', 'color': const Color(0xFFE94560)},
    {'name': 'Taupe', 'color': const Color(0xFFD4C5C0)},
    {'name': 'Beige', 'color': const Color(0xFFE8C2B0)},
    {'name': 'Navy', 'color': const Color(0xFF1E2F54)},
  ];

  final List<String> _sizeOptions = ['XS', 'S', 'M', 'L', 'XL'];
  final List<String> _categoryOptions = ['All', 'Women', 'Men', 'Boys', 'Girls'];

  @override
  void initState() {
    super.initState();
    // Copy incoming filter states
    final minPrice = (widget.activeFilter['minPrice'] as num?)?.toDouble() ?? 0.0;
    final maxPrice = (widget.activeFilter['maxPrice'] as num?)?.toDouble() ?? 300.0;
    _priceRange = RangeValues(minPrice, maxPrice);

    _selectedColors = Set<String>.from(widget.activeFilter['selectedColors'] ?? []);
    _selectedSizes = Set<String>.from(widget.activeFilter['selectedSizes'] ?? []);
    _selectedCategory = widget.activeFilter['selectedCategory'] ?? 'All';
    _selectedBrands = Set<String>.from(widget.activeFilter['selectedBrands'] ?? []);
  }

  void _discardFilters() {
    setState(() {
      _priceRange = const RangeValues(0.0, 300.0);
      _selectedColors.clear();
      _selectedSizes.clear();
      _selectedCategory = 'All';
      _selectedBrands.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filters reset to default values.'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _applyFilters() {
    final result = {
      'minPrice': _priceRange.start,
      'maxPrice': _priceRange.end,
      'selectedColors': _selectedColors.toList(),
      'selectedSizes': _selectedSizes.toList(),
      'selectedCategory': _selectedCategory,
      'selectedBrands': _selectedBrands.toList(),
    };
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Filters',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── PRICE RANGE SECTION ──
                const Text(
                  'Price range',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${_priceRange.start.round()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              '\$${_priceRange.end.round()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      RangeSlider(
                        values: _priceRange,
                        min: 0.0,
                        max: 300.0,
                        activeColor: const Color(0xFFE94560),
                        inactiveColor: Colors.black12,
                        onChanged: (RangeValues values) {
                          setState(() {
                            _priceRange = values;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── COLORS SECTION ──
                const Text(
                  'Colors',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                    itemCount: _colorOptions.length,
                    itemBuilder: (context, index) {
                      final name = _colorOptions[index]['name'] as String;
                      final color = _colorOptions[index]['color'] as Color;
                      final isSelected = _selectedColors.contains(name);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedColors.remove(name);
                            } else {
                              _selectedColors.add(name);
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFE94560)
                                  : (color == Colors.white ? Colors.black12 : Colors.transparent),
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: color == Colors.white ? Colors.black87 : Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // ── SIZES SECTION ──
                const Text(
                  'Sizes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _sizeOptions.map((size) {
                      final isSelected = _selectedSizes.contains(size);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedSizes.remove(size);
                            } else {
                              _selectedSizes.add(size);
                            }
                          });
                        },
                        child: Container(
                          width: 46,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFE94560) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFE94560) : Colors.black12,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              size,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // ── CATEGORY SECTION ──
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _categoryOptions.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFE94560) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFE94560) : Colors.black12,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // ── BRAND NAVIGATION SECTION ──
                GestureDetector(
                  onTap: () async {
                    final selected = await Navigator.of(context).push<Set<String>>(
                      MaterialPageRoute(
                        builder: (_) => BrandFilterScreen(selectedBrands: _selectedBrands),
                      ),
                    );
                    if (selected != null) {
                      setState(() {
                        _selectedBrands = selected;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Brand',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                            ),
                            if (_selectedBrands.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                _selectedBrands.join(', '),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ]
                          ],
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // ── BOTTOM ACTIONS BAR ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _discardFilters,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.black38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Discard',
                            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE94560),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
