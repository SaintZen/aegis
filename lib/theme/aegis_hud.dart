import 'package:flutter/material.dart';

/// Height of the global AEGIS HUD overlay drawn in [MaterialApp.builder]
/// (shield + label, below the status bar). Screens whose titles start at
/// the top of the SafeArea must reserve this or they clip the logo.
const double kAegisHudReserve = 42.0;

/// App bar that sits *below* the HUD instead of sharing its band.
PreferredSizeWidget aegisHudAppBar({
  required Widget title,
  List<Widget>? actions,
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
          centerTitle: centerTitle,
          title: title,
          actions: actions,
        ),
      ),
    ),
  );
}
