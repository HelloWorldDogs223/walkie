import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';

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
    
    if (!Platform.isIOS && !Platform.isAndroid) {
      print('HealthService: iOS/Android가 아니므로 건강 권한 건너뜀');
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
    if (!Platform.isIOS && !Platform.isAndroid) {
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
    if (!Platform.isIOS && !Platform.isAndroid) {
      print('HealthService: 지원되지 않는 플랫폼');
      return null;
    }
    
    try {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      
      print('HealthService: 걸음수 데이터 요청 - ${Platform.operatingSystem}');
      print('HealthService: 시간 범위: $startOfDay ~ $now');
      
      // Android에서는 각 데이터 소스를 명시적으로 지정
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startOfDay,
        endTime: now,
      );
      
      print('HealthService: 가져온 데이터 포인트 수: ${healthData.length}');
      
      if (healthData.isNotEmpty) {
        int steps = 0;
        for (var point in healthData) {
          print('HealthService: 데이터 포인트: ${point.value}, 소스: ${point.sourceName}');
          if (point.value is NumericHealthValue) {
            int pointSteps = (point.value as NumericHealthValue).numericValue.toInt();
            steps += pointSteps;
            print('HealthService: 추가된 걸음수: $pointSteps, 총계: $steps');
          }
        }
        print('HealthService: 최종 오늘 걸음 수: $steps');
        return steps;
      } else {
        print('HealthService: 가져온 건강 데이터가 없음');
        
        // Android에서 Samsung Health 연동 확인
        if (Platform.isAndroid) {
          print('HealthService: Android에서 Samsung Health 또는 Google Fit 연동이 필요할 수 있음');
        }
      }
    } catch (e) {
      print('HealthService: 걸음 수 가져오기 오류: $e');
      print('HealthService: 오류 스택: ${e.toString()}');
    }
    
    return null;
  }
  
  // 가속도계 기반 걸음 감지
  static StreamSubscription? _accelerometerSubscription;
  static int _quickStepCount = 0; // 가속도계로 감지한 걸음수
  static DateTime _lastStepTime = DateTime.now();
  static final _quickStepController = StreamController<int>.broadcast();
  
  static Future<void> initPedometer() async {
    try {
      final platform = Platform.isIOS ? 'iOS' : 'Android';
      print('HealthService: 가속도계 전용 모드 초기화 시작 ($platform)');
      
      // 가속도계만 초기화
      _initAccelerometer();
      
      print('HealthService: 가속도계 전용 모드 초기화 완료 ($platform)');
    } catch (e) {
      print('HealthService: 가속도계 초기화 오류: $e');
    }
  }
  
  // 가속도계 필터링을 위한 추가 변수들
  static List<double> _magnitudeHistory = [];
  static List<double> _yAxisHistory = [];
  static double _previousFilteredMagnitude = 0;
  static int _peakCandidateCount = 0;
  static DateTime _lastPeakCandidateTime = DateTime.now();
  
  // 가속도계로 빠른 걸음 감지 (개선된 알고리즘)
  static void _initAccelerometer() {
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      final now = DateTime.now();
      
      // 전체 가속도 크기 계산
      final magnitude = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z
      );
      
      // Y축 가속도 (수직 움직임) 가중치 적용
      final yWeightedMagnitude = math.sqrt(
        event.x * event.x + (event.y * 1.5) * (event.y * 1.5) + event.z * event.z
      );
      
      // 이동 평균 필터링 (최근 3개 값 사용 - 더 빠른 반응)
      _magnitudeHistory.add(yWeightedMagnitude);
      _yAxisHistory.add(event.y.abs());
      
      if (_magnitudeHistory.length > 3) {
        _magnitudeHistory.removeAt(0);
        _yAxisHistory.removeAt(0);
      }
      
      if (_magnitudeHistory.length < 2) return; // 최소 2개 데이터로 시작
      
      final avgMagnitude = _magnitudeHistory.reduce((a, b) => a + b) / _magnitudeHistory.length;
      final avgYAxis = _yAxisHistory.reduce((a, b) => a + b) / _yAxisHistory.length;
      
      final timeDiff = now.difference(_lastStepTime).inMilliseconds;
      final peakTimeDiff = now.difference(_lastPeakCandidateTime).inMilliseconds;
      
      // 플랫폼별 민감도 설정 (더 엄격하게)
      final bool isIOS = Platform.isIOS;
      final threshold = isIOS ? 11.0 : 12.0; // 임계값 상향 조정
      final minInterval = isIOS ? 400 : 450; // 최소 간격 늘려서 예민도 감소
      final yAxisThreshold = isIOS ? 2.0 : 2.5; // Y축 임계값 상향 조정
      
      // 직접적인 피크 감지 + 필터링된 피크 감지 (두 방식 병행)
      bool isDirectPeak = yWeightedMagnitude > threshold && 
                         yWeightedMagnitude > _previousFilteredMagnitude + 1.5 && // 더 큰 변화량 요구
                         event.y.abs() > yAxisThreshold &&
                         timeDiff > minInterval;
                         
      bool isFilteredPeak = avgMagnitude > threshold && 
                           avgMagnitude > _previousFilteredMagnitude &&
                           avgYAxis > yAxisThreshold &&
                           timeDiff > minInterval;
      
      if (isDirectPeak || isFilteredPeak) {
        _peakCandidateCount++;
        _lastPeakCandidateTime = now;
        
        // 간소화된 검증 (더 빠른 반응)
        if (peakTimeDiff > 30) { // 30ms 내 연속 피크는 무시
          final magnitudeChange = isDirectPeak ? 
            yWeightedMagnitude - _previousFilteredMagnitude :
            avgMagnitude - _previousFilteredMagnitude;
            
          if (magnitudeChange > 1.5) { // 최소 변화량 상향 조정 (0.8 → 1.5)
            _quickStepCount++;
            _lastStepTime = now;
            _peakCandidateCount = 0; // 리셋
            _quickStepController.add(_quickStepCount);
            final platformInfo = isIOS ? 'iOS' : 'Android';
            print('HealthService: [$platformInfo] 가속도계 걸음 감지! (${isDirectPeak ? '직접' : '필터'}, 임계값: ${threshold.toStringAsFixed(1)}, 크기: ${(isDirectPeak ? yWeightedMagnitude : avgMagnitude).toStringAsFixed(1)}) 총 $_quickStepCount 걸음');
          }
        }
      }
      
      // 피크 후보 카운트 리셋 (1초 후)
      if (peakTimeDiff > 1000) {
        _peakCandidateCount = 0;
      }
      
      _previousFilteredMagnitude = avgMagnitude;
    });
  }
  
  // 빠른 걸음수 스트림
  static Stream<int> get quickStepStream => _quickStepController.stream;
  
  // 가속도계 걸음수 리셋
  static void resetQuickStepCount([int startValue = 0]) {
    _quickStepCount = startValue;
    // 필터링 변수들도 모두 리셋
    _magnitudeHistory.clear();
    _yAxisHistory.clear();
    _previousFilteredMagnitude = 0;
    _peakCandidateCount = 0;
    _lastPeakCandidateTime = DateTime.now();
    print('HealthService: 가속도계 걸음수 및 필터링 변수 리셋 (시작값: $startValue)');
  }
  
  // 거리 계산 (미터)
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // 지구 반지름 (미터)
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    double distance = earthRadius * c;
    
    return distance; // 미터 단위
  }
  
  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
  
  // 칼로리 계산 (개선된 공식: 걸음수 + 거리 기반)
  static double calculateCalories(int steps, {double distanceInMeters = 0.0}) {
    // 기본 공식: METs 방식 사용
    // 걷기 (3-4km/h): 3.5 METs
    // 칼로리 = METs × 체중(kg) × 시간(시간)
    
    const double averageWeight = 65.0; // 평균 체중 (kg)
    const double walkingMET = 3.5; // 일반 걷기 METs
    
    if (distanceInMeters > 0) {
      // 거리 기반 계산 (더 정확함)
      const double avgWalkingSpeedKmh = 4.0; // 평균 걷기 속도 4km/h
      final double timeInHours = (distanceInMeters / 1000) / avgWalkingSpeedKmh;
      final double calories = walkingMET * averageWeight * timeInHours;
      return calories;
    } else {
      // 걸음수 기반 계산 (백업)
      // 평균: 1걸음 = 0.7미터, 4km/h 속도 가정
      const double averageStepLength = 0.7; // 미터
      final double estimatedDistance = steps * averageStepLength;
      final double timeInHours = (estimatedDistance / 1000) / 4.0;
      final double calories = walkingMET * averageWeight * timeInHours;
      return calories;
    }
  }
  
  // 오늘 걸음수 리셋
  static Future<void> resetTodaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    await prefs.remove('base_steps_$todayKey');
    print('HealthService: 오늘 걸음수 리셋 완료');
  }
  
  
  // 오늘 걸음수 계산 (안정화된 기준점 저장 방식)
  static Future<int> calculateTodaySteps(int currentTotalSteps) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    // 오늘 날짜의 기준점 가져오기
    int? todayBaseSteps = prefs.getInt('base_steps_$todayKey');
    
    if (todayBaseSteps == null) {
      // 오늘 처음 실행하는 경우 - 기준점 설정 후 약간의 지연
      await prefs.setInt('base_steps_$todayKey', currentTotalSteps);
      print('HealthService: 오늘 기준점 설정: $currentTotalSteps');
      
      // 기준점 설정 직후에는 기존 걸음수가 있을 수 있음 (하루 중간에 앱 설치한 경우)
      // Health API에서 오늘 걸음수를 직접 가져와서 사용
      final healthSteps = await getStepsToday();
      if (healthSteps != null && healthSteps > 0) {
        print('HealthService: Health API에서 가져온 오늘 걸음수: $healthSteps');
        return healthSteps;
      }
      
      return 0; // Health 데이터가 없으면 0부터 시작
    }
    
    // 오늘 걸음수 = 현재 총 걸음수 - 오늘 기준점
    int todaySteps = currentTotalSteps - todayBaseSteps;
    
    // 음수가 나오면 기준점이 잘못된 것 - 재설정
    if (todaySteps < 0) {
      print('HealthService: 기준점 오류 감지, 재설정 ($todaySteps < 0)');
      await prefs.setInt('base_steps_$todayKey', currentTotalSteps);
      return 0;
    }
    
    // 비정상적으로 큰 값이면 Health API 데이터로 보정
    if (todaySteps > 50000) { // 하루 5만보는 비현실적
      final healthSteps = await getStepsToday();
      if (healthSteps != null && healthSteps < todaySteps) {
        print('HealthService: 비정상 값 감지, Health API로 보정: $todaySteps -> $healthSteps');
        return healthSteps;
      }
    }
    
    print('HealthService: 오늘 걸음수: $todaySteps (총: $currentTotalSteps, 기준: $todayBaseSteps)');
    return todaySteps;
  }
  
  // 가속도계 상태 진단
  static void diagnosticAccelerometerStatus() {
    final platform = Platform.isIOS ? 'iOS' : 'Android';
    print('=== 가속도계 상태 진단 [$platform] ===');
    print('가속도계 걸음수: $_quickStepCount');
    print('가속도계 구독: ${_accelerometerSubscription != null ? '활성' : '비활성'}');
    print('필터링 기록 수: ${_magnitudeHistory.length}개');
    print('임계값: ${Platform.isIOS ? '9.0 (iOS 최적화)' : '10.5 (Android)'}');
    print('==================================');
  }

  // 어제 데이터 정리 (선택사항)
  static Future<void> cleanupOldStepData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final today = DateTime.now();
      
      for (String key in keys) {
        if (key.startsWith('base_steps_')) {
          final dateStr = key.replaceFirst('base_steps_', '');
          final parts = dateStr.split('-');
          if (parts.length == 3) {
            final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            final daysDiff = today.difference(date).inDays;
            
            // 7일 이상 오래된 데이터 삭제
            if (daysDiff > 7) {
              await prefs.remove(key);
              print('HealthService: 오래된 데이터 삭제: $key');
            }
          }
        }
      }
    } catch (e) {
      print('HealthService: 오래된 데이터 정리 오류: $e');
    }
  }
}