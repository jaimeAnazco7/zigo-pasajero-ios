import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/Colors.dart';
import '../utils/Extensions/app_common.dart';

class AppTheme {
  //
  AppTheme._();

  /// Tema principal — Neon Steel Blue (UI oscura coherente con acento teal).
  static final ThemeData lightTheme = ThemeData(
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: neonAccent,
      selectionHandleColor: neonAccent,
      selectionColor: neonAccent.withOpacity(0.35),
    ),
    primarySwatch: createMaterialColor(neonAccent),
    primaryColor: neonAccent,
    scaffoldBackgroundColor: neonBackground,
    fontFamily: GoogleFonts.play().fontFamily,
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: neonBackground,
      selectedItemColor: neonAccent,
      unselectedItemColor: neonHighlight.withOpacity(0.55),
      type: BottomNavigationBarType.fixed,
    ),
    iconTheme: IconThemeData(color: neonHighlight),
    textTheme: TextTheme(
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: neonHighlight),
    ),
    dialogBackgroundColor: neonSurfaceCard,
    unselectedWidgetColor: neonHighlight.withOpacity(0.6),
    dividerColor: dividerColor,
    cardColor: neonSurfaceCard,
    listTileTheme: ListTileThemeData(iconColor: neonAccent),
    dialogTheme: DialogTheme(shape: dialogShape()),
    appBarTheme: AppBarTheme(
      backgroundColor: neonSurfaceCard,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: neonHighlight),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: GoogleFonts.play().fontFamily,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: neonAccent,
      onPrimary: neonOnAccent,
      secondary: neonHighlight,
      onSecondary: neonOnAccent,
      surface: neonSurfaceCard,
      onSurface: Colors.white,
      error: neonError,
      onError: Colors.white,
    ),
  ).copyWith(
    pageTransitionsTheme: PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primarySwatch: createMaterialColor(neonAccent),
    primaryColor: neonAccent,
    scaffoldBackgroundColor: neonBackground,
    fontFamily: GoogleFonts.nunito().fontFamily,
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: neonBackground,
      selectedItemColor: neonAccent,
      unselectedItemColor: neonHighlight.withOpacity(0.5),
      type: BottomNavigationBarType.fixed,
    ),
    iconTheme: IconThemeData(color: neonHighlight),
    textTheme: TextTheme(
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: neonHighlight),
    ),
    dialogBackgroundColor: neonSurfaceCard,
    unselectedWidgetColor: neonHighlight.withOpacity(0.55),
    dividerColor: dividerColor.withOpacity(0.35),
    cardColor: neonSurfaceCard,
    dialogTheme: DialogTheme(shape: dialogShape()),
    appBarTheme: AppBarTheme(
      backgroundColor: neonSurfaceCard,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: neonHighlight),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: GoogleFonts.nunito().fontFamily,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: neonAccent,
      onPrimary: neonOnAccent,
      secondary: neonHighlight,
      onSecondary: neonOnAccent,
      surface: neonSurfaceCard,
      onSurface: Colors.white,
      error: neonError,
      onError: Colors.white,
    ),
  ).copyWith(
    pageTransitionsTheme: PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
