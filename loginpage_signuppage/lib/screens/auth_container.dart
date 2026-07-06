import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/billing_illustration.dart';

// Screens
import 'login_view.dart';
import 'register_view.dart';
import 'verification_views.dart';
import 'forgot_password_views.dart';

enum AuthState {
  login,
  register,
  emailSent,
  otp,
  verifiedSuccess,
  forgotPassword,
  resetLinkSent,
  resetPassword,
  resetSuccess,
}

class AuthContainer extends StatefulWidget {
  const AuthContainer({super.key});

  @override
  State<AuthContainer> createState() => _AuthContainerState();
}

class _AuthContainerState extends State<AuthContainer> {
  AuthState _currentState = AuthState.login;
  
  // Shared state variables
  String _userEmail = 'example@gmail.com';
  String _userName = 'Guest';

  void navigateTo(AuthState state, {String? email, String? name}) {
    setState(() {
      _currentState = state;
      if (email != null) _userEmail = email;
      if (name != null) _userName = name;
    });
  }

  Widget _buildActiveView() {
    switch (_currentState) {
      case AuthState.login:
        return LoginView(
          onNavigateToRegister: () => navigateTo(AuthState.register),
          onNavigateToForgotPassword: () => navigateTo(AuthState.forgotPassword),
          onLoginSuccess: (name, email) {
            navigateTo(AuthState.verifiedSuccess, name: name, email: email);
          },
        );
      case AuthState.register:
        return RegisterView(
          onNavigateToLogin: () => navigateTo(AuthState.login),
          onRegisterSuccess: (email) {
            navigateTo(AuthState.emailSent, email: email);
          },
        );
      case AuthState.emailSent:
        return EmailSentView(
          email: _userEmail,
          onNavigateToOTP: () => navigateTo(AuthState.otp),
          onNavigateToLogin: () => navigateTo(AuthState.login),
        );
      case AuthState.otp:
        return OTPView(
          email: _userEmail,
          onVerificationSuccess: () => navigateTo(AuthState.verifiedSuccess),
          onBack: () => navigateTo(AuthState.emailSent),
        );
      case AuthState.verifiedSuccess:
        return VerifiedSuccessView(
          userName: _userName,
          onContinue: () => navigateTo(AuthState.login),
        );
      case AuthState.forgotPassword:
        return ForgotPasswordView(
          onBackToLogin: () => navigateTo(AuthState.login),
          onCodeSent: (email) => navigateTo(AuthState.resetLinkSent, email: email),
        );
      case AuthState.resetLinkSent:
        return ResetLinkSentView(
          email: _userEmail,
          onNavigateToReset: () => navigateTo(AuthState.resetPassword),
          onBackToLogin: () => navigateTo(AuthState.login),
        );
      case AuthState.resetPassword:
        return ResetPasswordView(
          onPasswordResetSuccess: () => navigateTo(AuthState.resetSuccess),
        );
      case AuthState.resetSuccess:
        return ResetSuccessView(
          onGoToLogin: () => navigateTo(AuthState.login),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        leftPanel: const BillingIllustration(),
        rightPanel: Container(
          decoration: InvoiceBillTheme.cardDecoration,
          clipBehavior: Clip.antiAlias,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              // Sliding + Fade premium transition
              final slideAnimation = Tween<Offset>(
                begin: const Offset(0.08, 0.0),
                end: Offset.zero,
              ).animate(animation);
              
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<AuthState>(_currentState),
              child: Padding(
                padding: const EdgeInsets.all(36.0),
                child: _buildActiveView(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
