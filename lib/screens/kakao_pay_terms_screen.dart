import 'package:flutter/material.dart';

class KakaoPayTermsScreen extends StatelessWidget {
  const KakaoPayTermsScreen({Key? key}) : super(key: key);

  final String termsText = '''
카카오페이 이용약관

1. 결제 취소
- 결제 완료 후 7일 이내에는 전체 또는 부분 취소가 가능합니다.
- 취소 시 결제 금액은 결제 수단으로 즉시 환불됩니다.

2. 환불 규정
- 상품이 이미 배송된 경우에는 환불이 제한될 수 있습니다.
- 디지털 콘텐츠 결제의 경우, 다운로드 또는 이용 시작 시 환불이 불가합니다.

3. 기타
- 환불 요청은 고객센터를 통해 접수 가능합니다.
- 기타 카카오페이 정책에 따라 처리됩니다.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        title: const Text('카카오페이 이용약관'),
        backgroundColor: Colors.grey[900],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.7),
                      offset: const Offset(0, 3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Text(
                    termsText,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
