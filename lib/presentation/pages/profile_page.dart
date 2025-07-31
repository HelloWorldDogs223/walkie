import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nicknameController = TextEditingController();
  bool isNicknameValid = false;
  bool isChecking = false;
  bool isDuplicateChecked = false;
  bool isDuplicate = false;
  String? errorMessage;
  int? selectedImageIndex;

  // 이미 사용중인 닉네임 목록 (실제로는 API 호출)
  final List<String> existingNicknames = ['사용자1', '테스트', '워키', 'walker'];

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_validateNickname);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _validateNickname() {
    final nickname = _nicknameController.text.trim();
    setState(() {
      isDuplicateChecked = false;
      isDuplicate = false;
      
      if (nickname.isEmpty) {
        isNicknameValid = false;
        errorMessage = null;
      } else if (nickname.length < 2) {
        isNicknameValid = false;
        errorMessage = '닉네임은 2자 이상이어야 합니다';
      } else if (nickname.length > 10) {
        isNicknameValid = false;
        errorMessage = '닉네임은 10자 이하여야 합니다';
      } else if (_containsSpecialCharacters(nickname)) {
        isNicknameValid = false;
        errorMessage = '특수문자는 사용할 수 없습니다';
      } else {
        isNicknameValid = true;
        errorMessage = null;
      }
    });
  }

  bool _containsSpecialCharacters(String text) {
    final pattern = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
    return pattern.hasMatch(text);
  }

  Future<void> _checkDuplicate() async {
    if (!isNicknameValid) return;

    setState(() {
      isChecking = true;
    });

    // API 호출 시뮬레이션
    await Future.delayed(const Duration(seconds: 1));

    final nickname = _nicknameController.text.trim();
    final isDuplicateNickname = existingNicknames.contains(nickname.toLowerCase());

    setState(() {
      isChecking = false;
      isDuplicateChecked = true;
      isDuplicate = isDuplicateNickname;
      if (isDuplicateNickname) {
        errorMessage = '이미 사용중인 닉네임입니다';
      } else {
        errorMessage = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = isNicknameValid && isDuplicateChecked && !isDuplicate;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Text(
                  '프로필 설정',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 60),
                Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: Center(
                        child: selectedImageIndex != null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.blue,
                              )
                            : Image.asset(
                                'lib/assets/profile.png',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () async {
                          final result = await context.push<int>('/profile-image-select');
                          if (result != null) {
                            setState(() {
                              selectedImageIndex = result;
                            });
                          }
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.blue,
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
                const SizedBox(height: 8),
                const Text(
                  '다른 사용자에게 표시될 이름입니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nicknameController,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: '닉네임을 입력하세요',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: errorMessage != null ? Colors.red : Colors.blue,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          suffixIcon: isDuplicateChecked
                              ? Icon(
                                  isDuplicate ? Icons.close : Icons.check_circle,
                                  color: isDuplicate ? Colors.red : Colors.green,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isNicknameValid && !isChecking
                            ? _checkDuplicate
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isNicknameValid
                              ? Colors.blue
                              : Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: isChecking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                '중복확인',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isNicknameValid
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (errorMessage != null)
                        Text(
                          errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      if (isDuplicateChecked && !isDuplicate && errorMessage == null)
                        const Text(
                          '사용 가능한 닉네임입니다',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                      if (errorMessage == null && !isDuplicateChecked)
                        const Text(
                          '2~10자, 특수문자 제외',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: canProceed
                        ? () {
                            context.push('/profile-gender');
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canProceed
                          ? Colors.blue
                          : Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      '계속하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: canProceed
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}