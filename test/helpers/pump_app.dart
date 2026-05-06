import 'package:anxiety_anchor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Pumps [child] into a [MaterialApp] that mirrors production localization setup.
///
/// Use in tests as: `await pumpApp(tester, MyWidget());`
///
/// For widgets that already include a [Scaffold] (e.g. [ResourcesScreen]), prefer
/// [pumpMaterialAppWithL10n] with `home:` to avoid nested scaffolds.
Future<void> pumpApp(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Full [MaterialApp] with localization — use when you need [routes], [home], or [initialRoute].
///
/// Provide either [home] or [initialRoute] (not both), matching [MaterialApp] rules.
Future<void> pumpMaterialAppWithL10n(
  WidgetTester tester, {
  Widget? home,
  String? initialRoute,
  Map<String, WidgetBuilder>? routes,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
      initialRoute: initialRoute,
      routes: routes ?? const {},
    ),
  );
  await tester.pumpAndSettle();
}
