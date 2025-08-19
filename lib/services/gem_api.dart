import 'dart:convert';

import 'package:dio/dio.dart';
import '../providers/auth_provider.dart'; // AuthProvider import
import '../api/api_client.dart';
import '../api/api_constants.dart';

class GemApi {
  final ApiClient apiClient;

  GemApi({required this.apiClient});

  Future<int> fetchWallet() async {
    final response = await apiClient.get(ApiConstants.gemBase + 'wallet/');
    return json.decode(response.body)['balance'] as int;
  }

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
