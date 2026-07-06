import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/google_login_popup.dart';

class RegisterView extends StatefulWidget {
  final VoidCallback onNavigateToLogin;
  final Function(String email) onRegisterSuccess;

  const RegisterView({
    super.key,
    required this.onNavigateToLogin,
    required this.onRegisterSuccess,
  });

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _businessController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _agreeTerms = false;
  bool _isLoading = false;
  String? _termsError;

  @override
  void dispose() {
    _nameController.dispose();
    _businessController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    setState(() {
      _termsError = null;
    });

    final isFormValid = _formKey.currentState!.validate();
    if (!_agreeTerms) {
      setState(() {
        _termsError = "You must agree to the Terms & Conditions";
      });
      return;
    }

    if (isFormValid) {
      setState(() {
        _isLoading = true;
      });

      // Simulate network request
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          widget.onRegisterSuccess(_emailController.text);
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
          // Elegant Serif Heading
          Text(
            "Create Your Account",
            style: InvoiceBillTheme.serifHeading(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            "Set up your billing workspace in seconds.",
            style: InvoiceBillTheme.sansBody(),
          ),
          const SizedBox(height: 24),

          // Name and Business Name Fields (Grouped tightly)
          CustomTextField(
            controller: _nameController,
            labelText: "Full Name",
            hintText: "Enter your full name",
            prefixIcon: Icons.person_outline_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Full Name is required";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _businessController,
            labelText: "Business Name",
            hintText: "Enter company name",
            prefixIcon: Icons.business_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Business Name is required";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

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
          const SizedBox(height: 16),

          CustomTextField(
            controller: _phoneController,
            labelText: "Phone Number",
            hintText: "+1 (555) 000-0000",
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Phone Number is required";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _passwordController,
            labelText: "Password",
            hintText: "Create secure password",
            isPassword: true,
            prefixIcon: Icons.lock_outline_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Password is required";
              }
              if (value.length < 8) {
                return "Password must be at least 8 characters";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _confirmPasswordController,
            labelText: "Confirm Password",
            hintText: "Retype password",
            isPassword: true,
            prefixIcon: Icons.lock_outline_rounded,
            validator: (value) {
              if (value != _passwordController.text) {
                return "Passwords do not match";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Agree to Terms & Conditions Checkbox
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _agreeTerms,
                      activeColor: InvoiceBillTheme.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _agreeTerms = value ?? false;
                          if (_agreeTerms) _termsError = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: "I agree to the ",
                        style: InvoiceBillTheme.sansBody(
                          fontSize: 13,
                          color: InvoiceBillTheme.textDark,
                        ),
                        children: [
                          TextSpan(
                            text: "Terms & Conditions",
                            style: GoogleFonts.plusJakartaSans(
                              color: InvoiceBillTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: " and ",
                            style: InvoiceBillTheme.sansBody(fontSize: 13),
                          ),
                          TextSpan(
                            text: "Privacy Policy",
                            style: GoogleFonts.plusJakartaSans(
                              color: InvoiceBillTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_termsError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 32.0, top: 4.0),
                  child: Text(
                    _termsError!,
                    style: const TextStyle(
                      color: InvoiceBillTheme.errorRed,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),

          // Create Account Button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
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
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    "Create Account",
                    style: InvoiceBillTheme.buttonText(),
                  ),
          ),
          const SizedBox(height: 16),

          // Continue with Google Button
          GoogleButton(
            onLoginSuccess: (name, email) {
              widget.onRegisterSuccess(email);
            },
          ),
          const SizedBox(height: 24),

          // Footer login redirect
          Center(
            child: Wrap(
              children: [
                Text(
                  "Already have an account? ",
                  style: InvoiceBillTheme.sansBody(fontSize: 14),
                ),
                GestureDetector(
                  onTap: widget.onNavigateToLogin,
                  child: Text(
                    "Login",
                    style: InvoiceBillTheme.sansBody(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: InvoiceBillTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
