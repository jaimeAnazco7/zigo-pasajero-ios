import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart' as lt;
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../components/SearchLocationComponent.dart';
import '../components/drawer_component.dart';
import '../main.dart';
import '../model/CurrentRequestModel.dart';
import '../model/NearByDriverListModel.dart';
import '../network/RestApis.dart';
import '../screens/ReviewScreen.dart';
import '../screens/RidePaymentDetailScreen.dart';
import '../service/RideService.dart';
import '../service/VersionServices.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/LiveStream.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/app_textfield.dart';
import '../utils/Extensions/context_extension.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import '../utils/images.dart';
import 'BidingScreen.dart';
import 'LocationPermissionScreen.dart';
import 'NewEstimateRideListWidget.dart';
import 'NotificationScreen.dart';
import 'ScheduleRideListScreen.dart';

class DashBoardScreen extends StatefulWidget {
  @override
  DashBoardScreenState createState() => DashBoardScreenState();
  String? cancelReason;

  DashBoardScreen({this.cancelReason});
}

class DashBoardScreenState extends State<DashBoardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  RideService rideService = RideService();
  List<Marker> markers = [];
  Set<Polyline> _polyLines = Set<Polyline>();
  List<LatLng> polylineCoordinates = [];
  late PolylinePoints polylinePoints;
  OnRideRequest? servicesListData;
  double cameraZoom = 17.0, cameraTilt = 0;
  double cameraBearing = 30;
  int onTapIndex = 0;
  int selectIndex = 0;
  late StreamSubscription<ServiceStatus> serviceStatusStream;
  LocationPermission? permissionData;
  late BitmapDescriptor driverIcon;
  List<NearByDriverListModel>? nearDriverModel;
  GoogleMapController? mapController;

  List<OnRideRequest> schedule_ride_request = [];

  static const _cyanStatusBar = SystemUiOverlayStyle(
    statusBarColor: neonAccent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SystemChrome.setSystemUIOverlayStyle(_cyanStatusBar);
    });
    locationPermission();
    if (app_update_check != null) {
      VersionService().getVersionData(context, app_update_check);
    }
    if (widget.cancelReason != null) {
      afterBuildCreated(() {
        _triggerCanceledPopup();
      });
    } else {
      getCurrentRequest();
    }
    afterBuildCreated(() {
      init();
    });
  }

  void init() async {
    getCurrentUserLocation();
    riderIcon = await mapMarkerBitmapFromAsset(SourceIcon, targetWidth: kMapPinMarkerWidth);
    driverIcon = await mapMarkerBitmapFromAsset(
      Platform.isIOS ? DriverIOSIcon : MultipleDriver,
      targetWidth: kMapCarMarkerWidth,
    );
    await getAppSettingsData();

    polylinePoints = PolylinePoints();
  }

  Future<void> getCurrentUserLocation() async {
    if (permissionData != LocationPermission.denied) {
      if (sourceLocation != null) {
        polylineSource = LatLng(sourceLocation!.latitude, sourceLocation!.longitude);
        addMarker();
        startLocationTracking();
        await getNearByDriver();
        return;
      }
      final geoPosition = await Geolocator.getCurrentPosition(timeLimit: Duration(seconds: 30), desiredAccuracy: LocationAccuracy.high).catchError((error) {
        launchScreen(navigatorKey.currentState!.overlay!.context, LocationPermissionScreen());
      });
      sourceLocation = LatLng(geoPosition.latitude, geoPosition.longitude);
      try {
        List<Placemark>? placemarks = await placemarkFromCoordinates(geoPosition.latitude, geoPosition.longitude);
        await getNearByDriver();

        //set Country
        sharedPref.setString(COUNTRY, placemarks[0].isoCountryCode.validate(value: defaultCountry));

        Placemark place = placemarks[0];
        if (place != null) {
          sourceLocationTitle =
              "${place.name != null ? place.name : place.subThoroughfare}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}, ${place.country}";
          polylineSource = LatLng(geoPosition.latitude, geoPosition.longitude);
        }
      } catch (e) {
        throw e;
      }
      addMarker();
      startLocationTracking();

      setState(() {});
    } else {
      launchScreen(navigatorKey.currentState!.overlay!.context, LocationPermissionScreen());
    }
  }

  Future<void> getCurrentRequest() async {
    await getCurrentRideRequest().then((value) async {
      servicesListData = value.rideRequest ?? value.onRideRequest;
      print("CHecking140");
      schedule_ride_request = value.schedule_ride_request ?? [];
      print("CHecking142");
      print("CHecking142::${schedule_ride_request.length}");
      if (servicesListData == null && schedule_ride_request.isNotEmpty) {
        schedule_ride_request.map(
          (e) => e.schedule_datetime,
        );

        var d1 = DateTime.parse(DateTime.now().toUtc().toString().replaceAll("Z", ""));
        var d2 = DateTime.parse(schedule_ride_request.first.schedule_datetime.toString());

        print("CheckBothDate:::D1:::$d1 ===>D2: $d2");
        print("CHecking148");
        print("CHecking148.2");
        if (d1.isAfter(d2)) {
          print("CHecking150::}");
          servicesListData = schedule_ride_request.first;
          print("CHecking161:::${servicesListData!.toJson()}");
        } else {
          scheduleFunction(scheduledTime: d2.add(Duration(seconds: 5)), function: () => getCurrentRequest());
        }
      }
      if (servicesListData == null) {
        sharedPref.remove(REMAINING_TIME);
        sharedPref.remove(IS_TIME);
        setState(() {});
      }
      print("169");
      if (servicesListData != null) {
        print("171");
        if ((value.ride_has_bids == 1) && (servicesListData!.status == NEW_RIDE_REQUESTED || servicesListData!.status == "bid_rejected")) {
          launchScreen(
            context,
            isNewTask: true,
            Bidingscreen(
              dt: servicesListData!.isSchedule == 1 ? servicesListData!.schedule_datetime : servicesListData!.datetime,
              ride_id: servicesListData!.id!,
              source: {},
              endLocation: {},
              multiDropObj: {},
              multiDropLocationNamesObj: {},
            ),
            pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
          );
        } else if (servicesListData!.status != COMPLETED && servicesListData!.status != CANCELED) {
          int x = 0;
          if (value.rideRequest == null && value.onRideRequest == null) {
            x = servicesListData!.id!;
          } else {
            x = value.rideRequest != null ? value.rideRequest!.id! : value.onRideRequest!.id!;
          }
          QuerySnapshot<Object?> b = await rideService.checkIsRideExist(rideId: x);
          if (b.docs.length > 0) {
            //   Check Condition so screen looping issue not occur
            //   if Ride Not exist in firebase than don't navigate to next screen
            launchScreen(
              getContext,
              NewEstimateRideListWidget(
                dt: servicesListData!.isSchedule == 1 ? servicesListData!.schedule_datetime : servicesListData!.datetime,
                sourceLatLog: LatLng(double.parse(servicesListData!.startLatitude!), double.parse(servicesListData!.startLongitude!)),
                destinationLatLog: LatLng(double.parse(servicesListData!.endLatitude!), double.parse(servicesListData!.endLongitude!)),
                sourceTitle: servicesListData!.startAddress!,
                destinationTitle: servicesListData!.endAddress!,
                isCurrentRequest: true,
                servicesId: servicesListData!.serviceId,
                id: servicesListData!.id,
              ),
              pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
            );
          } else {
            if (value.schedule_ride_request != null && value.schedule_ride_request!.isNotEmpty) {
              if (value.schedule_ride_request!.first.id == x) {
                return;
              }
            }
            return toast(rideNotFound);
          }
        } else if (servicesListData!.status == COMPLETED && servicesListData!.isRiderRated == 0) {
          Future.delayed(
            Duration(seconds: 1),
            () {
              launchScreen(getContext, ReviewScreen(rideRequest: servicesListData!, driverData: value.driver), pageRouteAnimation: PageRouteAnimation.SlideBottomTop, isNewTask: true);
            },
          );
        }
        // Si sigue buscando conductor y ya pasó el tiempo configurado, refrescar mapa con radio ampliado
        if (servicesListData!.status == NEW_RIDE_REQUESTED && sourceLocation != null) {
          final createdAt = servicesListData!.createdAt != null ? DateTime.tryParse(servicesListData!.createdAt!) : null;
          final maxMin = appStore.rideMinutes != null ? (int.tryParse(appStore.rideMinutes!) ?? 5) : 5;
          final expandThreshold = (maxMin * 3) ~/ 5;
          if (createdAt != null && DateTime.now().difference(createdAt).inMinutes >= expandThreshold) {
            getNearByDriver(useExpandedRadius: true);
          }
        }
      } else if (value.payment != null && value.payment!.paymentStatus != "paid") {
        print("222");
        launchScreen(getContext, RidePaymentDetailScreen(rideId: value.payment!.rideRequestId), pageRouteAnimation: PageRouteAnimation.SlideBottomTop, isNewTask: true);
      }
    }).catchError((error, s) {
      log(error.toString() + "::$s");
      print("CHecking200:::$error ===$s");
    });
  }

  Future<void> locationPermission() async {
    serviceStatusStream = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      if (status == ServiceStatus.disabled) {
        launchScreen(navigatorKey.currentState!.overlay!.context, LocationPermissionScreen());
      } else if (status == ServiceStatus.enabled) {
        getCurrentUserLocation();
        if (locationScreenKey.currentContext != null) {
          if (Navigator.canPop(navigatorKey.currentState!.overlay!.context)) {
            Navigator.pop(navigatorKey.currentState!.overlay!.context);
          }
        }
      }
    }, onError: (error) {
      //
    });
  }

  addMarker() {
    markers.add(
      Marker(
        markerId: MarkerId('Order Detail'),
        position: sourceLocation!,
        draggable: true,
        infoWindow: InfoWindow(title: sourceLocationTitle, snippet: ''),
        icon: riderIcon,
      ),
    );
  }

  Future<void> startLocationTracking() async {
    Map req = {
      "latitude": sourceLocation!.latitude.toString(),
      "longitude": sourceLocation!.longitude.toString(),
    };
    await updateStatus(req).then((value) {}).catchError((error) {
      log(error);
    });
  }

  Future<BitmapDescriptor> getNetworkImageMarker(String imageUrl) async {
    final http.Response response = await http.get(Uri.parse(resolveApiMediaUrl(imageUrl)));
    return mapMarkerBitmapFromBytes(response.bodyBytes, targetWidth: kMapCarMarkerWidth);
  }

  Future<void> getNearByDriver({bool useExpandedRadius = false}) async {
    markers.removeWhere((m) => m.markerId.value.startsWith('Driver'));
    await getNearByDriverList(latLng: sourceLocation, useExpandedRadius: useExpandedRadius).then((value) async {
      value.data!.forEach((element) async {
        print("CHECKIMAGE:::${element}");
        try {
          var driverIcon1 = await getNetworkImageMarker(element.service_marker.validate());
          markers.add(
            Marker(
              markerId: MarkerId('Driver${element.id}'),
              position: LatLng(double.parse(element.latitude!.toString()), double.parse(element.longitude!.toString())),
              infoWindow: InfoWindow(title: '${element.firstName} ${element.lastName}', snippet: ''),
              icon: driverIcon1,
            ),
          );
          setState(() {});
        } catch (e, s) {
          markers.add(
            Marker(
              markerId: MarkerId('Driver${element.id}'),
              position: LatLng(double.parse(element.latitude!.toString()), double.parse(element.longitude!.toString())),
              infoWindow: InfoWindow(title: '${element.firstName} ${element.lastName}', snippet: ''),
              icon: driverIcon,
            ),
          );
          setState(() {});
        }
      });
    }).catchError((e, s) {
      print("ERROR  FOUND:::$e ++++>$s");
    });
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    LiveStream().on(CHANGE_LANGUAGE, (p0) {
      setState(() {});
    });
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final panelCollapsedHeight = 160.0 + bottomInset;
    final panelMaxHeight = (MediaQuery.sizeOf(context).height * 0.65).clamp(panelCollapsedHeight + 80.0, 900.0).toDouble();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _cyanStatusBar,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: _cyanStatusBar,
          toolbarHeight: 0,
        ),
      resizeToAvoidBottomInset: false,
      key: _scaffoldKey,
      drawer: DrawerComponent(),
      body: Stack(
        children: [
          if (sharedPref.getDouble(LATITUDE) != null && sharedPref.getDouble(LONGITUDE) != null)
            GoogleMap(
              onMapCreated: (controller) {
                mapController = controller;
              },
              padding: EdgeInsets.only(top: context.statusBarHeight + 4 + 24),
              compassEnabled: true,
              myLocationButtonEnabled: false,
              myLocationEnabled: true,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              mapType: MapType.normal,
              markers: markers.map((e) => e).toSet(),
              polylines: _polyLines,
              initialCameraPosition: CameraPosition(
                target: sourceLocation ?? LatLng(sharedPref.getDouble(LATITUDE)!, sharedPref.getDouble(LONGITUDE)!),
                zoom: cameraZoom,
                tilt: cameraTilt,
                bearing: cameraBearing,
              ),
            ),
          Positioned(
            top: context.statusBarHeight + 4,
            right: 14,
            left: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                topWidget(),
                SizedBox(
                  height: 8,
                ),
                inkWellWidget(
                  onTap: () async {
                    final geoPosition = await Geolocator.getCurrentPosition(timeLimit: Duration(seconds: 30), desiredAccuracy: LocationAccuracy.high).catchError((error) {
                      launchScreen(navigatorKey.currentState!.overlay!.context, LocationPermissionScreen());
                    });
                    mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(geoPosition.latitude, geoPosition.longitude)));
                  },
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1),
                      ],
                      borderRadius: BorderRadius.circular(defaultRadius),
                    ),
                    child: Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          SlidingUpPanel(
            color: neonBackground,
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(defaultRadius), topRight: Radius.circular(defaultRadius)),
            backdropTapClosesPanel: true,
            minHeight: panelCollapsedHeight,
            maxHeight: panelMaxHeight,
            panel: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    alignment: Alignment.center,
                    margin: EdgeInsets.only(bottom: 12),
                    height: 5,
                    width: 70,
                    decoration: BoxDecoration(color: neonAccent, borderRadius: BorderRadius.circular(defaultRadius)),
                  ),
                ),
                Text(language.whatWouldYouLikeToGo.capitalizeFirstLetter(), style: primaryTextStyle(color: Colors.white)),
                SizedBox(height: 12),
                AppTextField(
                  autoFocus: false,
                  readOnly: true,
                  onTap: () async {
                    showModalBottomSheet(
                      isScrollControlled: true,
                      backgroundColor: neonBackground,
                      barrierColor: Colors.black54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(defaultRadius), topRight: Radius.circular(defaultRadius)),
                        side: BorderSide(color: neonAccent.withOpacity(0.35), width: 1),
                      ),
                      context: context,
                      builder: (_) {
                        return SearchLocationComponent(title: sourceLocationTitle);
                      },
                    );
                  },
                  textFieldType: TextFieldType.EMAIL,
                  keyboardType: TextInputType.emailAddress,
                  cursorColor: neonAccent,
                  textStyle: primaryTextStyle(color: Colors.white),
                  decoration: _destinationSearchFieldDecoration(),
                ),
                SizedBox(height: 12),
              ],
            ),
          ),
          Visibility(
            visible: appStore.isLoading,
            child: loaderWidget(),
          ),
          if (appStore.isScheduleRide == "1" && schedule_ride_request.isNotEmpty)
            Positioned(
              bottom: panelCollapsedHeight + 16,
              right: 16,
              child: InkWell(
                onTap: () {
                  launchScreen(context, ScheduleRideListScreen());
                },
                child: Container(
                    height: 56,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 2, spreadRadius: 1)]),
                    child: Row(
                      children: [
                        lt.Lottie.asset(
                          taxiAnim,
                          height: 30,
                          width: 30,
                          fit: BoxFit.cover,
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Text(
                          "Your Scheduled Rides" /*language.schedule_list_title*/,
                          style: primaryTextStyle(size: 12),
                        )
                      ],
                    )),
              ),
            ),
          Observer(builder: (context) => Visibility(visible: appStore.isLoading, child: Positioned.fill(child: loaderWidget()))),
        ],
      ),
    ),
    );
  }

  InputDecoration _destinationSearchFieldDecoration() {
    final subtle = neonAccent.withOpacity(0.45);
    return InputDecoration(
      focusColor: neonAccent,
      prefixIcon: Icon(Feather.search, color: neonAccent.withOpacity(0.9)),
      filled: true,
      fillColor: neonSurfaceCard.withOpacity(0.55),
      isDense: true,
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color: neonError)),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color: subtle.withOpacity(0.35))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color: neonAccent, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color: subtle)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color: neonError)),
      alignLabelWithHint: true,
      hintText: language.enterYourDestination,
      hintStyle: primaryTextStyle(color: neonHighlight.withOpacity(0.78)),
    );
  }

  Widget topWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        inkWellWidget(
          onTap: () {
            _scaffoldKey.currentState!.openDrawer();
          },
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Color(0xFF3D3D3D),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1),
              ],
              borderRadius: BorderRadius.circular(defaultRadius),
            ),
            child: Icon(Icons.drag_handle, color: neonAccent),
          ),
        ),
        inkWellWidget(
          onTap: () async {
            launchScreen(context, NotificationScreen(), pageRouteAnimation: PageRouteAnimation.Slide);
          },
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1),
              ],
              borderRadius: BorderRadius.circular(defaultRadius),
            ),
            child: Icon(Ionicons.notifications_outline),
          ),
        ),
      ],
    );
  }

  void _triggerCanceledPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: Text(
                "${language.rideCanceledByDriver}",
                maxLines: 2,
                style: boldTextStyle(),
              )),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(Icons.clear),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${language.cancelledReason}",
                style: secondaryTextStyle(),
              ),
              Text(
                widget.cancelReason.validate(),
                style: primaryTextStyle(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> cancelRequest(String reason, {int? ride_id}) async {
    Map req = {
      "id": ride_id,
      "cancel_by": RIDER,
      "status": CANCELED,
      "reason": reason,
    };
    await rideRequestUpdate(request: req, rideId: ride_id).then((value) async {
      getCurrentRequest();
      toast(value.message);
    }).catchError((error) {});
  }
}
