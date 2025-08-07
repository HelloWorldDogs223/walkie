import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/permission_service.dart';

class FirstScreenPage extends StatelessWidget {
  const FirstScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    '앱 접근권한 안내',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    '서비스 이용을 위해 아래 권한이 필요합니다.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(thickness: 1),
                const SizedBox(height: 20),
                const Text(
                  '필수적 접근권한',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildPermissionItem(
                  iconWidget: Image.asset(
                    'assets/footprintIcon.png',
                    width: 24,
                    height: 24,
                  ),
                  title: '신체 활동',
                  description: '실시간 걸음 수 및 활동 상태를 측정합니다.',
                ),
                const SizedBox(height: 16),
                _buildPermissionItem(
                  iconWidget: Image.asset(
                    'assets/locationIcon.png',
                    width: 24,
                    height: 24,
                  ),
                  title: '위치',
                  description: '위치 기반 활동 기록에 사용됩니다.',
                ),
                const SizedBox(height: 16),
                _buildPermissionItem(
                  iconWidget: Image.asset(
                    'assets/BatteryIcon.png',
                    width: 24,
                    height: 24,
                  ),
                  title: '배터리 사용량 최적화 제외',
                  description: '앱을 실행하지 않아도 걸음 수, 활동 기록을 자동으로 측정합니다.',
                ),
                const SizedBox(height: 30),
                const Text(
                  '선택적 접근권한',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildPermissionItem(
                  icon: Icons.camera_alt_outlined,
                  title: '카메라',
                  description: '실시간 걸음 수 및 활동 상태를 측정합니다.',
                ),
                const SizedBox(height: 16),
                _buildPermissionItem(
                  icon: Icons.image_outlined,
                  title: '사진 및 동영상',
                  description: '위치 기반 활동 기록에 사용됩니다.',
                ),
                const SizedBox(height: 16),
                _buildPermissionItem(
                  icon: Icons.notifications_none_outlined,
                  title: '알림',
                  description: '앱 검을 수 수집, 공지사항 안내 등 앱 내 주요 알림을 제공합니다.',
                ),
                const SizedBox(height: 20),
                const Divider(thickness: 1),
                const Text(
                  '• 필수 권한은 다음 단계에서 \'허용\'을 선택해 주세요.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• 선택 권한은 필요 시에만 허용하셔도 됩니다.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      // 로딩 표시
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        // 권한 요청
                        print('권한 요청 시작...');
                        final results =
                            await PermissionService.requestAllPermissions();

                        // 권한 요청 결과 출력
                        print('권한 요청 결과:');
                        results.forEach((key, value) {
                          print('$key: ${value ? "허용됨" : "거부됨"}');
                        });

                        // 필수 권한 확인
                        final activityGranted = results['activity'] ?? false;
                        final locationGranted = results['location'] ?? false;
                        final healthGranted = results['health'] ?? false;
                        final sensorsGranted = results['sensors'] ?? false;
                        final batteryOptimizationGranted =
                            results['batteryOptimization'] ?? false;

                        if (!context.mounted) return;

                        // 로딩 다이얼로그 닫기
                        Navigator.pop(context);

                        print('권한 확인 결과:');
                        print('- 신체 활동: $activityGranted');
                        print('- 위치: $locationGranted');
                        print('- 건강: $healthGranted');
                        print('- 센서: $sensorsGranted');
                        print('- 배터리 최적화: $batteryOptimizationGranted');

                        // 중요 권한들 확인 (위치, 센서, 배터리최적화는 반드시 필요)
                        final criticalPermissionsMissing =
                            !locationGranted ||
                            !sensorsGranted ||
                            (batteryOptimizationGranted && Platform.isAndroid);

                        if (criticalPermissionsMissing) {
                          // 중요 권한이 거부된 경우만 설정 안내
                          final missingPermissions = <String>[];
                          if (!locationGranted) missingPermissions.add('위치');
                          if (!sensorsGranted) {
                            missingPermissions.add('동작 및 피트니스');
                          }
                          if (batteryOptimizationGranted &&
                              Platform.isAndroid) {
                            missingPermissions.add('배터리 최적화 제외');
                          }

                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('필수 권한 필요'),
                              content: Text(
                                '앱을 사용하기 위해서는 ${missingPermissions.join(', ')} 권한이 필요합니다. 설정에서 권한을 허용해주세요.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('닫기'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await openAppSettings();
                                  },
                                  child: const Text('설정으로 이동'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // 핵심 권한들이 허용된 경우 홈으로 이동
                          // (건강 권한이나 센서 권한은 나중에 필요할 때 다시 요청 가능)
                          if (!healthGranted) {
                            print('건강 권한이 거부되었지만 앱 사용은 가능합니다.');
                          }
                          if (!sensorsGranted) {
                            print('센서 권한이 거부되었지만 앱 사용은 가능합니다.');
                          }

                          context.go('/always-location');
                        }
                      } catch (e) {
                        print('권한 요청 중 오류 발생: $e');
                        if (context.mounted) {
                          Navigator.pop(context); // 로딩 다이얼로그 닫기

                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('오류'),
                              content: Text('권한 요청 중 오류가 발생했습니다: $e'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('확인'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    IconData? icon,
    Widget? iconWidget,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: iconWidget ?? Icon(icon, size: 24, color: Colors.grey[700]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
