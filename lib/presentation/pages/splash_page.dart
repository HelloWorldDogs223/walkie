import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/permission_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    print('SplashPage: initState called');
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    print('SplashPage: Starting navigation delay');
    // 앱 시작 시 권한 체크
    try {
      final permissionStatus = await PermissionService.checkPermissionStatus();
      print('SplashPage: Current permissions: $permissionStatus');
    } catch (e) {
      print('SplashPage: Error checking permissions: $e');
    }
    
    await Future.delayed(const Duration(seconds: 2));
    print('SplashPage: Delay completed, navigating to login');
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('SplashPage: build called');
    return Scaffold(
      backgroundColor: const Color(0xFF2750E0), // Fixed: Changed from 0x00 (transparent) to 0xFF (opaque)
      body: Center(
        child: SvgPicture.asset(
          'lib/assets/Logo.svg',
          width: 252,
          height: 65,
          placeholderBuilder: (BuildContext context) => Container(
            width: 252,
            height: 65,
            color: Colors.white,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
