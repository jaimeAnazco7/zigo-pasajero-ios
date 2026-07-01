import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../main.dart';
import '../network/RestApis.dart';
import '../screens/BankInfoScreen.dart';
import '../screens/EditProfileScreen.dart';
import '../screens/EmergencyContactScreen.dart';
import '../screens/RideListScreen.dart';
import '../screens/ScheduleRideListScreen.dart';
import '../screens/SettingScreen.dart';
import '../screens/WalletScreen.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/ConformationDialog.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import '../utils/images.dart';
import 'DrawerWidget.dart';

class DrawerComponent extends StatefulWidget {
  @override
  State<DrawerComponent> createState() => _DrawerComponentState();
}

class _DrawerComponentState extends State<DrawerComponent> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: neonBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 35),
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Observer(builder: (context) {
                return Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: radius(),
                        border: Border.all(color: neonAccent.withOpacity(0.45), width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: radius(),
                        child: commonCachedNetworkImage(appStore.userProfile.validate().validate(), height: 70, width: 70, fit: BoxFit.cover),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sharedPref.getString(FIRST_NAME).validate().capitalizeFirstLetter() +
                                " " +
                                sharedPref.getString(LAST_NAME).validate().capitalizeFirstLetter(),
                            style: boldTextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(appStore.userEmail, style: secondaryTextStyle(color: neonHighlight)),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
            Divider(thickness: 1, height: 40, color: neonAccent.withOpacity(0.22)),
            DrawerWidget(
              title: language.profile,
              iconData: ic_my_profile,
              icon: FontAwesome.user_o,
              onTap: () {
                Navigator.pop(context);
                launchScreen(context, EditProfileScreen(), pageRouteAnimation: PageRouteAnimation.Slide);
              },
            ),
            if (appStore.isScheduleRide == "1")
              DrawerWidget(
                title: language.schedule_list_title,
                iconData: ic_schedule,
                icon: Ionicons.calendar_outline,
                onTap: () {
                  Navigator.pop(context);
                  launchScreen(context, ScheduleRideListScreen());
                },
              ),
            DrawerWidget(
              title: language.rides,
              iconData: ic_my_rides,
              icon: Ionicons.car_outline,
              onTap: () {
                Navigator.pop(context);
                launchScreen(context, RideListScreen(), pageRouteAnimation: PageRouteAnimation.Slide);
              },
            ),
            if (showDrawerWalletAndBankMenu) ...[
              DrawerWidget(
                title: language.wallet,
                iconData: ic_my_wallet,
                icon: Ionicons.ios_wallet_outline,
                onTap: () {
                  Navigator.pop(context);
                  launchScreen(context, WalletScreen(), pageRouteAnimation: PageRouteAnimation.Slide);
                },
              ),
              DrawerWidget(
                title: language.bankInfo,
                iconData: ic_update_bank_info,
                icon: MaterialCommunityIcons.bank_outline,
                onTap: () {
                  Navigator.pop(context);
                  launchScreen(context, BankInfoScreen(), pageRouteAnimation: PageRouteAnimation.Slide);
                },
              ),
            ],
            DrawerWidget(
              title: language.emergencyContacts,
              iconData: ic_emergency_contact,
              icon: Ionicons.medkit_outline,
              onTap: () {
                Navigator.pop(context);
                launchScreen(context, EmergencyContactScreen(), pageRouteAnimation: PageRouteAnimation.Slide);
              },
            ),
            DrawerWidget(
              title: language.settings,
              iconData: ic_setting,
              icon: Ionicons.settings_outline,
              onTap: () {
                Navigator.pop(context);
                launchScreen(context, SettingScreen(), pageRouteAnimation: PageRouteAnimation.Slide);
              },
            ),
            DrawerWidget(
              title: language.logOut,
              iconData: ic_logout,
              icon: Ionicons.log_out_outline,
              onTap: () async {
                await showConfirmDialogCustom(context,
                    primaryColor: primaryColor,
                    dialogType: DialogType.CONFIRMATION,
                    title: language.areYouSureYouWantToLogoutThisApp,
                    positiveText: language.yes,
                    negativeText: language.no,                     onAccept: (v) async {
                  await appStore.setLoading(true);
                  await Future.delayed(Duration(milliseconds: 500));
                  await logout();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
