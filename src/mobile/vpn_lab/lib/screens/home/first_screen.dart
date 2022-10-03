// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:localstore/localstore.dart';
import 'package:vpn_lab/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:vpn_lab/screens/authentication/login.dart';
import 'dart:io' show Platform;

class FirstScreen extends StatefulWidget {
  const FirstScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _FirstScreenState createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  final db = Localstore.instance;

  @override
  void initState() {
    // preload svg asset
    Future.wait([
      precachePicture(
        ExactAssetPicture(
          SvgPicture.svgStringDecoderBuilder,
          'assets/images/main_logo.svg',
        ),
        null,
      ),
    ]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    late double imgSizeDivider,
        sizedBoxRatio,
        font1,
        font2,
        buttonFont,
        buttonBottomPadding,
        topMargin;
    if (Platform.isAndroid) {
      if (size.height > 851) {
        imgSizeDivider = 1;
        sizedBoxRatio = 1.1;
        font1 = 30;
        font2 = 20;
        buttonFont = 18;
        buttonBottomPadding = 0;
        topMargin = 10;
      } else if (size.height > 660) {
        imgSizeDivider = 1.2;
        sizedBoxRatio = 2;
        font1 = 25;
        font2 = 20;
        buttonFont = 15;
        buttonBottomPadding = 10;
        topMargin = 10;
      } else {
        imgSizeDivider = 1.3;
        sizedBoxRatio = 2;
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
        sizedBoxRatio = 2;
        font1 = 25;
        font2 = 20;
        buttonFont = 15;
        buttonBottomPadding = 10;
        topMargin = 0;
      } else {
        imgSizeDivider = 1.3;
        sizedBoxRatio = 2;
        font1 = 20;
        font2 = 18;
        buttonFont = 14;
        buttonBottomPadding = 10;
        topMargin = 0;
      }
    }

    return Scaffold(
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
                SvgPicture.asset(
                  "assets/images/main_logo.svg",
                  alignment: Alignment.center,
                  width: MediaQuery.of(context).size.width / imgSizeDivider,
                ),
                SizedBox(height: sizedBoxRatio * 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Hey there,",
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
                    "I’m here to protect",
                    style: TextStyle(
                        color: primaryLight,
                        fontFamily: 'Inter',
                        height: 1.2,
                        fontSize: font1,
                        fontWeight: FontWeight.w300),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "your internet privacy!",
                    style: TextStyle(
                        color: primaryLight,
                        fontFamily: 'Inter',
                        height: 1.2,
                        fontSize: font1,
                        fontWeight: FontWeight.w300),
                  ),
                ),
                SizedBox(height: sizedBoxRatio * 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    " \u2022  #1VPN",
                    style: TextStyle(
                        color: primaryLight,
                        fontFamily: 'Inter',
                        height: 1.3,
                        fontSize: font2,
                        fontWeight: FontWeight.w300),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    " \u2022  Secure Connection",
                    style: TextStyle(
                        color: primaryLight,
                        fontFamily: 'Inter',
                        height: 1.3,
                        fontSize: font2,
                        fontWeight: FontWeight.w300),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    " \u2022  Global Servers",
                    style: TextStyle(
                        color: primaryLight,
                        fontFamily: 'Inter',
                        height: 1.3,
                        fontSize: font2,
                        fontWeight: FontWeight.w300),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    " \u2022  No Logs Kept",
                    style: TextStyle(
                        color: primaryLight,
                        fontFamily: 'Inter',
                        height: 1.3,
                        fontSize: font2,
                        fontWeight: FontWeight.w300),
                  ),
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
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 1.0],
                colors: [
                  bgSecondaryGradStart,
                  bgSecondaryGradEnd,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => const LoginScreen()));
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
                "Get Started",
                style: TextStyle(
                    color: primaryLight,
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
