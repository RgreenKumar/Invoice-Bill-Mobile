import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

// ==========================================
// SCREEN 3 — EMAIL VERIFICATION SENT
// ==========================================
class EmailSentView extends StatefulWidget {
  final String email;
  final VoidCallback onNavigateToOTP;
  final VoidCallback onNavigateToLogin;

  const EmailSentView({
    super.key,
    required this.email,
    required this.onNavigateToOTP,
    required this.onNavigateToLogin,
  });

  @override
  State<EmailSentView> createState() => _EmailSentViewState();
}

class _EmailSentViewState extends State<EmailSentView> {
  bool _isResending = false;

  void _resendEmail() {
    setState(() {
      _isResending = true;
    });

    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification email resent!"),
            backgroundColor: InvoiceBillTheme.successGreen,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Large Success Illustration (Custom Vector)
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            color: InvoiceBillTheme.primaryBlue.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.mark_email_read_outlined,
              color: InvoiceBillTheme.primaryBlue,
              size: 56,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Heading
        Text(
          "Verification Email Sent!",
          textAlign: TextAlign.center,
          style: InvoiceBillTheme.serifHeading(fontSize: 28),
        ),
        const SizedBox(height: 12),

        // Text
        Text(
          "A verification email has been sent successfully. Please check your inbox.",
          textAlign: TextAlign.center,
          style: InvoiceBillTheme.sansBody(),
        ),
        const SizedBox(height: 24),

        // Email Details Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                "Email Address",
                style: InvoiceBillTheme.sansBody(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: InvoiceBillTheme.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: InvoiceBillTheme.sansBody(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: InvoiceBillTheme.textDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Open Gmail (Primary Action)
        ElevatedButton(
          onPressed: () {
            // Emulate opening Gmail web/app
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Simulated opening mail client..."),
                duration: Duration(seconds: 2),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: InvoiceBillTheme.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: Text(
            "Open Gmail",
            style: InvoiceBillTheme.buttonText(),
          ),
        ),
        const SizedBox(height: 12),

        // Resend Email (Secondary Action)
        OutlinedButton(
          onPressed: _isResending ? null : _resendEmail,
          style: OutlinedButton.styleFrom(
            foregroundColor: InvoiceBillTheme.textDark,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            side: const BorderSide(color: InvoiceBillTheme.inputBorder),
          ),
          child: _isResending
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Resend Email"),
        ),
        const SizedBox(height: 24),

        // Redirect to OTP directly
        GestureDetector(
          onTap: widget.onNavigateToOTP,
          child: Text(
            "Have the verification code? Enter OTP",
            style: InvoiceBillTheme.sansBody(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: InvoiceBillTheme.primaryBlue,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Back to Login
        GestureDetector(
          onTap: widget.onNavigateToLogin,
          child: Text(
            "Back to Login",
            style: InvoiceBillTheme.sansBody(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: InvoiceBillTheme.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// SCREEN 4 — EMAIL VERIFICATION (OTP)
// ==========================================
class OTPView extends StatefulWidget {
  final String email;
  final VoidCallback onVerificationSuccess;
  final VoidCallback onBack;

  const OTPView({
    super.key,
    required this.email,
    required this.onVerificationSuccess,
    required this.onBack,
  });

  @override
  State<OTPView> createState() => _OTPViewState();
}

class _OTPViewState extends State<OTPView> {
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  
  Timer? _timer;
  int _secondsRemaining = 30;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    
    // Set key event interceptor on focus nodes to capture backspace on empty inputs
    for (int i = 0; i < 6; i++) {
      _focusNodes[i].onKeyEvent = (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            _controllers[i].text.isEmpty &&
            i > 0) {
          _focusNodes[i - 1].requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      };
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Focus next input box
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyOTP(); // Automatically trigger verification when last digit is entered
      }
    }
  }


  void _verifyOTP() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) return;

    setState(() {
      _isVerifying = true;
    });

    Future.delayed(const Duration(seconds: 1500), () {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
        widget.onVerificationSuccess();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTime =
        "00:${_secondsRemaining.toString().padLeft(2, '0')}";

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Heading
        Text(
          "Verify Email",
          style: InvoiceBillTheme.serifHeading(fontSize: 28),
        ),
        const SizedBox(height: 8),

        // Subtitle
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: "Enter the 6-digit verification code sent to your email:\n",
            style: InvoiceBillTheme.sansBody(fontSize: 14),
            children: [
              TextSpan(
                text: widget.email,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: InvoiceBillTheme.textDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // OTP Boxes Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            6,
            (index) => SizedBox(
              width: 48,
              height: 56,
              child: TextFormField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: InvoiceBillTheme.textDark,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: InvoiceBillTheme.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: InvoiceBillTheme.primaryBlue, width: 2),
                  ),
                ),
                onChanged: (val) => _onCodeChanged(val, index),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Countdown Timer Text
        Text(
          _secondsRemaining > 0
              ? "Resend OTP in $formattedTime"
              : "Didn't receive the code?",
          style: InvoiceBillTheme.sansBody(
            fontSize: 13,
            color: _secondsRemaining > 0
                ? InvoiceBillTheme.textMuted
                : InvoiceBillTheme.textDark,
          ),
        ),
        const SizedBox(height: 32),

        // Verify OTP Button
        ElevatedButton(
          onPressed: _isVerifying ? null : _verifyOTP,
          style: ElevatedButton.styleFrom(
            backgroundColor: InvoiceBillTheme.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: _isVerifying
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  "Verify OTP",
                  style: InvoiceBillTheme.buttonText(),
                ),
        ),
        const SizedBox(height: 12),

        // Resend OTP Button (Active only when timer expires)
        TextButton(
          onPressed: _secondsRemaining > 0
              ? null
              : () {
                  _startTimer();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("New OTP code sent!")),
                  );
                },
          style: TextButton.styleFrom(
            foregroundColor: InvoiceBillTheme.primaryBlue,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: Text(
            "Resend OTP",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _secondsRemaining > 0
                  ? InvoiceBillTheme.textMuted
                  : InvoiceBillTheme.primaryBlue,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Go Back
        GestureDetector(
          onTap: widget.onBack,
          child: Text(
            "Go Back",
            style: InvoiceBillTheme.sansBody(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: InvoiceBillTheme.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// SCREEN 5 — EMAIL VERIFIED SUCCESSFULLY
// ==========================================
class VerifiedSuccessView extends StatefulWidget {
  final VoidCallback onContinue;
  final String? userName;

  const VerifiedSuccessView({
    super.key,
    required this.onContinue,
    this.userName,
  });

  @override
  State<VerifiedSuccessView> createState() => _VerifiedSuccessViewState();
}

class _VerifiedSuccessViewState extends State<VerifiedSuccessView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        // Premium Green Checkmark Animation
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            height: 110,
            width: 110,
            decoration: BoxDecoration(
              color: InvoiceBillTheme.successGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle_rounded,
                color: InvoiceBillTheme.successGreen,
                size: 72,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Heading
        Text(
          widget.userName != null && widget.userName != 'Guest'
              ? "Welcome, ${widget.userName}!\nEmail Verified Successfully"
              : "Email Verified\nSuccessfully!",
          textAlign: TextAlign.center,
          style: InvoiceBillTheme.serifHeading(fontSize: 28),
        ),
        const SizedBox(height: 12),

        // Text
        Text(
          "Your account has been activated.\nYou can now log in and set up invoicing.",
          textAlign: TextAlign.center,
          style: InvoiceBillTheme.sansBody(),
        ),
        const SizedBox(height: 40),

        // Primary Action
        ElevatedButton(
          onPressed: widget.onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: InvoiceBillTheme.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: Text(
            "Continue to Login",
            style: InvoiceBillTheme.buttonText(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
