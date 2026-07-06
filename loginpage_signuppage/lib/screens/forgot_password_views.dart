import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/custom_text_field.dart';

// ==========================================
// SCREEN 6 — FORGOT PASSWORD
// ==========================================
class ForgotPasswordView extends StatefulWidget {
  final VoidCallback onBackToLogin;
  final Function(String email) onCodeSent;

  const ForgotPasswordView({
    super.key,
    required this.onBackToLogin,
    required this.onCodeSent,
  });

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          widget.onCodeSent(_emailController.text);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading
          Text(
            "Forgot Password?",
            style: InvoiceBillTheme.serifHeading(fontSize: 30),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            "Enter your registered email address and we'll send you a link to reset your password.",
            style: InvoiceBillTheme.sansBody(),
          ),
          const SizedBox(height: 32),

          // Email Field
          CustomTextField(
            controller: _emailController,
            labelText: "Email Address",
            hintText: "Enter your email",
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Email is required";
              }
              final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegExp.hasMatch(value.trim())) {
                return "Enter a valid email address";
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Primary Button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: InvoiceBillTheme.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    "Send Verification Code",
                    style: InvoiceBillTheme.buttonText(),
                  ),
          ),
          const SizedBox(height: 20),

          // Back to Login Link
          Center(
            child: GestureDetector(
              onTap: widget.onBackToLogin,
              child: Text(
                "Back to Login",
                style: InvoiceBillTheme.sansBody(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: InvoiceBillTheme.primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SCREEN 7 — PASSWORD RESET EMAIL SENT
// ==========================================
class ResetLinkSentView extends StatefulWidget {
  final String email;
  final VoidCallback onNavigateToReset;
  final VoidCallback onBackToLogin;

  const ResetLinkSentView({
    super.key,
    required this.email,
    required this.onNavigateToReset,
    required this.onBackToLogin,
  });

  @override
  State<ResetLinkSentView> createState() => _ResetLinkSentViewState();
}

class _ResetLinkSentViewState extends State<ResetLinkSentView> {
  bool _isResending = false;

  void _resendEmail() {
    setState(() {
      _isResending = true;
    });

    Future.delayed(const Duration(seconds: 1500), () {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reset link resent!"),
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
        // Large Email Illustration
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            color: InvoiceBillTheme.primaryBlue.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.send_to_mobile_rounded,
              color: InvoiceBillTheme.primaryBlue,
              size: 56,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Heading
        Text(
          "Password Reset Link Sent",
          textAlign: TextAlign.center,
          style: InvoiceBillTheme.serifHeading(fontSize: 28),
        ),
        const SizedBox(height: 12),

        // Text
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: "A secure password reset link has been sent to your email:\n",
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

        // Open Gmail (Primary Action)
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Simulated opening mail client...")),
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

        // Demo Bypass Button (Go to Reset Password screen)
        GestureDetector(
          onTap: widget.onNavigateToReset,
          child: Text(
            "Mock: Click link in email -> Reset Password",
            style: InvoiceBillTheme.sansBody(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: InvoiceBillTheme.primaryBlue,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Back to Login Link
        GestureDetector(
          onTap: widget.onBackToLogin,
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

class CenterPlayground {
  static const Alignment alignment = Alignment.center;
}

// ==========================================
// SCREEN 8 — RESET PASSWORD
// ==========================================
class ResetPasswordView extends StatefulWidget {
  final VoidCallback onPasswordResetSuccess;

  const ResetPasswordView({
    super.key,
    required this.onPasswordResetSuccess,
  });

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;

  // Real-time strength states
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String value) {
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasLowercase = value.contains(RegExp(r'[a-z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = value.contains(RegExp(r'[!@#\$&*~`_\-+=?/\\|:;]'));
    });
  }

  void _handleSubmit() {
    final bool isStrong = _hasMinLength &&
        _hasUppercase &&
        _hasLowercase &&
        _hasNumber &&
        _hasSpecialChar;

    if (_formKey.currentState!.validate() && isStrong) {
      setState(() {
        _isLoading = true;
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          widget.onPasswordResetSuccess();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading
          Text(
            "Create New Password",
            style: InvoiceBillTheme.serifHeading(fontSize: 28),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            "Set a new password to secure your account workspace.",
            style: InvoiceBillTheme.sansBody(),
          ),
          const SizedBox(height: 28),

          // New Password Field
          CustomTextField(
            controller: _passwordController,
            labelText: "New Password",
            hintText: "Enter new password",
            isPassword: true,
            prefixIcon: Icons.lock_outline_rounded,
            onChanged: _checkPasswordStrength,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Password is required";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          CustomTextField(
            controller: _confirmPasswordController,
            labelText: "Confirm Password",
            hintText: "Retype new password",
            isPassword: true,
            prefixIcon: Icons.lock_outline_rounded,
            validator: (value) {
              if (value != _passwordController.text) {
                return "Passwords do not match";
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Strength indicator title
          Text(
            "Password Strength Requirements",
            style: InvoiceBillTheme.sansHeader(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Checklist Requirements Grid
          Column(
            children: [
              _buildRequirementRow("8 characters minimum", _hasMinLength),
              _buildRequirementRow("At least one uppercase letter (A-Z)", _hasUppercase),
              _buildRequirementRow("At least one lowercase letter (a-z)", _hasLowercase),
              _buildRequirementRow("At least one number (0-9)", _hasNumber),
              _buildRequirementRow("At least one special character (@,#,\$,etc)", _hasSpecialChar),
            ],
          ),
          const SizedBox(height: 32),

          // Reset Password Button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: InvoiceBillTheme.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    "Reset Password",
                    style: InvoiceBillTheme.buttonText(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            color: isMet ? InvoiceBillTheme.successGreen : InvoiceBillTheme.textMuted,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: InvoiceBillTheme.sansBody(
                fontSize: 12,
                color: isMet ? InvoiceBillTheme.textDark : InvoiceBillTheme.textMuted,
                fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SCREEN 9 — PASSWORD RESET SUCCESS
// ==========================================
class ResetSuccessView extends StatefulWidget {
  final VoidCallback onGoToLogin;

  const ResetSuccessView({
    super.key,
    required this.onGoToLogin,
  });

  @override
  State<ResetSuccessView> createState() => _ResetSuccessViewState();
}

class _ResetSuccessViewState extends State<ResetSuccessView>
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
        // Success check animation scale transition
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
          "Password Changed\nSuccessfully!",
          textAlign: TextAlign.center,
          style: InvoiceBillTheme.serifHeading(fontSize: 28),
        ),
        const SizedBox(height: 12),

        // Text
        Text(
          "Your password has been updated. You can now use your new password to sign in.",
          textAlign: TextAlign.center,
          style: InvoiceBillTheme.sansBody(),
        ),
        const SizedBox(height: 40),

        // Action Button
        ElevatedButton(
          onPressed: widget.onGoToLogin,
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
            "Go to Login",
            style: InvoiceBillTheme.buttonText(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
