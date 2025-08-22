import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart' as iap;
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../services/gem_api.dart';
import 'dart:async';
// import 'dart:js' as js;
import 'kakao_pay_terms_screen.dart';
import '../services/buy_gem.dart';

class GemStoreScreen extends StatefulWidget {
  const GemStoreScreen({super.key});

  @override
  State<GemStoreScreen> createState() => _GemStoreScreenState();
}

class _GemStoreScreenState extends State<GemStoreScreen> {
  late GemApi _api;
  int _balance = 0;
  bool _busy = false;

  final Map<int, String> productIdByAmount = const {
    50: 'gem_50',
    100: 'gem_100',
    300: 'gem_300',
    500: 'gem_500',
    1000: 'gem_1000',
  };

  final iap.InAppPurchase _iap = iap.InAppPurchase.instance;
  StreamSubscription<List<iap.PurchaseDetails>>? _purchaseSub;
  List<iap.ProductDetails> _products = [];
  bool _storeAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.accessToken;
    if (token == null) {
      _snack('로그인 후 이용해주세요.');
      return;
    }
    // 예: main.dart나 GemStoreScreen에서
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

// GemApi 생성
    final apiClient = ApiClient(authProvider: authProvider, navigatorKey: navigatorKey);

    _api = GemApi(apiClient: apiClient);

    await _refreshWallet();
    if (!kIsWeb) await _initMobileStore();
  }

  Future<void> _refreshWallet() async {
    try {
      final bal = await _api.fetchWallet();
      setState(() => _balance = bal);
    } catch (e) {
      _snack('잔액 조회 실패: $e');
    }
  }

  Future<void> _initMobileStore() async {
    final available = await _iap.isAvailable();
    setState(() => _storeAvailable = available);
    if (!available) return;

    final ids = productIdByAmount.values.toSet();
    final resp = await _iap.queryProductDetails(ids);
    setState(() => _products = resp.productDetails);

    _purchaseSub = _iap.purchaseStream.listen((purchases) async {
      for (final p in purchases) {
        if (p.status == iap.PurchaseStatus.purchased) {
          await _verifyPurchase(p.productID, p.verificationData.serverVerificationData,
              p.purchaseID ?? 'order_${DateTime.now().millisecondsSinceEpoch}');
        } else if (p.status == iap.PurchaseStatus.error) {
          _snack('결제 실패: ${p.error}');
        }
      }
    }, onDone: () => _purchaseSub?.cancel(), onError: (e) => debugPrint('purchaseStream error: $e'));
  }

  // Future<void> _buyGem(int amount) async {
  //   setState(() => _busy = true);
  //   final productId = productIdByAmount[amount]!;
  //
  //   try {
  //     if (kIsWeb) {
  //       final token = js.context.callMethod('startGooglePayPurchase', [productId]) as String?;
  //       if (token == null || token.isEmpty) {
  //         _snack('웹 결제 토큰을 받지 못했습니다.');
  //       } else {
  //         await _verifyPurchase(productId, token, 'web_${DateTime.now().millisecondsSinceEpoch}');
  //       }
  //     } else {
  //       final pd = _products.firstWhere(
  //             (p) => p.id == productId,
  //         orElse: () => throw Exception('상품($productId)이 스토어에 없습니다.'),
  //       );
  //       final param = iap.PurchaseParam(productDetails: pd);
  //       await _iap.buyConsumable(purchaseParam: param);
  //     }
  //   } catch (e) {
  //     _snack('결제 요청 실패: $e');
  //   } finally {
  //     setState(() => _busy = false);
  //   }
  // }

  // 버튼에서 호출할 공용 buyGem 래퍼
  Future<void> _onBuyGem(int amount) async {
    setState(() => _busy = true);
    try {
      await buyGem(
        amount: amount,
        productIdByAmount: productIdByAmount,
        products: _products,            // 모바일 전용
        iapInstance: _iap,              // 모바일 전용
        showSnack: _snack,              // 공용
        verifyPurchase: _verifyPurchase, // 웹 전용
      );
    } catch (e) {
      _snack('결제 실패: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _verifyPurchase(String productId, String purchaseToken, String orderId) async {
    setState(() => _busy = true);
    try {
      final provider = kIsWeb ? 'google_pay' : 'play';
      final res = await _api.confirmPurchase(
          provider: provider, productId: productId, purchaseToken: purchaseToken, orderId: orderId);
      if (res) {
        await _refreshWallet();
        _snack('결제 완료! 잔액이 갱신되었습니다.');
      } else {
        _snack('서버 검증 실패');
      }
    } on DioException catch (e) {
      _snack('서버 검증 실패: ${e.response?.data ?? e.message}');
    } catch (e) {
      _snack('서버 검증 실패: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _onFreeGemAd() async {
    setState(() => _busy = true);
    // try {
    //   // TODO: 광고 SDK 호출 후 성공 시 GEM 지급
    //   // 예시: 광고 시청 성공 시 서버 호출
    //   final success = await _api.grantFreeGem();
    //   if (success) {
    //     await _refreshWallet();
    //     _snack('광고 시청 완료! 무료 GEM이 지급되었습니다.');
    //   } else {
    //     _snack('무료 GEM 지급 실패');
    //   }
    // } catch (e) {
    //   _snack('오류 발생: $e');
    // } finally {
    //   setState(() => _busy = false);
    // }
  }


  int _priceForGem(int gemAmount) {
    // 예시: GEM 50 → 1000₩, GEM 100 → 2000₩ 등
    switch (gemAmount) {
      case 50:
        return 1000;
      case 100:
        return 2000;
      case 300:
        return 5000;
      case 500:
        return 8000;
      case 1000:
        return 15000;
      default:
        return gemAmount * 20;
    }
  }

  @override
  Widget build(BuildContext context) {
    final amounts = [50, 100, 300, 500, 1000];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Gem Store',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Chip(
              backgroundColor: Colors.white12,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.diamond, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$_balance',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 광고형 무료 GEM 버튼 (구매 버튼과 동일 디자인)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton(
                onPressed: _busy
                    ? null
                    : () async {
                  setState(() => _busy = true);
                  try {
                    await _onFreeGemAd();
                  } catch (e) {
                    _snack('무료 GEM 획득 실패: $e');
                  } finally {
                    setState(() => _busy = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.diamond, color: Colors.amber, size: 28),
                        SizedBox(width: 12),
                        Text(
                          '50 GEM',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      '광고 시청 후 획득',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

            // GEM 구매 버튼 리스트
            Expanded(
              child: ListView.builder(
                itemCount: amounts.length,
                itemBuilder: (context, index) {
                  final amt = amounts[index];
                  final price = _priceForGem(amt);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ElevatedButton(
                      onPressed: _busy
                          ? null
                          : () async {
                        setState(() => _busy = true);
                        try {
                          await _onBuyGem(amt);
                        } catch (e) {
                          _snack('결제 실패: $e');
                        } finally {
                          setState(() => _busy = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.diamond, color: Colors.amber, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                '$amt GEM',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$price ₩',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: Colors.amber,
                ),
              ),

            // 이용약관 버튼 (작게, 오른쪽 하단)
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const KakaoPayTermsScreen(),
                    ),
                  );
                },
                child: const Text(
                  '이용약관',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white38,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
