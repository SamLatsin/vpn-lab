// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:convert';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:vpn_lab/components/alerts.dart';
import 'package:vpn_lab/components/async_tasks.dart';
import 'package:vpn_lab/constants.dart';
import 'package:flutter/services.dart';
import 'package:vpn_lab/custom_icons.dart';
import 'package:signal_strength_indicator/signal_strength_indicator.dart';
import 'package:vpn_lab/models/server_model.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:vpn_lab/screens/premium/premium_screen.dart';
import 'package:vpn_lab/screens/settings/settings_screen.dart';
import 'dart:math' as math;
import 'dart:io' show Platform;

import '../../components/gradient_icon.dart';

// ignore: must_be_immutable
class MainScreen extends StatefulWidget {
  var user;
  MainScreen({Key? key, required this.user}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late Timer t;
  bool isPremium = false;
  bool isSimulator = false;
  final ScrollController _scrollController = ScrollController();
  late double sizedBoxRatio,
      font1,
      font2,
      font3,
      buttonFont,
      connectButtonSize,
      connectButtonInnerSize,
      selectHeight,
      connectIconSize,
      countriesHeight,
      countriesInterval,
      topMargin;
  late bool isButtonEnabled = true;
  late int connectionStatus =
      0; // 0 - disconnected, 1 - connecting, 2 - connected
  late final AnimationController _controllerDisconnectedRotationOuter =
      AnimationController(
    duration: const Duration(seconds: 50),
    vsync: this,
  )..repeat();
  late final Animation<double> _animationDisconnectedRotationOuter =
      CurvedAnimation(
    parent: _controllerDisconnectedRotationOuter,
    curve: Curves.linear,
  );
  late final AnimationController _controllerDisconnectedRotationInner =
      AnimationController(
    duration: const Duration(seconds: 50),
    vsync: this,
  )..repeat();
  final Tween<double> _animationDisconnectedRotationInner = Tween<double>(
    begin: 1,
    end: 0,
  );
  late final AnimationController _controllerScaleConnect = AnimationController(
      duration: const Duration(seconds: 1), vsync: this, value: 0.9);
  late final Animation<double> _animationScaleConnect = CurvedAnimation(
    parent: _controllerScaleConnect,
    curve: Curves.linear,
  );
  late final AnimationController _controllerScalePremium = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
    lowerBound: 0.9,
    upperBound: 1,
  )..repeat(reverse: true);
  late final Animation<double> _animationScalePremium = CurvedAnimation(
    parent: _controllerScalePremium,
    curve: Curves.linear,
  );

  List<Color> colorList = [
    bgSecondaryGradStart,
    bgSecondaryGradEnd,
  ];
  int index = 0; // gradient animation for connect button
  late Color buttonRightGradColor = bgSecondaryDark,
      buttonLeftGradColor = bgSecondaryDark;
  Alignment begin = Alignment.centerLeft;
  Alignment end = Alignment.centerRight;

  final stopwatch = Stopwatch();
  // late double _animatedStopwatchOpacity = 0;

  late Future<List<Server>> serverlistFuture;
  late Future userDataFuture;
  var userData;
  List<Server> serverlist = [];
  List<Server> filteredServerList = [];
  List<Server> countrieslist = [];
  Server? selectedServer;
  Server? optimalServer;
  int selectedServerIndex = -1;
  int dataGetState = 0;

  late OpenVPN openvpn;
  VpnStatus? status;
  VPNStage? stage;
  int? downloadSpeedBytes;
  int? uploadSpeedBytes;
  String _sDownloadSpeed = "0 B/s";
  String _sUploadSpeed = "0 B/s";

