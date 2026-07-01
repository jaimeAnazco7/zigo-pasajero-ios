import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:taxi_booking/utils/Extensions/context_extension.dart';

import '../../main.dart';
import '../../model/CurrentRequestModel.dart';
import '../../model/OrderHistory.dart';
import '../../model/RiderModel.dart';
import '../../network/RestApis.dart';
import '../../screens/RideHistoryScreen.dart';
import '../../utils/Colors.dart';
import '../../utils/Constants.dart';
import '../../utils/Extensions/AppButtonWidget.dart';
import '../components/RideAcceptWidget.dart';
import '../model/FRideBookingModel.dart';
import '../service/RideService.dart';
import '../utils/Common.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import '../utils/images.dart';
import 'DashBoardScreen.dart';
import 'PaymentScreen.dart';

class RidePaymentDetailScreen extends StatefulWidget {
  final int? rideId;

  //
  RidePaymentDetailScreen({this.rideId});

  @override
  RidePaymentDetailScreenState createState() => RidePaymentDetailScreenState();
}

class RidePaymentDetailScreenState extends State<RidePaymentDetailScreen> {
  List<RideHistory> rideHistory = [];
  RideService rideService = RideService();
  CurrentRequestModel? currentData;
  bool isCashPayment = true;
  bool isShow = false;
  bool currentScreen = true;
  bool navigateDone = false;
  RiderModel? riderModel;
  Payment? paymentData;
  bool isPaymentDone = false;
  bool paymentPressed = false;
  num? balance;
  num? requiredAmount;
  num? payableAmount;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    getCurrentRide();
  }

  getCurrentRide() async {
    Future.delayed(
      Duration.zero,
      () {
        appStore.setLoading(true);
        getCurrentRideRequest().then((value) async {
          appStore.setLoading(false);
          currentData = value;
          await orderDetailApi();
          setState(() {});
        }).catchError((error) {
          appStore.setLoading(false);
          log(error.toString());
        });
      },
    );
  }

  Future<void> savePaymentApi() async {
    if (paymentPressed == true) return;
    paymentPressed = true;
    appStore.setLoading(true);
    Map req = {
      "id": currentData!.payment!.id,
      "rider_id": currentData!.payment!.riderId,
      "ride_request_id": currentData!.payment!.rideRequestId,
      "datetime": DateTime.now().toString(),
      "total_amount": riderModel!.totalAmount,
      "payment_type": WALLET,
      "txn_id": "",
      "payment_status": PAID,
      "transaction_detail": ""
    };
    await savePayment(req).then((value) async {
      appStore.setLoading(false);
      await rideService.updateStatusOfRide(rideID: currentData!.payment!.rideRequestId, req: {
        "on_stream_api_call": 0, /*"payment_status": PAID*/
      });
      orderDetailApi();
      paymentPressed = false;
    }).catchError((error) {
      paymentPressed = false;
      isShow = true;
      setState(() {});
      appStore.setLoading(false);
      log(error.toString());
      toast(error.toString());
      getWalletList(page: 1).then((value) {
        appStore.setLoading(false);
        if (value.walletBalance != null) balance = value.walletBalance!.totalAmount!;
        payableAmount = currentData!.payment!.totalAmount!;
        requiredAmount = payableAmount! - balance!;
        requiredAmount = requiredAmount! + 1;
        setState(() {});
      }).catchError((error) {
        appStore.setLoading(false);
        log(error.toString());
      });
    });
  }

  Future<void> rideRequest() async {
    appStore.setLoading(true);
    Map req = {
      "payment_type": isCashPayment ? CASH : WALLET,
      "is_change_payment_type": 1,
    };
    log(req);
    await rideRequestUpdate(request: req, rideId: currentData!.payment!.rideRequestId).then((value) async {
      await rideService.updateStatusOfRide(rideID: currentData!.payment!.rideRequestId, req: {
        /*"tips": 1,*/ "on_stream_api_call": 0,
        "payment_type": isCashPayment ? CASH : WALLET,
      });
      appStore.setLoading(false);
      init();
    }).catchError((error) {
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  Future<void> orderDetailApi() async {
    // appStore.setLoading(true);
    await rideDetail(orderId: widget.rideId).then((value) {
      riderModel = value.data;
      if (value.ride_has_bids != null) {
        riderModel!.ride_has_bids = value.ride_has_bids;
      }
      if (value.payment != null) {
        currentData!.payment = value.payment;
        paymentData = value.payment;
      }
      rideHistory = value.rideHistory!;
      setState(() {});
      if (paymentData != null && paymentData!.paymentStatus == "paid") {
        isPaymentDone = true;
        if (navigateDone == true) return;
        navigateDone = true;
        Future.delayed(
          Duration(seconds: 3),
          () {
            launchScreen(getContext, DashBoardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
            isPaymentDone = false;
          },
        );
      }
    }).catchError((error, s) {
      print("CheckError:::$error ::::$s");
      toast(error.toString());
      appStore.setLoading(false);
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  BoxDecoration _neonCardDec() => BoxDecoration(
        color: neonSurfaceCard,
        borderRadius: radius(),
        border: Border.all(color: neonAccent.withOpacity(0.35)),
      );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: neonBackground,
      appBar: AppBar(
        centerTitle: true,
        title: Text(language.detailScreen, style: boldTextStyle(color: Colors.white)),
      ),
      body: StreamBuilder(
          stream: rideService.fetchRide(rideId: widget.rideId),
          builder: (context, snap) {
            if (snap.hasData) {
              List<FRideBookingModel> data = [];
              try {
                data = snap.data!.docs.map((e) => FRideBookingModel.fromJson(e.data() as Map<String, dynamic>)).toList();
              } catch (e) {
                data = [];
              }
              if (data.length == 0) {
                Future.delayed(
                  Duration(seconds: 2),
                  () {
                    if (currentScreen == false) return;
                    currentScreen = false;
                    orderDetailApi();
                  },
                );
              }
              if (data.isNotEmpty && data[0].paymentStatus.toString() == PAID && data[0].status.toString() == COMPLETED) {
                // isPaymentDone = true;
                Future.delayed(
                  Duration(seconds: 1),
                  () {
                    isPaymentDone = false;
                    if (currentScreen == false) return;
                    currentScreen = false;
                    orderDetailApi();
                  },
                );
              }

              return Stack(
                children: [
                  currentData != null
                      ? SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              addressComponent(),
                              SizedBox(height: 12),
                              paymentDetailWidget(),
                              SizedBox(height: 12),
                              priceDetailWidget(),
                              SizedBox(height: 12),
                              if (currentData!.payment != null && currentData!.payment!.paymentStatus != COMPLETED && isShow)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(language.payment, style: boldTextStyle(color: Colors.white)),
                                    SizedBox(height: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                          color: neonSurfaceCard,
                                          border: Border.all(color: neonAccent.withOpacity(0.4)),
                                          borderRadius: BorderRadius.circular(14)),
                                      padding: EdgeInsets.all(6),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: inkWellWidget(
                                                onTap: () {
                                                  isCashPayment = true;
                                                  setState(() {});
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      color: isCashPayment ? primaryColor : null,
                                                      boxShadow: isCashPayment ? [BoxShadow(color: Colors.grey.shade400, spreadRadius: 1, blurRadius: 1)] : [],
                                                      borderRadius: BorderRadius.circular(12)),
                                                  padding: EdgeInsets.all(12),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      ImageIcon(AssetImage(icCash), size: 20, color: isCashPayment ? neonOnAccent : neonHighlight.withOpacity(0.5)),
                                                      SizedBox(
                                                        width: 8,
                                                      ),
                                                      Text(
                                                        language.cash,
                                                        style: boldTextStyle(color: isCashPayment ? neonOnAccent : neonHighlight.withOpacity(0.65)),
                                                      ),
                                                    ],
                                                  ),
                                                )),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: inkWellWidget(
                                                onTap: () {
                                                  isCashPayment = false;
                                                  setState(() {});
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      color: isCashPayment == false ? primaryColor : null,
                                                      boxShadow: isCashPayment == false ? [BoxShadow(color: Colors.grey.shade400, spreadRadius: 1, blurRadius: 1)] : [],
                                                      borderRadius: BorderRadius.circular(12)),
                                                  padding: EdgeInsets.all(12),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      ImageIcon(AssetImage(icCard), size: 20, color: isCashPayment == false ? neonOnAccent : neonHighlight.withOpacity(0.5)),
                                                      SizedBox(
                                                        width: 8,
                                                      ),
                                                      Text(
                                                        language.addMoney,
                                                        style: boldTextStyle(color: isCashPayment == false ? neonOnAccent : neonHighlight.withOpacity(0.65)),
                                                      ),
                                                    ],
                                                  ),
                                                )),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text("${language.note} ", style: secondaryTextStyle(color: neonError, size: 14, weight: FontWeight.bold)),
                                        Expanded(
                                            child: Text(
                                          isCashPayment
                                              ? "${riderModel!.tips != null && payableAmount != null ? riderModel!.tips! + payableAmount! : payableAmount}${appStore.currencyCode} - ${language.fullCashPayment}"
                                              : "+$requiredAmount${appStore.currencyCode} ${language.moreMoneyForWalletPayment}",
                                          style: secondaryTextStyle(color: neonError, size: 12, weight: FontWeight.bold),
                                          maxLines: 1,
                                        )),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    AppButtonWidget(
                                      width: context.width(),
                                      text: isCashPayment == true ? language.updatePaymentStatus : language.continueD,
                                      textStyle: boldTextStyle(color: neonOnAccent),
                                      color: primaryColor,
                                      onTap: () async {
                                        if (isCashPayment == false) {
                                          appStore.setLoading(true);
                                          bool res = await launchScreen(context, PaymentScreen(amount: requiredAmount), pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                                          if (res == true) {
                                            await getWalletList(page: 1).then((value) {
                                              appStore.setLoading(false);
                                              if (value.walletBalance != null) balance = value.walletBalance!.totalAmount!;
                                              payableAmount = currentData!.payment!.totalAmount!;
                                              requiredAmount = payableAmount! - balance!;
                                              requiredAmount = requiredAmount! + 1;
                                              setState(() {});
                                              isShow = false;
                                              rideRequest();
                                            }).catchError((error) {
                                              appStore.setLoading(false);
                                              log(error.toString());
                                            });
                                          } else {
                                            toast("Add MONEY");
                                          }
                                        } else {
                                          isShow = false;
                                          rideRequest();
                                        }
                                      },
                                    )
                                  ],
                                ),
                              SizedBox(height: 8),
                              // if (currentData!.payment != null && data.length>0 && data[0].paymentStatus.toString() != PAID )
                            ],
                          ),
                        )
                      : Observer(builder: (context) {
                          return Visibility(
                            visible: appStore.isLoading,
                            child: loaderWidget(),
                          );
                        }),
                  Visibility(
                      visible: isPaymentDone,
                      child: Center(
                        child: Container(
                            // width: 250,
                            //     height: 200,
                            width: context.width(),
                            margin: EdgeInsets.symmetric(horizontal: 40),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: neonSurfaceCard,
                              borderRadius: BorderRadius.circular(defaultRadius),
                              border: Border.all(color: neonAccent.withOpacity(0.45)),
                              boxShadow: [
                                BoxShadow(color: neonAccent.withOpacity(0.25), blurRadius: 16, spreadRadius: 0, offset: Offset(0.0, 4.0)),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Lottie.asset(paymentSuccessful, width: 120, height: 120, fit: BoxFit.contain),
                                Text(
                                  "${language.paymentSuccess}",
                                  style: boldTextStyle(color: neonAccent, size: 24),
                                )
                              ],
                            )),
                      )),
                  Observer(builder: (context) {
                    return Visibility(
                      visible: appStore.isLoading,
                      child: loaderWidget(),
                    );
                  })
                ],
              );
            } else {
              return SizedBox();
            }
          }),
      bottomNavigationBar: currentData != null && currentData!.payment != null && isShow == false
          ? SafeScaffoldBottomBar(
              child: Container(
                width: context.width(),
                color: neonBackground,
                padding: EdgeInsets.all(16),
                child: AppButtonWidget(
                  text: getButtonText(),
                  textStyle: boldTextStyle(color: neonOnAccent),
                  width: MediaQuery.of(context).size.width,
                  onTap: () {
                    if (currentData!.payment!.paymentStatus == COMPLETED) {
                      orderDetailApi();
                    } else if (currentData!.payment!.paymentStatus != COMPLETED && currentData!.payment!.paymentType == CASH) {
                      toast(language.waitingForDriverConformation);
                    } else if (currentData!.payment!.paymentStatus != COMPLETED && currentData!.payment!.paymentType == WALLET) {
                      savePaymentApi();
                    }
                  },
                ),
              ),
            )
          : SizedBox(),
    );
  }

  String? getButtonText() {
    if (currentData!.payment!.paymentStatus == COMPLETED) {
      return language.continueNewRide;
    } else if (currentData!.payment!.paymentStatus != COMPLETED && currentData!.payment!.paymentType == CASH) {
      return language.waitingForDriverConformation;
    } else if (currentData!.payment!.paymentStatus != COMPLETED && currentData!.payment!.paymentType == WALLET) {
      return language.payToPayment;
    }
    return '';
  }

  Widget addressComponent() {
    if (riderModel == null) {
      return SizedBox();
    }
    return Container(
      decoration: _neonCardDec(),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Ionicons.calendar, color: neonAccent, size: 16),
                  SizedBox(width: 4),
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text('${printDate(riderModel!.createdAt.validate())}', style: primaryTextStyle(size: 14, color: Colors.white)),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(language.rideId, style: boldTextStyle(size: 16, color: neonHighlight)),
                  SizedBox(width: 8),
                  Text('#${riderModel!.id}', style: boldTextStyle(size: 16, color: Colors.white)),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Text('${language.lblDistance} ${riderModel!.distance!.toStringAsFixed(2)} ${riderModel!.distanceUnit.toString()}',
              style: boldTextStyle(size: 14, color: Colors.white)),
          SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.near_me, color: neonAccent, size: 18),
                  SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (riderModel!.startTime != null)
                          Text(riderModel!.startTime != null ? printDate(riderModel!.startTime!) : '',
                              style: secondaryTextStyle(size: 12, color: neonHighlight)),
                        if (riderModel!.startTime != null) SizedBox(height: 4),
                        Text(riderModel!.startAddress.validate(), style: primaryTextStyle(size: 14, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(width: 10),
                  SizedBox(
                    height: 30,
                    child: DottedLine(
                      direction: Axis.vertical,
                      lineLength: double.infinity,
                      lineThickness: 1,
                      dashLength: 2,
                      dashColor: neonAccent.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.location_on, color: neonError, size: 18),
                  SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (riderModel!.endTime != null)
                          Text(riderModel!.endTime != null ? printDate(riderModel!.endTime!) : '', style: secondaryTextStyle(size: 12, color: neonHighlight)),
                        if (riderModel!.endTime != null) SizedBox(height: 4),
                        Text(riderModel!.endAddress.validate(), style: primaryTextStyle(size: 14, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
              if (riderModel!.multiDropLocation != null && riderModel!.multiDropLocation!.isNotEmpty)
                Row(
                  children: [
                    SizedBox(width: 8),
                    SizedBox(
                      height: 24,
                      child: DottedLine(
                        direction: Axis.vertical,
                        lineLength: double.infinity,
                        lineThickness: 1,
                        dashLength: 2,
                        dashColor: neonAccent.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              if (riderModel!.multiDropLocation != null && riderModel!.multiDropLocation!.isNotEmpty)
                AppButtonWidget(
                  textColor: neonAccent,
                  color: neonSurfaceCard,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  height: 30,
                  shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius), side: BorderSide(color: neonAccent.withOpacity(0.8))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: neonAccent, size: 12),
                      Text(language.viewMore, style: primaryTextStyle(size: 14, color: neonAccent)),
                    ],
                  ),
                  onTap: () {
                    showOnlyDropLocationsDialog(
                        context,
                        riderModel!.multiDropLocation!
                            .map(
                              (e) => e.address,
                            )
                            .toList());
                  },
                )
            ],
          ),
          SizedBox(height: 12),
          inkWellWidget(
            onTap: () {
              launchScreen(context, RideHistoryScreen(rideHistory: rideHistory), pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(language.viewHistory, style: secondaryTextStyle(color: neonHighlight)),
                Icon(Entypo.chevron_right, color: neonAccent, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget paymentDetailWidget() {
    if (riderModel == null) {
      return SizedBox();
    }
    return Container(
      decoration: _neonCardDec(),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(language.paymentDetails, style: boldTextStyle(size: 16, color: Colors.white)),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.via, style: secondaryTextStyle(color: neonHighlight)),
              Text(paymentStatus(riderModel!.paymentType.validate()), style: boldTextStyle(color: Colors.white)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.status, style: secondaryTextStyle(color: neonHighlight)),
              Text(paymentStatus(riderModel!.paymentStatus.validate()),
                  style: boldTextStyle(color: paymentStatusColorNeon(riderModel!.paymentStatus.validate()))),
            ],
          ),
        ],
      ),
    );
  }

  Widget priceDetailWidget() {
    if (riderModel == null) {
      return SizedBox();
    }
    // print("CHeck Minimum FareAMount::${riderModel!.minimumFare}");
    return Container(
      decoration: _neonCardDec(),
      padding: EdgeInsets.all(16),
      child: riderModel!.ride_has_bids == 1
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language.priceDetail, style: boldTextStyle(size: 16, color: Colors.white)),
                SizedBox(height: 12),
                totalCount(
                    title: language.amount,
                    amount:
                        // riderModel!.surgeCharge != null && riderModel!.surgeCharge! > 0?
                        // riderModel!.subtotal!-riderModel!.surgeCharge!:riderModel!.subtotal!
                        riderModel!.totalAmount,
                    space: 8,
                    styleNeon: true),
                if (riderModel!.couponData != null && riderModel!.couponDiscount != 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(language.couponDiscount, style: secondaryTextStyle(color: neonHighlight)),
                      Row(
                        children: [
                          Text("-", style: boldTextStyle(color: neonAccent, size: 14)),
                          printAmountWidget(
                              amount: '${riderModel!.couponDiscount!.toStringAsFixed(digitAfterDecimal)}', color: neonAccent, size: 14, weight: FontWeight.normal)
                        ],
                      ),
                    ],
                  ),
                if (riderModel!.couponData != null && riderModel!.couponDiscount != 0) SizedBox(height: 8),
                if (riderModel!.tips != null) totalCount(title: language.tip, amount: riderModel!.tips, styleNeon: true),
                // if(riderModel!.surgeCharge != 0)
                //   SizedBox(height: 8,),
                // if (riderModel!.surgeCharge != null && riderModel!.surgeCharge! > 0) totalCount(title: language.fixedPrice, amount: riderModel!.surgeCharge, space: 0),
                if (riderModel!.extraCharges!.isNotEmpty)
                  SizedBox(
                    height: 8,
                  ),
                if (riderModel!.extraCharges!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(language.additionalFees, style: boldTextStyle(color: Colors.white)),
                      ...riderModel!.extraCharges!.map((e) {
                        return Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key.validate().capitalizeFirstLetter(), style: secondaryTextStyle(color: neonHighlight)),
                              printAmountWidget(amount: e.value!.toStringAsFixed(digitAfterDecimal), size: 14, color: Colors.white)
                            ],
                          ),
                        );
                      }).toList()
                    ],
                  ),

                // if (riderModel!.tips != null || riderModel!.extraCharges!.isNotEmpty)
                Divider(height: 16, thickness: 1, color: neonAccent.withOpacity(0.25)),

                riderModel!.tips != null
                    ? totalCount(title: language.total, amount: riderModel!.totalAmount! + riderModel!.tips!, isTotal: true, styleNeon: true)
                    : totalCount(title: language.total, amount: riderModel!.totalAmount, isTotal: true, styleNeon: true),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language.priceDetail, style: boldTextStyle(size: 16, color: Colors.white)),
                SizedBox(height: 12),
                riderModel!.subtotal! <= riderModel!.minimumFare!
                    ? totalCount(title: language.minimumFare, amount: riderModel!.minimumFare, styleNeon: true)
                    : Column(
                        children: [
                          totalCount(title: language.basePrice, amount: riderModel!.baseFare, space: 8, styleNeon: true),
                          totalCount(title: language.distancePrice, amount: riderModel!.perDistanceCharge, space: 8, styleNeon: true),
                          totalCount(
                              title: language.minutePrice,
                              amount: riderModel!.perMinuteDriveCharge,
                              space: riderModel!.perMinuteWaitingCharge != 0
                                  ? 8
                                  : riderModel!.surgeCharge != 0
                                      ? 8
                                      : 0,
                              styleNeon: true),
                          totalCount(
                              title: language.waitingTimePrice,
                              amount: riderModel!.perMinuteWaitingCharge,
                              space: riderModel!.surgeCharge != 0 ? 8 : 0,
                              styleNeon: true),
                        ],
                      ),
                if (riderModel!.surgeCharge != null && riderModel!.surgeCharge! > 0)
                  totalCount(title: language.fixedPrice, amount: riderModel!.surgeCharge, space: 0, styleNeon: true),
                SizedBox(height: 8),
                if (riderModel!.couponData != null && riderModel!.couponDiscount != 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(language.couponDiscount, style: secondaryTextStyle(color: neonHighlight)),
                      Row(
                        children: [
                          Text("-", style: boldTextStyle(color: neonAccent, size: 14)),
                          printAmountWidget(
                              amount: '${riderModel!.couponDiscount!.toStringAsFixed(digitAfterDecimal)}', color: neonAccent, size: 14, weight: FontWeight.normal)
                        ],
                      ),
                    ],
                  ),
                if (riderModel!.couponData != null && riderModel!.couponDiscount != 0) SizedBox(height: 8),
                if (riderModel!.tips != null) totalCount(title: language.tip, amount: riderModel!.tips, styleNeon: true),
                if (riderModel!.tips != null) SizedBox(height: 8),
                if (riderModel!.extraCharges!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(language.additionalFees, style: boldTextStyle(color: Colors.white)),
                      SizedBox(height: 8),
                      ...riderModel!.extraCharges!.map((e) {
                        return Padding(
                          padding: EdgeInsets.only(top: 4, bottom: 4),
                          child: totalCount(title: e.key.validate(), amount: e.value, styleNeon: true),
                        );
                      }).toList()
                    ],
                  ),
                Divider(height: 16, thickness: 1, color: neonAccent.withOpacity(0.25)),
                riderModel!.tips != null
                    ? totalCount(title: language.total, amount: riderModel!.totalAmount! + riderModel!.tips!, isTotal: true, styleNeon: true)
                    : totalCount(title: language.total, amount: riderModel!.totalAmount, isTotal: true, styleNeon: true),
              ],
            ),
    );
  }
}
