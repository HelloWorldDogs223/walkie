import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  bool _agreeAll = false;
  bool _agreeAge = false;
  bool _agreeService = false;
  bool _agreePrivacy = false;
  bool _agreeLocation = false;
  bool _agreeMarketing = false;

  void _updateAgreeAll() {
    setState(() {
      _agreeAll =
          _agreeAge &&
          _agreeService &&
          _agreePrivacy &&
          _agreeLocation &&
          _agreeMarketing;
    });
  }

  void _toggleAll(bool? value) {
    setState(() {
      _agreeAll = value ?? false;
      _agreeAge = _agreeAll;
      _agreeService = _agreeAll;
      _agreePrivacy = _agreeAll;
      _agreeLocation = _agreeAll;
      _agreeMarketing = _agreeAll;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // 캐릭터 이미지
                    Image.asset(
                      'assets/character.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 32),
                    // 제목
                    Column(
                      children: [
                        Text(
                          '워키 이용을 위해',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          '약관에 동의해주세요',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    // 구분선
                    const Divider(
                      color: Colors.grey,
                      thickness: 0.5,
                      height: 32,
                    ),
                    // 전체 동의
                    InkWell(
                      onTap: () => _toggleAll(!_agreeAll),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _agreeAll,
                                onChanged: _toggleAll,
                                activeColor: Color(0xFF4285F4),
                                shape: CircleBorder(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '전체 동의',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 개별 약관들
                    _buildTermsItem('만 14세 이상입니다.', _agreeAge, (value) {
                      setState(() {
                        _agreeAge = value ?? false;
                        _updateAgreeAll();
                      });
                    }, isRequired: true),
                    _buildTermsItem(
                      '[필수] 워키 이용약관',
                      _agreeService,
                      (value) {
                        setState(() {
                          _agreeService = value ?? false;
                          _updateAgreeAll();
                        });
                      },
                      isRequired: true,
                      hasArrow: true,
                    ),
                    _buildTermsItem(
                      '[필수] 개인정보 수집 및 이용동의',
                      _agreePrivacy,
                      (value) {
                        setState(() {
                          _agreePrivacy = value ?? false;
                          _updateAgreeAll();
                        });
                      },
                      isRequired: true,
                      hasArrow: true,
                    ),
                    _buildTermsItem(
                      '[필수] 개인정보 제3자 제공동의',
                      _agreeLocation,
                      (value) {
                        setState(() {
                          _agreeLocation = value ?? false;
                          _updateAgreeAll();
                        });
                      },
                      isRequired: true,
                      hasArrow: true,
                    ),
                    _buildTermsItem(
                      '[필수] 위치기반 서비스 이용약관',
                      _agreeMarketing,
                      (value) {
                        setState(() {
                          _agreeMarketing = value ?? false;
                          _updateAgreeAll();
                        });
                      },
                      isRequired: true,
                      hasArrow: true,
                    ),
                  ],
                ),
              ),
            ),
            // 다음 버튼
            Container(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      (_agreeAge &&
                          _agreeService &&
                          _agreePrivacy &&
                          _agreeLocation &&
                          _agreeMarketing)
                      ? () {
                          print('TermsPage: 다음 버튼 클릭됨 - 약관 동의 완료');
                          context.go('/first-screen');
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4285F4),
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '다음',
                    style: TextStyle(
                      fontSize: 18,
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
    );
  }

  void _showTermsBottomSheet(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 24),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Color(0xFF4285F4),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            '워키 이용을 위해\n약관에 동의해주세요',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '이용약관에 대한 설명을 작성합니다. 이용약관에 대한 설명을 작성합니다. 이용약관에 대한 설명을 작성합니다. 이용약관에 대한 설명을 작성합니다. 이용약관에 대한 설명을 작성합니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '이용약관에 대한 설명을 작성합니다. 이용약관에 대한 설명을 작성합니다. 이용약관에 대한 설명을 작성합니다. 이용약관에 대한 설명을 작성합니다. 이용약관에 대한 설명을 작성합니다. 이용약관에 대한 설명을 작성합니다. 이용약관에 대한 설명을 작성합니다. 이용약관에 대한 설명을 작성합니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '이용약관에 대한 설명을 작성합니다. 이용약관에 대한 설명을 작성합니다. 이용약관에 대한 설명을 작성합니다. 이용약관에 대한 설명을 작성합니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4285F4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  Widget _buildTermsItem(
    String title,
    bool value,
    Function(bool?) onChanged, {
    bool isRequired = false,
    bool hasArrow = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            // 체크박스와 텍스트 영역
            Expanded(
              child: InkWell(
                onTap: () => onChanged(!value),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: value,
                        onChanged: onChanged,
                        activeColor: Color(0xFF4285F4),
                        shape: CircleBorder(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 화살표 영역 (별도 클릭 처리)
            if (hasArrow)
              InkWell(
                onTap: () => _showTermsBottomSheet(context, title),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
