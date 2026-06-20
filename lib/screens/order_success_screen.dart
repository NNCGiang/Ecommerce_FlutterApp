import 'package:flutter/material.dart';
import 'home_screen.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Custom bags illustration in the center
              ScaleTransition(
                scale: _scaleAnimation,
                child: _buildBagsIllustration(),
              ),
              const SizedBox(height: 36),

              // Fade-in text
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Text(
                      'Success!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your order will be delivered soon.\nThank you for choosing our app!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Continue shopping button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B30),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'CONTINUE SHOPPING',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBagsIllustration() {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti pieces
          ..._buildConfettiList(),
          // Orange bag
          Transform.translate(
            offset: const Offset(-25, -5),
            child: Transform.rotate(
              angle: -0.15,
              child: _buildShoppingBag(
                color: const Color(0xFFFF9500),
                height: 90,
                width: 70,
                handleColor: const Color(0xFFFFCC00),
              ),
            ),
          ),
          // Red bag
          Transform.translate(
            offset: const Offset(20, 15),
            child: Transform.rotate(
              angle: 0.1,
              child: _buildShoppingBag(
                color: const Color(0xFFFF3B30),
                height: 110,
                width: 85,
                handleColor: const Color(0xFFFF9500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildConfettiList() {
    final confetti = [
      _ConfettiData(-80, -40, const Color(0xFFFFCC00), 10, 0.5, true),
      _ConfettiData(-100, 20, const Color(0xFFFF3B30), 8, -0.2, false),
      _ConfettiData(-50, -80, const Color(0xFF007AFF), 6, 0.8, false),
      _ConfettiData(80, -30, const Color(0xFFFF9500), 12, -0.4, true),
      _ConfettiData(110, 30, const Color(0xFF4CD964), 9, 0.3, false),
      _ConfettiData(50, -70, const Color(0xFFFF2D55), 7, -0.6, true),
      _ConfettiData(-30, 90, const Color(0xFF5AC8FA), 8, 0.1, false),
      _ConfettiData(70, 90, const Color(0xFF5856D6), 10, -0.8, true),
    ];

    return confetti.map((c) {
      return Transform.translate(
        offset: Offset(c.x, c.y),
        child: Transform.rotate(
          angle: c.angle,
          child: Container(
            width: c.size,
            height: c.isRect ? c.size * 1.5 : c.size,
            decoration: BoxDecoration(
              color: c.color,
              shape: c.isRect ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: c.isRect ? BorderRadius.circular(2) : null,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildShoppingBag({
    required Color color,
    required double height,
    required double width,
    required Color handleColor,
  }) {
    return Container(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Bag Handle
          Positioned(
            top: -16,
            child: Container(
              width: width * 0.45,
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: handleColor.withOpacity(0.8), width: 3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
          ),
          // Bag Body
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiData {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double angle;
  final bool isRect;

  _ConfettiData(this.x, this.y, this.color, this.size, this.angle, this.isRect);
}
