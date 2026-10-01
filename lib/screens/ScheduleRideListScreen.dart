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
import '../utils/images.dart';
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
        backgroundColor: neonBackground,
        appBar: AppBar(
          backgroundColor: neonBackground,
          elevation: 0,
          iconTheme: IconThemeData(color: neonHighlight),
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
                    style: secondaryTextStyle(size: 14, color: neonHighlight.withOpacity(0.88), weight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: schedule_ride_request.isEmpty && !appStore.isLoading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(noDataImg, width: 140, height: 180),
                              SizedBox(height: 12),
                              Text(
                                language.schedule_list_title,
                                style: boldTextStyle(color: neonHighlight, size: 16),
                              ),
                              SizedBox(height: 6),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  language.schedule_list_desc,
                                  textAlign: TextAlign.center,
                                  style: secondaryTextStyle(color: neonHighlight.withOpacity(0.75), size: 13),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: schedule_ride_request.length,
                          itemBuilder: (context, i) {
                            final ride = schedule_ride_request[i];
                            DateTime? when;
                            try {
                              when = DateTime.parse('${ride.schedule_datetime}Z').toLocal();
                            } catch (_) {
                              when = null;
                            }
                            return Container(
                              width: context.width(),
                              padding: EdgeInsets.all(14),
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: neonSurfaceCard,
                                border: Border.all(color: neonAccent.withOpacity(0.45)),
                                borderRadius: BorderRadius.circular(defaultRadius),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${language.rideId}: ${ride.id}",
                                              style: primaryTextStyle(size: 12, weight: FontWeight.bold, color: neonHighlight.withOpacity(0.8)),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              "${language.schedule_at}: ${when != null ? DateFormat('dd MMM yyyy hh:mm a').format(when) : (ride.schedule_datetime ?? '')}",
                                              style: boldTextStyle(size: 13, color: neonAccent),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton(
                                        color: neonSurfaceCard,
                                        icon: Icon(Icons.more_vert, color: neonHighlight),
                                        itemBuilder: (context) {
                                          return [
                                            PopupMenuItem(
                                              child: Text(language.cancel, style: primaryTextStyle(color: neonHighlight)),
                                              value: "cancel",
                                            ),
                                          ];
                                        },
                                        shape: RoundedRectangleBorder(borderRadius: radius(12)),
                                        onSelected: (value) {
                                          if (value == "cancel") {
                                            showModalBottomSheet(
                                                context: context,
                                                isDismissible: false,
                                                isScrollControlled: true,
                                                backgroundColor: neonSurfaceCard,
                                                builder: (context) {
                                                  return CancelOrderDialog(
                                                    onCancel: (reason) async {
                                                      Navigator.pop(context);
                                                      appStore.setLoading(true);
                                                      sharedPref.remove(REMAINING_TIME);
                                                      sharedPref.remove(IS_TIME);
                                                      await cancelRequest(reason, ride_id: ride.id);
                                                      appStore.setLoading(false);
                                                    },
                                                  );
                                                });
                                          }
                                        },
                                      )
                                    ],
                                  ),
                                  Divider(color: neonAccent.withOpacity(0.28), height: 20),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.near_me, color: neonAccent, size: 18),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          ride.startAddress.validate().isEmpty ? '—' : ride.startAddress.validate(),
                                          style: primaryTextStyle(size: 14, color: neonHighlight),
                                          maxLines: 3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 8, top: 2, bottom: 2),
                                    child: SizedBox(
                                      height: 14,
                                      child: DottedLine(
                                        direction: Axis.vertical,
                                        lineLength: double.infinity,
                                        lineThickness: 1,
                                        dashLength: 2,
                                        dashColor: neonAccent,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.location_on, color: neonError, size: 18),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          ride.endAddress.validate().isEmpty ? '—' : ride.endAddress.validate(),
                                          style: primaryTextStyle(size: 14, color: neonHighlight),
                                          maxLines: 3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (ride.multiDropLocation != null && ride.multiDropLocation!.isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(top: 10),
                                      child: AppButtonWidget(
                                        textColor: neonOnAccent,
                                        color: neonAccent,
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                        shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.add, color: neonOnAccent, size: 12),
                                            Text(language.viewMore, style: primaryTextStyle(size: 14, color: neonOnAccent)),
                                          ],
                                        ),
                                        onTap: () {
                                          showOnlyDropLocationsDialog(
                                            context,
                                            ride.multiDropLocation!.map((e) => e.address).toList(),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            Observer(builder: (context) {
              return Visibility(
                visible: appStore.isLoading,
                child: loaderWidget(),
              );
            }),
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
