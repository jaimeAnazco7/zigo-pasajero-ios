import 'package:flutter/material.dart';

import '../../main.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/DataProvider.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/LiveStream.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/app_textfield.dart';
import '../utils/Extensions/dataTypeExtensions.dart';

class CancelOrderDialog extends StatefulWidget {
  static String tag = '/CancelOrderDialog';

  final Function(String)? onCancel;
  /// Búsqueda de conductor sin aceptación: solo "Ya no necesito un viaje".
  final bool waitingForDriverOnly;

  CancelOrderDialog({this.onCancel, this.waitingForDriverOnly = false});

  @override
  CancelOrderDialogState createState() => CancelOrderDialogState();
}

class CancelOrderDialogState extends State<CancelOrderDialog> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController reasonController = TextEditingController();
  String? reason;
  int selectedReason = 0;
  late List<String> cancelReasonList;
  late FocusNode myFocusNode;

  List<String> _buildReasonList() {
    if (widget.waitingForDriverOnly) {
      return [language.noNeedRide];
    }
    return getCancelReasonList();
  }

  @override
  void initState() {
    myFocusNode = FocusNode();
    cancelReasonList = _buildReasonList();
    super.initState();
    init();
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    super.dispose();
  }

  Future<void> init() async {
    LiveStream().on('UpdateLanguage', (p0) {
      cancelReasonList = _buildReasonList();
      selectedReason = 0;
      setState(() {});
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: SizedBox(
            child: Padding(
              padding: const EdgeInsets.only(left: 0, right: 0, top: 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(language.cancelRide, style: boldTextStyle(size: 18)),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(Icons.clear),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < cancelReasonList.length; i++)
                            RadioListTile(
                              value: i,
                              groupValue: selectedReason,
                              onChanged: (value) {
                                selectedReason = value ?? -1;
                                if (selectedReason != -1 && cancelReasonList[selectedReason] == language.others) {
                                  myFocusNode.requestFocus();
                                }
                                setState(() {});
                              },
                              title: Text(cancelReasonList[i]),
                              activeColor: primaryColor,
                              contentPadding: EdgeInsets.zero,
                              visualDensity: VisualDensity(vertical: VisualDensity.minimumDensity, horizontal: VisualDensity.minimumDensity),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          if (selectedReason != -1 && cancelReasonList[selectedReason] == language.others)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: AppTextField(
                                focus: myFocusNode,
                                controller: reasonController,
                                textFieldType: TextFieldType.OTHER,
                                maxLength: 1000,
                                decoration: inputDecoration(context, label: language.writeReasonHere),
                                maxLines: 3,
                                minLines: 3,
                                validator: (value) {
                                  if (value!.isEmpty) return language.thisFieldRequired;
                                  return null;
                                },
                              ),
                            ),
                          if (selectedReason != -1 && cancelReasonList[selectedReason] == language.others) SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AppButtonWidget(
                        onTap: () {
                          if (formKey.currentState!.validate()) {
                            widget.onCancel?.call(selectedReason != -1 && cancelReasonList[selectedReason] != language.others ? cancelReasonList[selectedReason].validate() : reasonController.text);
                          }
                        },
                        text: language.submit,
                        color: primaryColor,
                        textStyle: boldTextStyle(color: Colors.white),
                        width: MediaQuery.of(context).size.width,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
