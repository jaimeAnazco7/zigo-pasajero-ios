/// Normaliza celular Perú a E.164 sin espacios: `+51` + 9 dígitos (Firebase Auth).
String? buildPeruMobileE164(String rawLocalNumber) {
  var digits = rawLocalNumber.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  if (digits.startsWith('51') && digits.length >= 11) {
    digits = digits.substring(2);
  }
  if (digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  if (digits.length > 9) {
    digits = digits.substring(digits.length - 9);
  }
  if (digits.length != 9) return null;
  return '+51$digits';
}

/// Parte nacional (9 dígitos) desde un E.164 peruano `+51xxxxxxxxx`.
String? nationalDigitsFromPeruE164(String e164) {
  final t = e164.trim().replaceAll(' ', '');
  if (t.startsWith('+51') && t.length == 12) {
    return t.substring(3);
  }
  if (t.startsWith('51') && t.length == 11) {
    return t.substring(2);
  }
  return null;
}
