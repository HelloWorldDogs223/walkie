import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/permission_service.dart';

class AlwaysLocationPage extends StatelessWidget {
  const AlwaysLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D4A9B), // 진한 파란색 배경
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 위치 아이콘
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 40,
                    color: Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(height: 24),
                // 제목
                const Text(
                  '위치 \'항상 허용\' 권한 안내',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // 설명 텍스트
                const Text(
                  '워키에서는 활동 기록에 걸기 운동 경로를 표시하고, 위치가 행정만찬 힘찬 참여를 위해 위치권한 \'항상 허용\'을 권장하고 있습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  '위치 권한을 \'항상 허용\'하지 않아도 앱을 사용할 수 있지만, 앱을 끄고 있을 때는 위치 정보를 읽을 수 없어 \'항상 허용\'하지 않으면 일부 위치 기반 서비스가 제한될 수 있습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // 권한 요청 안내
                const Text(
                  '권한 > 위치 > 항상 허용으로 설정해 주세요.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // 버튼들
                Row(
                  children: [
                    // 거부 버튼
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            // 프로필 설정 페이지로 이동
                            context.go('/profile');
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            '거부',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 설정 버튼
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            // 설정 앱으로 이동
                            await openAppSettings();
                            // 설정에서 돌아오면 프로필 설정 페이지로 이동
                            if (context.mounted) {
                              context.go('/profile');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '설정',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}