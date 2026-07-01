import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:taxi_booking/utils/Extensions/dataTypeExtensions.dart';
import 'package:taxi_booking/utils/images.dart';

import '../main.dart';
import '../network/RestApis.dart';
import '../screens/DashBoardScreen.dart';
import '../service/RideService.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import 'CancelOrderDialog.dart';

class BookingWidget extends StatefulWidget {
  final bool isLast;
  final int? id;
  final String? dt;

  BookingWidget({required this.id, this.isLast = false, this.dt});

  @override
  BookingWidgetState createState() => BookingWidgetState();
}

class BookingWidgetState extends State<BookingWidget> {
  RideService rideService = RideService();
  final int timerMaxSeconds = appStore.rideMinutes != null ? int.parse(appStore.rideMinutes!) * 60 : 5 * 60;

  int currentSeconds = 0;
  int duration = 0;
  int count = 0;
  Timer? timer;
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? d2;

  String get timerText => '${((duration - currentSeconds) ~/ 60).toString().padLeft(2, '0')}: ${((duration - currentSeconds) % 60).toString().padLeft(2, '0')}';
  bool called = false;

  /// Tiempo de búsqueda agotado: mismo modal, sin auto-cancelar hasta que el usuario elija.
  bool _timedOutWaitingDriver = false;
  bool _timeoutUiScheduled = false;

