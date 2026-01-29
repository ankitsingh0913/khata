import 'package:flutter/material.dart';
import '../services/social_auth_service.dart';
import '../config/app_theme.dart';

/// Configuration for a social login button
class SocialButtonConfig {
  final SocialAuthProvider provider;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final String? iconAsset; // For custom icons/SVGs

  const SocialButtonConfig({
    required this.provider,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.iconAsset,
  });
}

/// Default configurations for social providers
class SocialButtonConfigs {
  static const google = SocialButtonConfig(
    provider: SocialAuthProvider.google,
    label: 'Continue with Google',
    icon: Icons.g_mobiledata,
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
  );

  static const apple = SocialButtonConfig(
    provider: SocialAuthProvider.apple,
    label: 'Continue with Apple',
    icon: Icons.apple,
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
  );

  static const facebook = SocialButtonConfig(
    provider: SocialAuthProvider.facebook,
    label: 'Continue with Facebook',
    icon: Icons.facebook,
    backgroundColor: Color(0xFF1877F2),
    foregroundColor: Colors.white,
  );

  static List<SocialButtonConfig> get all => [google, apple, facebook];
}

/// Single social login button widget
class SocialLoginButton extends StatefulWidget {
  final SocialButtonConfig config;
  final Function(SocialAuthResult) onResult;
  final bool enabled;

  const SocialLoginButton({
    super.key,
    required this.config,
    required this.onResult,
    this.enabled = true,
  });

  @override
  State<SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<SocialLoginButton> {
  bool _isLoading = false;

  Future<void> _handleTap() async {
    if (_isLoading || !widget.enabled) return;

    setState(() => _isLoading = true);

    try {
      final result = await SocialAuthService().signInWith(widget.config.provider);
      widget.onResult(result);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: widget.enabled && !_isLoading ? _handleTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.config.backgroundColor,
          foregroundColor: widget.config.foregroundColor,
          elevation: 1,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: widget.config.backgroundColor == Colors.white
                  ? Colors.grey.shade300
                  : Colors.transparent,
            ),
          ),
        ),
        child: _isLoading
            ? SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.config.foregroundColor,
            ),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.config.icon, size: 24),
            const SizedBox(width: 12),
            Text(
              widget.config.label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Container widget for all social login buttons
class SocialLoginButtonsSection extends StatelessWidget {
  final Function(SocialAuthResult) onAuthResult;
  final List<SocialButtonConfig>? providers; // null = show all
  final bool enabled;
  final String? headerText;

  const SocialLoginButtonsSection({
    super.key,
    required this.onAuthResult,
    this.providers,
    this.enabled = true,
    this.headerText,
  });

  @override
  Widget build(BuildContext context) {
    final configs = providers ?? SocialButtonConfigs.all;

    return Column(
      children: [
        // Divider with "OR" text
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  headerText ?? 'OR',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
        ),

        // Social login buttons
        ...configs.map((config) => SocialLoginButton(
          config: config,
          onResult: onAuthResult,
          enabled: enabled,
        )),
      ],
    );
  }
}