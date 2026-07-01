import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../main.dart';
import '../model/LoginResponse.dart';
import '../network/RestApis.dart';
import '../screens/ChatScreen.dart';
import '../screens/RideDetailScreen.dart';
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/images.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import 'Extensions/Loader.dart';
import 'Extensions/app_common.dart';

Widget dotIndicator(list, i) {
  return SizedBox(
    height: 16,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        list.length,
        (ind) {
          return Container(
            height: 8,
            width: 8,
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(color: i == ind ? Colors.white : Colors.grey.withOpacity(0.5), borderRadius: BorderRadius.circular(defaultRadius)),
          );
        },
      ),
    ),
  );
}

InputDecoration inputDecoration(BuildContext context, {String? label, Widget? prefixIcon, Widget? suffixIcon, bool? alignWithHint = true, String? counterText}) {
  return InputDecoration(
    focusColor: primaryColor, // Cyan neón
    prefixIcon: prefixIcon != null ? IconTheme(
      data: IconThemeData(color: primaryColor), // Iconos en cyan neón
      child: prefixIcon,
    ) : null,
    counterText: counterText,
    // Borde normal: gris claro con opacidad
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(defaultRadius),
      borderSide: BorderSide(color: dividerColor.withOpacity(0.5), width: 1),
    ),
    // Borde enfocado: cyan neón brillante (efecto neón)
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(defaultRadius),
      borderSide: BorderSide(color: primaryColor, width: 2), // Cyan neón más grueso
    ),
    // Borde habilitado: gris claro
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(defaultRadius),
      borderSide: BorderSide(color: dividerColor.withOpacity(0.5), width: 1),
    ),
    // Borde de error: naranja vibrante ZIGO
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(defaultRadius),
      borderSide: BorderSide(color: zigoOrange, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(defaultRadius),
      borderSide: BorderSide(color: zigoOrange, width: 2),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(defaultRadius),
      borderSide: BorderSide(color: dividerColor.withOpacity(0.3), width: 1),
    ),
    alignLabelWithHint: alignWithHint,
    filled: true,
    fillColor: scaffoldSecondaryDark.withOpacity(0.5), // Fondo sutil
    isDense: true,
    labelText: label ?? "Sample Text",
    labelStyle: primaryTextStyle(color: textSecondaryColor), // Gris claro para label
    hintStyle: primaryTextStyle(color: Color(0xFFFF6600)), // Naranja para placeholders
    suffixIcon: suffixIcon != null ? IconTheme(
      data: IconThemeData(color: primaryColor), // Iconos en cyan neón
      child: suffixIcon,
    ) : null,
  );
}

/// Campos sobre fondo oscuro (perfil / formularios neón), alineado app conductor.
InputDecoration inputDecorationNeonForm(BuildContext context, {String? label, Widget? prefixIcon, Widget? suffixIcon, String? counterText}) {
  final subtle = neonAccent.withOpacity(0.45);
  return InputDecoration(
    focusColor: neonAccent,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    counterText: counterText,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color: subtle)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color: neonError)),
    disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color: subtle.withOpacity(0.35))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color: neonAccent, width: 1.5)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color: subtle)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(defaultRadius), borderSide: BorderSide(color: neonError)),
    alignLabelWithHint: true,
    filled: true,
    fillColor: neonSurfaceCard.withOpacity(0.55),
    isDense: true,
    labelText: label ?? "Sample Text",
    labelStyle: primaryTextStyle(color: neonHighlight),
  );
}

InputDecoration searchInputDecoration({String? hint}) {
  final line = neonAccent.withOpacity(0.45);
  return InputDecoration(
    contentPadding: EdgeInsets.symmetric(vertical: 8),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: line, width: 1),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: neonAccent, width: 2),
    ),
    border: UnderlineInputBorder(
      borderSide: BorderSide(color: line, width: 1),
    ),
    focusColor: neonAccent,
    isDense: true,
    hintStyle: primaryTextStyle(color: neonHighlight.withOpacity(0.82)),
    labelStyle: primaryTextStyle(color: neonHighlight.withOpacity(0.82)),
    hintText: hint,
  );
}

