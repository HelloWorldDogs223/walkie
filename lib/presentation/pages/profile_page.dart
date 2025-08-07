import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/signup_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final TextEditingController _nicknameController = TextEditingController();
  bool isChecking = false;

  @override
  void initState() {
    super.initState();
    // 기존 닉네임이 있다면 컨트롤러에 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final signupData = ref.read(signupNotifierProvider);
      if (signupData.nickname.isNotEmpty) {
        _nicknameController.text = signupData.nickname;
      }
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _checkDuplicate() async {
    setState(() {
      isChecking = true;
    });

    await ref.read(signupNotifierProvider.notifier).checkNicknameDuplicate();

    setState(() {
      isChecking = false;
    });
  }

  Widget _buildProfileImage() {
    final signupData = ref.watch(signupNotifierProvider);

    if (signupData.selectedUserImage != null) {
      // 사용자가 선택한 이미지
      return ClipOval(
        child: Image.file(
          signupData.selectedUserImage!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      );
    } else if (signupData.selectedImageIndex != null) {
      // 아바타 이미지
      return ClipOval(
        child: Image.asset(
          'assets/character${signupData.selectedImageIndex}.png',
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getAvatarColor(signupData.selectedImageIndex!),
              ),
              child: Icon(
                Icons.face,
                size: 50,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            );
          },
        ),
      );
    } else {
      // 기본 이미지
      return Image.asset(
        'assets/profileDefault.png',
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    }
  }

  Color _getAvatarColor(int index) {
    switch (index) {
      case 1:
        return const Color(0xFF6B9EFF);
      case 2:
        return const Color(0xFF8ED06C);
      case 3:
        return const Color(0xFF5B85FF);
      case 4:
        return const Color(0xFFFFA947);
      case 5:
        return const Color(0xFF2B4B96);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final signupData = ref.watch(signupNotifierProvider);
    final canProceed = ref
        .read(signupNotifierProvider.notifier)
        .canProceedFromProfile();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index == 0
                                      ? Colors.blue.shade800
                                      : Colors.grey[300],
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            '프로필을 완성해주세요!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Progress Indicator
                          const SizedBox(height: 40),
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[200],
                                ),
                                child: Center(child: _buildProfileImage()),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () async {
                                    final result = await context
                                        .push<Map<String, dynamic>>(
                                          '/profile-image-select',
                                        );
                                    if (result != null) {
                                      ref
                                          .read(signupNotifierProvider.notifier)
                                          .updateProfileImage(
                                            imageIndex:
                                                result['type'] == 'avatar'
                                                ? result['index']
                                                : null,
                                            userImage: result['type'] == 'user'
                                                ? result['image']
                                                : null,
                                            imageType: result['type'],
                                          );
                                    }
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            '닉네임을 설정해주세요',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: Stack(
                              children: [
                                TextField(
                                  controller: _nicknameController,
                                  style: const TextStyle(fontSize: 16),
                                  onChanged: (value) {
                                    // 즉시 UI 업데이트를 위한 setState
                                    setState(() {
                                      ref
                                          .read(signupNotifierProvider.notifier)
                                          .updateNickname(value);
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: '닉네임을 입력해주세요',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            signupData.nicknameErrorMessage !=
                                                null
                                            ? Colors.red
                                            : Colors.blue.shade800,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.only(
                                      left: 0,
                                      right: 100,
                                      top: 16,
                                      bottom: 16,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 8,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: signupData.isNicknameValid
                                            ? Colors.blue.shade800
                                            : Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: TextButton(
                                      onPressed:
                                          signupData.isNicknameValid &&
                                              !isChecking
                                          ? _checkDuplicate
                                          : null,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        backgroundColor: Colors.transparent,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: isChecking
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.blue,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              '중복확인',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    signupData.isNicknameValid
                                                    ? Colors.blue.shade800
                                                    : Colors.grey[400],
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (signupData.nicknameErrorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Image.asset(
                                        'assets/Warning.png',
                                        width: 16,
                                        height: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        signupData.nicknameErrorMessage!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ] else if (signupData.isDuplicateChecked &&
                              !signupData.isDuplicate) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '사용 가능한 닉네임입니다',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
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
                      onPressed: canProceed
                          ? () {
                              context.push('/profile-gender');
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
}
