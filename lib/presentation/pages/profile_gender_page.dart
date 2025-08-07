import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/signup_provider.dart';

class ProfileGenderPage extends ConsumerWidget {
  const ProfileGenderPage({super.key});

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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
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
                                color: index == 1
                                    ? Colors.blue.shade800
                                    : Colors.grey[300],
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 60),
                        const Text(
                          '성별을 입력해주세요',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 80),
                        Center(
                          child: Column(
                            children: [
                              _buildGenderOption('남성', ref, context),
                              const SizedBox(height: 16),
                              _buildGenderOption('여성', ref, context),
                            ],
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
                      onPressed: signupData.selectedGender != null
                          ? () {
                              context.push('/profile-year');
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '다음',
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
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(
    String gender,
    WidgetRef ref,
    BuildContext context,
  ) {
    final signupData = ref.watch(signupNotifierProvider);
    final isSelected = signupData.selectedGender == gender;

    return GestureDetector(
      onTap: () {
        ref.read(signupNotifierProvider.notifier).updateGender(gender);
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected ? Colors.blue.shade800 : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            gender,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.blue.shade800 : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}
