import 'package:flutter/material.dart';
import 'dart:math' as math;

class GoogleButton extends StatelessWidget {
  final Function(String name, String email) onLoginSuccess;

  const GoogleButton({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showGooglePopup(context),
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: const Color(0xFFD1D5DB), // gray-300
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Standard Vector-rendered Google G Logo
            CustomPaint(
              size: const Size(18, 18),
              painter: GoogleLogoPainter(),
            ),
            const SizedBox(width: 12),
            const Text(
              "Continue with Google",
              style: TextStyle(
                color: Color(0xFF374151), // gray-700
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGooglePopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return GooglePopupDialog(
          onAccountSelected: (name, email) {
            onLoginSuccess(name, email);
          },
        );
      },
    );
  }
}

// Painter to draw the high-quality Google color vector icon
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w / 2;

    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Red Sector
    paint.color = const Color(0xFFEA4335);
    final Path redPath = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx - r * 0.7, cy - r * 0.7)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -135 * (math.pi / 180),
        90 * (math.pi / 180),
        false,
      )
      ..close();
    canvas.drawPath(redPath, paint);

    // Yellow Sector
    paint.color = const Color(0xFFFBBC05);
    final Path yellowPath = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx - r * 0.7, cy + r * 0.7)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        135 * (math.pi / 180),
        90 * (math.pi / 180),
        false,
      )
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Green Sector
    paint.color = const Color(0xFF34A853);
    final Path greenPath = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx + r, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        0 * (math.pi / 180),
        135 * (math.pi / 180),
        false,
      )
      ..close();
    canvas.drawPath(greenPath, paint);

    // Blue Sector + Arm
    paint.color = const Color(0xFF4285F4);
    final Path bluePath = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx, cy - r)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -90 * (math.pi / 180),
        90 * (math.pi / 180),
        false,
      )
      ..lineTo(cx, cy + r * 0.2)
      ..lineTo(cx + r * 0.4, cy + r * 0.2)
      ..lineTo(cx + r * 0.4, cy - r * 0.2)
      ..lineTo(cx, cy - r * 0.2)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Inner White Cutout to make it a G
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.5, paint);

    // Redraw the middle horizontal arm bar of G
    paint.color = const Color(0xFF4285F4);
    final Rect armRect = Rect.fromLTRB(cx, cy - r * 0.22, cx + r * 0.95, cy + r * 0.22);
    canvas.drawRect(armRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GooglePopupDialog extends StatefulWidget {
  final Function(String name, String email) onAccountSelected;

  const GooglePopupDialog({
    super.key,
    required this.onAccountSelected,
  });

  @override
  State<GooglePopupDialog> createState() => _GooglePopupDialogState();
}

class _GooglePopupDialogState extends State<GooglePopupDialog> {
  bool _isLoading = false;
  String? _selectedName;

  void _selectAccount(String name, String email) {
    setState(() {
      _isLoading = true;
      _selectedName = name;
    });

    // Simulate standard Google checking screen
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop(); // Close popup dialog
        widget.onAccountSelected(name, email); // Return values
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 16,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24.0),
        child: _isLoading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Signing in with Google...",
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Connecting to $_selectedName",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Google Logo Header
                  Center(
                    child: Column(
                      children: [
                        CustomPaint(
                          size: const Size(24, 24),
                          painter: GoogleLogoPainter(),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Sign in with Google",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "to continue to InvoiceBill",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Account List
                  _buildAccountTile(
                    "Logavani V",
                    "logavani.v@gmail.com",
                    "L",
                    Colors.purple[700]!,
                  ),
                  const Divider(height: 1),
                  _buildAccountTile(
                    "Vengadesan R",
                    "vengadesanr613@gmail.com",
                    "V",
                    Colors.teal[700]!,
                  ),
                  const Divider(height: 1),

                  // Add Account option
                  InkWell(
                    onTap: () => _selectAccount("New User", "invoicebill.guest@gmail.com"),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.person_add_alt_1_outlined, color: Colors.grey[600], size: 22),
                          const SizedBox(width: 14),
                          Text(
                            "Use another account",
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Footer terms notice
                  Text(
                    "To continue, Google will share your name, email address, profile picture, and preference with InvoiceBill.",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAccountTile(String name, String email, String initial, Color color) {
    return InkWell(
      onTap: () => _selectAccount(name, email),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


