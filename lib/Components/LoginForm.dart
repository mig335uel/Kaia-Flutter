import 'dart:ffi';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:kaia/Service/AuthService.dart';
import 'package:kaia/Components/EmailLoginForm.dart';
import 'package:easy_localization/easy_localization.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool showEmailForm = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(
        //     colors: [
        //       Color.fromARGB(255, 255, 255, 255),
        //       Color.fromARGB(255, 165, 105, 255),
        //     ],
        //     begin: Alignment.topLeft,
        //     end: Alignment.bottomRight,
        //   ),
        //   borderRadius: BorderRadius.circular(10),
        // ),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: showEmailForm
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const OAuthButtom(),
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6A5BFC),
                      Color(0xFF7575FF),
                      Color(0xFF3FCECC),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: CupertinoButton(
                  onPressed: () {
                    setState(() {
                      showEmailForm = true;
                    });
                  },
                  child: Text(
                    'login'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          secondChild: EmailLoginForm(
            onBack: () {
              setState(() {
                showEmailForm = false;
              });
            },
          ),
        ),
      ),
    );
  }
}

class OAuthButtom extends StatelessWidget {
  const OAuthButtom({super.key});

  Widget _buildGoogleButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CupertinoButton(
      padding: const EdgeInsets.all(0),
      child: Container(
        padding: const EdgeInsets.all(12.5),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.transparent : const Color(0xFFC5C5C5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/google.svg', height: 24, width: 24),
            const SizedBox(width: 5),
            Text(
              'loginWithGoogle'.tr(),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      onPressed: () {
        AuthService.signInWithGoogle();
      },
    );
  }

  Widget _buildAppleButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CupertinoButton(
      padding: const EdgeInsets.all(0),
      child: Container(
        padding: const EdgeInsets.all(12.5),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white : Colors.black,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.transparent : const Color(0xFFC5C5C5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/apple.svg',
              height: 24,
              width: 24,
              colorFilter: isDark
                  ? const ColorFilter.mode(Colors.black, BlendMode.srcIn)
                  : const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            const SizedBox(width: 5),
            Text(
              'loginWithApple'.tr(),
              style: TextStyle(
                color: isDark ? Colors.black : Colors.white,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      onPressed: () {
        AuthService.signInWithApple();
      },
    );
  }

  Widget _buildAgorasButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CupertinoButton(
      padding: const EdgeInsets.all(0),
      child: Container(
        padding: const EdgeInsets.all(12.5),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.transparent : const Color(0xFFC5C5C5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/AgorasLogo.png', height: 24, width: 24),
            const SizedBox(width: 5),
            Text(
              'loginWithAgoras'.tr(),
              style: TextStyle(
                color: isDark ? Colors.black : Colors.white,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      onPressed: () {
        AuthService.signInWithAgoras();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS || Platform.isMacOS) {
      return Column(
        children: [
          _buildAppleButton(context),
          _buildGoogleButton(context),
          _buildAgorasButton(context),
        ],
      );
    }

    // For Android and other platforms, just show Google
    return Column(
      children: [
        _buildGoogleButton(context),
        _buildAgorasButton(context),
      ],
    );
  }
}
