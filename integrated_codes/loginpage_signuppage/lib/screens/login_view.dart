import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/google_login_popup.dart';

class LoginView extends StatefulWidget {
  final VoidCallback onNavigateToRegister;
  final VoidCallback onNavigateToForgotPassword;
  final Function(String name, String email) onLoginSuccess;

  const LoginView({
    super.key,
    required this.onNavigateToRegister,
    required this.onNavigateToForgotPassword,
    required this.onLoginSuccess,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate network request
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          widget.onLoginSuccess("Enterprise User", _emailController.text);
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
          Text("Sign In", style: InvoiceBillTheme.serifHeading(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            "Access your dashboard and manage invoices.",
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
          const SizedBox(height: 20),

          // Password Field
          CustomTextField(
            controller: _passwordController,
            labelText: "Password",
            hintText: "Enter your password",
            isPassword: true,
            prefixIcon: Icons.lock_outline_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Password is required";
              }
              if (value.length < 6) {
                return "Password must be at least 6 characters";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Options Row (Remember Me & Forgot Password)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Remember Me
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        activeColor: InvoiceBillTheme.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Remember Me",
                        overflow: TextOverflow.ellipsis,
                        style: InvoiceBillTheme.sansBody(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: InvoiceBillTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Forgot Password
              GestureDetector(
                onTap: widget.onNavigateToForgotPassword,
                child: Text(
                  "Forgot Password?",
                  style: InvoiceBillTheme.sansBody(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: InvoiceBillTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Primary Login Button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
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
                : Text("Login", style: InvoiceBillTheme.buttonText()),
          ),
          const SizedBox(height: 16),

          // Or Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[200])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "or",
                  style: InvoiceBillTheme.sansBody(fontSize: 13),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey[200])),
            ],
          ),
          const SizedBox(height: 16),

          // Google Login Button
          GoogleButton(onLoginSuccess: widget.onLoginSuccess),
          const SizedBox(height: 32),

          // Footer redirect
          Center(
            child: Wrap(
              children: [
                Text(
                  "Don't have an account? ",
                  style: InvoiceBillTheme.sansBody(fontSize: 14),
                ),
                GestureDetector(
                  onTap: widget.onNavigateToRegister,
                  child: Text(
                    "Create Account",
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
