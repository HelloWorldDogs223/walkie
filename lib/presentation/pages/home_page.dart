import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/location_service.dart';
import '../../core/utils/health_service.dart';
import '../widgets/exercise_info_card.dart';
import 'after_walk_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // UI 상태
  bool isPaused = false;
  bool isUICollapsed = false;

  // 타이머 관련
  DateTime? _startTime;
  Duration _totalPausedDuration = Duration.zero;
  Timer? _displayTimer;
  DateTime? _pauseStartTime;
  DateTime? _restStartTime;

  // 운동 데이터
  int _stepCount = 0;
  int _pausedStepCount = 0;
  double _totalDistance = 0.0;
  double _totalCalories = 0.0;

  // 지도 관련
  NaverMapController? _mapController;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<int>? _quickStepSubscription;
  Position? _currentPosition;
  Position? _lastPosition;
  NMarker? _userMarker;
  bool _isUserInteracting = false;

  // 경로 추적 관련
  List<NLatLng> _walkingPath = [];
  NPathOverlay? _pathOverlay;

  // 테스트용 시뮬레이션
  Timer? _simulationTimer;
  bool _isSimulationRunning = false;
  int _simulationStep = 0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _quickStepSubscription?.cancel();
    _displayTimer?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _loadSavedData();
    await _loadSavedPath();
    await _initLocation();
    await _initHealthTracking();
    _startTimer();
  }

  // 데이터 저장/로드
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    _pausedStepCount = prefs.getInt('paused_step_count') ?? 0;
    _totalDistance = prefs.getDouble('total_distance') ?? 0.0;
    await _loadTimerState();

    if (isPaused && mounted) {
      setState(() {
        _stepCount = _pausedStepCount;
        _totalCalories = HealthService.calculateCalories(_pausedStepCount);
      });
    }
  }

  Future<void> _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final startTimeMs = prefs.getInt('timer_start_time');
    final totalPausedMs = prefs.getInt('timer_total_paused') ?? 0;
    final pauseStartMs = prefs.getInt('timer_pause_start_time');
    final wasPaused = prefs.getBool('timer_was_paused') ?? false;

    if (startTimeMs != null) {
      _startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
      _totalPausedDuration = Duration(milliseconds: totalPausedMs);

      if (wasPaused && pauseStartMs != null) {
        _pauseStartTime = DateTime.fromMillisecondsSinceEpoch(pauseStartMs);
        isPaused = true;
      }
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('paused_step_count', _stepCount);
    await prefs.setDouble('total_distance', _totalDistance);
    await _saveTimerState();
  }

  Future<void> _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_startTime != null) {
      await prefs.setInt(
        'timer_start_time',
        _startTime!.millisecondsSinceEpoch,
      );
      await prefs.setInt(
        'timer_total_paused',
        _totalPausedDuration.inMilliseconds,
      );
      await prefs.setBool('timer_was_paused', isPaused);

      if (isPaused && _pauseStartTime != null) {
        await prefs.setInt(
          'timer_pause_start_time',
          _pauseStartTime!.millisecondsSinceEpoch,
        );
      } else {
        await prefs.remove('timer_pause_start_time');
      }
    }
  }

  // 경로 저장/로드 관련
  Future<void> _loadSavedPath() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(
      0,
      10,
    ); // YYYY-MM-DD
    final pathKey = 'walking_path_$today';

    final savedPathJson = prefs.getString(pathKey);
    if (savedPathJson != null) {
      try {
        final List<dynamic> pathData = json.decode(savedPathJson);
        _walkingPath = pathData
            .map(
              (point) =>
                  NLatLng(point['lat'] as double, point['lng'] as double),
            )
            .toList();

        debugPrint('오늘 경로 복원: ${_walkingPath.length}개 지점');

        // 경로가 있으면 지도에 다시 그리기
        if (_walkingPath.isNotEmpty && _mapController != null) {
          _updatePathOverlay();
        }
      } catch (e) {
        debugPrint('경로 로드 실패: $e');
        _walkingPath = [];
      }
    }

    // 오래된 경로 정리 (7일 이상)
    await _cleanupOldPaths();
  }

  Future<void> _savePath() async {
    if (_walkingPath.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final pathKey = 'walking_path_$today';

    // 메모리 최적화: 최대 1000개 지점으로 제한
    List<NLatLng> pathToSave = _walkingPath;
    if (pathToSave.length > 1000) {
      // 균등하게 샘플링하여 1000개로 축소
      final step = pathToSave.length / 1000;
      pathToSave = [];
      for (int i = 0; i < _walkingPath.length; i += step.ceil()) {
        pathToSave.add(_walkingPath[i]);
      }
    }

    final pathData = pathToSave
        .map((point) => {'lat': point.latitude, 'lng': point.longitude})
        .toList();

    await prefs.setString(pathKey, json.encode(pathData));
    debugPrint('경로 저장 완료: ${pathToSave.length}개 지점');
  }

  Future<void> _cleanupOldPaths() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

    for (String key in keys) {
      if (key.startsWith('walking_path_')) {
        try {
          final dateStr = key.substring(13); // 'walking_path_' 제거
          final pathDate = DateTime.parse(dateStr);

          if (pathDate.isBefore(cutoffDate)) {
            await prefs.remove(key);
            debugPrint('오래된 경로 삭제: $dateStr');
          }
        } catch (e) {
          // 잘못된 키 형식이면 삭제
          await prefs.remove(key);
        }
      }
    }
  }

  // 위치 관련
  Future<void> _initLocation() async {
    final locationService = ref.read(locationServiceProvider);
    try {
      final position = await locationService.getCurrentLocation();
      setState(() => _currentPosition = position);

      if (_mapController != null) {
        _updateMapPosition(position);
      }

      // 첫 위치를 경로에 추가
      _addToWalkingPath(NLatLng(position.latitude, position.longitude));

      _locationSubscription = locationService.getLocationStream().listen(
        _updateUserLocation,
        onError: (error) => debugPrint('Location error: $error'),
      );
    } catch (e) {
      debugPrint('Failed to get location: $e');
    }
  }

  Future<void> _updateUserLocation(Position position) async {
    if (_lastPosition != null && !isPaused) {
      final distance = HealthService.calculateDistance(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      if (distance >= 5.0) {
        setState(() {
          _totalDistance += distance;
          _totalCalories = HealthService.calculateCalories(
            _stepCount,
            distanceInMeters: _totalDistance,
          );
        });
        await _saveData();

        // 경로에 새로운 위치 추가
        _addToWalkingPath(NLatLng(position.latitude, position.longitude));
      }
    }

    setState(() {
      _currentPosition = position;
      _lastPosition = position;
    });

    debugPrint('위치 업데이트: ${position.latitude}, ${position.longitude}');

    await _updateMapMarker(position);
  }

  Future<void> _updateMapMarker(Position position) async {
    if (_mapController == null) return;

    final newPosition = NLatLng(position.latitude, position.longitude);

    if (_userMarker != null) {
      _mapController!.deleteOverlay(
        NOverlayInfo(type: NOverlayType.marker, id: _userMarker!.info.id),
      );
    }

    final marker = NMarker(
      id: 'user_location',
      position: newPosition,
      icon: const NOverlayImage.fromAssetImage('assets/mainCharacter.png'),
      size: const Size(48, 48),
      anchor: const NPoint(0.5, 0.8),
    );

    _userMarker = marker;
    _mapController!.addOverlay(marker);

    if (!_isUserInteracting) {
      _updateCameraToUserPosition(position.latitude, position.longitude);
    }
  }

  void _updateMapPosition(Position position) {
    final adjustedPosition = _getAdjustedCameraPosition(
      position.latitude,
      position.longitude,
    );
    _mapController!.updateCamera(
      NCameraUpdate.withParams(target: adjustedPosition, zoom: 15),
    );
    _updateMapMarker(position);
  }

  NLatLng _getAdjustedCameraPosition(double lat, double lng) {
    final latOffset = isUICollapsed ? 0.0015 : 0.003;
    return NLatLng(lat - latOffset, lng);
  }

  void _updateCameraToUserPosition(double lat, double lng, {double? zoom}) {
    if (_mapController != null) {
      final adjustedPosition = _getAdjustedCameraPosition(lat, lng);
      final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
        target: adjustedPosition,
        zoom: zoom,
      );
      cameraUpdate.setAnimation(duration: const Duration(milliseconds: 500));
      _mapController!.updateCamera(cameraUpdate);
    }
  }

  // 경로 추적 관련
  void _addToWalkingPath(NLatLng position) {
    _walkingPath.add(position);
    _updatePathOverlay();
    // 경로 추가할 때마다 저장 (비동기로 처리하여 성능 영향 최소화)
    _savePath();
  }

  Future<void> _updatePathOverlay() async {
    if (_mapController == null || _walkingPath.length < 2) return;

    // 기존 경로 오버레이 제거
    if (_pathOverlay != null) {
      _mapController!.deleteOverlay(
        NOverlayInfo(type: NOverlayType.pathOverlay, id: _pathOverlay!.info.id),
      );
    }

    // 새로운 경로 오버레이 생성 (더 예쁜 스타일)
    _pathOverlay = NPathOverlay(
      id: 'walking_path',
      coords: _walkingPath,
      color: const Color(0xFF4169E1), // 더 예쁜 파란색
      width: 6, // 살짝 얇게
      outlineColor: Colors.white,
      outlineWidth: 3, // 테두리 더 두껍게
    );

    _mapController!.addOverlay(_pathOverlay!);
  }

  void _clearWalkingPath() {
    if (_mapController != null && _pathOverlay != null) {
      _mapController!.deleteOverlay(
        NOverlayInfo(type: NOverlayType.pathOverlay, id: _pathOverlay!.info.id),
      );
    }
    _walkingPath.clear();
    _pathOverlay = null;
  }

  // 테스트용 시뮬레이션 함수들
  void _startWalkingSimulation() {
    if (_isSimulationRunning || _currentPosition == null) return;

    _isSimulationRunning = true;
    _simulationStep = 0;

    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _simulateWalkingStep();
    });
  }

  void _stopWalkingSimulation() {
    _simulationTimer?.cancel();
    _isSimulationRunning = false;
    _simulationStep = 0;
  }

  void _simulateWalkingStep() {
    if (_currentPosition == null) return;

    // 시뮬레이션 경로: 작은 원형으로 걷기
    final double radius = 0.0001; // 약 10미터 반경
    final double angle =
        (_simulationStep * 30.0) * (3.14159 / 180.0); // 30도씩 회전

    final double newLat =
        _currentPosition!.latitude + (radius * math.cos(angle));
    final double newLng =
        _currentPosition!.longitude + (radius * math.sin(angle));

    // 가상 Position 객체 생성
    final simulatedPosition = Position(
      latitude: newLat,
      longitude: newLng,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: _currentPosition!.altitude,
      heading: 0.0,
      speed: 1.4, // 평균 걷기 속도 (m/s)
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );

    // 가상으로 걷기 업데이트 트리거
    _simulateWalkingUpdate(simulatedPosition);
    _simulationStep++;

    // 한 바퀴 돌면 리셋
    if (_simulationStep >= 12) {
      _simulationStep = 0;
    }
  }

  Future<void> _simulateWalkingUpdate(Position position) async {
    if (_lastPosition != null && !isPaused) {
      final distance = HealthService.calculateDistance(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      if (distance >= 5.0) {
        setState(() {
          _totalDistance += distance;
          _stepCount += 10; // 가상으로 걸음수도 증가
          _totalCalories = HealthService.calculateCalories(
            _stepCount,
            distanceInMeters: _totalDistance,
          );
        });
        await _saveData();

        // 경로에 새로운 위치 추가
        _addToWalkingPath(NLatLng(position.latitude, position.longitude));
      }
    }

    setState(() {
      _currentPosition = position;
      _lastPosition = position;
    });

    await _updateMapMarker(position);
  }

  // 건강 추적
  Future<void> _initHealthTracking() async {
    try {
      bool hasPermission = await HealthService.requestHealthPermissions();
      if (hasPermission) {
        debugPrint('건강 권한 허용됨');
      }
      await _initPedometer();
    } catch (e) {
      debugPrint('건강 추적 초기화 오류: $e');
    }
  }

  Future<void> _initPedometer() async {
    try {
      await HealthService.initPedometer();
      await HealthService.cleanupOldStepData();

      if (mounted) {
        setState(() {
          _stepCount = _pausedStepCount;
          _totalCalories = HealthService.calculateCalories(
            _pausedStepCount,
            distanceInMeters: _totalDistance,
          );
        });
      }

      _quickStepSubscription = HealthService.quickStepStream.listen((
        quickSteps,
      ) {
        if (mounted && !isPaused) {
          setState(() {
            _stepCount = _pausedStepCount + quickSteps;
            _totalCalories = HealthService.calculateCalories(
              _stepCount,
              distanceInMeters: _totalDistance,
            );
          });
        }
      });
    } catch (e) {
      debugPrint('가속도계 초기화 오류: $e');
    }
  }

  // 타이머 관련
  void _startTimer() {
    _startTime ??= DateTime.now();
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  void _pauseTimer() {
    if (!isPaused) {
      _pauseStartTime = DateTime.now();
      _restStartTime = DateTime.now();
    } else {
      if (_pauseStartTime != null) {
        _totalPausedDuration += DateTime.now().difference(_pauseStartTime!);
        _pauseStartTime = null;
      }
      _restStartTime = null;
    }
  }

  // UI 액션
  Future<void> _togglePause() async {
    _pauseTimer();

    if (!isPaused) {
      setState(() {
        _pausedStepCount = _stepCount;
        isPaused = true;
      });
      await _saveData();
    } else {
      HealthService.resetQuickStepCount();
      setState(() {
        isPaused = false;
        _stepCount = _pausedStepCount;
      });
      await _saveData();
    }
  }

  void _toggleUICollapse() {
    setState(() => isUICollapsed = !isUICollapsed);

    if (_currentPosition != null && _mapController != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _updateCameraToUserPosition(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      });
    }
  }

  Future<void> _openCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사진이 촬영되었습니다!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('카메라를 실행할 수 없습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _onRecord() {
    // 운동 완료 페이지로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AfterWalkPage(
          walkTime: formattedTime,
          walkSteps: formattedSteps,
          walkCalories: formattedCalories,
          walkDistance: formattedMeters,
          restTime: formattedRestTime,
        ),
      ),
    );
  }

  Future<void> _onMyLocationPressed() async {
    if (_currentPosition != null && _mapController != null) {
      debugPrint(
        '현재위치 버튼: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      );
      final cameraPosition = await _mapController!.getCameraPosition();
      _updateCameraToUserPosition(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        zoom: cameraPosition.zoom < 15 ? 15 : cameraPosition.zoom,
      );
      _isUserInteracting = false;
    } else {
      debugPrint('현재위치 버튼: 위치 정보 없음 또는 맵 컨트롤러 없음');
      // 위치 서비스를 다시 요청해보기
      await _initLocation();
    }
  }

  // 포맷팅
  String get formattedSteps {
    return _stepCount > 0
        ? _stepCount.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          )
        : '0';
  }

  String get formattedCalories => _totalCalories.toInt().toString();
  String get formattedMeters => _totalDistance.toInt().toString();

  String get formattedTime {
    Duration currentTime;
    if (_startTime == null) {
      currentTime = Duration.zero;
    } else if (isPaused && _pauseStartTime != null) {
      currentTime =
          _pauseStartTime!.difference(_startTime!) - _totalPausedDuration;
    } else if (isPaused) {
      currentTime = Duration.zero;
    } else {
      currentTime =
          DateTime.now().difference(_startTime!) - _totalPausedDuration;
    }

    final totalSeconds = currentTime.inSeconds.clamp(0, 86399);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedRestTime {
    if (!isPaused || _restStartTime == null) return '00:00:00';

    final currentRestTime = DateTime.now().difference(_restStartTime!);
    final totalSeconds = currentRestTime.inSeconds.clamp(0, 86399);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = _currentPosition != null
        ? _getAdjustedCameraPosition(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          )
        : const NLatLng(37.5666, 126.979);

    final safeAreaPadding = MediaQuery.paddingOf(context);
    final bottomPadding = isUICollapsed ? 80.0 : (isPaused ? 240.0 : 220.0);
    final dynamicPadding = EdgeInsets.only(
      top: safeAreaPadding.top,
      bottom: safeAreaPadding.bottom + bottomPadding,
      left: safeAreaPadding.left,
      right: safeAreaPadding.right,
    );

    return Scaffold(
      body: Stack(
        children: [
          // 네이버 맵
          NaverMap(
            options: NaverMapViewOptions(
              contentPadding: dynamicPadding,
              initialCameraPosition: NCameraPosition(
                target: initialPosition,
                zoom: 15,
              ),
              locationButtonEnable: false,
              minZoom: 10,
              maxZoom: 18,
              mapType: NMapType.basic,
              indoorEnable: true,
              buildingHeight: 1.0,
              symbolScale: 1.0,
              symbolPerspectiveRatio: 1.0,
            ),
            onMapReady: (controller) async {
              _mapController = controller;

              // 저장된 경로가 있으면 다시 그리기
              if (_walkingPath.isNotEmpty) {
                await _updatePathOverlay();
              }

              if (_currentPosition != null) {
                _updateMapPosition(_currentPosition!);
              } else {
                await _initLocation();
              }
            },
            onCameraChange: (reason, animated) {
              if (reason == NCameraUpdateReason.gesture) {
                _isUserInteracting = true;
              }
            },
          ),

          // 뒤로가기 버튼
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, top: 10),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),

          // 테스트 시뮬레이션 버튼 (개발용)
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(right: 20, top: 10),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isSimulationRunning ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isSimulationRunning ? Icons.stop : Icons.play_arrow,
                      size: 18,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (_isSimulationRunning) {
                        _stopWalkingSimulation();
                      } else {
                        _startWalkingSimulation();
                      }
                      setState(() {});
                    },
                  ),
                ),
              ),
            ),
          ),

          // 하단 UI
          Positioned(
            bottom: -5,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  // 현재위치, 편의시설 버튼들
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 현재위치 버튼 (왼쪽)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.my_location, size: 20),
                            onPressed: _onMyLocationPressed,
                          ),
                        ),
                        // 편의시설 버튼 (오른쪽)
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.notifications_outlined,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '편의시설',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 운동 정보 카드
                  ExerciseInfoCard(
                    isUICollapsed: isUICollapsed,
                    formattedTime: formattedTime,
                    formattedSteps: formattedSteps,
                    formattedCalories: formattedCalories,
                    formattedMeters: formattedMeters,
                    isPaused: isPaused,
                    formattedRestTime: formattedRestTime,
                    onToggleCollapse: _toggleUICollapse,
                    onOpenCamera: _openCamera,
                    onTogglePause: _togglePause,
                    onRecord: _onRecord,
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
