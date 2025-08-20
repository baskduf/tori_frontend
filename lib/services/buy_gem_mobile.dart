import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart' as iap;

Future<void> buyGem({
  required int amount,
  required Map<int, String> productIdByAmount,
  required void Function(String msg) showSnack,
  required Future<void> Function(String productId, String purchaseToken, String orderId) verifyPurchase,
  List? products,            // 모바일 전용, 웹에서는 무시
  dynamic? iapInstance,      // 모바일 전용, 웹에서는 무시
}) async {
  final productId = productIdByAmount[amount]!;

  try {
    // 서버에 결제 시작 요청
    final response = await http.post(
      Uri.parse('https://yourserver.com/start_google_pay'),
      body: jsonEncode({'productId': productId}),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body);
    final token = data['token'] as String?;

    if (token == null || token.isEmpty) {
      showSnack('웹 결제 토큰을 받지 못했습니다.');
    } else {
      final orderId = 'web_${DateTime.now().millisecondsSinceEpoch}';
      await verifyPurchase(productId, token, orderId);
    }
  } catch (e) {
    showSnack('웹 결제 요청 실패: $e');
  }
}
