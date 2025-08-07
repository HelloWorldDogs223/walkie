import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageSelectPage extends StatefulWidget {
  const ProfileImageSelectPage({super.key});

  @override
  State<ProfileImageSelectPage> createState() => _ProfileImageSelectPageState();
}

class _ProfileImageSelectPageState extends State<ProfileImageSelectPage> {
  int selectedImageIndex = -1;
  File? _userImage;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 30),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '이미지 선택',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
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
                      color: index == 0 ? Colors.blue.shade800 : Colors.grey[300],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              const Text(
                '사용할 프로필 이미지를 선택해주세요.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 60),
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // 카메라/갤러리 버튼
                      return GestureDetector(
                        onTap: () => _showImagePicker(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFB8C5D0),
                            shape: BoxShape.circle,
                          ),
                          child: _userImage != null
                              ? ClipOval(
                                  child: Image.file(
                                    _userImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  size: 30,
                                  color: Colors.white,
                                ),
                        ),
                      );
                    } else {
                      // 아바타 옵션들
                      final isSelected =
                          selectedImageIndex == index && _userImage == null;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedImageIndex = index;
                            _userImage = null;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(shape: BoxShape.circle),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _buildAvatar(index),
                              if (isSelected)
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.blue.shade800,
                                      width: 4,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                height: 56,
                margin: const EdgeInsets.only(bottom: 40),
                child: ElevatedButton(
                  onPressed: (selectedImageIndex != -1 || _userImage != null)
                      ? () {
                          if (_userImage != null) {
                            context.pop({'type': 'user', 'image': _userImage});
                          } else {
                            context.pop({
                              'type': 'avatar',
                              'index': selectedImageIndex,
                            });
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (selectedImageIndex != -1 || _userImage != null)
                        ? Colors.blue.shade800
                        : Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '선택',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: (selectedImageIndex != -1 || _userImage != null)
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildAvatar(int index) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: ClipOval(
        child: Image.asset(
          'assets/character$index.png',
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.face,
              size: 50,
              color: Colors.white.withOpacity(0.9),
            );
          },
        ),
      ),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('카메라'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  title: const Text('앨범에서 선택'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _userImage = File(pickedFile.path);
          selectedImageIndex = -1;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지를 선택할 수 없습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
