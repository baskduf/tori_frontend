import 'package:flutter/material.dart';

class AppFooterInfo extends StatelessWidget {
  const AppFooterInfo({Key? key}) : super(key: key);

  /*final String infoText =
      '토리(주)\n'
      '사업자등록번호: 834-06-03324\n'
      '주소: 경산시 조영동 578-12\n'
      '전화번호: 010-9251-1437';*/

  final String infoText =
      '실시간 음성 매칭 플랫폼 - 토리\n'
      '현재 베타 테스트 중입니다.\n'
      '만약 오류가 있을시 홈 화면 좌측 하단으로 DM 부탁드립니다.';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter, // 하단 중앙
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 16.0, right: 16.0),
        child: Opacity(
          opacity: 0.5, // 반투명
          child: Text(
            infoText,
            textAlign: TextAlign.center, // 가운데 정렬
            style: const TextStyle(
              fontSize: 10, // 아주 작게
              color: Colors.grey, // 회색
              fontWeight: FontWeight.w400,
              height: 1.4, // 줄 간격
            ),
          ),
        ),
      ),
    );
  }
}