  DateTime _nowForDeadline() => DateTime.parse(DateTime.now().toUtc().toString().replaceAll("Z", ""));

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    print(REMAINING_TIME);
    print(IS_TIME);
    if (sharedPref.getString(IS_TIME) == null) {
      duration = timerMaxSeconds;
      startTimeout();
      sharedPref.setString(IS_TIME, DateTime.now().add(Duration(seconds: timerMaxSeconds)).toString());
      sharedPref.setString(REMAINING_TIME, timerMaxSeconds.toString());
    } else {
      duration = DateTime.parse(sharedPref.getString(IS_TIME)!).difference(DateTime.now()).inSeconds;
      if (duration > 0) {
        startTimeout();
      } else {
        sharedPref.remove(IS_TIME);
        duration = timerMaxSeconds;
        setState(() {});
        startTimeout();
      }
    }
  }

  // cancelRideCall() {
  //   Map req = {
  //     'status': CANCELED,
  //     'cancel_by': AUTO,
  //     "reason": "Ride is auto cancelled",
  //   };
  //   appStore.setLoading(true);
  //   rideRequestUpdate(request: req, rideId: widget.id).then((value) async {
  //     appStore.setLoading(false);
  //     toast(language.noNearByDriverFound);
  //     sharedPref.remove(REMAINING_TIME);
  //     sharedPref.remove(IS_TIME);
  //   }).catchError((error) {
  //     appStore.setLoading(false);
  //     log(error.toString());
  //   });
  // }

  startTimeout() {
    if (called == true) return;
    called = true;
    if (widget.dt != null) {
      DateTime? d1 = DateTime.tryParse(widget.dt.validate());
      if (d1 != null) {
        // d1=d1.toUtc();
        print("CheckDateTime:::${d1}");
        // d1=d1.t
        setState(
          () {
            // d2 = d1.toUtc().add(Duration(seconds: timerMaxSeconds));
            d2 = d1!.add(Duration(seconds: timerMaxSeconds));
          },
        );
        print("CheckDateTimedafjfkljf:::${d2}");
        return;
      }
    }
    return;
    var duration2 = Duration(seconds: 1);
    timer = Timer.periodic(duration2, (timer) {
      setState(
        () {
          currentSeconds = timer.tick;
          count++;
          if (count >= 60) {
            int data = int.parse(sharedPref.getString(REMAINING_TIME)!);
            data = data - count;
            Map req = {
              'max_time_for_find_driver_for_ride_request': data,
            };
            rideRequestUpdate(request: req, rideId: widget.id).then((value) {
              //
            }).catchError((error) {
              log(error.toString());
            });
            sharedPref.setString(REMAINING_TIME, data.toString());
            count = 0;
          }
          if (timer.tick >= duration) {
            timer.cancel();
            Map req = {
              'status': CANCELED,
              'cancel_by': AUTO,
              "reason": "Ride is auto cancelled",
            };
            appStore.setLoading(true);
            rideRequestUpdate(request: req, rideId: widget.id).then((value) async {
              appStore.setLoading(false);
              toast(language.noNearByDriverFound);
              sharedPref.remove(REMAINING_TIME);
              sharedPref.remove(IS_TIME);
            }).catchError((error) {
              appStore.setLoading(false);
              log(error.toString());
            });
          }
        },
      );
    });
  }

  Future<void> cancelRequest(String? reason) async {
    Map req = {
      "id": widget.id,
      "cancel_by": RIDER,
      "status": CANCELED,
      "reason": reason,
    };
    await rideRequestUpdate(request: req, rideId: widget.id).then((value) async {
      toast(value.message);
      // Misma señal que en la app conductor: el mapa del conductor escucha Firestore.
      rideService.updateStatusOfRide(rideID: widget.id, req: {
        'status': CANCELED,
        'on_stream_api_call': 0,
        'on_rider_stream_api_call': 0,
      });
      // Vuelve al inicio para poder solicitar otro viaje (el stream del ride a veces sigue vivo con estado cancelado).
      launchScreen(getContext, DashBoardScreen(), isNewTask: true);
    }).catchError((error) {
      log(error.toString());
    });
  }

  void _openCancelSheet() {
    showModalBottomSheet(
        context: context,
        isDismissible: false,
        isScrollControlled: true,
        builder: (context) {
          return CancelOrderDialog(
            waitingForDriverOnly: true,
            onCancel: (reason) async {
              Navigator.pop(context);
              appStore.setLoading(true);
              sharedPref.remove(REMAINING_TIME);
              sharedPref.remove(IS_TIME);
              await cancelRequest(reason);
              appStore.setLoading(false);
            },
          );
        });
  }

  void _continueSearchingDrivers() {
    sharedPref.remove(IS_TIME);
    sharedPref.remove(REMAINING_TIME);
    final newEnd = _nowForDeadline().add(Duration(seconds: timerMaxSeconds));
    setState(() {
      _timedOutWaitingDriver = false;
      _timeoutUiScheduled = false;
      d2 = newEnd;
    });
    sharedPref.setString(IS_TIME, DateTime.now().add(Duration(seconds: timerMaxSeconds)).toString());
    sharedPref.setString(REMAINING_TIME, timerMaxSeconds.toString());
    rideRequestUpdate(request: {'max_time_for_find_driver_for_ride_request': timerMaxSeconds}, rideId: widget.id).then((_) {}).catchError((e) => log(e.toString()));
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    if (_timedOutWaitingDriver) {
      return Container(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(language.lookingForNearbyDrivers, style: boldTextStyle(color: neonHighlight))),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: primaryColor, borderRadius: radius(8)),
                  child: Text('--:--', style: boldTextStyle(color: Colors.white)),
                ),
              ],
            ),
            SizedBox(height: 8),
            Lottie.asset(bookingAnim, height: 100, width: MediaQuery.of(context).size.width, fit: BoxFit.contain),
            SizedBox(height: 16),
            Text(language.driverSearchTimeoutMessage, style: primaryTextStyle(color: neonHighlight), textAlign: TextAlign.center),
            SizedBox(height: 20),
            AppButtonWidget(
              width: MediaQuery.of(context).size.width,
              text: language.keepSearchingDrivers,
              color: neonAccent,
              textColor: neonOnAccent,
              shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius)),
              onTap: _continueSearchingDrivers,
            ),
            SizedBox(height: 12),
            AppButtonWidget(
              width: MediaQuery.of(context).size.width,
              text: language.cancel,
              shapeBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(defaultRadius),
                side: BorderSide(color: Colors.white, width: 2),
              ),
              onTap: _openCancelSheet,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.lookingForNearbyDrivers, style: boldTextStyle(color: neonHighlight)),
              if (d2 != null)
                Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: primaryColor, borderRadius: radius(8)),
                    child: StreamBuilder(
                      stream: Stream.periodic(Duration(seconds: 1)),
                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                        final nowRef = _nowForDeadline();
                        final expired = d2 != null && d2!.difference(nowRef).inSeconds <= 0;
                        if (expired) {
                          if (!_timedOutWaitingDriver && !_timeoutUiScheduled) {
                            _timeoutUiScheduled = true;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              setState(() => _timedOutWaitingDriver = true);
                            });
                          }
                          return Text("--:--", style: boldTextStyle(color: Colors.white));
                        }
                        if (d2 == null) return Text("--:--", style: boldTextStyle(color: Colors.white));
                        return Text(
                            (d2!.difference(nowRef).inSeconds / 60).toInt().toString().padLeft(2, "0") +
                                ":" +
                                (d2!.difference(nowRef).inSeconds % 60).toString().padLeft(2, "0").toString(),
                            style: boldTextStyle(color: Colors.white));
                      },
                    ))
            ],
          ),
          SizedBox(height: 8),
          Lottie.asset(bookingAnim, height: 100, width: MediaQuery.of(context).size.width, fit: BoxFit.contain),
          SizedBox(height: 20),
          Text(language.weAreLookingForNearDriversAcceptsYourRide, style: primaryTextStyle(color: zigoOrange), textAlign: TextAlign.center),
          SizedBox(height: 16),
          AppButtonWidget(
            width: MediaQuery.of(context).size.width,
            text: language.cancel,
            shapeBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(defaultRadius),
              side: BorderSide(color: Colors.white, width: 2),
            ),
            onTap: _openCancelSheet,
          )
        ],
      ),
    );
  }
}