extension BooleanExtensions on bool? {
  /// Validate given bool is not null and returns given value if null.
  bool validate({bool value = false}) => this ?? value;
}

EdgeInsets dynamicAppButtonPadding(BuildContext context) {
  return EdgeInsets.symmetric(vertical: 14, horizontal: 16);
}

Widget inkWellWidget({Function()? onTap, required Widget child}) {
  return InkWell(onTap: onTap, child: child, highlightColor: Colors.transparent, hoverColor: Colors.transparent, splashColor: Colors.transparent);
}

bool get isRTL => rtlLanguage.contains(appStore.selectedLanguage);

/// Rutas relativas del API (p. ej. `/storage/...`) → URL absoluta con [DOMAIN_URL].
/// Si el backend devuelve `.../backend/storage/...` sin `public/`, esa URL suele dar 404;
/// los archivos reales están en `.../backend/public/storage/...` (workaround hasta corregir .env en servidor).
String resolveApiMediaUrl(String? raw) {
  var u = raw.validate().trim();
  if (u.isEmpty) return '';
  final lower = u.toLowerCase();
  if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
    final base = DOMAIN_URL.replaceAll(RegExp(r'/$'), '');
    u = u.startsWith('/') ? '$base$u' : '$base/$u';
  }
  final base = DOMAIN_URL.replaceAll(RegExp(r'/$'), '');
  final wrongPrefix = '$base/storage/';
  final rightPrefix = '$base/public/storage/';
  if (u.startsWith(wrongPrefix)) {
    u = u.replaceFirst(wrongPrefix, rightPrefix);
  }
  return u;
}

Widget commonCachedNetworkImage(
  String? url, {
  double? height,
  double? width,
  BoxFit? fit,
  AlignmentGeometry? alignment,
  bool usePlaceholderIfUrlEmpty = true,
  double? radius,
  String? placeholderAsset,
}) {
  final resolved = resolveApiMediaUrl(url);
  final placeholderFit = _placeholderFitForAsset(placeholderAsset, fit);
  if (resolved.isEmpty) {
    return placeHolderWidget(height: height, width: width, fit: placeholderFit, alignment: alignment, radius: radius, asset: placeholderAsset);
  }
  if (resolved.toLowerCase().startsWith('http')) {
    return CachedNetworkImage(
      imageUrl: resolved,
      height: height,
      width: width,
      fit: fit,
      alignment: alignment as Alignment? ?? Alignment.center,
      errorWidget: (_, s, d) {
        return placeHolderWidget(height: height, width: width, fit: placeholderFit, alignment: alignment, radius: radius, asset: placeholderAsset);
      },
      placeholder: (_, s) {
        if (!usePlaceholderIfUrlEmpty) return SizedBox();
        return placeHolderWidget(height: height, width: width, fit: placeholderFit, alignment: alignment, radius: radius, asset: placeholderAsset);
      },
    );
  }
  return placeHolderWidget(height: height, width: width, fit: placeholderFit, alignment: alignment, radius: radius, asset: placeholderAsset);
}

BoxFit _placeholderFitForAsset(String? asset, BoxFit? requested) {
  if (asset == driverDefaultAvatar) return BoxFit.contain;
  return requested ?? BoxFit.cover;
}

Widget placeHolderWidget({double? height, double? width, BoxFit? fit, AlignmentGeometry? alignment, double? radius, String? asset}) {
  return Image.asset(asset ?? placeholder, height: height, width: width, fit: fit ?? BoxFit.cover, alignment: alignment ?? Alignment.center);
}

List<BoxShadow> defaultBoxShadow({
  Color? shadowColor,
  double? blurRadius,
  double? spreadRadius,
  Offset offset = const Offset(0.0, 0.0),
}) {
  return [
    BoxShadow(
      color: shadowColor ?? Colors.grey.withOpacity(0.2),
      blurRadius: blurRadius ?? 4.0,
      spreadRadius: spreadRadius ?? 1.0,
      offset: offset,
    )
  ];
}

/// Hide soft keyboard
void hideKeyboard(context) => FocusScope.of(context).requestFocus(FocusNode());

const double degrees2Radians = pi / 180.0;

double radians(double degrees) => degrees * degrees2Radians;

Future<bool> isNetworkAvailable() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
}

