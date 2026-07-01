import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';

import '../components/OTPDialog.dart';
import '../main.dart';
import '../network/RestApis.dart';
import '../screens/DashBoardScreen.dart';
import '../screens/EditProfileScreen.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import 'AuthService1.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

Future<void> loginWithOTP(BuildContext context, String phoneNumber) async {
  appStore.setLoading(true);
  return await _auth.verifyPhoneNumber(
    phoneNumber: phoneNumber,
    verificationCompleted: (PhoneAuthCredential credential) async {
      appStore.setLoading(false);
    },
    verificationFailed: (FirebaseAuthException e) {
      if (e.code == 'invalid-phone-number') {
        toast('The provided phone number is not valid.');
        throw 'The provided phone number is not valid.';
      } else {
        log('**************${e.toString()}');
        appStore.setLoading(false);
        toast(e.toString());
        throw e.toString();
      }
    },
    codeSent: (String verificationId, int? resendToken) async {
      Navigator.pop(context);
      appStore.setLoading(false);
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(content: OTPDialog(verificationId: verificationId, isCodeSent: true, phoneNumber: phoneNumber)),
        barrierDismissible: false,
      );
    },
    codeAutoRetrievalTimeout: (String verificationId) {
      appStore.setLoading(false);
    },
  );
}

class GoogleAuthServices {
  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: GOOGLE_SIGN_IN_SERVER_CLIENT_ID,
  );
  AuthServices authService = AuthServices();

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
      if (googleSignInAccount != null) {
        //Authentication
        final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        final UserCredential authResult = await _auth.signInWithCredential(credential);
        final User user = authResult.user!;

        assert(!user.isAnonymous);

        final User currentUser = _auth.currentUser!;
        assert(user.uid == currentUser.uid);

        googleSignIn.signOut();

        await loginFromFirebase(user, LoginTypeGoogle, googleSignInAuthentication.accessToken);
      } else {
        throw errorSomethingWentWrong;
      }
    } catch (e) {
      throw e;
    }
  }
}

/// Sign-In with Apple.
Future<void> appleLogIn() async {
  if (await TheAppleSignIn.isAvailable()) {
    AuthorizationResult result = await TheAppleSignIn.performRequests([
      AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
    ]);
    switch (result.status) {
      case AuthorizationStatus.authorized:
        final appleIdCredential = result.credential!;
        final oAuthProvider = OAuthProvider('apple.com');
        final credential = oAuthProvider.credential(
          idToken: String.fromCharCodes(appleIdCredential.identityToken!),
          accessToken: String.fromCharCodes(appleIdCredential.authorizationCode!),
        );
        final authResult = await _auth.signInWithCredential(credential);
        final user = authResult.user!;

        if (result.credential!.email != null) {
          await saveAppleData(result);
        }

        await loginFromFirebase(user, LoginTypeApple, String.fromCharCodes(appleIdCredential.authorizationCode!));
        break;
      case AuthorizationStatus.error:
        throw ("Sign in failed: ${result.error!.localizedDescription}");
      case AuthorizationStatus.cancelled:
        throw ('User cancelled');
    }
  } else {
    throw ('Apple SignIn is not available for your device');
  }
}

Future<void> saveAppleData(AuthorizationResult result) async {
  await sharedPref.setString('appleEmail', result.credential!.email.validate());
  await sharedPref.setString('appleGivenName', result.credential!.fullName!.givenName.validate());
  await sharedPref.setString('appleFamilyName', result.credential!.fullName!.familyName.validate());
}

// Future deleteUser(String email, String password) async {
//   if (FirebaseAuth.instance.currentUser != null) {
//     FirebaseAuth.instance.currentUser!.delete();
//     await FirebaseAuth.instance.signOut();
//   }
// }

Future<void> loginFromFirebase(User currentUser, String loginType, String? accessToken) async {
  String firstName = '';
  String lastName = '';
  if (loginType == LoginTypeGoogle) {
    if (currentUser.displayName != null && currentUser.displayName!.trim().isNotEmpty) {
      if (currentUser.displayName.validate().split(' ').length >= 1) firstName = currentUser.displayName.splitBefore(' ');
      if (currentUser.displayName.validate().split(' ').length >= 2) lastName = currentUser.displayName.splitAfter(' ');
    } else {
      firstName = "Rider";
      lastName = "Anonymous";
    }
  } else {
    firstName = sharedPref.getString('appleGivenName').validate();
    lastName = sharedPref.getString('appleFamilyName').validate();
  }
  Map req = {
    "email": currentUser.email,
    "login_type": loginType,
    "user_type": RIDER,
    "first_name": firstName,
    "last_name": lastName,
    "username": currentUser.email,
    "uid": currentUser.uid,
    'accessToken': accessToken,
    "player_id": sharedPref.getString(PLAYER_ID).validate(),
    if (!currentUser.phoneNumber.isEmptyOrNull) 'contact_number': currentUser.phoneNumber.validate(),
  };

  await logInApi(req, isSocialLogin: true).then((value) async {
    AuthServices authService = AuthServices();
    authService.loginFromFirebaseUser(currentUser, loginDetail: value, fullName: (firstName + lastName).toLowerCase()).then((value) {});
    Navigator.pop(getContext);
    sharedPref.setString(UID, currentUser.uid);
    await appStore.setUserProfile(currentUser.photoURL.toString());
    await sharedPref.setString(USER_PROFILE_PHOTO, currentUser.photoURL.toString());
    if (value.data!.contactNumber.isEmptyOrNull) {
      launchScreen(getContext, EditProfileScreen(isGoogle: true), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
    } else {
      if (value.data!.uid.isEmptyOrNull) {
        File? imgFile;
        try {
          Directory tempDir = await getTemporaryDirectory();
          String filePath = '${tempDir.path}/downloaded_image.jpg';
          var response = await http.get(Uri.parse(currentUser.photoURL.toString()));
          if (response.statusCode == 200) {
            imgFile = File(filePath);
            await imgFile.writeAsBytes(response.bodyBytes);
            return imgFile;
          } else {
            imgFile = null;
          }
        } catch (e) {
          imgFile = null;
        }
        await updateProfile(
          uid: sharedPref.getString(UID).toString(),
          userEmail: currentUser.email.validate(),
          file: imgFile != null ? imgFile : null,
        ).then((value) {
          launchScreen(getContext, DashBoardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
        }).catchError((error) {
          log(error.toString());
        });
      } else if (value.data!.playerId.isEmptyOrNull) {
        await updatePlayerId().then((value) {
          launchScreen(getContext, DashBoardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
        }).catchError((error) {
          log(error.toString());
        });
      } else {
        launchScreen(getContext, DashBoardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
      }
    }
  }).catchError((e) async {
    log(e.toString());
    try {
      await _auth.signOut();
    } catch (_) {}
    throw e;
  });
}
