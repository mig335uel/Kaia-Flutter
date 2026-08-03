import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kaia/UI/SocialMode/Home.dart';
import 'package:kaia/UI/SocialMode/login_screen.dart';
import 'package:kaia/UI/complete-profile.dart';
import 'package:kaia/Service/NotificationService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart'; // Importante para SystemUiOverlayStyle
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await MobileAds.instance.initialize();
  await Supabase.initialize(url: 'https://database.kaia.agoras.es', publishableKey: 'sb_publishable_vDmIFdPscUqwdgiK6Ilch2_G26bzkpT', authOptions: FlutterAuthClientOptions());
  // await Supabase.initialize(url: 'https://wpugrcftbewydtquhjvb.supabase.co', publishableKey: 'sb_publishable_w_buzUN9t9PIgN_NGi2ghg_U0uuEXww', authOptions: FlutterAuthClientOptions());
  await GoogleSignIn.instance.initialize(
    serverClientId: '56790361943-87olac8bu9i6ca617c9mms3irt19eqke.apps.googleusercontent.com',
  );

  await Firebase.initializeApp();
  
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('es')],
      path: 'assets/translations',
      fallbackLocale: const Locale('es'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kaia',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      themeMode: ThemeMode.system, // Cambia automáticamente con el sistema (iOS/Android)
      
      // MODO CLARO
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8E2DE2), // Tu color morado
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Platform.isIOS ? Colors.transparent : Colors.white,
          elevation: 0,
          // AQUÍ CONFIGURAS LA STATUS BAR: Íconos oscuros para el modo claro
          systemOverlayStyle: SystemUiOverlayStyle.dark, 
        ),
      ),
      
      // MODO OSCURO
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8E2DE2),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212), // Gris muy oscuro
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          // AQUÍ CONFIGURAS LA STATUS BAR: Íconos blancos para el modo oscuro
          systemOverlayStyle: SystemUiOverlayStyle.light, 
        ),
      ),
      home: const AuthWrapper(),
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/?')) {
          return MaterialPageRoute(
            builder: (context) {
              return const AuthWrapper();
            },
          );
        }
        return null;
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isProfileComplete = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        _checkAuthState();
      }
    });
  }

  Future<void> _checkAuthState() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      setState(() {
        _isLoading = false;
        _isProfileComplete = false;
      });
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('id', session.user.id)
          .maybeSingle();

      setState(() {
        _isLoading = false;
        _isProfileComplete = response != null;
      });
    } catch (e) {
      print("Error checking user profile: $e");
      setState(() {
        _isLoading = false;
        _isProfileComplete = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (session == null) {
      return const LoginScreen();
    }

    if (!_isProfileComplete) {
      return const CompleteProfile();
    }

    return const Home();
  }
}
