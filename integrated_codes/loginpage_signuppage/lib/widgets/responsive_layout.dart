import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget leftPanel;
  final Widget rightPanel;

  const ResponsiveLayout({
    super.key,
    required this.leftPanel,
    required this.rightPanel,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        
        if (isDesktop) {
          return Row(
            children: [
              // Left Illustration Panel
              Expanded(
                flex: 12,
                child: leftPanel,
              ),
              // Right Authentication Card Panel
              Expanded(
                flex: 10,
                child: Container(
                  color: const Color(0xFF183548), // Match background color
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40.0,
                        vertical: 30.0,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: rightPanel,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          // Mobile View
          return Container(
            color: const Color(0xFF183548),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mini logo for mobile at the top
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "InvoiceBill",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: rightPanel,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
