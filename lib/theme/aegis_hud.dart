import 'package:flutter/material.dart';

/// Height of the global AEGIS HUD overlay drawn in [MaterialApp.builder]
/// (shield + label, below the status bar). Screens whose titles start at
/// the top of the SafeArea must reserve this or they clip the logo.
const double kAegisHudReserve = 42.0;

/// App bar that sits *below* the HUD instead of sharing its band.
PreferredSizeWidget aegisHudAppBar({
  required Widget title,
  List<Widget>? actions,
  Widget? leading,
  Color backgroundColor = const Color(0xFF0A0A0A),
  bool centerTitle = true,
}) {
  return PreferredSize(
    key: const Key('aegis_hud_app_bar'),
    preferredSize: const Size.fromHeight(kToolbarHeight + kAegisHudReserve),
    child: ColoredBox(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.only(top: kAegisHudReserve),
        child: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          toolbarHeight: kToolbarHeight,
          // Theme sets toolbarHeight 0 and title color transparent so the
          // global HUD can own the top band. Force a real toolbar here.
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 2,
            fontFamily: 'RobotoMono',
          ),
          centerTitle: centerTitle,
          leading: leading,
          title: title,
          actions: actions,
        ),
      ),
    ),
  );
}