String parseHtmlString(String? htmlString) {
  return parse(parse(htmlString).body!.text).documentElement!.text;
}

Widget loaderWidget() {
  return Center(
    child: Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.4), blurRadius: 10, spreadRadius: 0, offset: Offset(0.0, 0.0)),
        ],
      ),
      width: 50,
      height: 50,
      child: CircularProgressIndicator(strokeWidth: 3, color: primaryColor),
    ),
  );
}

void afterBuildCreated(Function()? onCreated) {
  makeNullable(SchedulerBinding.instance)!.addPostFrameCallback((_) => onCreated?.call());
}

T? makeNullable<T>(T? value) => value;

String printDate(String date) {
  return DateFormat('dd MMM yyyy').format(DateTime.parse(date).toLocal()) + " at " + DateFormat('hh:mm a').format(DateTime.parse(date).toLocal());
}

Widget emptyWidget() {
  return Center(child: Image.asset(noDataImg, width: 150, height: 250));
}

String statusTypeIcon({String? type}) {
  String icon = ic_history_img1;
  if (type == NEW_RIDE_REQUESTED) {
    icon = ic_history_img1;
  } else if (type == ACCEPTED || type == BID_ACCEPTED) {
    icon = ic_history_img2;
  } else if (type == ARRIVING) {
    icon = ic_history_img3;
  } else if (type == ARRIVED) {
    icon = ic_history_img4;
  } else if (type == IN_PROGRESS) {
    icon = ic_history_img5;
  } else if (type == CANCELED) {
    icon = ic_history_img6;
  } else if (type == COMPLETED) {
    icon = ic_history_img7;
  }
  return icon;
}

Widget scheduleOptionWidget(BuildContext context, bool isSelected, String imagePath, String title) {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(
          color: isSelected
              ? primaryColor
              : appStore.isDarkMode
                  ? Colors.transparent
                  : borderColor),
    ),
    child: Row(
      children: [
        ImageIcon(AssetImage(imagePath), size: 20, color: isSelected ? primaryColor : Colors.grey),
        SizedBox(width: 16),
        Text(title, style: boldTextStyle()),
      ],
    ),
  );
}

Widget totalCount({String? title, num? amount, bool? isTotal = false, double? space, bool styleNeon = false}) {
  if (amount! > 0) {
    final Color totalColor = styleNeon ? neonAccent : Colors.green;
    final Color lineTitleColor = styleNeon ? neonHighlight : textPrimaryColor;
    return Padding(
      padding: EdgeInsets.only(bottom: space ?? 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: Text(title!,
                  style: isTotal == true
                      ? boldTextStyle(color: totalColor, size: 18)
                      : (styleNeon ? secondaryTextStyle(color: lineTitleColor) : secondaryTextStyle()))),
          printAmountWidget(
              amount: '${amount.toStringAsFixed(digitAfterDecimal)}',
              size: isTotal == true ? 18 : 14,
              color: isTotal == true ? totalColor : (styleNeon ? Colors.white : textPrimaryColorGlobal))
        ],
      ),
    );
  } else {
    return SizedBox();
  }
}

