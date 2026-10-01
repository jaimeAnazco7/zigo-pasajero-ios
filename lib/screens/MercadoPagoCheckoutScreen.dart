import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_booking/network/RestApis.dart';
import 'package:taxi_booking/utils/Colors.dart';
import 'package:taxi_booking/utils/Common.dart';
import 'package:taxi_booking/utils/Extensions/AppButtonWidget.dart';
import 'package:taxi_booking/utils/Extensions/app_common.dart';
import 'package:taxi_booking/utils/Extensions/app_textfield.dart';
import 'package:taxi_booking/utils/Extensions/dataTypeExtensions.dart';

import '../../main.dart';

/// Checkout API Mercado Pago — recarga billetera (token en app, cobro en backend).
class MercadoPagoCheckoutScreen extends StatefulWidget {
  final num amount;
  final String? publicKey;

  MercadoPagoCheckoutScreen({required this.amount, this.publicKey});

  @override
  State<MercadoPagoCheckoutScreen> createState() => _MercadoPagoCheckoutScreenState();
}

class _MercadoPagoCheckoutScreenState extends State<MercadoPagoCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final cardNumberCont = TextEditingController();
  final expCont = TextEditingController();
  final cvvCont = TextEditingController();
  final nameCont = TextEditingController();
  final docNumberCont = TextEditingController();

  String publicKey = '';
  String docType = 'DNI';
  bool saveCard = true;
  bool loading = false;
  List<Map<String, dynamic>> savedCards = [];
  int? selectedSavedCardId;

  @override
  void initState() {
    super.initState();
    publicKey = widget.publicKey.validate();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => loading = true);
    try {
      if (publicKey.isEmpty) {
        final cfg = await mercadoPagoConfig();
        publicKey = (cfg['public_key'] ?? '').toString();
      }
      final cardsRes = await mercadoPagoCards();
      final list = cardsRes['data'];
      if (list is List) {
        savedCards = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      log(e.toString());
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    cardNumberCont.dispose();
    expCont.dispose();
    cvvCont.dispose();
    nameCont.dispose();
    docNumberCont.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _tokenizeNewCard() async {
    final number = cardNumberCont.text.replaceAll(' ', '');
    final parts = expCont.text.split('/');
    if (parts.length != 2) throw 'Fecha inválida (MM/AA)';
    final month = int.tryParse(parts[0].trim()) ?? 0;
    var year = int.tryParse(parts[1].trim()) ?? 0;
    if (year < 100) year += 2000;

    final body = {
      'card_number': number,
      'expiration_month': month,
      'expiration_year': year,
      'security_code': cvvCont.text.trim(),
      'cardholder': {
        'name': nameCont.text.trim(),
        'identification': {
          'type': docType,
          'number': docNumberCont.text.trim(),
        },
      },
    };

    final uri = Uri.parse('https://api.mercadopago.com/v1/card_tokens?public_key=$publicKey');
    final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    final json = jsonDecode(res.body);
    if (res.statusCode >= 300 || json['id'] == null) {
      throw (json['message'] ?? json['error'] ?? 'No se pudo tokenizar la tarjeta').toString();
    }
    return Map<String, dynamic>.from(json);
  }

  Future<Map<String, dynamic>> _tokenizeSavedCard(String mpCardId) async {
    final body = {
      'card_id': mpCardId,
      'security_code': cvvCont.text.trim(),
    };
    final uri = Uri.parse('https://api.mercadopago.com/v1/card_tokens?public_key=$publicKey');
    final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    final json = jsonDecode(res.body);
    if (res.statusCode >= 300 || json['id'] == null) {
      throw (json['message'] ?? json['error'] ?? 'No se pudo tokenizar la tarjeta guardada').toString();
    }
    return Map<String, dynamic>.from(json);
  }

  Future<Map<String, dynamic>?> _tokenizeExtraForSave() async {
    if (!saveCard || selectedSavedCardId != null) return null;
    try {
      return await _tokenizeNewCard();
    } catch (_) {
      return null;
    }
  }

  Future<void> _pay() async {
    if (publicKey.isEmpty) {
      toast('Mercado Pago sin public_key. Configúralo en el admin.');
      return;
    }
    if (selectedSavedCardId == null) {
      if (!_formKey.currentState!.validate()) return;
    } else if (cvvCont.text.trim().length < 3) {
      toast('Ingresa el CVV');
      return;
    }

    setState(() => loading = true);
    try {
      Map<String, dynamic> tokenJson;
      String? saveTokenId;

      if (selectedSavedCardId != null) {
        final card = savedCards.firstWhere((c) => c['id'] == selectedSavedCardId);
        tokenJson = await _tokenizeSavedCard(card['mp_card_id'].toString());
        final payRes = await mercadoPagoPaySavedCard({
          'amount': widget.amount,
          'card_id': selectedSavedCardId,
          'token': tokenJson['id'],
          'payment_method_id': tokenJson['payment_method_id'] ?? card['payment_method_id'] ?? 'visa',
          'installments': 1,
          'identification_type': docType,
          'identification_number': docNumberCont.text.trim().isEmpty ? '00000000' : docNumberCont.text.trim(),
        });
        if (payRes['ok'] == true) {
          toast(language.transactionSuccessful);
          if (mounted) Navigator.pop(context, true);
        } else {
          toast((payRes['message'] ?? language.transactionFailed).toString());
        }
      } else {
        tokenJson = await _tokenizeNewCard();
        // Segundo token opcional para guardar (el primero se consume en el pago)
        if (saveCard) {
          final extra = await _tokenizeExtraForSave();
          saveTokenId = extra?['id']?.toString();
        }
        final payRes = await mercadoPagoProcessPayment({
          'amount': widget.amount,
          'token': tokenJson['id'],
          'payment_method_id': tokenJson['payment_method_id'] ?? 'visa',
          'installments': 1,
          'issuer_id': tokenJson['issuer_id'],
          'identification_type': docType,
          'identification_number': docNumberCont.text.trim(),
          'cardholder_name': nameCont.text.trim(),
          'save_card': saveCard,
          if (saveTokenId != null) 'save_token': saveTokenId,
        });
        if (payRes['ok'] == true) {
          toast(language.transactionSuccessful);
          if (mounted) Navigator.pop(context, true);
        } else {
          toast((payRes['message'] ?? language.transactionFailed).toString());
        }
      }
    } catch (e) {
      toast(e.toString());
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mercado Pago', style: boldTextStyle(color: appTextPrimaryColorWhite)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recarga: ${appStore.currencyName} ${widget.amount}', style: boldTextStyle(size: 18)),
                  SizedBox(height: 16),
                  if (savedCards.isNotEmpty) ...[
                    Text('Tarjetas guardadas', style: boldTextStyle()),
                    SizedBox(height: 8),
                    ...savedCards.map((c) {
                      final selected = selectedSavedCardId == c['id'];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: primaryColor),
                        title: Text('${(c['payment_method_id'] ?? 'card').toString().toUpperCase()} •••• ${c['last_four'] ?? ''}'),
                        subtitle: Text('${c['expiration_month'] ?? ''}/${c['expiration_year'] ?? ''}'),
                        onTap: () => setState(() {
                          selectedSavedCardId = selected ? null : c['id'] as int?;
                        }),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () async {
                            try {
                              await mercadoPagoDeleteCard(c['id']);
                              savedCards.removeWhere((e) => e['id'] == c['id']);
                              if (selectedSavedCardId == c['id']) selectedSavedCardId = null;
                              setState(() {});
                            } catch (e) {
                              toast(e.toString());
                            }
                          },
                        ),
                      );
                    }),
                    Divider(),
                    TextButton(
                      onPressed: () => setState(() => selectedSavedCardId = null),
                      child: Text('Usar otra tarjeta', style: primaryTextStyle(color: primaryColor)),
                    ),
                    SizedBox(height: 8),
                  ],
                  if (selectedSavedCardId != null) ...[
                    AppTextField(
                      controller: cvvCont,
                      textFieldType: TextFieldType.OTHER,
                      decoration: inputDecoration(context, label: 'CVV'),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 12),
                    AppTextField(
                      controller: docNumberCont,
                      textFieldType: TextFieldType.OTHER,
                      decoration: inputDecoration(context, label: 'Nº documento (DNI)'),
                      keyboardType: TextInputType.number,
                    ),
                  ] else ...[
                    AppTextField(
                      controller: cardNumberCont,
                      textFieldType: TextFieldType.OTHER,
                      decoration: inputDecoration(context, label: 'Número de tarjeta'),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.length < 13) ? 'Tarjeta inválida' : null,
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: expCont,
                            textFieldType: TextFieldType.OTHER,
                            decoration: inputDecoration(context, label: 'MM/AA'),
                            inputFormatters: [LengthLimitingTextInputFormatter(5)],
                            keyboardType: TextInputType.datetime,
                            validator: (v) => (v == null || !v.contains('/')) ? 'MM/AA' : null,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: cvvCont,
                            textFieldType: TextFieldType.OTHER,
                            decoration: inputDecoration(context, label: 'CVV'),
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                            keyboardType: TextInputType.number,
                            validator: (v) => (v == null || v.length < 3) ? 'CVV' : null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    AppTextField(
                      controller: nameCont,
                      textFieldType: TextFieldType.NAME,
                      decoration: inputDecoration(context, label: 'Nombre en la tarjeta'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: docType,
                      decoration: inputDecoration(context, label: 'Tipo documento'),
                      items: ['DNI', 'CE', 'RUC', 'Otro'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => docType = v ?? 'DNI'),
                    ),
                    SizedBox(height: 12),
                    AppTextField(
                      controller: docNumberCont,
                      textFieldType: TextFieldType.OTHER,
                      decoration: inputDecoration(context, label: 'Nº documento'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Guardar tarjeta para próximas recargas', style: primaryTextStyle()),
                      value: saveCard,
                      activeColor: primaryColor,
                      onChanged: (v) => setState(() => saveCard = v),
                    ),
                  ],
                  SizedBox(height: 24),
                  AppButtonWidget(
                    text: 'Pagar ${appStore.currencyName} ${widget.amount}',
                    onTap: () {
                      if (!loading) _pay();
                    },
                  ),
                ],
              ),
            ),
          ),
          if (loading) loaderWidget(),
        ],
      ),
    );
  }
}
