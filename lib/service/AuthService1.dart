import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../main.dart';
import '../model/LoginResponse.dart';
import '../network/RestApis.dart';
import '../screens/DashBoardScreen.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class AuthServices {
  Future<User?> createAuthUser(String? email, String? password, bool isOtpLogin) async {
    try {
      if (!isOtpLogin) {
        final UserCredential value = await _auth.createUserWithEmailAndPassword(email: email!, password: password!);
        return value.user;
      }
      return _auth.currentUser;
    } on FirebaseException catch (error) {
      if (error.code == "ERROR_EMAIL_ALREADY_IN_USE" || error.code == "account-exists-with-different-credential" || error.code == "email-already-in-use") {
        try {
          final UserCredential value = await _auth.signInWithEmailAndPassword(email: email!, password: password!);
          return value.user;
        } catch (e) {
          toast(getMessageFromErrorCode(error));
          return null;
        }
      }
      toast(getMessageFromErrorCode(error));
      return null;
    } catch (e) {
      toast(e.toString());
      return null;
    }
  }

  Future<void> signUpWithEmailPassword(
    context, {
    String? email,
    String? password,
    String? mobileNumber,
    String? fName,
    String? lName,
    String? userName,
    String? userType,
    bool isOtpLogin = false,
  }) async {
    try {
      final User? user = await createAuthUser(email, password, isOtpLogin);
      if (user == null) {
        appStore.setLoading(false);
        toast('No se pudo crear la sesión. Intenta iniciar sesión.');
        return;
      }

      UserModel userModel = UserModel();
      userModel.uid = user.uid.validate();
      userModel.email = email;
      userModel.contactNumber = mobileNumber.validate();
      userModel.username = userName.validate();
      userModel.userType = userType.validate();
      userModel.displayName = fName.validate() + " " + lName.validate();
      userModel.firstName = fName.validate();
      userModel.lastName = lName.validate();
      userModel.createdAt = Timestamp.now().toDate().toString();
      userModel.updatedAt = Timestamp.now().toDate().toString();
      userModel.playerId = sharedPref.getString(PLAYER_ID).validate();
      await sharedPref.setString(UID, user.uid.validate());

      try {
        await userService.addDocumentWithCustomId(user.uid, userModel.toJson());
      } catch (e) {
        log('Firestore user doc: $e');
        // Continuar: el usuario ya existe en Laravel; no bloquear el login.
      }

      if (isOtpLogin) {
        appStore.setLoading(false);
        updateProfileUid();
        launchScreen(context, DashBoardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
        return;
      }

      Map request = {
        "email": userModel.email,
        "password": password,
        "player_id": sharedPref.getString(PLAYER_ID).validate(),
        'user_type': RIDER,
      };

      await logInApi(request);
      appStore.setLoading(false);
      updateProfileUid();
      launchScreen(context, DashBoardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
    } on FirebaseException catch (error) {
      appStore.setLoading(false);
      toast(getMessageFromErrorCode(error));
    } catch (e) {
      appStore.setLoading(false);
      log(e.toString());
      toast(e.toString());
    }
  }

  Future<void> loginFromFirebaseUser(User currentUser, {LoginResponse? loginDetail, String? fullName}) async {
    UserModel userModel = UserModel();
    if (await userService.isUserExist(loginDetail!.data!.email)) {
      ///Return user data
      await userService.userByEmail(loginDetail.data!.email).then((user) async {
        userModel = user;
        appStore.setUserEmail(userModel.email.validate());
        appStore.setUId(userModel.uid.validate());

        // await updateUserData(user);
      }).catchError((e) {
        log(e);
        throw e;
      });
    } else {
      /// Create user
      userModel.uid = currentUser.uid.validate();
      userModel.id = loginDetail.data!.id;
      userModel.email = loginDetail.data!.email.validate();
      userModel.username = loginDetail.data!.username.validate();
      userModel.contactNumber = loginDetail.data!.contactNumber.validate();
      userModel.username = loginDetail.data!.username.validate();
      userModel.email = loginDetail.data!.email.validate();

      if (Platform.isIOS) {
        userModel.username = fullName;
      } else {
        userModel.username = loginDetail.data!.username.validate();
      }

      userModel.contactNumber = loginDetail.data!.contactNumber.validate();
      userModel.profileImage = loginDetail.data!.profileImage.validate();
      userModel.playerId = sharedPref.getString(PLAYER_ID);

      sharedPref.setString(UID, currentUser.uid.validate());
      log(sharedPref.getString(UID));
      sharedPref.setString(USER_EMAIL, userModel.email.validate());
      sharedPref.setBool(IS_LOGGED_IN, true);

      log(userModel.toJson());

      await userService.addDocumentWithCustomId(currentUser.uid, userModel.toJson()).then((value) {
        //
      }).catchError((e) {
        throw e;
      });
    }
  }

  Future deleteUserFirebase() async {
    if (FirebaseAuth.instance.currentUser != null) {
      FirebaseAuth.instance.currentUser!.delete();
      await FirebaseAuth.instance.signOut();
    }
  }

// Future<void> updateUserData(UserModel user) async {
//   userService.updateDocument({
//     'player_id': sharedPref.getString(PLAYER_ID),
//     'updatedAt': Timestamp.now(),
//   }, user.uid);
// }
// Future<void> signInWithEmailPassword(context, {required String email, required String password}) async {
//   await _auth.signInWithEmailAndPassword(email: email, password: password).then((value) async {
//     appStore.setLoading(true);
//     final User user = value.user!;
//     UserModel userModel = await userService.getUser(email: user.email);
//     //await updateUserData(userModel);
//
//     appStore.setLoading(true);
//     //Login Details to SharedPreferences
//     sharedPref.setString(UID, userModel.uid.validate());
//     sharedPref.setString(USER_EMAIL, userModel.email.validate());
//     sharedPref.setBool(IS_LOGGED_IN, true);
//
//     //Login Details to AppStore
//     appStore.setUserEmail(userModel.email.validate());
//     appStore.setUId(userModel.uid.validate());
//
//     //
//   }).catchError((e) {
//     toast(e.toString());
//     log(e.toString());
//   });
// }
}
