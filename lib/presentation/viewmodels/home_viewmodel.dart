import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/utils/location_service.dart';

part 'home_viewmodel.freezed.dart';

@freezed
class HomeState with _$HomeState {
  const factory HomeState({
    Position? currentPosition,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _HomeState;
}

final homeViewModelProvider = StateNotifierProvider.autoDispose<HomeViewModel, AsyncValue<HomeState>>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return HomeViewModel(locationService);
});

class HomeViewModel extends StateNotifier<AsyncValue<HomeState>> {
  final LocationService _locationService;
  
  HomeViewModel(this._locationService) : super(const AsyncValue.data(HomeState())) {
    _init();
  }
  
  Future<void> _init() async {
    state = const AsyncValue.loading();
    try {
      await _locationService.checkLocationPermission();
      state = const AsyncValue.data(HomeState());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<void> getCurrentLocation() async {
    state = const AsyncValue.loading();
    try {
      final position = await _locationService.getCurrentLocation();
      state = AsyncValue.data(
        HomeState(currentPosition: position),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}