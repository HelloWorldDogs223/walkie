import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              // WALKIE 로고
              Column(
                children: [
                  Container(
                    child: Text(
                      'WALKIE',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4285F4),
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '걷기의 즐거움 위기와 함께',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 4),
              // 로그인 버튼들
              Column(
                children: [
                  // 카카오 로그인
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.go('/terms');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFE812),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      icon: Container(
                        width: 24,
                        height: 24,
                        child: Image.asset(
                          'lib/assets/kakao.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                      label: Text(
                        '카카오 로그인',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 네이버 로그인
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.go('/terms');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF03C75A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      icon: Container(
                        width: 24,
                        height: 24,
                        child: Image.asset(
                          'lib/assets/naver.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                      label: Text(
                        '네이버 로그인',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 구글 로그인
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.go('/terms');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      icon: Container(
                        width: 24,
                        height: 24,
                        child: Image.asset(
                          'lib/assets/google.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                      label: Text(
                        '구글로 로그인',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}