import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api/api_constants.dart';

//TODO
class RewardedAdService {
  RewardedAd? _rewardedAd;

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: '<YOUR_AD_UNIT_ID>',
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          print('Rewarded ad loaded.');
        },
        onAdFailedToLoad: (err) {
          print('Failed to load rewarded ad: $err');
        },
      ),
    );
  }

  void showRewardedAd(String token) {
    if (_rewardedAd == null) return;

    _rewardedAd!.show(onUserEarnedReward: (ad, reward) async {
      print('User earned reward: ${reward.amount}');
      await _grantRewardToServer(reward.amount.toInt(), '<YOUR_AD_UNIT_ID>', token);
    });
  }

  Future<void> _grantRewardToServer(int rewardAmount, String adUnitId, String token) async {
    final response = await http.post(
      Uri.parse(ApiConstants.rewardedAd),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'reward_amount': rewardAmount,
        'ad_unit_id': adUnitId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('New balance: ${data['new_balance']}');
    } else {
      final error = jsonDecode(response.body);
      print('Failed to grant reward: ${error['error']}');
    }
  }
}
