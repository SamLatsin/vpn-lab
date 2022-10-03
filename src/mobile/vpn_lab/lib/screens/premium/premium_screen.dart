// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:vpn_lab/components/alerts.dart';
import 'package:vpn_lab/components/async_tasks.dart';
import 'package:vpn_lab/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:vpn_lab/custom_icons.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
// ignore: depend_on_referenced_packages
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

import 'package:vpn_lab/screens/premium/test_purchase.dart';

const String _month = 'base_plan_30';
const String _year = 'base_plan_365';
const List<String> _kProductIds = <String>[
  _month,
  _year,
];

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _PremiumScreenState createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controllerScalePremium = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
    lowerBound: 0.9,
    upperBound: 1,
  )..stop();
  late final Animation<double> _animationScalePremium = CurvedAnimation(
    parent: _controllerScalePremium,
    curve: Curves.linear,
  );
  int selectedOffer = 0;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = <ProductDetails>[];
  List<PurchaseDetails> _purchases = <PurchaseDetails>[];
  bool _purchasePending = false;
  String? _purchaseError;

  late Future userDataFuture, storeFuture;
  // ignore: prefer_typing_uninitialized_variables
  var userData;
  int dataGetState = 0;

  @override
  void initState() {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription =
        purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (Object error) {
      // handle error here.
    });
    storeFuture = initStoreInfo();
    cleanPendingTransactions();

    super.initState();
    userDataFuture = getUserData();
    storeFuture.whenComplete(() {
      dataGetState = 1;
    });
  }

  Future<void> cleanPendingTransactions() async {
    if (Platform.isIOS) {
      var paymentWrapper = SKPaymentQueueWrapper();
      var transactions = await paymentWrapper.transactions();
      // ignore: avoid_function_literals_in_foreach_calls
      transactions.forEach((transaction) async {
        await paymentWrapper.finishTransaction(transaction);
      });
    }
  }

  Future<void> initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _products = <ProductDetails>[];
        _purchases = <PurchaseDetails>[];
        _purchasePending = false;
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
        _products = productDetailResponse.productDetails;
        _purchases = <PurchaseDetails>[];
        _purchasePending = false;
      });
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      setState(() {
        _products = productDetailResponse.productDetails;
        _purchases = <PurchaseDetails>[];
        _purchasePending = false;
      });
      return;
    }

    setState(() {
      _products = productDetailResponse.productDetails;
      _purchasePending = false;
    });
  }

  @override
  void dispose() {
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      iosPlatformAddition.setDelegate(null);
    }
    _subscription.cancel();
    _controllerScalePremium.dispose();
    super.dispose();
  }

  void showPendingUI() {
    setState(() {
      _purchasePending = true;
    });
  }

  void handleError(IAPError error) {
    setState(() {
      _purchasePending = false;
    });
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
      _purchasePending = false;
      Navigator.pop(context, true);
    });
  }

  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    if (_purchaseError != "Service is unavalable") {
      getFlushError(_purchaseError!).show(context);
    }
    // handle invalid purchase here if  _verifyPurchase` failed.
  }

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

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    late double imgSizeDivider,
        sizedBoxRatio,
        font2,
        font3,
        logoHeight,
        premiumOffset,
        powerIconSize,
        offerWidth,
        purchaseButtonHeight,
        purchaseButtonWidth,
        purchaseButtonOffset,
        topMargin;
    if (Platform.isAndroid) {
      if (size.height > 812) {
        purchaseButtonHeight = 60;
        purchaseButtonWidth = 214;
        purchaseButtonOffset = 30;
        offerWidth = 180;
        premiumOffset = -30;
        powerIconSize = 20;
        logoHeight = 80;
        imgSizeDivider = 5;
        sizedBoxRatio = 1.2;
        font2 = 17;
        font3 = 10;
        topMargin = 10;
      } else if (size.height > 660) {
        purchaseButtonHeight = 55;
        purchaseButtonWidth = 200;
        purchaseButtonOffset = 28;
        offerWidth = 170;
        premiumOffset = -30;
        powerIconSize = 20;
        logoHeight = 70;
        imgSizeDivider = 5;
        sizedBoxRatio = 0.8;
        font2 = 17;
        font3 = 8;
        topMargin = 10;
      } else {
        purchaseButtonHeight = 45;
        purchaseButtonWidth = 170;
        purchaseButtonOffset = 22;
        offerWidth = 140;
        premiumOffset = -25;
        powerIconSize = 15;
        logoHeight = 70;
        imgSizeDivider = 1.5;
        sizedBoxRatio = 0.65;
        font2 = 15;
        font3 = 7;
        topMargin = 10;
      }
    }
    if (Platform.isIOS) {
      if (size.height > 900) {
        purchaseButtonHeight = 60;
        purchaseButtonWidth = 214;
        purchaseButtonOffset = 30;
        offerWidth = 190;
        premiumOffset = -30;
        powerIconSize = 20;
        logoHeight = 80;
        imgSizeDivider = 5;
        sizedBoxRatio = 1.2;
        font2 = 20;
        font3 = 10;
        topMargin = 0;
      } else if (size.height > 812) {
        purchaseButtonHeight = 60;
        purchaseButtonWidth = 214;
        purchaseButtonOffset = 30;
        offerWidth = 170;
        premiumOffset = -30;
        powerIconSize = 20;
        logoHeight = 80;
        imgSizeDivider = 5;
        sizedBoxRatio = 1.1;
        font2 = 18;
        font3 = 10;
        topMargin = 0;
      } else if (size.height > 660) {
        purchaseButtonHeight = 55;
        purchaseButtonWidth = 200;
        purchaseButtonOffset = 28;
        offerWidth = 170;
        premiumOffset = -30;
        powerIconSize = 20;
        logoHeight = 70;
        imgSizeDivider = 5;
        sizedBoxRatio = 0.8;
        font2 = 17;
        font3 = 8;
        topMargin = 0;
      } else {
        purchaseButtonHeight = 45;
        purchaseButtonWidth = 170;
        purchaseButtonOffset = 22;
        offerWidth = 140;
        premiumOffset = -25;
        powerIconSize = 15;
        logoHeight = 70;
        imgSizeDivider = 1.5;
        sizedBoxRatio = 0.65;
        font2 = 15;
        font3 = 7;
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
                                Navigator.pop(context, false);
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
          if (userData["isPremium"] == 1) {
            Navigator.pop(context, true);
          }
          dataGetState += 1;
        }

        return Scaffold(
          backgroundColor: bgPrimary,
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: SafeArea(
                child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: topMargin,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
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
                                  Navigator.pop(context, false);
                                },
                              ),
                            ),
                          ),
                          Text(
                            "Premium",
                            style: TextStyle(
                                color: primaryLight.withOpacity(0.5),
                                fontFamily: 'Inter',
                                fontSize: font2,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: sizedBoxRatio * 20),
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xff202960),
                                      Color(0xff2444A1),
                                    ]),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(height: sizedBoxRatio * 30),
                                  Text(
                                    "Become 40% happier",
                                    style: TextStyle(
                                        color: primaryLight,
                                        fontFamily: 'Inter',
                                        fontSize: font2,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "with VPN premium VIP",
                                    style: TextStyle(
                                        color: primaryLight,
                                        fontFamily: 'Inter',
                                        height: 1.7,
                                        fontSize: font2,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: sizedBoxRatio * 20),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            bgSecondaryGradStart
                                                .withOpacity(0.3),
                                            bgSecondaryGradEnd.withOpacity(0.3),
                                          ]),
                                    ),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: sizedBoxRatio * 15),
                                          Text(
                                            "CHOOSE THE PLAN THAT'S RIGHT FOR YOU",
                                            style: TextStyle(
                                                color: primaryLight,
                                                fontFamily: 'Inter',
                                                height: 1.7,
                                                fontSize: font2 - 3,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: sizedBoxRatio * 15),
                                          SizedBox(height: sizedBoxRatio * 10),
                                          Row(
                                            children: [
                                              Icon(
                                                size: font2,
                                                CustomIcons.benefit,
                                                color: primaryLight,
                                              ),
                                              Text(
                                                "  Connects you to the fastest VPN Proxy Server",
                                                style: TextStyle(
                                                    color: primaryLight,
                                                    fontFamily: 'Inter',
                                                    fontSize: font2 - 4,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: sizedBoxRatio * 10),
                                          Row(
                                            children: [
                                              Icon(
                                                size: font2,
                                                CustomIcons.benefit,
                                                color: primaryLight,
                                              ),
                                              Text(
                                                "  It's free and offers unlimited traffic",
                                                style: TextStyle(
                                                    color: primaryLight,
                                                    fontFamily: 'Inter',
                                                    fontSize: font2 - 4,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: sizedBoxRatio * 10),
                                          Row(
                                            children: [
                                              Icon(
                                                size: font2,
                                                CustomIcons.benefit,
                                                color: primaryLight,
                                              ),
                                              Text(
                                                "  No log is saved from any users",
                                                style: TextStyle(
                                                    color: primaryLight,
                                                    fontFamily: 'Inter',
                                                    fontSize: font2 - 4,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: sizedBoxRatio * 10),
                                          Row(
                                            children: [
                                              Icon(
                                                size: font2,
                                                CustomIcons.benefit,
                                                color: primaryLight,
                                              ),
                                              Text(
                                                "  Bank grade security and encryption technique",
                                                style: TextStyle(
                                                    color: primaryLight,
                                                    fontFamily: 'Inter',
                                                    fontSize: font2 - 4,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: sizedBoxRatio * 20),
                                        ]),
                                  ),
                                  SizedBox(height: sizedBoxRatio * 15),
                                  Text(
                                    "PREMIUM STREAMING PLANS",
                                    style: TextStyle(
                                        color: primaryLight,
                                        fontFamily: 'Inter',
                                        fontSize: font2,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: sizedBoxRatio * 40),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Stack(
                                          alignment: Alignment.topCenter,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: const BoxDecoration(
                                                color: primaryLight,
                                                shape: BoxShape.circle,
                                              ),
                                              transform:
                                                  Matrix4.translationValues(
                                                      0.0, premiumOffset, 0.0),
                                              child: Column(
                                                children: [
                                                  SizedBox(
                                                      height:
                                                          sizedBoxRatio * 2),
                                                  Icon(
                                                    Icons
                                                        .power_settings_new_rounded,
                                                    size: powerIconSize,
                                                    color: premiumFont,
                                                  ),
                                                  SizedBox(
                                                      height:
                                                          sizedBoxRatio * 18),
                                                ],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                if (selectedOffer == 1) {
                                                  selectedOffer = 0;
                                                  _controllerScalePremium
                                                      .stop();
                                                } else {
                                                  selectedOffer = 1;
                                                  _controllerScalePremium
                                                      .repeat(reverse: true);
                                                }
                                                setState(() {});
                                              },
                                              child: Container(
                                                width: offerWidth,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20),
                                                decoration: BoxDecoration(
                                                  color: premiumFont,
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                    Radius.circular(10),
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: (selectedOffer ==
                                                              1)
                                                          ? bgSecondaryDark
                                                              .withOpacity(0.6)
                                                          : transparent,
                                                      spreadRadius: 3,
                                                      blurRadius: 3,
                                                      offset:
                                                          const Offset(0, 5),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: primaryLight,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        bottomLeft:
                                                            Radius.circular(10),
                                                        bottomRight:
                                                            Radius.circular(10),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      "Limited Time",
                                                      style: TextStyle(
                                                          color: premiumFont,
                                                          fontFamily: 'Inter',
                                                          fontSize: font2 - 4,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      height:
                                                          sizedBoxRatio * 10),
                                                  Text(
                                                    _products[0].title,
                                                    style: TextStyle(
                                                        color: primaryLight,
                                                        fontFamily: 'Inter',
                                                        fontSize: font2 - 4,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Text(
                                                    _products[0].price,
                                                    style: TextStyle(
                                                        color: primaryLight,
                                                        height: 1.7,
                                                        fontFamily: 'Inter',
                                                        fontSize: font2 - 4,
                                                        fontWeight:
                                                            FontWeight.w400),
                                                  ),
                                                  Text(
                                                    "•",
                                                    style: TextStyle(
                                                        color: primaryLight,
                                                        height: 1.5,
                                                        fontFamily: 'Inter',
                                                        fontSize: font2 - 4,
                                                        fontWeight:
                                                            FontWeight.w400),
                                                  ),
                                                  Text(
                                                    _products[0].description,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        color: primaryLight,
                                                        height: 1.7,
                                                        fontFamily: 'Inter',
                                                        fontSize: font2 - 4,
                                                        fontWeight:
                                                            FontWeight.w400),
                                                  ),
                                                  SizedBox(
                                                      height:
                                                          sizedBoxRatio * 10),
                                                ]),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Stack(
                                          alignment: Alignment.topCenter,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: const BoxDecoration(
                                                color: primaryLight,
                                                shape: BoxShape.circle,
                                              ),
                                              transform:
                                                  Matrix4.translationValues(
                                                      0.0, premiumOffset, 0.0),
                                              child: Column(
                                                children: [
                                                  SizedBox(
                                                      height:
                                                          sizedBoxRatio * 2),
                                                  Icon(
                                                    Icons
                                                        .power_settings_new_rounded,
                                                    size: powerIconSize,
                                                    color: premiumFont,
                                                  ),
                                                  SizedBox(
                                                      height:
                                                          sizedBoxRatio * 18),
                                                ],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                if (selectedOffer == 2) {
                                                  selectedOffer = 0;
                                                  _controllerScalePremium
                                                      .stop();
                                                } else {
                                                  selectedOffer = 2;
                                                  _controllerScalePremium
                                                      .repeat(reverse: true);
                                                }
                                                setState(() {});
                                              },
                                              child: Container(
                                                width: offerWidth,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xff3CAACD),
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                    Radius.circular(10),
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: (selectedOffer ==
                                                              2)
                                                          ? bgSecondaryDark
                                                              .withOpacity(0.6)
                                                          : transparent,
                                                      spreadRadius: 3,
                                                      blurRadius: 3,
                                                      offset:
                                                          const Offset(0, 5),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: primaryLight,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        bottomLeft:
                                                            Radius.circular(10),
                                                        bottomRight:
                                                            Radius.circular(10),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      "Limited Time",
                                                      style: TextStyle(
                                                          color: premiumFont,
                                                          fontFamily: 'Inter',
                                                          fontSize: font2 - 4,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      height:
                                                          sizedBoxRatio * 10),
                                                  Text(
                                                    _products[1].title,
                                                    style: TextStyle(
                                                        color: primaryLight,
                                                        fontFamily: 'Inter',
                                                        fontSize: font2 - 4,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Text(
                                                    _products[1].price,
                                                    style: TextStyle(
                                                        color: primaryLight,
                                                        height: 1.7,
                                                        fontFamily: 'Inter',
                                                        fontSize: font2 - 4,
                                                        fontWeight:
                                                            FontWeight.w400),
                                                  ),
                                                  Text(
                                                    "•",
                                                    style: TextStyle(
                                                        color: primaryLight,
                                                        height: 1.5,
                                                        fontFamily: 'Inter',
                                                        fontSize: font2 - 4,
                                                        fontWeight:
                                                            FontWeight.w400),
                                                  ),
                                                  Text(
                                                    _products[1].description,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        color: primaryLight,
                                                        height: 1.7,
                                                        fontFamily: 'Inter',
                                                        fontSize: font2 - 4,
                                                        fontWeight:
                                                            FontWeight.w400),
                                                  ),
                                                  SizedBox(
                                                      height:
                                                          sizedBoxRatio * 10),
                                                ]),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: sizedBoxRatio * 50),
                                ],
                              ),
                            ),
                            Container(
                              height: logoHeight,
                              width: double.infinity,
                              transform:
                                  Matrix4.translationValues(0.0, -50.0, 0.0),
                              child: SvgPicture.asset(
                                "assets/images/main_icon.svg",
                                alignment: Alignment.center,
                                width: MediaQuery.of(context).size.width /
                                    imgSizeDivider,
                              ),
                            ),
                          ],
                        ),
                        ScaleTransition(
                          scale: _animationScalePremium,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  (selectedOffer == 0)
                                      ? buttonDisabled
                                      : bgSecondaryGradStart,
                                  (selectedOffer == 0)
                                      ? buttonDisabled
                                      : bgSecondaryGradEnd
                                ],
                              ),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                            ),
                            transform: Matrix4.translationValues(
                                0.0, purchaseButtonOffset, 0.0),
                            height: purchaseButtonHeight,
                            width: purchaseButtonWidth,
                            child: Material(
                              color: transparent,
                              child: InkWell(
                                splashColor: Colors.black12,
                                highlightColor: Colors.black12,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(10)),
                                onTap: (selectedOffer == 0)
                                    ? null
                                    : () {
                                        late PurchaseParam purchaseParam;

                                        if (Platform.isAndroid) {
                                          // NOTE: If you are making a subscription purchase/upgrade/downgrade, we recommend you to
                                          // verify the latest status of you your subscription by using server side receipt validation
                                          // and update the UI accordingly. The subscription purchase status shown
                                          // inside the app may not be accurate.

                                          // final GooglePlayPurchaseDetails?
                                          //     oldSubscription =
                                          //     _getOldSubscription(
                                          //         productDetails, purchases);

                                          // purchaseParam = GooglePlayPurchaseParam(
                                          //     productDetails: _products[selectedOffer-1],
                                          //     changeSubscriptionParam:
                                          //         (oldSubscription != null)
                                          //             ? ChangeSubscriptionParam(
                                          //                 oldPurchaseDetails:
                                          //                     oldSubscription,
                                          //                 prorationMode: ProrationMode
                                          //                     .immediateWithTimeProration,
                                          //               )
                                          //             : null);
                                        } else {
                                          purchaseParam = PurchaseParam(
                                            productDetails:
                                                _products[selectedOffer - 1],
                                          );
                                        }
                                        try {
                                          _inAppPurchase.buyNonConsumable(
                                              purchaseParam: purchaseParam);
                                        } on PlatformException catch (e) {
                                          if (e.code ==
                                              'storekit_duplicate_product_object') {}
                                        }
                                      },
                                child: Align(
                                  child: Text(
                                    "Continue",
                                    style: TextStyle(
                                        color: (selectedOffer == 0)
                                            ? primaryLight.withOpacity(0.5)
                                            : primaryLight,
                                        fontFamily: 'Inter',
                                        fontSize: font2,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: sizedBoxRatio * 40),
                    Text(
                      "Auto Renews. Cancel Anytime.",
                      style: TextStyle(
                          color: primaryLight,
                          fontFamily: 'Inter',
                          fontSize: font3 + 5,
                          fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
                _purchasePending
                    ? Container(
                        color: bgPrimary.withOpacity(0.5),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: primaryLight,
                          ),
                        ),
                      )
                    : Container(),
              ],
            )),
          ),
        );
      },
    );
  }
}
