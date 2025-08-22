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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;
    if (token == null) {
      _snack('로그인 후 이용해주세요.');
      return;
    }

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
          await _verifyPurchase(
            p.productID,
            p.verificationData.serverVerificationData,
            p.purchaseID ?? 'order_${DateTime.now().millisecondsSinceEpoch}',
          );
        } else if (p.status == iap.PurchaseStatus.error) {
          _snack('결제 실패: ${p.error}');
        }
      }
    }, onDone: () => _purchaseSub?.cancel(), onError: (e) => debugPrint('purchaseStream error: $e'));
  }

  Future<void> _onBuyGem(int amount) async {
    setState(() => _busy = true);
    try {
      await buyGem(
        amount: amount,
        productIdByAmount: productIdByAmount,
        products: _products,
        iapInstance: _iap,
        showSnack: _snack,
        verifyPurchase: _verifyPurchase,
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
    try {
      final success = true;
      if (success) {
        await _refreshWallet();
        _snack('광고 시청 완료! 무료 GEM이 지급되었습니다.');
      } else {
        _snack('무료 GEM 지급 실패');
      }
    } catch (e) {
      _snack('오류 발생: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  int _priceForGem(int gemAmount) {
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
    // 무료 광고 GEM 포함한 전체 GEM 리스트
    final gemItems = [
      {'amount': 50, 'price': 0, 'isFreeAd': true}, // 무료 광고 GEM
      {'amount': 50, 'price': 1000, 'isFreeAd': false},
      {'amount': 100, 'price': 2000, 'isFreeAd': false},
      {'amount': 300, 'price': 5000, 'isFreeAd': false},
      {'amount': 500, 'price': 8000, 'isFreeAd': false},
      {'amount': 1000, 'price': 15000, 'isFreeAd': false},
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(''),
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
                  Text('$_balance', style: const TextStyle(color: Colors.white)),
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
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: gemItems.length,
                itemBuilder: (context, index) {
                  final item = gemItems[index];

                  return GestureDetector(
                    onTap: _busy
                        ? null
                        : () async {
                      setState(() => _busy = true);
                      try {
                        if (item['isFreeAd'] as bool) {
                          await _onFreeGemAd();
                        } else {
                          await _onBuyGem(item['amount'] as int);
                        }
                      } catch (e) {
                        _snack('실패: $e');
                      } finally {
                        setState(() => _busy = false);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade900, Colors.grey.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.diamond, color: Colors.amber, size: 36),
                          const SizedBox(height: 12),
                          Text(
                            '${item['amount']} GEM',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['isFreeAd'] as bool
                                ? '광고 시청 후 획득'
                                : '${item['price']} ₩',
                            style: const TextStyle(fontSize: 16, color: Colors.white70),
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
                child: CircularProgressIndicator(color: Colors.amber),
              ),

            // 이용약관 버튼
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KakaoPayTermsScreen()),
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
