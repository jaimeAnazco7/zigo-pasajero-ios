import 'package:flutter/material.dart';

import '../main.dart';
import '../model/EstimatePriceModel.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';

class CarDetailWidget extends StatefulWidget {
  final ServicesListData service;

  CarDetailWidget({required this.service});

  @override
  CarDetailWidgetState createState() => CarDetailWidgetState();
}

class CarDetailWidgetState extends State<CarDetailWidget> {
  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              alignment: Alignment.center,
              height: 5,
              width: 70,
              decoration: BoxDecoration(color: neonAccent, borderRadius: BorderRadius.circular(defaultRadius)),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                commonCachedNetworkImage(widget.service.serviceImage, height: 100, width: 200, fit: BoxFit.contain, alignment: Alignment.center),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text(widget.service.name.validate(), style: boldTextStyle(color: Colors.white)),
          SizedBox(height: 8),
          Text('${language.get} ${widget.service.name} ${language.rides}', style: secondaryTextStyle(color: neonHighlight.withOpacity(0.88))),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${language.tripDistance}", style: primaryTextStyle(color: neonHighlight.withOpacity(0.9))),
              Text('${widget.service.dropoffDistanceInKm!.toInt() == 0 ? widget.service.distance! : widget.service.dropoffDistanceInKm!} ${widget.service.distanceUnit}',
                  style: primaryTextStyle(color: Colors.white)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.capacity, style: primaryTextStyle(color: neonHighlight.withOpacity(0.9))),
              Text('${widget.service.capacity} ${language.people}', style: primaryTextStyle(color: Colors.white)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.baseFare, style: primaryTextStyle(color: neonHighlight.withOpacity(0.9))),
              printAmountWidget(
                  amount: '${widget.service.baseFare!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal, color: neonAccent),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.minimumFare, style: primaryTextStyle(color: neonHighlight.withOpacity(0.9))),
              printAmountWidget(
                  amount: '${widget.service.minimumFare!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal, color: neonAccent),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.perDistance, style: primaryTextStyle(color: neonHighlight.withOpacity(0.9))),
              printAmountWidget(
                  amount: '${widget.service.perDistance!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal, color: neonAccent),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.perMinDrive, style: primaryTextStyle(color: neonHighlight.withOpacity(0.9))),
              printAmountWidget(
                  amount: '${widget.service.perMinuteDrive!.toStringAsFixed(digitAfterDecimal)}/${language.min}', weight: FontWeight.normal, color: neonAccent),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.perMinWait, style: primaryTextStyle(color: neonHighlight.withOpacity(0.9))),
              printAmountWidget(
                  amount: '${widget.service.perMinuteWait!.toStringAsFixed(digitAfterDecimal)}/${language.min}', weight: FontWeight.normal, color: neonAccent),
            ],
          ),
          if (widget.service.fixed_charge != null && widget.service.fixed_charge! > 0) SizedBox(height: 8),
          if (widget.service.fixed_charge != null && widget.service.fixed_charge! > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(language.fixedPrice, style: primaryTextStyle(color: neonHighlight.withOpacity(0.9))),
                printAmountWidget(amount: '${widget.service.fixed_charge!.toStringAsFixed(digitAfterDecimal)}', weight: FontWeight.normal, color: neonAccent)
              ],
            ),
          SizedBox(height: 8),
          Text(widget.service.description.validate(), style: secondaryTextStyle(color: neonHighlight.withOpacity(0.82)), textAlign: TextAlign.justify),
          AppButtonWidget(
            text: language.close,
            width: MediaQuery.of(context).size.width,
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
