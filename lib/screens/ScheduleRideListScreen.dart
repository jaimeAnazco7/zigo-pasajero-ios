import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:taxi_booking/utils/Extensions/context_extension.dart';
import 'package:taxi_booking/utils/Extensions/dataTypeExtensions.dart';

import '../components/CancelOrderDialog.dart';
import '../components/RideAcceptWidget.dart';
import '../main.dart';
import '../model/CurrentRequestModel.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';

class ScheduleRideListScreen extends StatefulWidget {
  ScheduleRideListScreen({super.key});

  @override
  State<ScheduleRideListScreen> createState() => _ScheduleRideListScreenState();
}

class _ScheduleRideListScreenState extends State<ScheduleRideListScreen> {
  List<OnRideRequest> schedule_ride_request = [];

  @override
  void initState() {
    super.initState();
    getCurrentRequest();
  }

  getCurrentRequest() async {
    appStore.setLoading(true);
    await getCurrentRideRequest().then((value) {
      appStore.setLoading(false);
      schedule_ride_request = value.schedule_ride_request ?? [];
      setState(() {});
    }).catchError((error, stack) {
      appStore.setLoading(false);
      log("Error-- " + error.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, schedule_ride_request);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "${language.schedule_list_title}",
            style: primaryTextStyle(size: 18, weight: FontWeight.bold, color: neonHighlight),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    "🚖 ${language.schedule_list_desc}",
                    style: secondaryTextStyle(size: 14, color: Colors.black, weight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < schedule_ride_request.length; i++)
                          Container(
                            width: context.width(),
                            padding: EdgeInsets.all(8),
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: primaryColor),
                              borderRadius: BorderRadius.circular(defaultRadius),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            "${language.rideId}: ${schedule_ride_request[i].id}",
                                            style: primaryTextStyle(size: 12, weight: FontWeight.bold),
                                          ),
                                          Text(
                                            "${language.schedule_at}: ${DateFormat('dd MMM yyyy hh:mm a').format(DateTime.parse(schedule_ride_request[i].schedule_datetime.toString() + "Z").toLocal())}",
                                            style: secondaryTextStyle(size: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton(
                                      itemBuilder: (context) {
                                        return [
                                          PopupMenuItem(
                                            child: Text(language.cancel),
                                            value: "cancel",
                                          ),
                                        ];
                                      },
                                      // color: Colors.white70,
                                      shadowColor: Colors.black,
                                      popUpAnimationStyle: AnimationStyle(curve: Curves.bounceIn, reverseCurve: Curves.bounceInOut),
                                      borderRadius: radius(24),
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(borderRadius: radius(12)),
                                      child: Icon(Icons.more_vert),
                                      enabled: true,
                                      clipBehavior: Clip.none,
                                      onSelected: (value) {
                                        if (value == "cancel") {
                                          showModalBottomSheet(
                                              context: context,
                                              isDismissible: false,
                                              isScrollControlled: true,
                                              builder: (context) {
                                                return CancelOrderDialog(
                                                  onCancel: (reason) async {
                                                    Navigator.pop(context);
                                                    appStore.setLoading(true);
                                                    sharedPref.remove(REMAINING_TIME);
                                                    sharedPref.remove(IS_TIME);
                                                    await cancelRequest(reason, ride_id: schedule_ride_request[i].id);
                                                    appStore.setLoading(false);
                                                  },
                                                );
                                              });
                                        }
                                      },
                                    )
                                  ],
                                ),
                                Divider(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.near_me, color: Colors.green, size: 18),
                                        SizedBox(width: 8),
                                        Expanded(child: Text(schedule_ride_request[i].startAddress.validate(), style: primaryTextStyle(size: 14), maxLines: 2)),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        SizedBox(width: 8),
                                        SizedBox(
                                          height: 12,
                                          child: DottedLine(
                                            direction: Axis.vertical,
                                            lineLength: double.infinity,
                                            lineThickness: 1,
                                            dashLength: 2,
                                            dashColor: primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, color: Colors.red, size: 18),
                                        SizedBox(width: 8),
                                        Expanded(child: Text(schedule_ride_request[i].endAddress.validate(), style: primaryTextStyle(size: 14), maxLines: 2)),
                                      ],
                                    ),
                                    if (schedule_ride_request[i].multiDropLocation != null && schedule_ride_request[i].multiDropLocation!.isNotEmpty)
                                      Row(
                                        children: [
                                          SizedBox(width: 8),
                                          SizedBox(
                                            height: 12,
                                            child: DottedLine(
                                              direction: Axis.vertical,
                                              lineLength: double.infinity,
                                              lineThickness: 1,
                                              dashLength: 2,
                                              dashColor: primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (schedule_ride_request[i].multiDropLocation != null && schedule_ride_request[i].multiDropLocation!.isNotEmpty)
                                      AppButtonWidget(
                                        textColor: primaryColor,
                                        color: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                        // height: 30,
                                        shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius), side: BorderSide(color: primaryColor)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.add,
                                              color: primaryColor,
                                              size: 12,
                                            ),
                                            Text(
                                              language.viewMore,
                                              style: primaryTextStyle(size: 14),
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          showOnlyDropLocationsDialog(
                                              context,
                                              schedule_ride_request[i]
                                                  .multiDropLocation!
                                                  .map(
                                                    (e) => e.address,
                                                  )
                                                  .toList());
                                        },
                                      )
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Observer(builder: (context) {
              if (!appStore.isLoading && schedule_ride_request.isEmpty) {
                return emptyWidget();
              }
              return Visibility(
                visible: appStore.isLoading,
                child: loaderWidget(),
              );
            }),
            // Observer(builder: (context) => Visibility(visible: appStore.isLoading, child: Positioned.fill(child: loaderWidget()))),
          ],
        ),
      ),
    );
  }

  Future<void> cancelRequest(String reason, {int? ride_id}) async {
    Map req = {
      "id": ride_id,
      "cancel_by": RIDER,
      "status": CANCELED,
      "reason": reason,
    };
    appStore.setLoading(true);
    await rideRequestUpdate(request: req, rideId: ride_id).then((value) async {
      appStore.setLoading(false);
      toast(value.message);
      schedule_ride_request.removeWhere(
        (element) => element.id == ride_id,
      );
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
    });
  }
}
