import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/signup_provider.dart';

class ProfileLocationPage extends ConsumerWidget {
  const ProfileLocationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signupData = ref.watch(signupNotifierProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 30),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Progress Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == 3 ? Colors.blue : Colors.grey[300],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 60),
                    const Text(
                      '주로 산책하는 지역을\n입력해주세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 100),
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: GestureDetector(
                          onTap: () async {
                            final result = await context.push<String>(
                              '/profile-location-search',
                            );
                            if (result != null) {
                              ref
                                  .read(signupNotifierProvider.notifier)
                                  .updateLocation(result);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    signupData.selectedLocation ?? '주소 검색하기',
                                    style: TextStyle(
                                      color: signupData.selectedLocation != null
                                          ? Colors.black
                                          : Colors.grey[400],
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.search,
                                  color: Colors.grey[400],
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: signupData.selectedLocation != null
                      ? () {
                          // Navigate to home or complete profile setup
                          context.go('/home');
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: signupData.selectedLocation != null
                        ? Colors.blue
                        : Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '시작하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: signupData.selectedLocation != null
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
