import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class BillingIllustration extends StatefulWidget {
  const BillingIllustration({super.key});

  @override
  State<BillingIllustration> createState() => _BillingIllustrationState();
}

class _BillingIllustrationState extends State<BillingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3E53),
            Color(0xFF142B3A),
            Color(0xFF0F1E29),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background Decorative Gradients / Glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: InvoiceBillTheme.primaryBlue.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: InvoiceBillTheme.accentBlue.withOpacity(0.08),
              ),
            ),
          ),

          // Main Layout Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: InvoiceBillTheme.primaryBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: InvoiceBillTheme.primaryBlue.withOpacity(0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: InvoiceBillTheme.accentBlue,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "InvoiceBill",
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 1),

                  // Animated Dashboard Illustration Screen
                  Center(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final value = _controller.value;
                        return SizedBox(
                          height: 340,
                          width: 440,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              // Layer 1: Glassmorphism Main Board (Background)
                              Positioned(
                                top: 20 + (math.sin(value * math.pi * 2) * 5),
                                child: Container(
                                  width: 360,
                                  height: 240,
                                  decoration: InvoiceBillTheme.glassDecoration,
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Dashboard header simulation
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            width: 100,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ),
                                          Row(
                                            children: List.generate(
                                              3,
                                              (index) => Container(
                                                margin: const EdgeInsets.only(left: 6),
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white.withOpacity(0.15),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      // Chart Bars
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            _buildChartBar(30, value, 0.4),
                                            _buildChartBar(55, value, 0.6),
                                            _buildChartBar(40, value, 0.8),
                                            _buildChartBar(75, value, 1.0),
                                            _buildChartBar(60, value, 0.5),
                                            _buildChartBar(90, value, 0.7),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Layer 2: Floating Active Invoice Card (Bottom Left)
                              Positioned(
                                left: -10,
                                bottom: 20 + (math.cos(value * math.pi * 2) * 8),
                                child: Container(
                                  width: 200,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      )
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "INV-2026-04",
                                            style: TextStyle(
                                              color: InvoiceBillTheme.textMuted,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: InvoiceBillTheme.successGreen.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              "PAID",
                                              style: TextStyle(
                                                color: InvoiceBillTheme.successGreen,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                      const Text(
                                        "\$12,450.00",
                                        style: TextStyle(
                                          color: InvoiceBillTheme.textDark,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const CircleAvatar(
                                            radius: 8,
                                            backgroundColor: Color(0xFFF3F4F6),
                                            child: Text(
                                              "A",
                                              style: TextStyle(
                                                  fontSize: 6, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Acme Enterprise",
                                            style: GoogleFonts.plusJakartaSans(
                                              color: InvoiceBillTheme.textDark,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Layer 3: Floating Payment Circular Badge (Top Right)
                              Positioned(
                                right: 10,
                                top: 0 - (math.sin(value * math.pi * 2) * 10),
                                child: Container(
                                  width: 140,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      )
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEFF6FF),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.trending_up_rounded,
                                          color: InvoiceBillTheme.primaryBlue,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Growth",
                                              style: GoogleFonts.plusJakartaSans(
                                                color: InvoiceBillTheme.textMuted,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Text(
                                              "+28.4%",
                                              style: TextStyle(
                                                color: InvoiceBillTheme.successGreen,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Serif Heading Tagline
                  Text(
                    "Smart Invoicing\nMade Simple",
                    style: GoogleFonts.lora(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    "Manage billing, track payments and grow your business with confidence.",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: const Color(0xFF94A3B8), // slate-400
                      height: 1.5,
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(double height, double animValue, double delayFactor) {
    // Generate organic waves using animValue and delayFactor
    final double scaling = 0.8 + 0.2 * math.sin((animValue * math.pi * 2) + (delayFactor * math.pi));
    final double finalHeight = height * scaling;

    return Container(
      width: 24,
      height: finalHeight,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            InvoiceBillTheme.primaryBlue.withOpacity(0.2),
            InvoiceBillTheme.primaryBlue,
          ],
        ),
      ),
    );
  }
}
