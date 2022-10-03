// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:localstore/localstore.dart';
import 'package:vpn_lab/components/alerts.dart';
import 'package:vpn_lab/components/async_tasks.dart';
import 'package:vpn_lab/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:vpn_lab/custom_icons.dart';
import 'package:vpn_lab/screens/authentication/registration.dart';
import 'package:vpn_lab/screens/authentication/restore.dart';
import 'package:vpn_lab/screens/main/main_screen.dart';
import 'dart:io' show Platform;
// import 'package:http/http.dart' as http;
// import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();
  late double imgSizeDivider,
      sizedBoxRatio,
      font1,
      font2,
      buttonFont,
      buttonBottomPadding,
      _height,
      topMargin;
  late bool isEmailValid = false,
      isPasswordValid = false,
      isButtonEnabled = false;

  @override
  void initState() {
    _focusNode1.addListener(() {
      if (_focusNode1.hasFocus) {
        setState(() {});
      }
    });
    _focusNode2.addListener(() {
      if (_focusNode2.hasFocus) {
        setState(() {});
      }
    });

    super.initState();
  }

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = Localstore.instance;
    Size size = MediaQuery.of(context).size;
    String emailRegExp =
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
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
        sizedBoxRatio = 1;
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

    if (_focusNode1.hasFocus || _focusNode2.hasFocus) {
      _height = 0;
    } else {
      _height = size.height / 2.2 / imgSizeDivider;
    }

    void checkButtonConditions() {
      if (emailController.text != "" &&
          passwordController.text != "" &&
          isEmailValid &&
          isPasswordValid) {
        isButtonEnabled = true;
      } else {
        isButtonEnabled = false;
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
                    "Hello Welcome back",
                    style: TextStyle(
                        color: primaryLight,
                        fontFamily: 'Inter',
                        fontSize: font1,
                        height: 1.2,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Login to Continue",
                    style: TextStyle(
                        color: primaryLight,
                        fontFamily: 'Inter',
                        height: 1.8,
                        fontSize: font2,
                        fontWeight: FontWeight.w300),
                  ),
                ),
                SizedBox(height: sizedBoxRatio * 20),
                Container(
                  decoration: BoxDecoration(
                    color: bgSecondaryDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: TextField(
                    onChanged: (text) {
                      if (RegExp(emailRegExp).hasMatch(text)) {
                        isEmailValid = true;
                      } else {
                        isEmailValid = false;
                      }
                      checkButtonConditions();
                      setState(() {});
                    },
                    controller: emailController,
                    focusNode: _focusNode1,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      suffixIcon: InkWell(
                          onTap: () {},
                          child: Container(
                              width: 0,
                              alignment: Alignment.bottomCenter,
                              height: 0,
                              child: Icon(
                                  isEmailValid
                                      ? CustomIcons.ok_circle
                                      : CustomIcons.cancel_circle,
                                  size: 25,
                                  color: (emailController.text == "")
                                      ? bgSecondaryDark
                                      : isEmailValid
                                          ? bgIconBlue
                                          : bgIconRed))),
                      border: InputBorder.none,
                      labelText: 'Email',
                      labelStyle:
                          TextStyle(color: primaryLight.withOpacity(0.5)),
                    ),
                    style: TextStyle(
                        color: isEmailValid ? primaryLight : bgIconRed,
                        fontWeight: FontWeight.w400,
                        fontSize: buttonFont,
                        height: 1.8),
                  ),
                ),
                SizedBox(height: sizedBoxRatio * 15),
                Container(
                  decoration: BoxDecoration(
                    color: bgSecondaryDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: TextField(
                    onChanged: (text) {
                      isPasswordValid = true;
                      checkButtonConditions();
                      setState(() {});
                    },
                    controller: passwordController,
                    focusNode: _focusNode2,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      suffixIcon: InkWell(
                          onTap: () {},
                          child: Container(
                              width: 0,
                              alignment: Alignment.bottomCenter,
                              height: 0,
                              child: Icon(
                                  isPasswordValid
                                      ? CustomIcons.ok_circle
                                      : CustomIcons.cancel_circle,
                                  size: 25,
                                  color: (passwordController.text == "")
                                      ? bgSecondaryDark
                                      : isPasswordValid
                                          ? bgIconBlue
                                          : bgIconRed))),
                      border: InputBorder.none,
                      labelText: 'Password',
                      labelStyle:
                          TextStyle(color: primaryLight.withOpacity(0.5)),
                    ),
                    style: TextStyle(
                        color: isPasswordValid ? primaryLight : bgIconRed,
                        fontWeight: FontWeight.w400,
                        fontSize: buttonFont,
                        height: 1.8),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) => const RegisterScreen()));
                      },
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                            color: primaryLight,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            fontSize: buttonFont - 3,
                            decoration: TextDecoration.underline,
                            height: 3),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) => const RestoreScreen()));
                      },
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(
                            color: primaryLight,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            fontSize: buttonFont - 3,
                            decoration: TextDecoration.underline,
                            height: 3),
                      ),
                    ),
                  ],
                ),
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
                      if (!isButtonEnabled) {
                        return;
                      }
                      // ignore: prefer_typing_uninitialized_variables
                      var response;
                      try {
                        response = await loginUser(
                            emailController.text, passwordController.text);
                      } catch (e) {
                        return getFlushError("Service is unavaliable")
                            .show(context);
                      }
                      if (response["error"]) {
                        isPasswordValid = false;
                        // ignore: use_build_context_synchronously
                        getFlushError(response["result"]).show(context);
                      } else {
                        isPasswordValid = true;
                        var userData = {
                          'token': response["result"]["token"],
                          'email': response["result"]["email"],
                          'isPremium': response["result"]["isPremium"],
                          'subscriptionEndDate': response["result"]
                              ["subscriptionEndDate"]
                        };
                        db.collection('account').doc("0").set(userData);
                        // ignore: use_build_context_synchronously
                        Navigator.pushAndRemoveUntil(
                          context,
                          CupertinoPageRoute(
                              builder: (context) => MainScreen(user: userData)),
                          (Route<dynamic> route) => false,
                        );
                      }
                      checkButtonConditions();
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
                "Login my account",
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