Widget printAmountWidget({required String amount, double? size, Color? color, FontWeight? weight, TextDecoration? textDecoration}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    // mainAxisAlignment: MainAxisAlignment.start,
    // crossAxisAlignment: CrossAxisAlignment.center,
    children: appStore.currencyPosition.toString().toLowerCase().trim() == LEFT.toLowerCase().trim()
        ? [
            Text(
              "${appStore.currencyCode} ",
              // appStore.currencyPosition.toString().toLowerCase().trim() == LEFT.toLowerCase().trim() ? '${appStore.currencyCode}$amount' : '$amount ${appStore.currencyCode}',
              // textDirection: TextDirection.LTR,
              style: TextStyle(
                  fontSize: size ?? textPrimarySizeGlobal,
                  color: color ?? textPrimaryColorGlobal,
                  fontWeight: weight ?? FontWeight.bold,
                  fontFamily: GoogleFonts.roboto().fontFamily,
                  decoration: textDecoration ?? TextDecoration.none),
            ),
            Text(
              "$amount",
              // appStore.currencyPosition.toString().toLowerCase().trim() == LEFT.toLowerCase().trim() ? '${appStore.currencyCode}$amount' : '$amount ${appStore.currencyCode}',
              // textDirection: TextDirection.LTR,
              style: TextStyle(
                  fontSize: size ?? textPrimarySizeGlobal,
                  color: color ?? textPrimaryColorGlobal,
                  fontWeight: weight ?? FontWeight.bold,
                  fontFamily: GoogleFonts.roboto().fontFamily,
                  decoration: textDecoration ?? TextDecoration.none),
            ),
          ]
        : [
            Text(
              "$amount ",
              style: TextStyle(
                  fontSize: size ?? textPrimarySizeGlobal,
                  color: color ?? textPrimaryColorGlobal,
                  fontWeight: weight ?? FontWeight.bold,
                  fontFamily: GoogleFonts.roboto().fontFamily,
                  decoration: textDecoration ?? TextDecoration.none),
            ),
            Text(
              "${appStore.currencyCode}",
              // appStore.currencyPosition.toString().toLowerCase().trim() == LEFT.toLowerCase().trim() ? '${appStore.currencyCode}$amount' : '$amount ${appStore.currencyCode}',
              // textDirection: TextDirection.LTR,
              style: TextStyle(
                  fontSize: size ?? textPrimarySizeGlobal,
                  color: color ?? textPrimaryColorGlobal,
                  fontWeight: weight ?? FontWeight.bold,
                  fontFamily: GoogleFonts.roboto().fontFamily,
                  decoration: textDecoration ?? TextDecoration.none),
            ),
          ],
  );
}

Future<bool> checkPermission() async {
  // Request app level location permission
  LocationPermission locationPermission = await Geolocator.requestPermission();

  if (locationPermission == LocationPermission.whileInUse || locationPermission == LocationPermission.always) {
    await Geolocator.getCurrentPosition().then((value) {
      sharedPref.setDouble(LATITUDE, value.latitude);
      sharedPref.setDouble(LONGITUDE, value.longitude);
    });
    // Check system level location permission
    if (!await Geolocator.isLocationServiceEnabled()) {
      return await Geolocator.openLocationSettings().then((value) => false).catchError((e) => false);
    } else {
      return true;
    }
  } else {
    toast(language.pleaseEnableLocationPermission);

    // Open system level location permission
    await Geolocator.openAppSettings();

    return false;
  }
}

/// Handle error and loading widget when using FutureBuilder or StreamBuilder
Widget snapWidgetHelper<T>(
  AsyncSnapshot<T> snap, {
  Widget? errorWidget,
  Widget? loadingWidget,
  String? defaultErrorMessage,
  @Deprecated('Do not use this') bool checkHasData = false,
  Widget Function(String)? errorBuilder,
}) {
  if (snap.hasError) {
    log(snap.error);
    if (errorBuilder != null) {
      return errorBuilder.call(defaultErrorMessage ?? snap.error.toString());
    }
    return Center(
      child: errorWidget ??
          Text(
            defaultErrorMessage ?? snap.error.toString(),
            style: primaryTextStyle(),
          ),
    );
  } else if (!snap.hasData) {
    return loadingWidget ?? Loader();
  } else {
    return SizedBox();
  }
}

Future<bool> setValue(String key, dynamic value, {bool print1 = true}) async {
  if (print1) print('${value.runtimeType} - $key - $value');

  if (value is String) {
    return await sharedPref.setString(key, value.validate());
  } else if (value is int) {
    return await sharedPref.setInt(key, value.validate());
  } else if (value is bool) {
    return await sharedPref.setBool(key, value.validate());
  } else if (value is double) {
    return await sharedPref.setDouble(key, value);
  } else if (value is Map<String, dynamic>) {
    return await sharedPref.setString(key, jsonEncode(value));
  } else if (value is List<String>) {
    return await sharedPref.setStringList(key, value);
  } else {
    throw ArgumentError('Invalid value ${value.runtimeType} - Must be a String, int, bool, double, Map<String, dynamic> or StringList');
  }
}

