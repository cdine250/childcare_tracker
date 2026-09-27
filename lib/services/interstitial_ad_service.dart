import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdService {
  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  void loadAd() {
    if (_isLoading || _interstitialAd != null) {
      return;
    }

    _isLoading = true;

    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _isLoading = false;
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  void showAd() {
    final InterstitialAd? ad = _interstitialAd;

    if (ad == null) {
      loadAd();
      return;
    }

    _interstitialAd = null;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadAd();
      },
    );

    ad.show();
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}