import 'dart:ui';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../api/gem_api.dart';

class RewardedAdService {
  final GemApi gemApi; // 서버 호출용 GemApi
  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  RewardedAdService({required this.gemApi});

  void loadAd(String adUnitId) {
    if (_isLoading) return;
    _isLoading = true;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          print('RewardedAd loaded');
        },
        onAdFailedToLoad: (error) {
          print('Failed to load RewardedAd: $error');
          _rewardedAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  void showAd(String adUnitId, VoidCallback onRewarded) {
    if (_rewardedAd == null) {
      print('Ad not loaded yet. Loading...');
      loadAd(adUnitId);
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadAd(adUnitId); // 다음 광고 미리 로드
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('Failed to show ad: $error');
        ad.dispose();
        loadAd(adUnitId);
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        print('User earned reward - server SSV will handle actual payout');
        onRewarded(); // UI 알림만
      },
    );


    _rewardedAd = null;
  }
}
