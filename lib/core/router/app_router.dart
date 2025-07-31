import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/pages/home_page.dart';
import '../../presentation/pages/splash_page.dart';
import '../../presentation/pages/first_screen_page.dart';
import '../../presentation/pages/login_page.dart';
import '../../presentation/pages/terms_page.dart';
import '../../presentation/pages/always_location_page.dart';
import '../../presentation/pages/profile_page.dart';
import '../../presentation/pages/profile_image_select_page.dart';
import '../../presentation/pages/profile_gender_page.dart';
import '../../presentation/pages/profile_location_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/first-screen',
        name: 'first-screen',
        builder: (context, state) => const FirstScreenPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/terms',
        name: 'terms',
        builder: (context, state) => const TermsPage(),
      ),
      GoRoute(
        path: '/always-location',
        name: 'always-location',
        builder: (context, state) => const AlwaysLocationPage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/profile-image-select',
        name: 'profile-image-select',
        builder: (context, state) => const ProfileImageSelectPage(),
      ),
      GoRoute(
        path: '/profile-gender',
        name: 'profile-gender',
        builder: (context, state) => const ProfileGenderPage(),
      ),
      GoRoute(
        path: '/profile-location',
        name: 'profile-location',
        builder: (context, state) => const ProfileLocationPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});