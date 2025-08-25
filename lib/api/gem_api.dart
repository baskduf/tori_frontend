import 'dart:convert';
import 'api_client.dart';
import 'api_constants.dart';

class GemApi {
  final ApiClient apiClient;

  GemApi({required this.apiClient});

  // 기존 지갑 조회
  Future<int> fetchWallet() async {
    final response = await apiClient.get('${ApiConstants.gemBase}wallet/');
    print(response.body);
    return json.decode(response.body)['balance'] as int;
  }

  // 구매 확인
  Future<bool> confirmPurchase({
    required String provider,
    required String productId,
    required String purchaseToken,
    required String orderId,
  }) async {
    final response = await apiClient.post(
      ApiConstants.gemBase + 'purchase/confirm/',
      body: {
        'provider': provider,
        'product_id': productId,
        'purchase_token': purchaseToken,
        'order_id': orderId,
      },
    );
    return response.statusCode == 200;
  }
}
