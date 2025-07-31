import 'dart:io';
import 'package:health/health.dart';

class HealthService {
  static final Health _health = Health();
  
  static const List<HealthDataType> _dataTypes = [
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WORKOUT,
  ];

  static Future<bool> requestHealthPermissions() async {
    print('HealthService: 건강 권한 요청 시작');
    
    if (!Platform.isIOS) {
      print('HealthService: iOS가 아니므로 건강 권한 건너뜀');
      return true;
    }
    
    try {
      // 권한 요청
      bool authorized = await _health.requestAuthorization(_dataTypes);
      print('HealthService: 건강 권한 요청 결과: $authorized');
      
      if (authorized) {
        // 각 데이터 타입별 권한 상태 확인
        for (var dataType in _dataTypes) {
          var status = await _health.hasPermissions([dataType]);
          print('HealthService: $dataType 권한 상태: $status');
        }
      }
      
      return authorized;
    } catch (e) {
      print('HealthService: 건강 권한 요청 오류: $e');
      return false;
    }
  }

  static Future<bool> checkHealthPermissions() async {
    if (!Platform.isIOS) {
      return true;
    }
    
    try {
      bool hasPermissions = await _health.hasPermissions(_dataTypes) ?? false;
      print('HealthService: 현재 건강 권한 상태: $hasPermissions');
      return hasPermissions;
    } catch (e) {
      print('HealthService: 건강 권한 확인 오류: $e');
      return false;
    }
  }

  static Future<int?> getStepsToday() async {
    if (!Platform.isIOS) {
      return null;
    }
    
    try {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startOfDay,
        endTime: now,
      );
      
      if (healthData.isNotEmpty) {
        int steps = 0;
        for (var point in healthData) {
          if (point.value is NumericHealthValue) {
            steps += (point.value as NumericHealthValue).numericValue.toInt();
          }
        }
        print('HealthService: 오늘 걸음 수: $steps');
        return steps;
      }
    } catch (e) {
      print('HealthService: 걸음 수 가져오기 오류: $e');
    }
    
    return null;
  }
}