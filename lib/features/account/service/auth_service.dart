import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/analytics/analytics_service.dart';

/// Owns the Firebase Auth session. The app signs in anonymously on first launch
/// so a profile exists immediately, then links an Apple credential when the
/// user chooses to sign in — which keeps all their data.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> get userChanges => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  /// Guarantees a signed-in user, creating an anonymous one if needed.
  Future<User?> ensureSignedIn() async {
    if (_auth.currentUser != null) return _auth.currentUser;
    try {
      final credential = await _auth.signInAnonymously();
      debugPrint('[AuthService] anonymous sign-in ok: ${credential.user?.uid}');
      return credential.user;
    } catch (e) {
      debugPrint('[AuthService] anonymous sign-in failed: $e');
      rethrow;
    }
  }

  /// Signs in with Apple, linking to the existing anonymous account when there
  /// is one so the user keeps their plan and preferences.
  Future<User?> signInWithApple() async {
    try {
      final nonce = _generateNonce();
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: _sha256(nonce),
      );

      final credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: nonce,
        accessToken: appleCredential.authorizationCode,
      );

      final current = _auth.currentUser;
      final result = current != null && current.isAnonymous
          ? await _linkOrSignIn(current, credential)
          : await _auth.signInWithCredential(credential);

      await _applyAppleDisplayName(result.user, appleCredential);
      debugPrint('[AuthService] Apple sign-in ok: ${result.user?.uid}');
      return result.user;
    } catch (e) {
      debugPrint('[AuthService] Apple sign-in failed: $e');
      rethrow;
    }
  }

  /// Links the credential to the anonymous user; if that Apple ID already has an
  /// account, signs into it instead.
  Future<UserCredential> _linkOrSignIn(User anonymous, OAuthCredential credential) async {
    try {
      return await anonymous.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'credential-already-in-use' && e.code != 'provider-already-linked') rethrow;
      debugPrint('[AuthService] credential already in use, signing in instead');
      return _auth.signInWithCredential(credential);
    }
  }

  /// Apple only returns the full name on the very first authorisation.
  Future<void> _applyAppleDisplayName(User? user, AuthorizationCredentialAppleID apple) async {
    final given = apple.givenName?.trim();
    if (user == null || given == null || given.isEmpty) return;
    if ((user.displayName ?? '').isNotEmpty) return;
    try {
      await user.updateDisplayName([given, apple.familyName?.trim()].whereType<String>().join(' ').trim());
    } catch (e, s) {
      AnalyticsService.reportError('AuthService', 'updateDisplayName', e, stack: s);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('[AuthService] signed out');
    } catch (e) {
      debugPrint('[AuthService] sign out failed: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      debugPrint('[AuthService] account deleted');
    } catch (e) {
      debugPrint('[AuthService] account deletion failed: $e');
      rethrow;
    }
  }

  /// Random nonce, hashed before it reaches Apple and sent raw to Firebase.
  String _generateNonce([int length = 32]) {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  String _sha256(String input) => sha256.convert(utf8.encode(input)).toString();
}
