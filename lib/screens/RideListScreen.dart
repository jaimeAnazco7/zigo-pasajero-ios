import 'package:flutter/material.dart';

import '../components/CreateTabScreen.dart';
import '../main.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import 'DashBoardScreen.dart';

class RideListScreen extends StatefulWidget {
  @override
  RideListScreenState createState() => RideListScreenState();
}

class RideListScreenState extends State<RideListScreen> {
  int currentPage = 1;
  int totalPage = 1;
  List<String> riderStatus = [COMPLETED, CANCELED];

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
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.canPop(context)) {
          return true;
        } else {
          launchScreen(getContext, DashBoardScreen(), isNewTask: true);
          return false;
        }
      },
      child: DefaultTabController(
        length: riderStatus.length,
        child: Scaffold(
          backgroundColor: neonBackground,
          appBar: AppBar(
            backgroundColor: neonSurfaceCard,
            foregroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: neonAccent.withOpacity(0.45), width: 1),
            ),
            iconTheme: IconThemeData(color: neonHighlight),
            title: Text(language.rides, style: boldTextStyle(color: Colors.white)),
          ),
          body: SafeArea(
            top: false,
            bottom: true,
            maintainBottomViewPadding: true,
            child: Column(
              children: [
                Container(
                  height: 40,
                  margin: EdgeInsets.only(right: 16, left: 16, top: 16),
                  decoration: BoxDecoration(
                    color: neonSurfaceCard,
                    border: Border.all(color: neonAccent.withOpacity(0.4)),
                    borderRadius: radius(defaultRadius + 2),
                  ),
                  child: TabBar(
                    dividerHeight: 0,
                    padding: EdgeInsets.all(2),
                    indicator: BoxDecoration(borderRadius: radius(), color: neonAccent),
                    labelColor: neonOnAccent,
                    unselectedLabelColor: neonHighlight,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: boldTextStyle(color: neonOnAccent, size: 14),
                    unselectedLabelStyle: boldTextStyle(color: neonHighlight, size: 14),
                    tabs: riderStatus.map((e) {
                      return Tab(
                        child: Text(changeStatusText(e)),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: riderStatus.map((e) {
                      return CreateTabScreen(status: e);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
