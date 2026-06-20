import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:khata/config/auth0_config.dart';

/// Enum for social auth providers - easily extendable
enum SocialAuthProvider {
  google,
  apple,
  facebook,
  // Add more providers here in future
}

/// Result class for social auth
class SocialAuthResult {
  final bool success;
  final String? userId;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? error;
  final SocialAuthProvider provider;
  final String? idToken;

  SocialAuthResult({
    this.idToken, 
    required this.success,
    required this.provider,
    this.userId,
    this.email,
    this.displayName,
    this.photoUrl,
    this.error,
  });
}

/// Abstract class for social auth providers - Strategy Pattern
abstract class SocialAuthProviderHandler {
  SocialAuthProvider get provider;
  Future<SocialAuthResult> signIn();
  Future<void> signOut();
}

/// Google Auth Handler
class GoogleAuthHandler implements SocialAuthProviderHandler {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '337359007063-agj5j2cjd5nare3m5qrc4khicb1j7m3v.apps.googleusercontent.com',
  );
  @override
  SocialAuthProvider get provider => SocialAuthProvider.google;

  @override
  Future<SocialAuthResult> signIn() async {
    try {
      if(kDebugMode){
        print("google sign in triggered");
      }
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if(account == null){
        return SocialAuthResult(
          success: false, 
          provider: provider,
          error: 'Sign in aborted by user'
        );
      }
      final GoogleSignInAuthentication googleAuth = await account.authentication;
      final String? idToken = googleAuth.idToken;
      if(idToken == null){
        return SocialAuthResult(
          success: false,
          provider: provider,
          error: 'Google Sign-In Id Token not found'
        );
      }
      return SocialAuthResult(
        success: true,
        provider: provider,
        userId: account.id,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        idToken: idToken,
      );

    } catch (e) {
      if(kDebugMode){
        print('Error signing in with Google: $e');
      }
      return SocialAuthResult(
        success: false,
        provider: provider,
        error: e.toString(),
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      if (kDebugMode) print('Error signing out of Google: $e');
    }
  }
}

/// Apple Auth Handler
class AppleAuthHandler implements SocialAuthProviderHandler {
  @override
  SocialAuthProvider get provider => SocialAuthProvider.apple;

  @override
  Future<SocialAuthResult> signIn() async {
    try {
      // TODO: Implement actual Apple Sign-In
      // Add sign_in_with_apple package and implement

      await Future.delayed(const Duration(seconds: 1));

      if (kDebugMode) {
        print('Apple Sign-In triggered');
      }

      return SocialAuthResult(
        success: false,
        provider: provider,
        error: 'Apple Sign-In not configured. Add sign_in_with_apple package.',
      );
    } catch (e) {
      return SocialAuthResult(
        success: false,
        provider: provider,
        error: e.toString(),
      );
    }
  }

  @override
  Future<void> signOut() async {
    // TODO: Implement Apple Sign-Out
  }
}

/// Facebook Auth Handler
class FacebookAuthHandler implements SocialAuthProviderHandler {
  @override
  SocialAuthProvider get provider => SocialAuthProvider.facebook;

  @override
  Future<SocialAuthResult> signIn() async {
    try {
      // TODO: Implement actual Facebook Sign-In
      // Add flutter_facebook_auth package and implement

      await Future.delayed(const Duration(seconds: 1));

      if (kDebugMode) {
        print('Facebook Sign-In triggered');
      }

      return SocialAuthResult(
        success: false,
        provider: provider,
        error: 'Facebook Sign-In not configured. Add flutter_facebook_auth package.',
      );
    } catch (e) {
      return SocialAuthResult(
        success: false,
        provider: provider,
        error: e.toString(),
      );
    }
  }

  @override
  Future<void> signOut() async {
    // TODO: Implement Facebook Sign-Out
  }
}

/// Main Social Auth Service - Factory Pattern
class SocialAuthService {
  static final SocialAuthService _instance = SocialAuthService._internal();
  factory SocialAuthService() => _instance;
  SocialAuthService._internal();

  final Map<SocialAuthProvider, SocialAuthProviderHandler> _handlers = {
    SocialAuthProvider.google: GoogleAuthHandler(),
    SocialAuthProvider.apple: AppleAuthHandler(),
    SocialAuthProvider.facebook: FacebookAuthHandler(),
  };

  /// Register a new provider handler (for extensibility)
  void registerHandler(SocialAuthProviderHandler handler) {
    _handlers[handler.provider] = handler;
  }

  /// Get handler for a provider
  SocialAuthProviderHandler? getHandler(SocialAuthProvider provider) {
    return _handlers[provider];
  }

  /// Sign in with a specific provider
  Future<SocialAuthResult> signInWith(SocialAuthProvider provider) async {
    final handler = _handlers[provider];
    if (handler == null) {
      return SocialAuthResult(
        success: false,
        provider: provider,
        error: 'Provider not configured',
      );
    }
    return await handler.signIn();
  }

  /// Sign out from a specific provider
  Future<void> signOutFrom(SocialAuthProvider provider) async {
    final handler = _handlers[provider];
    if (handler != null) {
      await handler.signOut();
    }
  }

  /// Get all available providers
  List<SocialAuthProvider> get availableProviders => _handlers.keys.toList();
}