import 'package:flutter/material.dart';

class BrandFilterScreen extends StatefulWidget {
  final Set<String> selectedBrands;

  const BrandFilterScreen({super.key, required this.selectedBrands});

  @override
  State<BrandFilterScreen> createState() => _BrandFilterScreenState();
}

class _BrandFilterScreenState extends State<BrandFilterScreen> {
  late Set<String> _tempSelectedBrands;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _allBrands = [
    'adidas',
    'adidas Originals',
    'Blend',
    'Boutique Moschino',
    'Champion',
    'Diesel',
    'Jack & Jones',
    'Naf Naf',
    'Red Valentino',
    's.Oliver',
  ];

  @override
  void initState() {
    super.initState();
    _tempSelectedBrands = Set<String>.from(widget.selectedBrands);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _discardBrands() {
    setState(() {
      _tempSelectedBrands.clear();
    });
  }

  void _applyBrands() {
    Navigator.of(context).pop(_tempSelectedBrands);
  }

  @override
  Widget build(BuildContext context) {
    // Filter brands based on query
    final filteredBrands = _allBrands.where((brand) {
      return brand.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Brand',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ── SEARCH BAR ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),

              // ── BRAND LIST WITH CHECKBOXES ──
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
                  itemCount: filteredBrands.length,
                  itemBuilder: (context, index) {
                    final brand = filteredBrands[index];
                    final isChecked = _tempSelectedBrands.contains(brand);

                    return Column(
                      children: [
                        CheckboxListTile(
                          activeColor: const Color(0xFFE94560),
                          title: Text(
                            brand,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isChecked ? FontWeight.bold : FontWeight.w500,
                              color: isChecked ? const Color(0xFFE94560) : Colors.black87,
                            ),
                          ),
                          value: isChecked,
                          controlAffinity: ListTileControlAffinity.trailing,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _tempSelectedBrands.add(brand);
                              } else {
                                _tempSelectedBrands.remove(brand);
                              }
                            });
                          },
                        ),
                        const Divider(height: 1, thickness: 0.5, color: Colors.black12),
                      ],
                    );
                  },
                ),
              ),
            ],
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
                          onPressed: _discardBrands,
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
                          onPressed: _applyBrands,
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
