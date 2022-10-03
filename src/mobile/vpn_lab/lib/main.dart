import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vpn_lab/components/async_tasks.dart';
import 'package:vpn_lab/constants.dart';
import 'package:vpn_lab/screens/home/first_screen.dart';
import 'package:vpn_lab/screens/main/main_screen.dart';

void main() {
  // WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VPNApp());
}

class VPNApp extends StatelessWidget {
  const VPNApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return FutureBuilder(
      future: getUserData(),
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
                                "Try again",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: primaryLight,
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    height: 2,
                                    fontWeight: FontWeight.bold),
                              ),
                              onTap: () {
                                runApp(
                                  MaterialApp(
                                    debugShowCheckedModeBanner: false,
                                    title: 'VPN Lab',
                                    theme: ThemeData(
                                      primarySwatch: Colors.grey,
                                    ),
                                    home: const VPNApp(),
                                  ),
                                );
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
            home: const Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: bgPrimary,
              body: AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.light,
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      color: primaryLight,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        var userData = snapshot.data;
        return (userData != false)
            ? MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'VPN Lab',
                theme: ThemeData(
                  primarySwatch: Colors.grey,
                ),
                home: MainScreen(user: userData),
              )
            : MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'VPN Lab',
                theme: ThemeData(
                  primarySwatch: Colors.grey,
                ),
                home: const FirstScreen(),
              );
      },
    );
  }
}
