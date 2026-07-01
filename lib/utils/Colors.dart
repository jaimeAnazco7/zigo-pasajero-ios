import 'package:flutter/material.dart';

// --- ZIGO Neon Steel Blue (alineado app conductor Mighty Taxi) ---
// No importar main.dart aquí: evita dependencia circular.

/// Fondo principal oscuro
const Color neonBackground = Color(0xFF01203d);

/// Acento / neón
const Color neonAccent = Color(0xFF18e8bc);

/// Celeste highlights / texto secundario sobre oscuro
const Color neonHighlight = Color(0xFFc6f7fd);

/// Texto sobre botón con relleno acento
const Color neonOnAccent = Color(0xFF01203d);

/// Tarjeta / superficie sobre el fondo oscuro
const Color neonSurfaceCard = Color(0xFF082f4d);

/// Error (armonizado con paleta neón)
const Color neonError = Color(0xFFFF4D8C);

/// Color primario de la app (Material, acentos)
Color primaryColor = neonAccent;

/// **Sin cambios:** rutas en mapa (Google Maps).
const polyLineColor = Color.fromARGB(255, 33, 83, 229);

/// Bordes generales (ligero acento)
Color borderColor = const Color(0x6618e8bc);

const scaffoldSecondaryDark = neonSurfaceCard;
const scaffoldColorDark = neonBackground;
const scaffoldColorLight = Colors.white;
const appButtonColorDark = neonSurfaceCard;

/// Divisores (acento suave)
const dividerColor = Color(0x3318e8bc);

/// Texto principal en superficies claras / contraste
const textPrimaryColor = neonOnAccent;

/// Texto secundario (UI clara)
const textSecondaryColor = Color(0xFF5c6f76);

const viewLineColor = Color(0xFFEAEAEA);

Color appBarBackgroundColorGlobal = neonBackground;
Color appButtonBackgroundColorGlobal = primaryColor;
Color defaultAppButtonTextColorGlobal = neonOnAccent;
const Color appButtonTextStyleColor = neonOnAccent;
const appTextPrimaryColorWhite = Colors.white;

// --- Compatibilidad: código legado que usaba naranja / amarillo ZIGO ---
const zigoOrange = neonAccent;
const zigoOrangeLight = neonHighlight;
const zigoYellow = neonHighlight;