  String formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B/s";
    if (bytes <= 1024) return "$bytes B/s";
    const suffixes = [
      "B/s",
      "KB/s",
      "MB/s",
      "GB/s",
      "TB/s",
      "PB/s",
      "EB/s",
      "ZB/s",
      "YB/s"
    ];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  void calculateSpeed(data, status) {
    if (status == null) {
      return;
    }
    if (status.connectedOn == null || data.connectedOn == null) {
      return;
    }
    downloadSpeedBytes = int.parse(data.byteIn) - int.parse(status.byteIn);
    uploadSpeedBytes = int.parse(data.byteOut) - int.parse(status.byteOut);
    if (downloadSpeedBytes != 0) {
      _sDownloadSpeed = formatBytes(downloadSpeedBytes!, 1);
    }
    if (uploadSpeedBytes != 0) {
      _sUploadSpeed = formatBytes(uploadSpeedBytes!, 1);
    }
  }

  @override
  void initState() {
    super.initState();
    serverlistFuture = getServers(widget.user["token"]);
    userDataFuture = getUserData();
    serverlistFuture.whenComplete(() {
      dataGetState = 1;
    });
    if (!isSimulator) {
      openvpn = OpenVPN(
        onVpnStatusChanged: (data) {
          // print(data);
          if (data?.connectedOn != null) {
            calculateSpeed(data, status);
            saveCurrentServerState(selectedServer!, data!);
          }
          try {
            setState(() {
              status = data;
            });
          } catch (e) {
            openvpn.disconnect();
          }
        },
        onVpnStageChanged: (data, raw) {
          // print(data);

          if ((data == VPNStage.disconnected && connectionStatus == 1) ||
              (data == VPNStage.disconnected && connectionStatus == 2)) {
            disconnect();
          }
          if (data == VPNStage.connected && connectionStatus == 1) {
            onConnected();
          }
          setState(() {
            stage = data;
          });
        },
      );
      openvpn.initialize(
        groupIdentifier: "group.com.vpnLab",
        providerBundleIdentifier: "com.digitalgang.VPNLab.VPNExtension",
        localizedDescription: "VPN Lab",
      );
    }
  }

  @override
  void dispose() {
    _controllerDisconnectedRotationOuter.dispose();
    _controllerDisconnectedRotationInner.dispose();
    _controllerScaleConnect.dispose();
    _controllerScalePremium.dispose();
    super.dispose();
  }

  void changeRotateSpeed() {
    int seconds;
    if (connectionStatus == 1) {
      seconds = 10;
    } else {
      seconds = 50;
    }
    _controllerDisconnectedRotationInner.duration = Duration(seconds: seconds);
    _controllerDisconnectedRotationInner.repeat();
    _controllerDisconnectedRotationOuter.duration = Duration(seconds: seconds);
    _controllerDisconnectedRotationOuter.repeat();
  }

  updateConnectButton() {
    changeRotateSpeed();
    buttonRightGradColor = primaryLight;
    // _animatedStopwatchOpacity = 1;
  }

  void onConnected() {
    connectionStatus = 2;
    stopwatch.stop();
    stopwatch.reset();
    stopwatch.start();
    changeRotateSpeed();
  }

  Future connect() async {
    if (!isPremium && selectedServer!.premium) {
      selectedServer = null;
      selectedServerIndex = -1;
      filteredServerList = serverlist.toList();
      setState(() {});
      Navigator.push(context,
          CupertinoPageRoute(builder: (context) => const PremiumScreen()));
      return;
    }
    if (selectedServer != null && !isSimulator) {
      // print("Connecting to ${selectedServer?.name}, ${selectedServer?.ip}");
      if (selectedServer?.type == "openvpn") {
        openvpn.connect(utf8.decode(base64.decode(selectedServer!.config)),
            selectedServer!.name,
            certIsRequired: true);
      }
    }
    if (isSimulator) {
      Future.delayed(const Duration(seconds: 2), () {
        onConnected();
      });
    }
    connectionStatus = 1;

    updateConnectButton();
    t = Timer(const Duration(seconds: 15), () {
      if (connectionStatus == 1) {
        disconnect();
        getFlushError("Failed to connect this server").show(context);
      }
    });
    return;
    // return Future.delayed(const Duration(seconds: 15), () {
    //   if (connectionStatus == 1) {
    //     disconnect();
    //     getFlushError("Failed to connect this server").show(context);
    //   }
    // });
  }

