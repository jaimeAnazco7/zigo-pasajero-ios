import 'package:flutter/material.dart';

import 'images.dart';

//region App name
const mAppName = 'ZIGO PASAJERO';
//endregion

// region Google map key
const GOOGLE_MAP_API_KEY = 'AIzaSyCXn1MGy_9obvgjtwc9hu5HhZ5bEGEas60';
/// Lima Metropolitana (aprox.): esquinas del rectángulo para `locationRestriction` en Places Autocomplete.
/// Ajusta estos valores si necesitas ampliar o acotar la zona (SW = suroeste, NE = noreste).
const double placesLimaMetroSwLat = -12.58;
const double placesLimaMetroSwLng = -77.42;
const double placesLimaMetroNeLat = -11.28;
const double placesLimaMetroNeLng = -76.52;
//endregion

//region DomainUrl
const DOMAIN_URL = 'https://zigotaxi.com/backend'; // Don't add slash at the end of the url
//endregion

//region OneSignal Keys
//You have to generate 2 apps on onesignal account one for rider and one for driver
const mOneSignalAppIdDriver = '675225dd-eade-4895-b433-bf58aa5d5e8b';
const mOneSignalDriverChannelID = 'default';

const mOneSignalAppIdRider = '404128d4-cfa0-40a0-9a0c-547b4c168817';
const mOneSignalRiderChannelID = 'default';
// Las REST keys están en secrets.dart (gitignored). Ver secrets.example.dart.
//endregion

//region firebase configuration
// zigo-taxi-produccion — alinea este bloque con tu app Firebase Android (com.zigotaxi.rider)
const projectId = 'zigo-taxi-produccion';
const appIdAndroid = '1:596360016418:android:907ad32295af8dfbe3507b';
const apiKeyFirebase = 'AIzaSyBOEdpMal83dLG9n27u_mmqz6kpZpb3Zwo';
const messagingSenderId = '596360016418';
const storageBucket = 'zigo-taxi-produccion.firebasestorage.app';
const authDomain = 'zigo-taxi-produccion.firebaseapp.com';
/// Cliente OAuth **Web** (mismo `client_id` con `client_type: 3` en `android/app/google-services.json`).
/// En Android, `GoogleSignIn` lo necesita para obtener `idToken` y que Firebase acepte la credencial.
const GOOGLE_SIGN_IN_SERVER_CLIENT_ID = '596360016418-oi6p3q0m9c5c5r67cvcpsdp0cvb9iml8.apps.googleusercontent.com';
//endregion

//region Currency & country code
const currencySymbol = '\$';
const currencyNameConst = 'usd';
const defaultCountry = 'IN';
const digitAfterDecimal = 2;
//endregion

//region Drawer (menú lateral pasajero)
/// `false`: oculta **Cartera** e **Información bancaria** en el drawer. Pon `true` para volver a mostrarlas.
const bool showDrawerWalletAndBankMenu = false;
//endregion

//region top up default value
const PRESENT_TOP_UP_AMOUNT_CONST = '1000|2000|3000';
const PRESENT_TIP_AMOUNT_CONST = '10|20|30';
//endregion

// INTRO SCREEN IMAGES ic_walk1,ic_walk2 and ic_walk3
const walkthrough_image_1 = ic_walk1;
const walkthrough_image_2 = ic_walk2;
const walkthrough_image_3 = ic_walk3;

//region url
const mBaseUrl = "$DOMAIN_URL/api/";
//endregion

//region userType
const ADMIN = 'admin';
const DRIVER = 'driver';
const RIDER = 'rider';
//endregion

const PER_PAGE = 15;
const passwordLengthGlobal = 8;
const defaultRadius = 10.0;
const defaultSmallRadius = 6.0;

const textPrimarySizeGlobal = 16.00;
const textBoldSizeGlobal = 16.00;
const textSecondarySizeGlobal = 14.00;

double tabletBreakpointGlobal = 600.0;
double desktopBreakpointGlobal = 720.0;
double statisticsItemWidth = 230.0;
double defaultAppButtonElevation = 4.0;

bool enableAppButtonScaleAnimationGlobal = true;
int? appButtonScaleAnimationDurationGlobal;
ShapeBorder? defaultAppButtonShapeBorder;

var customDialogHeight = 140.0;
var customDialogWidth = 220.0;

enum ThemeModes { SystemDefault, Light, Dark }

//region loginType
const LoginTypeApp = 'app';
const LoginTypeGoogle = 'google';
const LoginTypeOTP = 'otp';
const LoginTypeApple = 'apple';
//endregion

//region SharedReference keys
const REMEMBER_ME = 'REMEMBER_ME';
const IS_FIRST_TIME = 'IS_FIRST_TIME';
const IS_LOGGED_IN = 'IS_LOGGED_IN';
const LEFT = 'left';

const USER_ID = 'USER_ID';
const FIRST_NAME = 'FIRST_NAME';
const LAST_NAME = 'LAST_NAME';
const TOKEN = 'TOKEN';
const USER_EMAIL = 'USER_EMAIL';
const USER_TOKEN = 'USER_TOKEN';
const USER_PROFILE_PHOTO = 'USER_PROFILE_PHOTO';
const USER_TYPE = 'USER_TYPE';
const USER_NAME = 'USER_NAME';
const USER_PASSWORD = 'USER_PASSWORD';
const USER_ADDRESS = 'USER_ADDRESS';
const STATUS = 'STATUS';
const CONTACT_NUMBER = 'CONTACT_NUMBER';
const PLAYER_ID = 'PLAYER_ID';
const UID = 'UID';
const ADDRESS = 'ADDRESS';
const IS_OTP = 'IS_OTP';
const IS_GOOGLE = 'IS_GOOGLE';
const GENDER = 'GENDER';
const IS_TIME = 'IS_TIME';
const IS_TIME2 = 'IS_TIME_BID';
const REMAINING_TIME = 'REMAINING_TIME';
const REMAINING_TIME2 = 'REMAINING_TIME_BID';
const LOGIN_TYPE = 'login_type';
const COUNTRY = 'COUNTRY';
const LATITUDE = 'LATITUDE';
const LONGITUDE = 'LONGITUDE';
//endregion

