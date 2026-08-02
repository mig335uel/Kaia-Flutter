import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
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
      final appleName = firebase_auth.AppleFullPersonName(
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
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
      final credential_apple =
          firebase_auth.AppleAuthProvider.credentialWithIDToken(
            idToken,
            rawNonce,
            appleName,
          );

      await firebase_auth.FirebaseAuth.instance.signInWithCredential(
        credential_apple,
      );

      print("Native Apple Auth Success: ${response.user?.id}");
    } catch (e) {
      print("Error in Native Apple Auth: $e");
    }
  }

    static Future<void> signInWithAgoras() async {
    try {
      final rawNonce = Supabase.instance.client.auth.generateRawNonce();
      
      // Generate PKCE code challenge
      final codeVerifier = rawNonce;
      final digest = sha256.convert(utf8.encode(codeVerifier));
      final codeChallenge = base64UrlEncode(digest.bytes).replaceAll('=', '');

      final url = Uri.https(
        'zqcgontfrcuofeqrtvvq.supabase.co',
        '/auth/v1/oauth/authorize',
        {
          'client_id': '07d2d1a6-b408-40fc-ae2e-03207e614176',
          'response_type': 'code',
          'scope': 'openid profile email',
          'redirect_uri': 'https://api.agoras.es/oauth/callback',
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256',
          'state': codeVerifier,
        },
      ).toString();

      final response = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: 'kaia',
      );

      final idToken = Uri.parse(response).queryParameters['id_token'];

      if (idToken != null) {
        // 1. Autenticamos en Supabase (Agregado await)
        final supabaseResponse = await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider('custom:agoras'), 
          idToken: idToken,
        );
        print("Supabase Agoras Auth Success: ${supabaseResponse.user?.id}");

        // 2. Autenticamos en Firebase
        final provider = firebase_auth.OAuthProvider('oidc.agoras');
        final credential = provider.credential(
          idToken: idToken,
          rawNonce: rawNonce, // Pasamos el nonce original para validar la sesión
        );

        final firebaseUser = await firebase_auth.FirebaseAuth.instance.signInWithCredential(
          credential,
        );
        print("Firebase Agoras Auth Success: ${firebaseUser.user?.uid}");
      }
    } catch (e) {
      print("Error in Agoras Auth: $e");
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

      // Si el proveedor fue Agoras, cerramos la sesión en el navegador web
      if (providers.contains('custom:agoras') || providers.contains('agoras')) {
        try {
          // Ajusta el dominio (ej: auth.agoras.es) a donde esté hosteado agorasoauth
          await FlutterWebAuth2.authenticate(
            url: 'https://accounts.agoras.es/auth/signout?redirect_uri=kaia://logout',
            callbackUrlScheme: 'kaia',
          );
          print("El usuario cerró sesión en Agoras correctamente");
        } catch (e) {
          print("Error al cerrar sesión de Agoras en la web: $e");
        }
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
