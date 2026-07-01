import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../main.dart';
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/images.dart';

class NoInternetScreen extends StatefulWidget {
  @override
  _NoInternetScreenState createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    //
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: netScreenKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          language.networkErr,
          style: boldTextStyle(color: neonHighlight),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(networkErrorView, width: 200, height: 200, fit: BoxFit.contain),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(language.yourInternetIsNotWorking, textAlign: TextAlign.start, style: secondaryTextStyle(size: 20)),
          ),
        ],
      ),
      bottomNavigationBar: SafeScaffoldBottomBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: AppButtonWidget(
            width: MediaQuery.of(context).size.width,
            text: language.tryAgain,
            textColor: primaryColor,
            color: Colors.white,
            shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius), side: BorderSide(color: primaryColor)),
            onTap: () async {
              List<ConnectivityResult> b = await Connectivity().checkConnectivity();
              if (!b.contains(ConnectivityResult.none)) {
                if (Navigator.canPop(navigatorKey.currentState!.overlay!.context)) {
                  Navigator.pop(navigatorKey.currentState!.overlay!.context);
                }
              } else {
                toast(language.noConnected);
              }
            },
          ),
        ),
      ),
    );
  }
}
