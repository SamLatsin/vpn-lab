// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vpn_lab/components/alerts.dart';
import 'package:vpn_lab/components/async_tasks.dart';
import 'package:vpn_lab/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:vpn_lab/screens/authentication/new_password_screen.dart';
import 'dart:io' show Platform;

class PincodeScreen extends StatefulWidget {
  final String email;

  const PincodeScreen({Key? key, required this.email}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _PincodeScreenState createState() => _PincodeScreenState();
}

class _PincodeScreenState extends State<PincodeScreen> {
  final FocusNode _focusNode1 = FocusNode();
  late double imgSizeDivider,
      sizedBoxRatio,
      font1,
      font2,
      buttonFont,
      buttonBottomPadding,
      _height,
      topMargin;
  late bool isButtonEnabled = false, isCodeWrong = false;

  @override
  void initState() {
    _focusNode1.addListener(() {
      if (_focusNode1.hasFocus) {
        setState(() {});
      }
    });
    super.initState();
  }

  final pincodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    if (Platform.isAndroid) {
      if (size.height > 851) {
        imgSizeDivider = 1;
        sizedBoxRatio = 1.2;
        font1 = 30;
        font2 = 20;
        buttonFont = 18;
        buttonBottomPadding = 0;
        topMargin = 10;
      } else if (size.height > 660) {
        imgSizeDivider = 1.2;
        sizedBoxRatio = 1.5;
        font1 = 25;
        font2 = 20;
        buttonFont = 15;
        buttonBottomPadding = 10;
        topMargin = 10;
      } else {
        imgSizeDivider = 1.3;
        sizedBoxRatio = 1;
        font1 = 20;
        font2 = 18;
        buttonFont = 14;
        buttonBottomPadding = 10;
        topMargin = 10;
      }
    }
    if (Platform.isIOS) {
      if (size.height > 812) {
        imgSizeDivider = 1;
        sizedBoxRatio = 1.2;
        font1 = 30;
        font2 = 20;
        buttonFont = 18;
        buttonBottomPadding = 0;
        topMargin = 0;
      } else if (size.height > 660) {
        imgSizeDivider = 1.2;
        sizedBoxRatio = 1.5;
        font1 = 25;
        font2 = 20;
        buttonFont = 15;
        buttonBottomPadding = 10;
        topMargin = 0;
      } else {
        imgSizeDivider = 1.3;
        sizedBoxRatio = 1;
        font1 = 20;
        font2 = 18;
        buttonFont = 14;
        buttonBottomPadding = 10;
        topMargin = 0;
      }
    }

    if (_focusNode1.hasFocus) {
      _height = 0;
    } else {
      _height = size.height / 2.2 / imgSizeDivider;
    }

    void checkCode(String code) async {
      // ignore: prefer_typing_uninitialized_variables
      var response;
      try {
        response = await checkRestoreCode(widget.email, code);
      } catch (e) {
        return getFlushError("Service is unavaliable").show(context);
      }
      if (response["error"]) {
        isButtonEnabled = false;
        isCodeWrong = true;
        // ignore: use_build_context_synchronously
        getFlushError(response["result"]).show(context);
      } else {
        isCodeWrong = false;
        // ignore: use_build_context_synchronously
        Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(
              builder: (context) =>
                  NewPasswordScreen(email: widget.email, code: code)),
          (Route<dynamic> route) => false,
        );
      }
      setState(() {});
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: bgPrimary,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                SizedBox(
                  height: topMargin,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: _height,
                  child: SvgPicture.asset(
                    "assets/images/main_logo.svg",
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width / imgSizeDivider,
                  ),
                ),
                SizedBox(height: sizedBoxRatio * 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "We sent you a verification code",
                    style: TextStyle(
                        color: primaryLight,
                        fontFamily: 'Inter',
                        height: 1.8,
                        fontSize: font2,
                        fontWeight: FontWeight.w300),
                  ),
                ),
                SizedBox(height: sizedBoxRatio * 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: PinCodeTextField(
                    controller: pincodeController,
                    keyboardType: TextInputType.number,
                    focusNode: _focusNode1,
                    cursorColor: primaryLight,
                    appContext: context,
                    length: 6,
                    obscureText: false,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(10.0),
                        fieldHeight: 60,
                        fieldWidth: 45,
                        activeFillColor: bgSecondaryDark,
                        errorBorderColor: bgIconBlue,
                        // disabledColor: primaryLight,
                        inactiveFillColor: bgSecondaryDark,
                        selectedColor: bgSecondaryDark,
                        selectedFillColor: bgSecondaryDark,
                        activeColor: isCodeWrong ? bgIconRed : transparent),
                    animationDuration: const Duration(milliseconds: 300),
                    enableActiveFill: true,
                    textStyle: TextStyle(
                        color: primaryLight,
                        fontFamily: 'Inter',
                        // height: 1.8,
                        fontSize: font2,
                        fontWeight: FontWeight.w300),
                    onChanged: (value) {
                      isCodeWrong = false;
                      setState(() {});
                    },
                    onCompleted: (v) {
                      isButtonEnabled = true;
                      // checkCode(v);
                    },
                  ),
                ),
                SizedBox(height: sizedBoxRatio * 15),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: Padding(
          padding:
              EdgeInsets.only(left: 20, right: 20, bottom: buttonBottomPadding),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                const BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 4),
                    blurRadius: 5.0)
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 1.0],
                colors: [
                  isButtonEnabled ? bgSecondaryGradStart : buttonDisabled,
                  isButtonEnabled ? bgSecondaryGradEnd : buttonDisabled,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              onPressed: !isButtonEnabled
                  ? null
                  : () async {
                      checkCode(pincodeController.text);
                      setState(() {});
                    },
              style: ButtonStyle(
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                backgroundColor: MaterialStateProperty.all(Colors.transparent),
                shadowColor: MaterialStateProperty.all(Colors.transparent),
                padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 20.0)),
              ),
              child: Text(
                "Restore my account",
                style: TextStyle(
                    color: isButtonEnabled
                        ? primaryLight
                        : primaryLight.withOpacity(0.5),
                    fontSize: buttonFont,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
