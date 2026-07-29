import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:kaia/Service/NotificationService.dart';
import 'package:crypto/crypto.dart';


class AuthService {
  static Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance
          .authenticate();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser!.authentication;

      // Create a new credential
      final credential = googleAuth.idToken!;

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: credential,
      );

      // Autenticamos en Firebase
      final credential2 = firebase_auth.GoogleAuthProvider.credential(
        idToken: credential,
      );

      // Once signed in, return the UserCredential
      await firebase_auth.FirebaseAuth.instance.signInWithCredential(
        credential2,
      );
    } catch (e) {
      print("Error in Google Auth: $e");
    }
  }

  static Future<void> signInWithApple() async {
    try {
      // 1. Generamos los nonces para evitar ataques de replay (Exigido por Apple/Supabase)
      final rawNonce = Supabase.instance.client.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      // 2. Lanzamos el botoncito nativo de Apple inferior de iOS
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      final appleName = firebase_auth.AppleFullPersonName(givenName: credential.givenName, familyName: credential.familyName);
      if (idToken == null) {
        throw const AuthException(
          'No se ha podido obtener el ID Token de Apple.',
        );
      }

      // 3. Autenticamos en Supabase sin abrir el navegador, pasando directamente el token
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      // 4. Autenticamos en Firebase
      final credential_apple = firebase_auth.AppleAuthProvider.credentialWithIDToken(
        idToken,
        rawNonce,
        appleName
      );

      await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential_apple);

      print("Native Apple Auth Success: ${response.user?.id}");
    } catch (e) {
      print("Error in Native Apple Auth: $e");
    }



  }
      static Future<void> signOut() async {
    try {
      // 1. Comprobamos el proveedor a través de Supabase
      final user = Supabase.instance.client.auth.currentUser;
      
      // 'providers' es una lista. Ej: ['google'] o ['apple']
      final providers = user?.appMetadata?['providers'] as List<dynamic>? ?? [];

      // 2. Si el proveedor fue Google, cerramos su sesión nativa
      if (providers.contains('google')) {
        await GoogleSignIn.instance.signOut();
      }

      // (Opcional) Puedes comprobar de la misma manera si fue Apple
      if (providers.contains('apple')) {
        // Apple no requiere un "signOut" nativo como Google
        print("El usuario había iniciado sesión con Apple");
      }

      // Borramos el token del dispositivo para notificaciones
      await NotificationService.removeDeviceToken();

      // 3. Cerramos la sesión en Firebase
      await firebase_auth.FirebaseAuth.instance.signOut();

      // 4. Cerramos la sesión en Supabase
      await Supabase.instance.client.auth.signOut();
      
    } catch (e) {
      print("Error al cerrar sesión: $e");
    }
  }


}