//region Taxi Status
const ACTIVE = 'active';
const IN_ACTIVE = 'inactive';
const PENDING = 'pending';
const BANNED = 'banned';
const REJECT = 'reject';
//endregion

//region Wallet keys
const CREDIT = 'credit';
const DEBIT = 'debit';
const OTHERS = 'Others';
//endregion

//region paymentType
const PAYMENT_TYPE_STRIPE = 'stripe';
const PAYMENT_TYPE_RAZORPAY = 'razorpay';
const PAYMENT_TYPE_PAYSTACK = 'paystack';
const PAYMENT_TYPE_FLUTTERWAVE = 'flutterwave';
const PAYMENT_TYPE_PAYPAL = 'paypal';
const PAYMENT_TYPE_PAYTABS = 'paytabs';
const PAYMENT_TYPE_MERCADOPAGO = 'mercadopago';
const PAYMENT_TYPE_PAYTM = 'paytm';
const PAYMENT_TYPE_MYFATOORAH = 'myfatoorah';

const stripeURL = 'https://api.stripe.com/v1/payment_intents';
//endregion

var errorThisFieldRequired = 'This field is required';

//region Ride Status
const UPCOMING = 'upcoming';
const NEW_RIDE_REQUESTED = 'new_ride_requested';
const ACCEPTED = 'accepted';
const BID_ACCEPTED = 'bid_accepted';
const ARRIVING = 'arriving';
const ARRIVED = 'arrived';
const IN_PROGRESS = 'in_progress';
const CANCELED = 'canceled';
const COMPLETED = 'completed';
const SUCCESS = 'payment_status_message';
const AUTO = 'auto';
const COMPLAIN_COMMENT = "complaintcomment";
//endregion

///fix Decimal
const fixedDecimal = digitAfterDecimal;

//region
const CHARGE_TYPE_FIXED = 'fixed';
const CHARGE_TYPE_PERCENTAGE = 'percentage';
const CASH_WALLET = 'cash_wallet';
const CASH = 'cash';
const MALE = 'male';
const FEMALE = 'female';
const OTHER = 'other';
const WALLET = 'wallet';
const DISTANCE_TYPE_KM = 'km';
const DISTANCE_TYPE_MILE = 'mile';
//endregion

//region app setting key
const CLOCK = 'clock';
const PRESENT_TOPUP_AMOUNT = 'preset_topup_amount';
const PRESENT_TIP_AMOUNT = 'preset_tip_amount';
const RIDE_FOR_OTHER = 'RIDE_FOR_OTHER';
const IS_MULTI_DROP = 'RIDE_MULTIPLE_DROP_LOCATION';
const RIDE_IS_SCHEDULE_RIDE = 'RIDE_IS_SCHEDULE_RIDE';
const IS_BID_ENABLE = 'is_bidding';
const MAX_TIME_FOR_RIDER_MINUTE = 'max_time_for_find_drivers_for_regular_ride_in_minute';
const MAX_TIME_FOR_DRIVER_SECOND = 'ride_accept_decline_duration_for_driver_in_second';
const MIN_AMOUNT_TO_ADD = 'min_amount_to_add';
const MAX_AMOUNT_TO_ADD = 'max_amount_to_add';
//endregion

//region FireBase Collection Name
const MESSAGES_COLLECTION = "RideTalk";
const RIDE_CHAT = "RideTalkHistory";
const RIDE_COLLECTION = 'rides';
const USER_COLLECTION = "users";
//endregion

const IS_ENTER_KEY = "IS_ENTER_KEY";
const SELECTED_WALLPAPER = "SELECTED_WALLPAPER";
const PER_PAGE_CHAT_COUNT = 50;
const TEXT = "TEXT";
const IMAGE = "IMAGE";
const VIDEO = "VIDEO";
const AUDIO = "AUDIO";
const FIXED_CHARGES = "fixed_charges";
const MIN_DISTANCE = "min_distance";
const MIN_WEIGHT = "min_weight";
const PER_DISTANCE_CHARGE = "per_distance_charges";
const PER_WEIGHT_CHARGE = "per_weight_charges";
const PAID = 'paid';
const PAYMENT_PENDING = 'pending';
const PAYMENT_FAILED = 'failed';
const PAYMENT_PAID = 'paid';
const THEME_MODE_INDEX = 'theme_mode_index';
const CHANGE_MONEY = 'CHANGE_MONEY';
const CHANGE_LANGUAGE = 'CHANGE_LANGUAGE';
List<String> rtlLanguage = ['ar', 'ur'];

enum MessageType { TEXT, IMAGE, VIDEO, AUDIO }

extension MessageExtension on MessageType {
  String? get name {
    switch (this) {
      case MessageType.TEXT:
        return 'TEXT';
      case MessageType.IMAGE:
        return 'IMAGE';
      case MessageType.VIDEO:
        return 'VIDEO';
      case MessageType.AUDIO:
        return 'AUDIO';
      default:
        return null;
    }
  }
}

var errorSomethingWentWrong = 'Something Went Wrong';
var rideNotFound = "Ride Not Detected";

var demoEmail = 'joy58@gmail.com';
const mRazorDescription = mAppName;
const mStripeIdentifier = 'IN';
