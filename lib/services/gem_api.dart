import 'package:dio/dio.dart';
import '../providers/auth_provider.dart'; // AuthProvider import

class GemApi {
  final Dio _dio;
  final AuthProvider authProvider;

  GemApi(String baseUrl, {required this.authProvider})
      : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    // 요청 인터셉터 추가
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = authProvider.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<int> fetchWallet() async {
    final res = await _dio.get('/wallet/');
    return res.data['balance'] as int;
  }

  Future<Response> confirmPurchase({
    required String provider, // 'play' | 'google_pay'
    required String productId,
    required String purchaseToken,
    required String orderId,
  }) {
    return _dio.post(
      '/purchase/confirm/',
      data: {
        'provider': provider,
        'product_id': productId,
        'purchase_token': purchaseToken,
        'order_id': orderId,
      },
    );
  }
}
