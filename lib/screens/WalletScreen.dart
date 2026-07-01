import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:taxi_booking/utils/Extensions/dataTypeExtensions.dart';

import '../../main.dart';
import '../../network/RestApis.dart';
import '../model/UserDetailModel.dart';
import '../model/WalletListModel.dart';
import '../screens/WithDrawScreen.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/app_textfield.dart';
import 'BankInfoScreen.dart';
import 'PaymentScreen.dart';

class WalletScreen extends StatefulWidget {
  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController addMoneyController = TextEditingController();
  ScrollController scrollController = ScrollController();
  int currentPage = 1;
  int totalPage = 1;

  int currentIndex = -1;

  List<WalletModel> walletData = [];

  num totalAmount = 0;

  UserBankAccount? userBankAccount;

  @override
  void initState() {
    super.initState();
    init();
    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        if (currentPage < totalPage) {
          appStore.setLoading(true);
          currentPage++;
          setState(() {});

          init();
        }
      }
    });
    afterBuildCreated(() => appStore.setLoading(true));
  }

  void init() async {
    getBankDetail();
    getWalletListApi();
  }

  getWalletListApi() async {
    await getWalletList(page: currentPage).then((value) {
      appStore.setLoading(false);

      currentPage = value.pagination!.currentPage!;
      totalPage = value.pagination!.totalPages!;
      if (value.walletBalance != null) totalAmount = value.walletBalance!.totalAmount!;
      if (currentPage == 1) {
        walletData.clear();
      }
      walletData.addAll(value.data ?? []);
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  getBankDetail() async {
    await getUserDetail(userId: sharedPref.getInt(USER_ID)).then((value) {
      userBankAccount = value.data!.userBankAccount;
      setState(() {});
    }).then((value) {
      log(value);
    });
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
        title: Text(language.wallet, style: boldTextStyle(color: appTextPrimaryColorWhite)),
      ),
      body: Observer(builder: (context) {
        return Stack(
          children: [
            SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.only(left: 16, top: 30, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: neonAccent,
                        borderRadius: BorderRadius.circular(defaultRadius),
                        border: Border.all(color: neonHighlight.withOpacity(0.5), width: 1),
                        boxShadow: [
                          BoxShadow(color: neonAccent.withOpacity(0.28), blurRadius: 12, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(language.availableBalance, style: secondaryTextStyle(color: neonOnAccent.withOpacity(0.92))),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              printAmountWidget(amount: totalAmount.toStringAsFixed(digitAfterDecimal), size: 22, color: neonOnAccent),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  Text(language.recentTransactions, style: boldTextStyle(color: Colors.white, size: 16)),
                  AnimationLimiter(
                    child: ListView.builder(
                      padding: EdgeInsets.only(top: 8, bottom: 8),
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: walletData.length,
                      shrinkWrap: true,
                      itemBuilder: (_, index) {
                        WalletModel data = walletData[index];

                        return AnimationConfiguration.staggeredList(
                          delay: Duration(milliseconds: 200),
                          position: index,
                          duration: Duration(milliseconds: 375),
                          child: SlideAnimation(
                            child: Container(
                              margin: EdgeInsets.only(top: 8, bottom: 8),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: neonSurfaceCard,
                                border: Border.all(color: neonAccent.withOpacity(0.38), width: 1),
                                borderRadius: BorderRadius.circular(defaultRadius),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(defaultRadius),
                                      color: neonAccent.withOpacity(0.12),
                                      border: Border.all(color: neonAccent.withOpacity(0.35)),
                                    ),
                                    padding: EdgeInsets.all(8),
                                    child: Icon(
                                      data.type == CREDIT ? Icons.add : Icons.remove,
                                      color: data.type == CREDIT ? neonAccent : neonError,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data.type == DEBIT ? language.moneyDebit : language.moneyDeposited,
                                          style: boldTextStyle(color: Colors.white, size: 16),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          printDate(data.createdAt!),
                                          style: secondaryTextStyle(color: neonHighlight.withOpacity(0.88), size: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "${data.type == CREDIT ? "+" : "-"} ",
                                        style: boldTextStyle(color: data.type == CREDIT ? neonAccent : neonError),
                                      ),
                                      printAmountWidget(
                                        amount: " ${data.amount!.toStringAsFixed(digitAfterDecimal)}",
                                        color: data.type == CREDIT ? neonAccent : neonError,
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
            Visibility(
              visible: appStore.isLoading,
              child: loaderWidget(),
            ),
            !appStore.isLoading && walletData.isEmpty ? emptyWidget() : SizedBox(),
          ],
        );
      }),
      bottomNavigationBar: SafeScaffoldBottomBar(
        child: Container(
          color: neonBackground,
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              if (totalAmount > 0)
                Expanded(
                  child: AppButtonWidget(
                    text: language.withDraw,
                    width: MediaQuery.of(context).size.width,
                    onTap: () async {
                      if (userBankAccount != null && userBankAccount!.accountNumber.validate().isNotEmpty) {
                        launchScreen(
                            context,
                            WithDrawScreen(
                              bankInfo: userBankAccount!,
                              onTap: () {
                                init();
                              },
                            ));
                      } else {
                        toast(language.missingBankDetail);
                        await launchScreen(context, BankInfoScreen());
                        getBankDetail();
                      }
                    },
                  ),
                ),
              if (totalAmount > 0) SizedBox(width: 16),
              Expanded(
                child: AppButtonWidget(
                  text: language.addMoney,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: neonBackground,
                      barrierColor: Colors.black54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(defaultRadius),
                          topRight: Radius.circular(defaultRadius),
                        ),
                        side: BorderSide(color: neonAccent.withOpacity(0.35), width: 1),
                      ),
                      builder: (_) {
                        return Form(
                          key: formKey,
                          child: StatefulBuilder(
                            builder: (BuildContext context, StateSetter setState) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(language.addMoney, style: boldTextStyle(color: Colors.white)),
                                          CloseButton(
                                            color: neonHighlight,
                                            onPressed: () {
                                              Navigator.pop(context);
                                              addMoneyController.clear();
                                              currentIndex = -1;
                                            },
                                          )
                                        ],
                                      ),
                                      AppTextField(
                                        controller: addMoneyController,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                                        ],
                                        textFieldType: TextFieldType.PHONE,
                                        keyboardType: TextInputType.number,
                                        errorThisFieldRequired: language.thisFieldRequired,
                                        cursorColor: neonAccent,
                                        textStyle: primaryTextStyle(color: Colors.white),
                                        onChanged: (val) {
                                          //
                                        },
                                        validator: (String? val) {
                                          if (appStore.minAmountToAdd != null && num.parse(val!) < appStore.minAmountToAdd!) {
                                            addMoneyController.text = appStore.minAmountToAdd.toString();
                                            addMoneyController.selection = TextSelection.fromPosition(TextPosition(offset: appStore.minAmountToAdd.toString().length));
                                            return "${language.minimum} ${appStore.minAmountToAdd} ${language.required}";
                                          } else if (appStore.maxAmountToAdd != null && num.parse(val!) > appStore.maxAmountToAdd!) {
                                            addMoneyController.text = appStore.maxAmountToAdd.toString();
                                            addMoneyController.selection = TextSelection.fromPosition(TextPosition(offset: appStore.maxAmountToAdd.toString().length));
                                            return "${language.maximum} ${appStore.maxAmountToAdd} ${language.required}";
                                          }
                                          return null;
                                        },
                                        decoration: inputDecorationNeonForm(context, label: language.amount),
                                      ),
                                      SizedBox(height: 16),
                                      Wrap(
                                        runSpacing: 8,
                                        spacing: 8,
                                        children: appStore.walletPresetTopUpAmount.split('|').map((e) {
                                          final idx = appStore.walletPresetTopUpAmount.split('|').indexOf(e);
                                          final sel = currentIndex == idx;
                                          return inkWellWidget(
                                            onTap: () {
                                              currentIndex = idx;
                                              if (appStore.minAmountToAdd != null && num.parse(e) < appStore.minAmountToAdd!) {
                                                addMoneyController.text = appStore.minAmountToAdd.toString();
                                                addMoneyController.selection = TextSelection.fromPosition(TextPosition(offset: appStore.minAmountToAdd.toString().length));
                                                toast("${language.minimum} ${appStore.minAmountToAdd} ${language.required}");
                                              } else if (appStore.minAmountToAdd != null &&
                                                  num.parse(e) < appStore.minAmountToAdd! &&
                                                  appStore.maxAmountToAdd != null &&
                                                  num.parse(e) > appStore.maxAmountToAdd.toString().length) {
                                                addMoneyController.text = appStore.maxAmountToAdd.toString();
                                                addMoneyController.selection = TextSelection.fromPosition(TextPosition(offset: e.length));
                                                toast("${language.maximum} ${appStore.maxAmountToAdd} ${language.required}");
                                              } else {
                                                addMoneyController.text = e;
                                                addMoneyController.selection = TextSelection.fromPosition(TextPosition(offset: e.length));
                                              }

                                              setState(() {});
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: sel ? neonAccent : neonSurfaceCard,
                                                border: Border.all(
                                                  color: sel ? neonAccent : neonAccent.withOpacity(0.4),
                                                ),
                                                borderRadius: BorderRadius.circular(defaultRadius),
                                              ),
                                              child: printAmountWidget(
                                                amount: e,
                                                color: sel ? neonOnAccent : neonHighlight,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      SizedBox(height: 16),
                                      AppButtonWidget(
                                        text: language.addMoney,
                                        width: MediaQuery.of(context).size.width,
                                        onTap: () async {
                                          if (addMoneyController.text.isNotEmpty) {
                                            if (formKey.currentState!.validate() && addMoneyController.text.isNotEmpty) {
                                              Navigator.pop(context);
                                              bool res = await launchScreen(
                                                  context,
                                                  PaymentScreen(amount: num.parse(addMoneyController.text)),
                                                  pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                                              if (res == true) {
                                                getWalletListApi();
                                              }
                                              addMoneyController.clear();
                                              currentIndex = -1;
                                            } else {
                                              toast(language.pleaseSelectAmount);
                                            }
                                          } else {
                                            toast(language.pleaseSelectAmount);
                                          }
                                        },
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
