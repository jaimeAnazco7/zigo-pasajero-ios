import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:pinput/pinput.dart';

import '../../main.dart';
import '../../network/RestApis.dart';
import '../screens/DashBoardScreen.dart';
import '../screens/SignUpScreen.dart';
import '../service/AuthService.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/app_textfield.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import '../utils/phone_utils.dart';

class OTPDialog extends StatefulWidget {
  final String? verificationId;
  final String? phoneNumber;
  final bool? isCodeSent;
  final PhoneAuthCredential? credential;

  OTPDialog({this.verificationId, this.isCodeSent, this.phoneNumber, this.credential});

  @override
  OTPDialogState createState() => OTPDialogState();
}

class OTPDialogState extends State<OTPDialog> {
  var otpController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String verId = '';
  /// Solo Perú en inicio de sesión por teléfono (+51).
  String otpCode = '+51';

  Future<void> submit() async {
    appStore.setLoading(true);

    AuthCredential credential = PhoneAuthProvider.credential(verificationId: widget.verificationId!, smsCode: verId.validate());

    await FirebaseAuth.instance.signInWithCredential(credential).then((result) async {
      final e164 = widget.phoneNumber!.trim().replaceAll(' ', '');
      final national = nationalDigitsFromPeruE164(e164) ?? e164.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^51'), '');
      Map req = {
        "email": "",
        "login_type": "mobile",
        "user_type": RIDER,
        "username": national,
        'accessToken': national,
        'contact_number': e164,
        "player_id": sharedPref.getString(PLAYER_ID).validate(),
      };

      log(req);
      await logInApi(req, isSocialLogin: true).then((value) async {
        appStore.setLoading(false);
        if (value.data == null) {
          Navigator.pop(context);
          launchScreen(
            context,
            SignUpScreen(countryCode: '+51', userName: national, socialLogin: true),
          );
        } else {
          updatePlayerId();
          Navigator.pop(context);
          launchScreen(context, DashBoardScreen(), isNewTask: true);
        }
      }).catchError((e) {
        Navigator.pop(context);
        toast(e.toString());
        appStore.setLoading(false);
      });
    }).catchError((e) {
      Navigator.pop(context);
      toast(e.toString());
      appStore.setLoading(false);
    });
  }

  Future<void> sendOTP() async {
    if (!formKey.currentState!.validate()) return;

    final parsed = buildPeruMobileE164(phoneController.text.trim());
    if (parsed == null) {
      toast('Ingrese un celular de 9 dígitos (Perú).');
      return;
    }
    appStore.setLoading(true);
    log('OTP E.164: $parsed');
    await loginWithOTP(context, parsed).then((value) {}).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isCodeSent.validate()) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  language.signInUsingYourMobileNumber,
                  style: boldTextStyle(),
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.cancel_outlined, color: Colors.black),
              )
            ],
          ),
          SizedBox(height: 30),
          Form(
            key: formKey,
            child: AppTextField(
              controller: phoneController,
              textFieldType: TextFieldType.PHONE,
              decoration: inputDecoration(
                context,
                label: language.phoneNumber,
                prefixIcon: IntrinsicHeight(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: Image.asset(
                                'flags/pe.png',
                                package: 'country_code_picker',
                                width: 28,
                                height: 20,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('+51', style: primaryTextStyle()),
                          ],
                        ),
                      ),
                      VerticalDivider(color: Colors.grey.withOpacity(0.5)),
                    ],
                  ),
                ),
              ),
              validator: (value) {
                if (value!.trim().isEmpty) return language.thisFieldRequired;
                return null;
              },
            ),
          ),
          SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              AppButtonWidget(
                onTap: () {
                  if (phoneController.text.trim().isEmpty) {
                    return toast(language.thisFieldRequired);
                  } else {
                    hideKeyboard(context);
                    sendOTP();
                  }
                },
                text: language.sendOTP,
                color: primaryColor,
                textStyle: boldTextStyle(color: Colors.white),
                width: MediaQuery.of(context).size.width,
              ),
              Positioned(
                child: Observer(builder: (context) {
                  return Visibility(
                    visible: appStore.isLoading,
                    child: loaderWidget(),
                  );
                }),
              ),
            ],
          )
        ],
      );
    } else {
      return Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(Icons.cancel_outlined, color: Colors.black)),
              ),
              Icon(Icons.message, color: primaryColor, size: 50),
              SizedBox(height: 16),
              Text(language.validateOtp, style: boldTextStyle(size: 18)),
              SizedBox(height: 16),
              Column(
                children: [
                  Text(language.otpCodeHasBeenSentTo, style: secondaryTextStyle(size: 16), textAlign: TextAlign.center),
                  SizedBox(height: 4),
                  Text(widget.phoneNumber.validate(), style: boldTextStyle()),
                  SizedBox(height: 10),
                  Text(language.pleaseEnterOtp, style: secondaryTextStyle(size: 16), textAlign: TextAlign.center),
                ],
              ),
              SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Pinput(
                    keyboardType: TextInputType.number,
                    readOnly: false,
                    autofocus: true,
                    onClipboardFound: (value) {},
                    length: 6,
                    onTap: () {},
                    onLongPress: () {},
                    cursor: Text(
                      "|",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 40,
                      height: 44,
                      textStyle: TextStyle(
                        fontSize: 18,
                      ),
                      decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.all(Radius.circular(8)), border: Border.all(color: primaryColor)),
                    ),
                    toolbarEnabled: true,
                    useNativeKeyboard: true,
                    defaultPinTheme: PinTheme(
                      width: 40,
                      height: 44,
                      textStyle: TextStyle(
                        fontSize: 18,
                      ),
                      decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.all(Radius.circular(8)), border: Border.all(color: dividerColor)),
                    ),
                    isCursorAnimationEnabled: true,
                    showCursor: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    closeKeyboardWhenCompleted: false,
                    enableSuggestions: false,
                    autofillHints: [AutofillHints.oneTimeCode],
                    controller: otpController,
                    onCompleted: (val) {
                      otpController.text = val;
                      verId = val;
                      submit();
                    },
                  ),
                ),
              ),
            ],
          ),
          Observer(
            builder: (context) => Positioned.fill(
              child: Visibility(
                visible: appStore.isLoading,
                child: loaderWidget(),
              ),
            ),
          ),
        ],
      );
    }
  }
}
