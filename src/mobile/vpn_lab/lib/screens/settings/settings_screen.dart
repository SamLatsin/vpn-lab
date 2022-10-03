// ignore_for_file: prefer_const_literals_to_create_immutables

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:launch_review/launch_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vpn_lab/components/alerts.dart';
import 'package:vpn_lab/components/async_tasks.dart';
import 'package:vpn_lab/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:vpn_lab/custom_icons.dart';
import 'package:vpn_lab/screens/authentication/login.dart';
import 'package:vpn_lab/screens/premium/premium_screen.dart';
// ignore: depend_on_referenced_packages
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
// ignore: depend_on_referenced_packages
import 'dart:io' show Platform;

import 'package:vpn_lab/screens/premium/test_purchase.dart';

const String _month = 'base_plan_30';
const String _year = 'base_plan_365';
const List<String> _kProductIds = <String>[
  _month,
  _year,
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  bool isPremium = false;
  String subscriptionEnd = "";

  // ignore: prefer_final_fields
  late AnimationController _controllerScalePremium = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
    lowerBound: 0.9,
    upperBound: 1,
  )..repeat(reverse: true);
  late final Animation<double> _animationScalePremium = CurvedAnimation(
    parent: _controllerScalePremium,
    curve: Curves.linear,
  );

  late Future userDataFuture, storeFuture;
  // ignore: prefer_typing_uninitialized_variables
  var userData;
  int dataGetState = 0;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  List<PurchaseDetails> _purchases = <PurchaseDetails>[];
  String? _purchaseError;

  @override
  // ignore: must_call_super
  void initState() {
    storeFuture = Future<bool>.value(false);
    userDataFuture = getUserData();
    userDataFuture.whenComplete(() {
      dataGetState = 1;
    });
  }

  Future<void> initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _purchases = <PurchaseDetails>[];
      });
      return;
    }

    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
    }

    final ProductDetailsResponse productDetailResponse =
        await _inAppPurchase.queryProductDetails(_kProductIds.toSet());
    if (productDetailResponse.error != null) {
      setState(() {
        _purchases = <PurchaseDetails>[];
      });
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      setState(() {
        _purchases = <PurchaseDetails>[];
      });
      return;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _controllerScalePremium.dispose();
    super.dispose();
  }

  void showPendingUI() {
    setState(() {});
  }

  void handleError(IAPError error) {
    setState(() {});
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // IMPORTANT!! Always verify a purchase before delivering the product.
    // For the purpose of an example, we directly return true.
    if (userData == null) {
      _purchaseError = "Service is unavalable";
      await InAppPurchase.instance.completePurchase(purchaseDetails);
      return Future<bool>.value(false);
    }
    var response = await assignUserToTransactionIdAppStore(
        userData["email"], purchaseDetails.purchaseID);
    if (!response["error"]) {
      return Future<bool>.value(true);
    }
    _purchaseError = response["result"];
    return Future<bool>.value(false);
  }

  Future<void> deliverProduct(PurchaseDetails purchaseDetails) async {
    // IMPORTANT!! Always verify purchase details before delivering the product.
    setState(() {
      _purchases.add(purchaseDetails);
      Navigator.pop(context, true);
    });
  }

  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    if (_purchaseError != "Service is unavalable") {
      getFlushError(_purchaseError!).show(context);
    }
    // handle invalid purchase here if  _verifyPurchase` failed.
  }

  // ignore: unused_element
  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          final bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            deliverProduct(purchaseDetails);
          } else {
            _handleInvalidPurchase(purchaseDetails);
            return;
          }
        }
        if (Platform.isAndroid) {}
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void initialiseUser(user) {
    if (user["isPremium"] == 0) {
      isPremium = false;
    } else {
      isPremium = true;
      subscriptionEnd = user["subscriptionEndDate"].substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      _controllerScalePremium.stop();
    }
    Size size = MediaQuery.of(context).size;
    late double imgSizeDivider, sizedBoxRatio, verticalMargin, font2, topMargin;
    if (Platform.isAndroid) {
      if (size.height > 812) {
        verticalMargin = 20;
        imgSizeDivider = 5;
        sizedBoxRatio = 1.2;
        font2 = 20;
        topMargin = 10;
      } else if (size.height > 660) {
        verticalMargin = 20;
        imgSizeDivider = 5;
        sizedBoxRatio = 1;
        font2 = 18;
        topMargin = 10;
      } else {
        verticalMargin = 10;
        imgSizeDivider = 1.5;
        sizedBoxRatio = 1;
        font2 = 16;
        topMargin = 10;
      }
    }
    if (Platform.isIOS) {
      if (size.height > 812) {
        verticalMargin = 20;
        imgSizeDivider = 5;
        sizedBoxRatio = 1.2;
        font2 = 20;
        topMargin = 0;
      } else if (size.height > 660) {
        verticalMargin = 20;
        imgSizeDivider = 5;
        sizedBoxRatio = 1;
        font2 = 18;
        topMargin = 0;
      } else {
        verticalMargin = 10;
        imgSizeDivider = 1.5;
        sizedBoxRatio = 1;
        font2 = 16;
        topMargin = 0;
      }
    }

    return FutureBuilder<List>(
      future: Future.wait([
        storeFuture,
        userDataFuture,
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'VPN Lab',
            theme: ThemeData(
              primarySwatch: Colors.grey,
            ),
            home: Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: bgPrimary,
              body: AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.light,
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Service is unavaliable",
                          style: TextStyle(
                              color: primaryLight,
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        SizedBox(
                          height: 40,
                          width: 150,
                          child: Ink(
                            decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      bgSecondaryGradStart,
                                      bgSecondaryGradEnd,
                                    ]),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            child: InkWell(
                              splashColor: Colors.black12,
                              highlightColor: Colors.black12,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              child: const Text(
                                "Back",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: primaryLight,
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    height: 2,
                                    fontWeight: FontWeight.bold),
                              ),
                              onTap: () {
                                _controllerScalePremium.stop();
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'VPN Lab',
            theme: ThemeData(
              primarySwatch: Colors.grey,
            ),
            home: Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: bgPrimary,
              body: AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.light,
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: primaryLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        if (dataGetState == 1) {
          userData = snapshot.data![1];
          initialiseUser(userData);
          dataGetState += 1;
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          height: 40,
                          width: 40,
                          child: Ink(
                            decoration: const BoxDecoration(
                                color: bgSecondaryDark,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            child: InkWell(
                              splashColor: Colors.black12,
                              highlightColor: Colors.black12,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: primaryLight,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                        Text(
                          "Settings",
                          style: TextStyle(
                              color: primaryLight.withOpacity(0.5),
                              fontFamily: 'Inter',
                              fontSize: font2,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: sizedBoxRatio * 20),
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: bgSecondaryDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: sizedBoxRatio * 30),
                              Text(
                                (isPremium)
                                    ? "Account Type: Premium"
                                    : "Account Type: Free",
                                style: TextStyle(
                                    color: primaryLight,
                                    fontFamily: 'Inter',
                                    fontSize: font2 - 4,
                                    fontWeight: FontWeight.w400),
                              ),
                              Text(
                                "Valid until: $subscriptionEnd",
                                style: TextStyle(
                                    color: primaryLight,
                                    fontFamily: 'Inter',
                                    fontSize: (isPremium) ? font2 - 4 : 0,
                                    height: 1.8,
                                    fontWeight: FontWeight.w400),
                              ),
                              SizedBox(height: sizedBoxRatio * 20),
                              ScaleTransition(
                                scale: _animationScalePremium,
                                child: Material(
                                  color: transparent,
                                  child: SizedBox(
                                    height: (isPremium) ? 0 : 60,
                                    width: 215,
                                    child: Ink(
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                (isPremium)
                                                    ? transparent
                                                    : bgSecondaryGradStart,
                                                (isPremium)
                                                    ? transparent
                                                    : bgSecondaryGradEnd
                                              ]),
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(10))),
                                      child: InkWell(
                                        splashColor: Colors.black12,
                                        highlightColor: Colors.black12,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(10)),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              size: (isPremium) ? 0 : font2,
                                              CustomIcons.crown,
                                              color: primaryLight,
                                            ),
                                            Text(
                                              (isPremium) ? "" : "  Go Premium",
                                              style: TextStyle(
                                                  color: primaryLight,
                                                  fontFamily: 'Inter',
                                                  fontSize: font2,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        onTap: () async {
                                          if (isPremium) {
                                          } else {
                                            var result = await Navigator.push(
                                                context,
                                                CupertinoPageRoute(
                                                    builder: (context) =>
                                                        const PremiumScreen()));
                                            if (result == true) {
                                              userData = await getUserData();
                                              initialiseUser(userData);
                                              setState(() {
                                                if (userData![
                                                        "subscriptionEndDate"] !=
                                                    null) {
                                                  isPremium = true;
                                                  subscriptionEnd = userData![
                                                      "subscriptionEndDate"];
                                                }
                                              });
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: sizedBoxRatio * 20),
                            ],
                          ),
                        ),
                        Container(
                          height: 80,
                          width: double.infinity,
                          transform: Matrix4.translationValues(0.0, -50.0, 0.0),
                          child: SvgPicture.asset(
                            "assets/images/main_icon.svg",
                            alignment: Alignment.center,
                            width: MediaQuery.of(context).size.width /
                                imgSizeDivider,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: sizedBoxRatio * 60),
                    InkWell(
                      onTap: () async {
                        const url = 'https://YOUR_DOMAIN/support';
                        // ignore: deprecated_member_use
                        await launch(url);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: verticalMargin),
                        child: Align(
                          child: Text(
                            "Help & Support",
                            style: TextStyle(
                                color: primaryLight,
                                fontFamily: 'Inter',
                                fontSize: font2,
                                fontWeight: FontWeight.w400),
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      thickness: 1,
                      color: primaryLight.withOpacity(0.5),
                    ),
                    InkWell(
                      onTap: () async {
                        LaunchReview.launch(
                            androidAppId: "YOUR_ANDROID_APP_ID",
                            iOSAppId: "YOUR_IOS_APP_ID");
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: verticalMargin),
                        child: Align(
                          child: Text(
                            (Platform.isAndroid)
                                ? "Rate me on Google Play"
                                : (Platform.isIOS)
                                    ? "Rate me on AppStore"
                                    : "Rate me",
                            style: TextStyle(
                                color: primaryLight,
                                fontFamily: 'Inter',
                                fontSize: font2,
                                fontWeight: FontWeight.w400),
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      thickness: 1,
                      color: primaryLight.withOpacity(0.5),
                    ),
                    InkWell(
                      onTap: () async {
                        var result =
                            await restorePurchasesAppStore(userData["email"]);
                        if (result["error"]) {
                          // ignore: use_build_context_synchronously
                          getFlushError(result["result"]!).show(context);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: verticalMargin),
                        child: Align(
                          child: Text(
                            "Restore purchase",
                            style: TextStyle(
                                color: primaryLight,
                                fontFamily: 'Inter',
                                fontSize: font2,
                                fontWeight: FontWeight.w400),
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      thickness: 1,
                      color: primaryLight.withOpacity(0.5),
                    ),
                    InkWell(
                      onTap: () async {
                        if (Platform.isAndroid) {
                          await Share.share(
                              'VPN Lab allows you to send and receive information online without the risk of anyone but you. YOUR_LINK_TO_APP');
                        }
                        if (Platform.isIOS) {
                          await Share.share(
                              'VPN Lab allows you to send and receive information online without the risk of anyone but you. YOUR_LINK_TO_APP');
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: verticalMargin),
                        child: Align(
                          child: Text(
                            "Share app",
                            style: TextStyle(
                                color: primaryLight,
                                fontFamily: 'Inter',
                                fontSize: font2,
                                fontWeight: FontWeight.w400),
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      thickness: 1,
                      color: primaryLight.withOpacity(0.5),
                    ),
                    InkWell(
                      onTap: () async {
                        await logoutUser();
                        // ignore: use_build_context_synchronously
                        Navigator.pushAndRemoveUntil(
                          context,
                          CupertinoPageRoute(
                              builder: (context) => const LoginScreen()),
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: verticalMargin),
                        child: Align(
                          child: Text(
                            "Sign Out",
                            style: TextStyle(
                                color: red,
                                fontFamily: 'Inter',
                                fontSize: font2,
                                fontWeight: FontWeight.w400),
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
      },
    );
  }
}
