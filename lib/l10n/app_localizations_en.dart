// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get support_resources_header => 'External Routing';

  @override
  String get support_resources_intro =>
      'External routing channels. Aegis does not operate medical, legal, or clinical services.';

  @override
  String get support_emergency_line =>
      'If someone is in immediate danger, contact emergency services. Aegis cannot respond to emergencies.';

  @override
  String get terms_of_use_label => 'Terms of Use';

  @override
  String get privacy_notice_label => 'Privacy Notice';

  @override
  String get anchor_motto_latin => 'Ancoram Teneo';

  @override
  String get anchor_motto_translation => 'I Hold The Anchor';

  @override
  String get dictionaryTitle => 'Dictionary';

  @override
  String get dictionarySearchHint => 'Search roles';

  @override
  String get dictionaryClose => 'Close';

  @override
  String get dictionaryNoResults => 'No matching entries.';
}
