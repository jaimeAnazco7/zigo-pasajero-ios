import 'package:flutter/material.dart';

import '../../main.dart';
import '../../utils/Common.dart';
import '../../utils/Extensions/app_common.dart';
import '../languageConfiguration/LanguageDataConstant.dart';
import '../languageConfiguration/LanguageDefaultJson.dart';
import '../languageConfiguration/ServerLanguageResponse.dart';
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/LiveStream.dart';
import '../utils/Extensions/dataTypeExtensions.dart';

class LanguageScreen extends StatefulWidget {
  @override
  LanguageScreenState createState() => LanguageScreenState();
}

class LanguageScreenState extends State<LanguageScreen> {
  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  /// Solo etiqueta en pantalla (Perú / USA). La lógica sigue usando [LanguageJsonData.languageCode] como hasta ahora.
  String _countryLabelForLanguage(LanguageJsonData data) {
    final lang = (data.languageCode ?? '').toLowerCase().trim();
    if (lang.startsWith('en')) return 'USA';
    if (lang.startsWith('es')) return 'Perú';
    final cc = (data.countryCode ?? '').replaceAll('-', '_').toUpperCase();
    if (cc.contains('PE')) return 'Perú';
    if (cc.contains('US')) return 'USA';
    return data.languageName.validate();
  }

  /// Banderas emoji (🇺🇸 / 🇵🇪). Vacío → se usa la imagen del servidor.
  String _flagEmojiForLanguage(LanguageJsonData data) {
    final lang = (data.languageCode ?? '').toLowerCase().trim();
    if (lang.startsWith('en')) return '🇺🇸';
    if (lang.startsWith('es')) return '🇵🇪';
    final cc = (data.countryCode ?? '').replaceAll('-', '_').toUpperCase();
    if (cc.contains('PE')) return '🇵🇪';
    if (cc.contains('US')) return '🇺🇸';
    return '';
  }

  Widget _languageLeadingIcon(LanguageJsonData data) {
    final flag = _flagEmojiForLanguage(data);
    if (flag.isNotEmpty) {
      return SizedBox(
        width: 34,
        height: 34,
        child: Center(child: Text(flag, style: const TextStyle(fontSize: 26))),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: commonCachedNetworkImage(data.languageImage.validate(), width: 34, height: 34),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(language.language, style: boldTextStyle(color: neonHighlight)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Wrap(
          runSpacing: 12,
          spacing: 12,
          children: List.generate(defaultServerLanguageData!.length, (index) {
            LanguageJsonData data = defaultServerLanguageData![index];
            return inkWellWidget(
              onTap: () async {
                await setValue(SELECTED_LANGUAGE_CODE, data.languageCode);
                await setValue(SELECTED_LANGUAGE_COUNTRY_CODE, data.languageCode);
                selectedServerLanguageData = data;
                setValue(IS_SELECTED_LANGUAGE_CHANGE, true);
                setState(() {});
                LiveStream().emit(CHANGE_LANGUAGE);
                await appStore.setLanguage(data.languageCode!, context: context);
              },
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: (sharedPref.getString(SELECTED_LANGUAGE_CODE) ?? defaultLanguageCode) == data.languageCode ? primaryColor.withOpacity(0.6) : Colors.transparent,
                    border: Border.all(width: 0.4, color: textSecondaryColorGlobal),
                    borderRadius: radius()),
                width: (MediaQuery.of(context).size.width - 44) / 2,
                child: Row(
                  children: [
                    _languageLeadingIcon(data),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(child: Text(_countryLabelForLanguage(data), style: primaryTextStyle())),
                    sharedPref.getString(SELECTED_LANGUAGE_CODE).validateLanguage() == data.languageCode
                        ? Icon(Icons.radio_button_checked, size: 20, color: primaryColor)
                        : Icon(Icons.radio_button_off, size: 20, color: dividerColor),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
