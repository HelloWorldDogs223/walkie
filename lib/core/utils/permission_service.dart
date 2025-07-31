import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'health_service.dart';

class PermissionService {
  static Future<bool> requestActivityRecognition() async {
    print('활동 권한 요청 중...');
    
    // 현재 권한 상태 확인
    var status = await Permission.activityRecognition.status;
    print('활동 권한 현재 상태: $status');
    
    // 권한이 영구적으로 거부되었는지 확인
    if (status.isPermanentlyDenied) {
      print('활동 권한이 영구적으로 거부됨');
      return false;
    }
    
    // 권한 요청
    status = await Permission.activityRecognition.request();
    print('활동 권한 요청 결과: $status');
    
    return status.isGranted;
  }

  static Future<bool> requestNotification() async {
    print('알림 권한 요청 중...');
    
    var status = await Permission.notification.status;
    print('알림 권한 현재 상태: $status');
    
    if (status.isPermanentlyDenied) {
      print('알림 권한이 영구적으로 거부됨');
      return false;
    }
    
    status = await Permission.notification.request();
    print('알림 권한 요청 결과: $status');
    
    return status.isGranted;
  }

  static Future<bool> requestLocationPermissions() async {
    print('위치 권한 요청 중...');
    
    // 먼저 기본 위치 권한 확인
    var locationStatus = await Permission.location.status;
    print('위치 권한 현재 상태: $locationStatus');
    
    if (locationStatus.isPermanentlyDenied) {
      print('위치 권한이 영구적으로 거부됨');
      return false;
    }
    
    // 위치 권한 요청
    locationStatus = await Permission.location.request();
    print('위치 권한 요청 결과: $locationStatus');
    
    if (locationStatus.isGranted) {
      // iOS의 경우 항상 위치 권한도 요청
      if (Platform.isIOS) {
        final alwaysStatus = await Permission.locationAlways.status;
        print('항상 위치 권한 현재 상태: $alwaysStatus');
        
        if (!alwaysStatus.isPermanentlyDenied) {
          final result = await Permission.locationAlways.request();
          print('항상 위치 권한 요청 결과: $result');
        }
      }
      return true;
    }
    return false;
  }

  static Future<bool> requestSensorPermission() async {
    print('센서/모션 권한 요청 중...');
    
    var status = await Permission.sensors.status;
    print('센서 권한 현재 상태: $status');
    
    if (status.isPermanentlyDenied) {
      print('센서 권한이 영구적으로 거부됨');
      return false;
    }
    
    status = await Permission.sensors.request();
    print('센서 권한 요청 결과: $status');
    
    return status.isGranted;
  }

  static Future<bool> requestBatteryOptimizationDisable() async {
    if (!Platform.isAndroid) {
      print('iOS에서는 배터리 최적화 권한이 필요하지 않습니다.');
      return true;
    }
    
    print('배터리 최적화 제외 권한 요청 중...');
    
    var status = await Permission.ignoreBatteryOptimizations.status;
    print('배터리 최적화 제외 권한 현재 상태: $status');
    
    if (status.isPermanentlyDenied) {
      print('배터리 최적화 제외 권한이 영구적으로 거부됨');
      return false;
    }
    
    if (!status.isGranted) {
      status = await Permission.ignoreBatteryOptimizations.request();
      print('배터리 최적화 제외 권한 요청 결과: $status');
    }
    
    return status.isGranted;
  }

  static Future<Map<String, bool>> requestAllPermissions() async {
    print('플랫폼: ${Platform.isIOS ? "iOS" : "Android"}');
    print('운영체제 버전: ${Platform.operatingSystemVersion}');
    
    final results = <String, bool>{};
    
    // 순차적으로 권한 요청 (한 번에 하나씩)
    print('1. 위치 권한 요청 시작');
    results['location'] = await requestLocationPermissions();
    
    print('2. 신체 활동 권한 요청 시작');
    results['activity'] = await requestActivityRecognition();
    
    print('3. 센서/모션 권한 요청 시작');
    results['sensors'] = await requestSensorPermission();
    
    print('4. 건강 데이터 권한 요청 시작');
    results['health'] = await HealthService.requestHealthPermissions();
    
    print('5. 배터리 최적화 제외 권한 요청 시작');
    results['batteryOptimization'] = await requestBatteryOptimizationDisable();
    
    print('6. 알림 권한 요청 시작');
    results['notification'] = await requestNotification();
    
    print('모든 권한 요청 완료: $results');
    return results;
  }

  static Future<Map<String, bool>> checkPermissionStatus() async {
    final results = <String, bool>{};
    
    results['activity'] = await Permission.activityRecognition.isGranted;
    results['location'] = await Permission.location.isGranted;
    results['locationAlways'] = await Permission.locationAlways.isGranted;
    results['notification'] = await Permission.notification.isGranted;
    
    return results;
  }
}