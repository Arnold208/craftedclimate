import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:craftedclimate/forgotPassword/email_reset.dart';
import 'package:craftedclimate/forgotPassword/new_password.dart';
import 'package:craftedclimate/forgotPassword/otp_reset.dart';

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  final PageController _pageController = PageController(initialPage: 0);
  int _activePage = 0;

  String? _userEmail;
  String? _otpCode;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      EmailReset(onEmailVerified: _navigateToOtpResetPage),
      OtpReset(
        onOtpVerified: _navigateToNewPasswordPage,
        email: _userEmail ?? 'N/A',
      ),
      NewPassword(
        otpCode: _otpCode ?? 'N/A',
        email: _userEmail ?? 'N/A',
      ),
    ];
  }

  void _navigateToOtpResetPage(String email) {
    setState(() {
      _userEmail = email;
      _pages[1] = OtpReset(
        onOtpVerified: _navigateToNewPasswordPage,
        email: _userEmail!,
      );
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  void _navigateToNewPasswordPage(String otpCode) {
    setState(() {
      _otpCode = otpCode;
      _pages[2] = NewPassword(
        otpCode: _otpCode ?? 'N/A',
        email: _userEmail ?? 'N/A',
      );
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _activePage == 0 || _activePage == 1
          ? AppBar(
              backgroundColor: Colors.white,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: SvgPicture.asset(
                _activePage == 0
                    ? 'assets/images/reset2.svg'
                    : _activePage == 1
                        ? 'assets/images/reset1.svg'
                        : 'assets/images/reset3.svg',
                height: MediaQuery.of(context).size.width * 0.7,
              ),
            ),
            const SizedBox(
              height: 40,
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _activePage = page;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (BuildContext context, int index) {
                  return _pages[index];
                },
              ),
            ),
            SizedBox(
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  _pages.length,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: InkWell(
                      onTap: () {
                        // _pageController.animateToPage(
                        //   index,
                        //   duration: const Duration(milliseconds: 300),
                        //   curve: Curves.easeIn,
                        // );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: _activePage == index
                              ? Colors.green
                              : const Color.fromARGB(255, 234, 233, 233),
                        ),
                        height: 10,
                        width: 40,
                      ),
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