  void disconnect() async {
    t.cancel();
    if (!isSimulator) {
      openvpn.disconnect();
    }
    connectionStatus = 0;
    // disconnect
    stopwatch.stop();
    // print(stopwatch.elapsed);
    stopwatch.reset();
    updateConnectButton();
  }

  Server findOptimalServer(List<Server> serverlist) {
    num maxLoad = 0.0;
    Server tempServer = serverlist[0];
    if (isPremium) {
      for (var server in serverlist) {
        if (server.load > maxLoad) {
          tempServer = server;
          maxLoad = server.load;
        }
      }
    } else {
      for (var server in serverlist) {
        if (server.load > maxLoad && !server.premium) {
          tempServer = server;
          maxLoad = server.load;
        }
      }
    }
    return tempServer;
  }

  void initialiseUser(user) {
    if (user["isPremium"] == 0) {
      isPremium = false;
    } else {
      isPremium = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    if (Platform.isAndroid) {
      if (size.height > 812) {
        connectButtonSize = 50;
        connectButtonInnerSize = 170;
        selectHeight = 75;
        connectIconSize = 60;
        countriesHeight = 50;
        countriesInterval = 10;
        font1 = 30;
        font2 = 20;
        font3 = 14;
        sizedBoxRatio = 1.2;
        buttonFont = 18;
        topMargin = 10;
      } else if (size.height > 660) {
        connectButtonSize = 40;
        connectButtonInnerSize = 120;
        selectHeight = 65;
        connectIconSize = 45;
        countriesHeight = 50;
        countriesInterval = 10;
        font1 = 23;
        font2 = 16;
        font3 = 14;
        sizedBoxRatio = 0.7;
        buttonFont = 15;
        topMargin = 10;
      } else {
        connectButtonSize = 30;
        connectButtonInnerSize = 100;
        selectHeight = 65;
        connectIconSize = 40;
        countriesHeight = 30;
        countriesInterval = 0;
        font1 = 20;
        font2 = 14;
        font3 = 10;
        sizedBoxRatio = 0.5;
        buttonFont = 14;
        topMargin = 10;
      }
    }
    if (Platform.isIOS) {
      if (size.height > 900) {
        connectButtonSize = 50;
        connectButtonInnerSize = 170;
        selectHeight = 80;
        connectIconSize = 60;
        countriesHeight = 50;
        countriesInterval = 10;
        font1 = 30;
        font2 = 20;
        font3 = 14;
        sizedBoxRatio = 1.2;
        buttonFont = 18;
        topMargin = 0;
      } else if (size.height > 802) {
        connectButtonSize = 50;
        connectButtonInnerSize = 170;
        selectHeight = 70;
        connectIconSize = 60;
        countriesHeight = 50;
        countriesInterval = 10;
        font1 = 28;
        font2 = 18;
        font3 = 14;
        sizedBoxRatio = 0.7;
        buttonFont = 18;
        topMargin = 0;
      } else if (size.height > 660) {
        connectButtonSize = 40;
        connectButtonInnerSize = 120;
        selectHeight = 65;
        connectIconSize = 45;
        countriesHeight = 50;
        countriesInterval = 10;
        font1 = 23;
        font2 = 16;
        font3 = 14;
        sizedBoxRatio = 0.7;
        buttonFont = 15;
        topMargin = 0;
      } else {
        connectButtonSize = 30;
        connectButtonInnerSize = 100;
        selectHeight = 65;
        connectIconSize = 40;
        countriesHeight = 30;
        countriesInterval = 0;
        font1 = 20;
        font2 = 14;
        font3 = 10;
        sizedBoxRatio = 0.5;
        buttonFont = 14;
        topMargin = 0;
      }
    }

    double availableHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom +
        0.1; // for refresh working

    return FutureBuilder<List>(
      future: Future.wait([
        serverlistFuture,
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
                          const SizedBox(
                            height: 20,
                          ),
                          Text(
                            "Getting servers...",
                            style: TextStyle(
                                color: primaryLight,
                                fontFamily: 'Inter',
                                fontSize: font3,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      )),
                ),
              ),
            ),
          );
        }
        if (dataGetState == 1) {
          serverlist = snapshot.data![0];
          filteredServerList = serverlist.toList();
          optimalServer = findOptimalServer(serverlist);
          var seen = <String>{};
          countrieslist = serverlist
              .where((server) => seen.add(server.abbreviation))
              .toList();
          userData = snapshot.data![1];
          widget.user = userData;
          initialiseUser(userData);
          dataGetState += 1;
        }
        // print(size.height);
        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: bgPrimary,
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: SafeArea(
              child: RefreshIndicator(
                displacement: 0,
                color: primaryLight.withOpacity(0.5),
                backgroundColor: bgSecondaryGradStart.withOpacity(0.5),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: SizedBox(
                      height: availableHeight,
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
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  child: InkWell(
                                    splashColor: Colors.black12,
                                    highlightColor: Colors.black12,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10)),
                                    child: const Icon(
                                      IconData(0xe3dc,
                                          fontFamily: 'MaterialIcons'),
                                      color: primaryLight,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          CupertinoPageRoute(
                                              builder: (context) =>
                                                  const SettingsScreen()));
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: (isPremium) ? 0 : 40,
                                width: 130,
                                child: Ink(
                                  decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            bgSecondaryGradStart,
                                            bgSecondaryGradEnd
                                          ]),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  child: InkWell(
                                    splashColor: Colors.black12,
                                    highlightColor: Colors.black12,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10)),
                                    child: ScaleTransition(
                                      scale: _animationScalePremium,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            size: (isPremium) ? 0 : font3,
                                            CustomIcons.crown,
                                            color: primaryLight,
                                          ),
                                          Text(
                                            "  Go Premium",
                                            style: TextStyle(
                                                color: primaryLight,
                                                fontFamily: 'Inter',
                                                fontSize: font3,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    onTap: () async {
                                      var result = await Navigator.push(
                                          context,
                                          CupertinoPageRoute(
                                              builder: (context) =>
                                                  const PremiumScreen()));
                                      if (result == true) {
                                        isPremium = true;
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: sizedBoxRatio * 20),
                          Container(
                            height: selectHeight,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: bgSecondaryDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonFormField2(
                              offset: const Offset(0, -20),
                              dropdownMaxHeight: 300,
                              selectedItemHighlightColor: bgSecondaryGradStart,
                              dropdownDecoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: bgSecondaryDark,
                              ),
                              style: TextStyle(
                                  color: primaryLight,
                                  fontFamily: 'Inter',
                                  fontSize: font2,
                                  fontWeight: FontWeight.w300),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                filled: true,
                                fillColor: bgSecondaryDark,
                                labelText: 'Select location',
                                border: InputBorder.none,
                                labelStyle: TextStyle(
                                    color: primaryLight.withOpacity(0.5),
                                    fontFamily: 'Inter',
                                    // height: 1.8,
                                    fontSize: font2,
                                    fontWeight: FontWeight.w500),
                              ),
                              items: filteredServerList.map((Server server) {
                                return DropdownMenuItem(
                                  value: server,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        server.name,
                                        style: TextStyle(
                                            color: primaryLight,
                                            fontFamily: 'Inter',
                                            // height: 1.3,
                                            fontSize: font2,
                                            fontWeight: FontWeight.w400),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(
                                            CustomIcons.crown,
                                            color: (server.premium)
                                                ? yellow
                                                : transparent,
                                          ),
                                          SignalStrengthIndicator.bars(
                                            value: server.load,
                                            minValue: 0,
                                            maxValue: 1,
                                            size: 20,
                                            barCount: 4,
                                            radius: const Radius.circular(20.0),
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            levels: <num, Color>{
                                              0.0: Colors.red,
                                              0.25: Colors.yellow,
                                              0.5: Colors.green,
                                              0.75: Colors.green,
                                            },
                                          ),
                                          Image.asset(
                                            'icons/flags/png/${server.abbreviation}.png',
                                            package: 'country_icons',
                                            height: 30,
                                            width: 30,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              selectedItemBuilder: (BuildContext context) {
                                return filteredServerList
                                    .map<Widget>((Server item) {
                                  return Row(
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                            color: primaryLight,
                                            fontFamily: 'Inter',
                                            // height: 1.3,
                                            fontSize: font2,
                                            fontWeight: FontWeight.w400),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Icon(
                                        CustomIcons.crown,
                                        color: (item.premium)
                                            ? yellow
                                            : transparent,
                                      ),
                                    ],
                                  );
                                }).toList();
                              },
                              onChanged: (Server? item) {
                                // printServerList(filteredServerList);
                                if (connectionStatus == 1 ||
                                    connectionStatus == 2) {
                                  disconnect();
                                }
                                for (var i = 0; i < countrieslist.length; i++) {
                                  if (countrieslist[i].abbreviation ==
                                      item?.abbreviation) {
                                    selectedServerIndex = countrieslist[i].id;
                                  }
                                }

                                selectedServer = item;
                                setState(() {});
                              },
                              icon: Transform.rotate(
                                angle: -90 * math.pi / 180,
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: primaryLight.withOpacity(0.5),
                                ),
                              ),
                              iconSize: 25,
                              value: selectedServer,
                            ),
                          ),
                          SizedBox(height: sizedBoxRatio * 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                height: countriesHeight,
                                child: InkWell(
                                  splashColor: transparent,
                                  highlightColor: transparent,
                                  onTap: () {
                                    if (_scrollController.position.pixels >=
                                        0) {
                                      _scrollController.animateTo(
                                        _scrollController.position.pixels - 70,
                                        duration:
                                            const Duration(milliseconds: 200),
                                        curve: Curves.fastOutSlowIn,
                                      );
                                    }
                                  },
                                  child: Transform.rotate(
                                    angle: math.pi / 180,
                                    child: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: primaryLight.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: SizedBox(
                                  height: countriesHeight,
                                  child: ListView.builder(
                                      // key: ValueKey(index),
                                      controller: _scrollController,
                                      scrollDirection: Axis.horizontal,
                                      shrinkWrap: true,
                                      itemCount: countrieslist.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return GestureDetector(
                                          onTap: () {
                                            if (connectionStatus == 1 ||
                                                connectionStatus == 2) {
                                              disconnect();
                                            }
                                            filteredServerList =
                                                serverlist.toList();
                                            if (selectedServerIndex !=
                                                countrieslist[index].id) {
                                              selectedServerIndex =
                                                  countrieslist[index].id;
                                              selectedServer =
                                                  countrieslist[index];
                                              filteredServerList.removeWhere(
                                                  (server) =>
                                                      server.abbreviation !=
                                                      selectedServer
                                                          ?.abbreviation);
                                              // printServerList(
                                              //     filteredServerList);
                                            } else {
                                              selectedServerIndex = -1;
                                              selectedServer = null;
                                              filteredServerList =
                                                  serverlist.toList();
                                            }
                                            // previousSelectedServerIndex =
                                            //     selectedServerIndex;
                                            setState(() {});
                                          },
                                          child: Container(
                                            height: 50,
                                            width: 50,
                                            margin: EdgeInsets.symmetric(
                                                horizontal: countriesInterval),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    (countrieslist[index].id ==
                                                            selectedServerIndex)
                                                        ? bgIconBlue
                                                        : bgSecondaryDark,
                                                width: 4.0,
                                              ),
                                            ),
                                            child: CircleAvatar(
                                              // foregroundImage: ExactAssetImage(
                                              //     'icons/flags/png/ru.png',
                                              //     package: 'country_icons'),
                                              radius: 50,
                                              backgroundImage: ExactAssetImage(
                                                'icons/flags/png/${countrieslist[index].abbreviation}.png',
                                                package: 'country_icons',
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                ),
                              ),
                              SizedBox(
                                height: countriesHeight,
                                child: InkWell(
                                  splashColor: transparent,
                                  highlightColor: transparent,
                                  onTap: () {
                                    if (_scrollController.position.pixels <=
                                        _scrollController
                                            .position.maxScrollExtent) {
                                      _scrollController.animateTo(
                                        _scrollController.position.pixels + 70,
                                        duration:
                                            const Duration(milliseconds: 200),
                                        curve: Curves.fastOutSlowIn,
                                      );
                                    }
                                  },
                                  child: Transform.rotate(
                                    angle: 180 * math.pi / 180,
                                    child: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: primaryLight.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: sizedBoxRatio * 25),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  thickness: 1,
                                  endIndent: 20,
                                  color: primaryLight.withOpacity(0.5),
                                ),
                              ),
                              Text(
                                "OR",
                                style: TextStyle(
                                    color: primaryLight.withOpacity(0.5),
                                    fontFamily: 'Inter',
                                    fontSize: font3,
                                    fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Divider(
                                  thickness: 1,
                                  indent: 20,
                                  color: primaryLight.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: sizedBoxRatio * 25),
                          Container(
                            height: selectHeight,
                            decoration: BoxDecoration(
                              color: bgSecondaryDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Optimal location",
                                      style: TextStyle(
                                          color: primaryLight.withOpacity(0.5),
                                          fontFamily: 'Inter',
                                          fontSize: font3,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      optimalServer!.name,
                                      style: TextStyle(
                                          color: primaryLight,
                                          fontFamily: 'Inter',
                                          fontSize: font2,
                                          fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: () {},
                                  child: Ink(
                                    child: Container(
                                      height: 50,
                                      width: 80,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            stops: [0.0, 1.0],
                                            colors: [
                                              bgSecondaryGradStart,
                                              bgSecondaryGradEnd,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          onPrimary: bgIconBlue,
                                          shadowColor: transparent,
                                          fixedSize: const Size(78, 48),
                                          primary: bgSecondaryDark,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                        ),
                                        onPressed: () {
                                          if (connectionStatus == 1) {
                                            null;
                                          } else {
                                            changeRotateSpeed();
                                            buttonRightGradColor = primaryLight;
                                            // _animatedStopwatchOpacity = 1;
                                            if (connectionStatus == 0) {
                                              filteredServerList =
                                                  serverlist.toList();
                                              selectedServer = optimalServer;
                                              for (var i = 0;
                                                  i < countrieslist.length;
                                                  i++) {
                                                if (countrieslist[i]
                                                        .abbreviation ==
                                                    selectedServer
                                                        ?.abbreviation) {
                                                  selectedServerIndex =
                                                      countrieslist[i].id;
                                                }
                                              }
                                              connect();
                                            }
                                            if (connectionStatus == 2) {
                                              disconnect();
                                            }
                                            setState(() {});
                                          }
                                        },
                                        child: Text(
                                          (optimalServer == selectedServer &&
                                                  connectionStatus == 1)
                                              ? "•••"
                                              : (connectionStatus == 0 ||
                                                      optimalServer !=
                                                          selectedServer)
                                                  ? "Start"
                                                  : "Stop",
                                          style: TextStyle(
                                              color: bgIconBlue,
                                              fontFamily: 'Inter',
                                              fontSize: font2 - 1,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: sizedBoxRatio * 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Status: ",
                                style: TextStyle(
                                    color: primaryLight,
                                    fontFamily: 'Inter',
                                    fontSize: font3,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                (connectionStatus == 0)
                                    ? "Disconnected"
                                    : (connectionStatus == 1)
                                        ? "Connecting to ${selectedServer?.name}"
                                        : "Connected to ${selectedServer?.name}",
                                style: TextStyle(
                                    color: (connectionStatus == 0)
                                        ? primaryLight.withOpacity(0.5)
                                        : (connectionStatus == 1)
                                            ? primaryLight.withOpacity(0.5)
                                            : primaryLight,
                                    fontFamily: 'Inter',
                                    fontSize: font3,
                                    fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                          SizedBox(height: sizedBoxRatio * 15),
                          InkWell(
                            highlightColor: transparent,
                            splashColor: transparent,
                            onTapDown: (val) {
                              if (connectionStatus != 1) {
                                _controllerScaleConnect.animateTo(1.0);
                              }
                              setState(() {});
                            },
                            onTapCancel: () {
                              _controllerScaleConnect.animateBack(0.9);
                              setState(() {});
                            },
                            onTapUp: (val) {},
                            onTap: () {
                              _controllerScaleConnect.animateBack(0.9);
                              if (connectionStatus == 0) {
                                if (selectedServer == null) {
                                  selectedServer = optimalServer;
                                  for (var i = 0;
                                      i < countrieslist.length;
                                      i++) {
                                    if (countrieslist[i].abbreviation ==
                                        selectedServer?.abbreviation) {
                                      selectedServerIndex = countrieslist[i].id;
                                    }
                                  }
                                }
                                connect();

                                // } else if (connectionStatus == 1) {
                                //   onConnected();
                              } else if (connectionStatus == 2) {
                                disconnect();
                              }
                              setState(() {});
                            },
                            child: RotationTransition(
                              turns: _animationDisconnectedRotationOuter,
                              child: DottedBorder(
                                dashPattern: [2, 17],
                                strokeWidth: 4,
                                color: bgSecondaryGradStart.withOpacity(0.7),
                                padding: const EdgeInsets.all(5),
                                borderType: BorderType.Circle,
                                child: AnimatedContainer(
                                    duration: const Duration(seconds: 5),
                                    padding: EdgeInsets.all(connectButtonSize),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: bgSecondaryGradStart
                                              .withOpacity(0.2),
                                          spreadRadius: 5,
                                          blurRadius: 40,
                                        ),
                                      ],
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          bgSecondaryGradStart.withOpacity(0.2),
                                          bgSecondaryGradEnd.withOpacity(0.2),
                                        ],
                                      ),
                                    ),
                                    child: RotationTransition(
                                      turns: _animationDisconnectedRotationInner
                                          .animate(
                                              _controllerDisconnectedRotationInner),
                                      child: ScaleTransition(
                                        scale: _animationScaleConnect,
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: [
                                                bgSecondaryGradStart,
                                                bgSecondaryGradEnd
                                              ],
                                            ),
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 350),
                                            onEnd: () {
                                              index = index + 1;
                                              if (connectionStatus == 0) {
                                                buttonLeftGradColor =
                                                    bgSecondaryDark;
                                                buttonRightGradColor =
                                                    bgSecondaryDark;
                                                begin = Alignment.centerLeft;
                                                end = Alignment.centerRight;
                                              } else if (connectionStatus ==
                                                  1) {
                                                buttonRightGradColor =
                                                    colorList[index %
                                                        colorList.length];
                                                buttonLeftGradColor = colorList[
                                                    (index + 1) %
                                                        colorList.length];
                                              } else if (connectionStatus ==
                                                  2) {
                                                buttonLeftGradColor =
                                                    bgSecondaryGradEnd;
                                                buttonRightGradColor =
                                                    bgSecondaryGradStart;
                                                begin = Alignment.centerLeft;
                                                end = Alignment.centerRight;
                                              }
                                              setState(() {});
                                            },
                                            height: connectButtonInnerSize,
                                            width: connectButtonInnerSize,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                begin: begin,
                                                end: end,
                                                colors: [
                                                  buttonRightGradColor,
                                                  buttonLeftGradColor
                                                ],
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                GradientIcon(
                                                  Icons
                                                      .power_settings_new_rounded,
                                                  connectIconSize,
                                                  LinearGradient(
                                                    colors: [
                                                      (connectionStatus == 0)
                                                          ? bgSecondaryGradStart
                                                          : (connectionStatus ==
                                                                  1)
                                                              ? primaryLight
                                                              : primaryLight,
                                                      (connectionStatus == 0)
                                                          ? bgSecondaryGradEnd
                                                          : (connectionStatus ==
                                                                  1)
                                                              ? primaryLight
                                                              : primaryLight,
                                                    ],
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight,
                                                  ),
                                                ),
                                                Text(
                                                    (connectionStatus == 0)
                                                        ? "Connect"
                                                        : (connectionStatus ==
                                                                1)
                                                            ? "Connecting"
                                                            : "Disconnect",
                                                    style: TextStyle(
                                                        color: primaryLight,
                                                        fontFamily: 'Inter',
                                                        fontSize: font1 - 7,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    )),
                              ),
                            ),
                          ),
                          SizedBox(height: sizedBoxRatio * 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: (connectionStatus == 2) ? 45 : 0,
                                    height: (connectionStatus == 2) ? 45 : 0,
                                    padding: const EdgeInsets.all(5),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: bgIconBlue.withOpacity(0.5),
                                    ),
                                    child: Transform.rotate(
                                      angle: 90 * math.pi / 180,
                                      child: Icon(
                                        Icons.arrow_back_rounded,
                                        color: (connectionStatus == 2)
                                            ? primaryLight
                                            : transparent,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _sUploadSpeed,
                                    style: TextStyle(
                                        color: (connectionStatus == 2)
                                            ? primaryLight
                                            : transparent,
                                        fontFamily: 'Inter',
                                        fontSize: font3,
                                        height: 2,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              Container(
                                color: transparent,
                                child: Text(
                                  "Time: ${stopwatch.elapsed.inMinutes.remainder(60).toString().padLeft(2, '0')}:${stopwatch.elapsed.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                                  style: TextStyle(
                                      color: (connectionStatus == 0)
                                          ? transparent
                                          : (connectionStatus == 1)
                                              ? transparent
                                              : primaryLight,
                                      fontFamily: 'Inter',
                                      fontSize: font3,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Column(
                                children: [
                                  Container(
                                    width: (connectionStatus == 2) ? 45 : 0,
                                    height: (connectionStatus == 2) ? 45 : 0,
                                    padding: const EdgeInsets.all(5),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: bgIconBlue.withOpacity(0.5),
                                    ),
                                    child: Transform.rotate(
                                      angle: -90 * math.pi / 180,
                                      child: Icon(
                                        Icons.arrow_back_rounded,
                                        color: (connectionStatus == 2)
                                            ? primaryLight
                                            : transparent,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _sDownloadSpeed,
                                    style: TextStyle(
                                      color: (connectionStatus == 2)
                                          ? primaryLight
                                          : transparent,
                                      fontFamily: 'Inter',
                                      fontSize: font3,
                                      height: 2,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                onRefresh: () async {
                  try {
                    serverlist = await getServers(widget.user["token"]);
                    userData = await getUserData();
                  } catch (e) {
                    // ignore: use_build_context_synchronously
                    return getFlushError("Service is unavaliable")
                        .show(context);
                  }
                  initialiseUser(userData);
                  if (connectionStatus != 0) {
                    disconnect();
                  }
                  filteredServerList = serverlist.toList();
                  selectedServer = null;
                  selectedServerIndex = -1;
                  optimalServer = findOptimalServer(serverlist);
                  var seen = <String>{};
                  countrieslist = serverlist
                      .where((server) => seen.add(server.abbreviation))
                      .toList();
                  setState(() {});
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
