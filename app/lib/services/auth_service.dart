import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sign-in is only asked for when someone starts Pro or restores on a new
/// device. Free users never have an account.
///   iOS: Sign in with Apple. Android: Google. Both -> one Supabase user.
class AuthService {
  AuthService(this.client, {required this.googleServerClientId});

  final SupabaseClient client;
  final String googleServerClientId;

  User? get user => client.auth.currentUser;
  Stream<AuthState> get changes => client.auth.onAuthStateChange;
  Future<String?> accessToken() async => client.auth.currentSession?.accessToken;

  Future<User?> signInWithPlatform() => Platform.isIOS ? signInWithApple() : signInWithGoogle();

  Future<User?> signInWithApple() async {
    final rawNonce = _nonce();
    final cred = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
    );
    final res = await client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: cred.identityToken!,
      nonce: rawNonce,
    );
    // Apple only sends the name the first time; keep it.
    final name = [cred.givenName, cred.familyName].whereType<String>().join(' ');
    if (name.isNotEmpty) {
      await client.from('profiles').update({'display_name': name}).eq('id', res.user!.id);
    }
    return res.user;
  }

  Future<User?> signInWithGoogle() async {
    final account = await GoogleSignIn(serverClientId: googleServerClientId).signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    final res = await client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: auth.idToken!,
      accessToken: auth.accessToken,
    );
    return res.user;
  }

  Future<void> signOut() => client.auth.signOut();

  /// Required by both stores. Server deletes the auth user; every table and
  /// the user's storage folder cascade.
  Future<void> deleteAccount() async {
    await client.functions.invoke('delete-account');
    await client.auth.signOut();
  }

  String _nonce([int length = 32]) {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
