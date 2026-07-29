import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-8578170674294985/8504839265';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-8578170674294985/3472773891'; // <-- ¡Cambia esto!
    }
    return '';
  }

  static final BannerAd _bannerAd = BannerAd(
    adUnitId: bannerAdUnitId,
    size: AdSize.banner,
    request: AdRequest(),
    listener: BannerAdListener(
      onAdLoaded: (ad) {},
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
      },
    ),
  );

  static void loadBannerAd() {
    _bannerAd.load();
  }

  static void disposeBannerAd() {
    _bannerAd.dispose();
  }

  static Widget getBannerAdWidget() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: _bannerAd.size.width.toDouble(),
        height: _bannerAd.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd),
      ),
    );
  }
}