String statusName({String? status}) {
  if (status == NEW_RIDE_REQUESTED) {
    status = language.newRideRequested;
  } else if (status == ACCEPTED || status == BID_ACCEPTED) {
    status = language.accepted;
  } else if (status == ARRIVING) {
    status = language.arriving;
  } else if (status == ARRIVED) {
    status = language.arrived;
  } else if (status == IN_PROGRESS) {
    status = language.inProgress;
  } else if (status == CANCELED) {
    status = language.cancelled;
  } else if (status == COMPLETED) {
    status = language.completed;
  }
  return status!;
}

String paymentStatus(String paymentStatus) {
  if (paymentStatus.toLowerCase() == PAYMENT_PENDING.toLowerCase()) {
    return language.pending;
  } else if (paymentStatus.toLowerCase() == PAYMENT_FAILED.toLowerCase()) {
    return language.failed;
  } else if (paymentStatus == PAYMENT_PAID) {
    return language.paid;
  } else if (paymentStatus == CASH) {
    return language.cash;
  } else if (paymentStatus == WALLET) {
    return language.wallet;
  }
  return language.pending;
}

String changeStatusText(String? status) {
  if (status == COMPLETED) {
    return language.completed;
  } else if (status == CANCELED) {
    return language.cancelled;
  }
  return '';
}

String getMessageFromErrorCode(FirebaseException error) {
  switch (error.code) {
    case "ERROR_EMAIL_ALREADY_IN_USE":
    case "account-exists-with-different-credential":
    case "email-already-in-use":
      return "The email address is already in use by another account.";
    case "ERROR_WRONG_PASSWORD":
    case "wrong-password":
      return "Wrong email/password combination.";
    case "ERROR_USER_NOT_FOUND":
    case "user-not-found":
      return "No user found with this email.";
    case "ERROR_USER_DISABLED":
    case "user-disabled":
      return "User disabled.";
    case "ERROR_TOO_MANY_REQUESTS":
    case "operation-not-allowed":
      return "Too many requests to log into this account.";
    case "ERROR_OPERATION_NOT_ALLOWED":
    case "operation-not-allowed":
      return "Server error, please try again later.";
    case "ERROR_INVALID_EMAIL":
    case "invalid-email":
      return "Email address is invalid.";
    default:
      return error.message.toString();
  }
}

Widget socialWidget({String? image, String? text}) {
  return Image.asset(image.validate(), fit: BoxFit.cover, height: 30, width: 30);
}

void scheduleFunction({required DateTime scheduledTime, required Function function}) {
  var d1 = DateTime.parse(DateTime.now().toUtc().toString().replaceAll("Z", ""));
  Duration delay = scheduledTime.difference(d1);
  print("CheckDelay:::${delay.inSeconds}");
  if (delay.isNegative) {
    print("Scheduled time is in the past.");
    return;
  }
  Timer(delay, () {
    function();
  });
  print("Function scheduled to run at $scheduledTime");
}

oneSignalSettings() async {
  await Permission.notification.request();
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.Debug.setAlertLevel(OSLogLevel.none);
  OneSignal.consentRequired(false);

  OneSignal.initialize(mOneSignalAppIdRider);

  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    event.preventDefault();
    event.notification.display();
  });

  saveOneSignalPlayerId();
  if (appStore.isLoggedIn) {
    updatePlayerId();
  }
  OneSignal.Notifications.addClickListener((notification) async {
    var notId = notification.notification.additionalData!["id"];
    log("$notId---" + notification.notification.additionalData!['type'].toString());
    var notType = notification.notification.additionalData!['type'];
    if (notId != null) {
      if (notId.toString().contains('CHAT')) {
        LoginResponse user = await getUserDetail(userId: int.parse(notId.toString().replaceAll("CHAT_", "")));
        launchScreen(
            getContext,
            ChatScreen(
              userData: user.data,
              ride_id: -1,
            ),
            isNewTask: true);
      } else if (notType == SUCCESS) {
        launchScreen(getContext, RideDetailScreen(orderId: notId), isNewTask: true);
      }
    }
  });
}

Future<void> saveOneSignalPlayerId() async {
  // await OneSignal.shared.getDeviceState().then((value) async {
  // });
  OneSignal.User.pushSubscription.addObserver((state) async {
    if (OneSignal.User.pushSubscription.id.validate().isNotEmpty) await sharedPref.setString(PLAYER_ID, OneSignal.User.pushSubscription.id.validate());
  });
}

