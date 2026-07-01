import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:image_picker/image_picker.dart';

import '../../main.dart';
import '../../utils/Common.dart';
import '../../utils/Constants.dart';
import '../../utils/Extensions/app_textfield.dart';
import '../components/ImageSourceDialog.dart';
import '../languageConfiguration/LanguageDefaultJson.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import 'DashBoardScreen.dart';

class EditProfileScreen extends StatefulWidget {
  final bool? isGoogle;

  EditProfileScreen({this.isGoogle = false});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  XFile? imageProfile;
  String countryCode = defaultCountryCode;

  TextEditingController emailController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController contactNumberController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  FocusNode emailFocus = FocusNode();
  FocusNode userNameFocus = FocusNode();
  FocusNode firstnameFocus = FocusNode();
  FocusNode lastnameFocus = FocusNode();
  FocusNode contactFocus = FocusNode();
  FocusNode addressFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    appStore.setLoading(true);
    getUserDetail(userId: sharedPref.getInt(USER_ID)).then((value) {
      emailController.text = value.data!.email.validate();
      usernameController.text = value.data!.username.validate();
      firstNameController.text = value.data!.firstName.validate();
      lastNameController.text = value.data!.lastName.validate();
      addressController.text = value.data!.address.validate();
      contactNumberController.text = value.data!.contactNumber.validate();
      if (value.data!.country_code != null) {
        contactNumberController.text = value.data!.country_code.validate() + value.data!.contactNumber.validate();
      }
      appStore.setUserEmail(value.data!.email.validate());
      appStore.setUserName(value.data!.username.validate());
      appStore.setFirstName(value.data!.firstName.validate());
      if (sharedPref.getString(LOGIN_TYPE) != LoginTypeGoogle) {
        appStore.setUserProfile(value.data!.profileImage.validate());
      }
      sharedPref.setString(USER_EMAIL, value.data!.email.validate());
      sharedPref.setString(FIRST_NAME, value.data!.firstName.validate());
      sharedPref.setString(LAST_NAME, value.data!.lastName.validate());
      sharedPref.setString(USER_PROFILE_PHOTO, value.data!.profileImage.validate());

      appStore.setLoading(false);
      setState(() {});
    }).catchError((error) {
      log(error.toString());
      appStore.setLoading(false);
    });
  }

  Widget profileImage() {
    if (imageProfile != null) {
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Image.file(File(imageProfile!.path), height: 100, width: 100, fit: BoxFit.cover, alignment: Alignment.center),
        ),
      );
    } else {
      if (sharedPref.getString(USER_PROFILE_PHOTO) != null && sharedPref.getString(USER_PROFILE_PHOTO)!.isNotEmpty) {
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: commonCachedNetworkImage(sharedPref.getString(USER_PROFILE_PHOTO).validate(), fit: BoxFit.cover, height: 100, width: 100),
          ),
        );
      } else {
        return Center(
          child: Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: commonCachedNetworkImage(sharedPref.getString(USER_PROFILE_PHOTO).validate(), height: 90, width: 90),
            ),
          ),
        );
      }
    }
  }

  Future<void> saveProfile() async {
    hideKeyboard(context);
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      appStore.setLoading(true);
      await updateProfile(
        uid: sharedPref.getString(UID).toString(),
        file: imageProfile != null ? File(imageProfile!.path.validate()) : null,
        contactNumber: widget.isGoogle == true ? '$countryCode${contactNumberController.text.trim()}' : contactNumberController.text.trim(),
        address: addressController.text.trim(),
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        userEmail: emailController.text.trim(),
      ).then((value) {
        appStore.setLoading(false);
        toast(language.profileUpdateMsg);
        if (widget.isGoogle == true) {
          launchScreen(context, DashBoardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
        } else {
          // Navigator.pop(context);
        }
      }).catchError((error) {
        appStore.setLoading(false);
        log(error.toString());
      });
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: neonBackground,
      appBar: AppBar(
        title: Text(language.editProfile, style: boldTextStyle(color: appTextPrimaryColorWhite)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(left: 16, top: 30, right: 16, bottom: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      profileImage(),
                      if (sharedPref.getString(LOGIN_TYPE) != LoginTypeGoogle)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            margin: EdgeInsets.only(top: 60, left: 80),
                            height: 35,
                            width: 35,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: neonAccent,
                              border: Border.all(color: neonHighlight.withOpacity(0.5), width: 1.5),
                              boxShadow: [
                                BoxShadow(color: neonAccent.withOpacity(0.35), blurRadius: 8),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(defaultRadius), topRight: Radius.circular(defaultRadius))),
                                  builder: (_) {
                                    return Padding(
                                      padding: MediaQuery.of(context).viewInsets,
                                      child: ImageSourceDialog(
                                        onCamera: () async {
                                          Navigator.pop(context);
                                          imageProfile = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 100);
                                          setState(() {});
                                        },
                                        onGallery: () async {
                                          Navigator.pop(context);
                                          imageProfile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 100);
                                          setState(() {});
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                              icon: Icon(Icons.edit, color: Colors.white, size: 20),
                            ),
                          ),
                        )
                    ],
                  ),
                  SizedBox(height: 20),
                  AppTextField(
                    readOnly: true,
                    enabled: false,
                    controller: emailController,
                    textFieldType: TextFieldType.EMAIL,
                    focus: emailFocus,
                    nextFocus: userNameFocus,
                    textStyle: primaryTextStyle(color: neonHighlight.withOpacity(0.9)),
                    decoration: inputDecorationNeonForm(context, label: language.email),
                    onTap: () {
                      toast(language.notChangeEmail);
                    },
                  ),
                  if (sharedPref.getString(LOGIN_TYPE) != 'mobile' && sharedPref.getString(LOGIN_TYPE) != null) SizedBox(height: 16),
                  if (sharedPref.getString(LOGIN_TYPE) != 'mobile' && sharedPref.getString(LOGIN_TYPE) != null)
                    AppTextField(
                      readOnly: true,
                      enabled: false,
                      isValidationRequired: false,
                      controller: usernameController,
                      textFieldType: TextFieldType.USERNAME,
                      focus: userNameFocus,
                      nextFocus: firstnameFocus,
                      textStyle: primaryTextStyle(color: neonHighlight.withOpacity(0.9)),
                      decoration: inputDecorationNeonForm(context, label: language.userName),
                      onTap: () {
                        toast(language.notChangeUsername);
                      },
                    ),
                  SizedBox(height: 16),
                  AppTextField(
                    controller: firstNameController,
                    textFieldType: TextFieldType.NAME,
                    focus: firstnameFocus,
                    cursorColor: neonAccent,
                    textStyle: primaryTextStyle(color: Colors.white),
                    nextFocus: lastnameFocus,
                    decoration: inputDecorationNeonForm(context, label: language.firstName),
                    errorThisFieldRequired: language.thisFieldRequired,
                  ),
                  SizedBox(height: 16),
                  AppTextField(
                    controller: lastNameController,
                    textFieldType: TextFieldType.NAME,
                    focus: lastnameFocus,
                    cursorColor: neonAccent,
                    textStyle: primaryTextStyle(color: Colors.white),
                    nextFocus: contactFocus,
                    decoration: inputDecorationNeonForm(context, label: language.lastName),
                    errorThisFieldRequired: language.thisFieldRequired,
                  ),
                  SizedBox(height: 16),
                  widget.isGoogle == true
                      ? AppTextField(
                          controller: contactNumberController,
                          textFieldType: TextFieldType.PHONE,
                          focus: contactFocus,
                          cursorColor: neonAccent,
                          textStyle: primaryTextStyle(color: Colors.white),
                          nextFocus: addressFocus,
                          decoration: inputDecorationNeonForm(
                            context,
                            label: language.phoneNumber,
                            prefixIcon: IntrinsicHeight(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CountryCodePicker(
                                    padding: EdgeInsets.zero,
                                    initialSelection: countryCode,
                                    showCountryOnly: false,
                                    dialogSize: Size(MediaQuery.of(context).size.width - 60, MediaQuery.of(context).size.height * 0.6),
                                    showFlag: true,
                                    showFlagDialog: true,
                                    showOnlyCountryWhenClosed: false,
                                    alignLeft: false,
                                    textStyle: primaryTextStyle(color: Colors.white),
                                    dialogBackgroundColor: neonSurfaceCard,
                                    barrierColor: Colors.black54,
                                    dialogTextStyle: primaryTextStyle(color: Colors.white),
                                    searchDecoration: InputDecoration(
                                      focusColor: neonAccent,
                                      iconColor: neonHighlight,
                                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: neonAccent.withOpacity(0.35))),
                                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: neonAccent)),
                                    ),
                                    searchStyle: primaryTextStyle(color: Colors.white),
                                    onInit: (c) {
                                      countryCode = c!.dialCode!;
                                    },
                                    onChanged: (c) {
                                      countryCode = c.dialCode!;
                                    },
                                  ),
                                  VerticalDivider(color: neonAccent.withOpacity(0.35)),
                                ],
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value!.trim().isEmpty) return errorThisFieldRequired;
                            return null;
                          },
                        )
                      : AppTextField(
                          controller: contactNumberController,
                          textFieldType: TextFieldType.PHONE,
                          focus: contactFocus,
                          cursorColor: neonAccent,
                          textStyle: primaryTextStyle(color: Colors.white),
                          nextFocus: addressFocus,
                          isValidationRequired: true,
                          readOnly: sharedPref.getString(LOGIN_TYPE) == LoginTypeGoogle ? false : true,
                          decoration: inputDecorationNeonForm(
                            context,
                            label: language.phoneNumber,
                          ),
                          onTap: () {
                            if (sharedPref.getString(LOGIN_TYPE) != LoginTypeGoogle) {
                              toast(language.youCannotChangePhoneNumber);
                            }
                          },
                        ),
                  SizedBox(height: 16),
                  AppTextField(
                    controller: addressController,
                    focus: addressFocus,
                    textFieldType: TextFieldType.ADDRESS,
                    textInputAction: TextInputAction.newline,
                    maxLength: 300,
                    cursorColor: neonAccent,
                    textStyle: primaryTextStyle(color: Colors.white),
                    decoration: inputDecorationNeonForm(context, label: language.address, counterText: ''),
                  ),
                ],
              ),
            ),
          ),
          Observer(
            builder: (_) {
              return Visibility(
                visible: appStore.isLoading,
                child: loaderWidget(),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeScaffoldBottomBar(
        child: Container(
          color: neonBackground,
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: AppButtonWidget(
            text: language.updateProfile,
            textStyle: boldTextStyle(color: neonOnAccent),
            color: primaryColor,
            onTap: () {
              if (sharedPref.getString(USER_EMAIL) == demoEmail) {
                toast(language.demoMsg);
              } else {
                saveProfile();
              }
            },
          ),
        ),
      ),
    );
  }
}
