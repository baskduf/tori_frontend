// lib/screens/widgets/searching_widget.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../api/api_constants.dart';

class SearchingWidget extends StatefulWidget {
  final Widget Function({required Widget child, double? width, double? height}) glassContainerBuilder;
  final Animation<double> rotationAnimation;

  const SearchingWidget({
    super.key,
    required this.glassContainerBuilder,
    required this.rotationAnimation,
  });

  @override
  State<SearchingWidget> createState() => _SearchingWidgetState();
}

class _SearchingWidgetState extends State<SearchingWidget>
    with SingleTickerProviderStateMixin {
  int _dotCount = 1;
  late Timer _dotTimer;

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  int _matchingUsers = 30 + Random().nextInt(171); // 30~200 초기값
  late Timer _userCountTimer;

  @override
  void initState() {
    super.initState();

    _loadBannerAd();

    // 점 애니메이션
    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() {
        _dotCount = _dotCount % 4 + 1;
      });
    });

    // 매칭 유저 수 천천히 변화
    _userCountTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      setState(() {
        _matchingUsers += Random().nextInt(3) - 1; // -1,0,+1
        if (_matchingUsers < 30) _matchingUsers = 30;
        if (_matchingUsers > 200) _matchingUsers = 200;
      });
    });

    // 파동 애니메이션
    _waveController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _waveAnimation =
        Tween<double>(begin: 0, end: 60).animate(CurvedAnimation(
          parent: _waveController,
          curve: Curves.easeOut,
        ));
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: ApiConstants.rewardedAdUnitId, // 실제 배너 ID로 교체
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() => _isBannerAdReady = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('BannerAd failed: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _dotTimer.cancel();
    _userCountTimer.cancel();
    _waveController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  String get _dots => '.' * _dotCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 광고 영역
        if (_isBannerAdReady)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          ),

        // 지구 아이콘 + 파동 애니메이션
        Stack(
          alignment: Alignment.center,
          children: [
            // 파동 원
            AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return Container(
                  width: _waveAnimation.value,
                  height: _waveAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white24
                        .withOpacity(1 - _waveAnimation.value / 60),
                  ),
                );
              },
            ),
            widget.glassContainerBuilder(
              width: 140,
              height: 140,
              child: RotationTransition(
                turns: widget.rotationAnimation,
                child: const Icon(
                  Icons.public,
                  size: 80,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),
        // 매칭 중 안내
        Text(
          '매칭 상대를 찾는 중$_dots',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            shadows: [
              Shadow(
                color: Colors.black54,
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        // 매칭 유저 수 안내
        Text(
          '현재 $_matchingUsers명의 유저가 매칭중입니다.\n당신과 가장 적합한 매칭을 찾고 있습니다.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.white54,
            shadows: [
              Shadow(
                color: Colors.black45,
                offset: Offset(0, 1),
                blurRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