Future<void> exportedLog({required String logMessage, required String file_name}) async {
  return;
  final downloadsDirectory = Directory('/storage/emulated/0/Download');
  if (!await downloadsDirectory.exists()) {
    await downloadsDirectory.create(recursive: true);
  }
  final filePath = '${downloadsDirectory.path}/${file_name + "${DateTime.now().hour}_${DateTime.now().minute}"}.txt';
  final file = File(filePath);
  try {
    await file.writeAsString(logMessage, mode: FileMode.append);
  } catch (e) {}
}

Color paymentStatusColor(String paymentStatus) {
  Color color = textPrimaryColor;

  switch (paymentStatus) {
    case PAYMENT_PAID:
      color = Colors.green;
      break;
    case PAYMENT_FAILED:
      color = Colors.red;
      break;
    case PAYMENT_PENDING:
      color = Colors.grey;
      break;
    default:
      break;
  }
  return color;
}

/// Estado de pago en pantallas con tema Neon Steel Blue.
Color paymentStatusColorNeon(String paymentStatus) {
  switch (paymentStatus) {
    case PAYMENT_PAID:
      return neonAccent;
    case PAYMENT_FAILED:
      return neonError;
    case PAYMENT_PENDING:
      return neonHighlight;
    default:
      return neonHighlight;
  }
}

Future<void> getAppSettingsData() async {
  // appStore.setisBidEnable(element.value ?? "0");
  await getAppSetting().then((value) {
    if (value.walletSetting != null) {
      value.walletSetting!.forEach((element) {
        if (element.key == PRESENT_TOPUP_AMOUNT) {
          appStore.setWalletPresetTopUpAmount(element.value ?? PRESENT_TOP_UP_AMOUNT_CONST);
        }
        if (element.key == MIN_AMOUNT_TO_ADD) {
          if (element.value != null) appStore.setMinAmountToAdd(num.parse(element.value!).round());
        }
        if (element.key == MAX_AMOUNT_TO_ADD) {
          if (element.value != null) appStore.setMaxAmountToAdd(num.parse(element.value!).round());
        }
      });
    }
    if (value.rideSetting != null) {
      value.rideSetting!.forEach((element) {
        if (element.key == PRESENT_TIP_AMOUNT) {
          appStore.setWalletTipAmount(element.value ?? PRESENT_TIP_AMOUNT_CONST);
        }
        if (element.key == RIDE_FOR_OTHER) {
          appStore.setIsRiderForAnother(element.value ?? "0");
        }
        if (element.key == IS_MULTI_DROP) {
          appStore.setisMultiDrop(element.value ?? "0");
        }
        if (element.key == RIDE_IS_SCHEDULE_RIDE) {
          appStore.setisScheduleRide(element.value ?? "0");
        }
        if (element.key == IS_BID_ENABLE) {
          appStore.setisBidEnable(element.value ?? "0");
        }
        // isBidEnable
        if (element.key == MAX_TIME_FOR_RIDER_MINUTE) {
          appStore.setRiderMinutes(element.value ?? '4');
        }
      });
    }
    if (value.currencySetting != null) {
      appStore.setCurrencyCode(value.currencySetting!.symbol ?? currencySymbol);
      appStore.setCurrencyName(value.currencySetting!.code ?? currencyNameConst);
      appStore.setCurrencyPosition(value.currencySetting!.position ?? LEFT);
    }
    if (value.settingModel != null) {
      appStore.settingModel = value.settingModel!;
      if (value.settingModel!.helpSupportUrl != null) appStore.mHelpAndSupport = value.settingModel!.helpSupportUrl!;
    }
    if (value.privacyPolicyModel != null && value.privacyPolicyModel!.value != null) appStore.privacyPolicy = value.privacyPolicyModel!.value!;
    if (value.termsCondition != null && value.termsCondition!.value != null) appStore.termsCondition = value.termsCondition!.value!;
  }).catchError((error, stack) {
    // FirebaseCrashlytics.instance.recordError("setting_update_issue::" + error.toString(), stack, fatal: true);
    log('${error.toString()} STack:::${stack}');
  });
}
