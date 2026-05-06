import 'package:anxiety_anchor/models/shield_directory_entry.dart';

/// Shield directory: external routing index.
///
/// **Legal gate:** any row with `placeholder: true` is hidden from the
/// release-visible list ([shieldDirectoryLiveEntries]). Flip `placeholder` to
/// `false` only after the URL, phone, and copy have been vetted and signed off.
///
/// **Verification discipline:** re-verify URLs and phone numbers on a cadence
/// (e.g. quarterly). Update [_verifiedBaseline] when a sweep completes, or set
/// `verifiedAt` per-entry for finer-grained audit.
final DateTime _verifiedBaseline = DateTime.utc(2026, 4, 18);

/// All directory entries (including drafts / placeholders).
///
/// Use [shieldDirectoryLiveEntries] for anything user-facing.
final List<ShieldDirectoryEntry> shieldDirectoryEntries = [
  // ---- Crisis channels (immediate routing) --------------------------------
  ShieldDirectoryEntry(
    id: 'crisis_988',
    category: 'crisis_immediate',
    title: '988 Suicide & Crisis Lifeline',
    description: 'National lifeline. 24/7 voice/text routing.',
    url: 'https://988lifeline.org',
    phone: '988',
    sms: 'Text 988',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'crisis_text_line',
    category: 'crisis_immediate',
    title: 'Crisis Text Line',
    description: 'Text-based routing for acute states.',
    url: 'https://www.crisistextline.org',
    sms: 'Text HOME to 741741',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'crisis_veterans_line',
    category: 'crisis_immediate',
    title: 'Veterans Crisis Line',
    description: '24/7 routing for veterans, service members, families.',
    url: 'https://www.veteranscrisisline.net',
    phone: '988',
    sms: 'Text 838255',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'crisis_trevor',
    category: 'crisis_immediate',
    title: 'The Trevor Project',
    description: '24/7 routing for LGBTQ+ youth under 25.',
    url: 'https://www.thetrevorproject.org',
    phone: '1-866-488-7386',
    sms: 'Text START to 678-678',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'crisis_trans_lifeline',
    category: 'crisis_immediate',
    title: 'Trans Lifeline',
    description: 'Peer-staffed routing for trans callers.',
    url: 'https://translifeline.org',
    phone: '1-877-565-8860',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'crisis_dv_hotline',
    category: 'crisis_immediate',
    title: 'National Domestic Violence Hotline',
    description: '24/7 routing for domestic violence situations.',
    url: 'https://www.thehotline.org',
    phone: '1-800-799-7233',
    sms: 'Text START to 88788',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'crisis_rainn',
    category: 'crisis_immediate',
    title: 'RAINN',
    description: '24/7 routing for sexual violence aftermath.',
    url: 'https://www.rainn.org',
    phone: '1-800-656-4673',
    verifiedAt: _verifiedBaseline,
  ),

  // ---- School & district --------------------------------------------------
  ShieldDirectoryEntry(
    id: 'edu_ocr_complaint',
    category: 'education_school',
    title: 'U.S. Dept. of Education — OCR Complaint',
    description:
        'File a Title VI/IX/504 complaint against a school or district.',
    url: 'https://www2.ed.gov/about/offices/list/ocr/complaintintro.html',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'edu_parent_center_hub',
    category: 'education_school',
    title: 'Parent Center Hub',
    description: "Find your state's Parent Training & Information Center.",
    url: 'https://www.parentcenterhub.org/find-your-center/',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'edu_wrightslaw',
    category: 'education_school',
    title: 'Wrightslaw',
    description: 'Reference library for special education law.',
    url: 'https://www.wrightslaw.com',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'edu_state_doe_portal',
    category: 'education_school',
    title: 'State DOE Complaint Portal',
    description: 'State-specific Department of Education filing portal.',
    url: 'https://example.org/state-doe-portal',
    jurisdiction: 'state:XX',
    placeholder: true,
    verifiedAt: _verifiedBaseline,
  ),

  // ---- Veterans routing ---------------------------------------------------
  ShieldDirectoryEntry(
    id: 'vet_va_locator',
    category: 'veterans',
    title: 'VA Facility Locator',
    description: 'VA medical, clinic, and benefits site locator.',
    url: 'https://www.va.gov/find-locations',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'vet_vet_center',
    category: 'veterans',
    title: 'Vet Center Finder',
    description: 'Readjustment site locator (combat veterans and families).',
    url: 'https://www.va.gov/find-locations/?facilityType=vet_center',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'vet_vso_search',
    category: 'veterans',
    title: 'Accredited VSO Search',
    description: 'Accredited Veteran Service Officer lookup.',
    url: 'https://www.va.gov/vso/',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'vet_give_an_hour',
    category: 'veterans',
    title: 'Give an Hour',
    description: 'Pro-bono clinician network. Service members, families, others.',
    url: 'https://giveanhour.org',
    verifiedAt: _verifiedBaseline,
  ),

  // ---- Legal & civil rights ----------------------------------------------
  ShieldDirectoryEntry(
    id: 'legal_lawhelp',
    category: 'legal_civil_rights',
    title: 'LawHelp.org',
    description: 'Free civil legal help finder by state.',
    url: 'https://www.lawhelp.org',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'legal_lsc',
    category: 'legal_civil_rights',
    title: 'LSC — Get Legal Help',
    description: 'Legal aid locator via Legal Services Corporation.',
    url: 'https://www.lsc.gov/about-lsc/what-legal-aid/get-legal-help',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'legal_ada',
    category: 'legal_civil_rights',
    title: 'ADA.gov',
    description: 'Americans with Disabilities Act information and filing.',
    url: 'https://www.ada.gov',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'legal_eeoc',
    category: 'legal_civil_rights',
    title: 'EEOC',
    description: 'Workplace discrimination complaint channel.',
    url: 'https://www.eeoc.gov',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'legal_jan',
    category: 'legal_civil_rights',
    title: 'Job Accommodation Network (JAN)',
    description: 'Workplace accommodation guidance.',
    url: 'https://askjan.org',
    verifiedAt: _verifiedBaseline,
  ),

  // ---- Health routing ----------------------------------------------------
  ShieldDirectoryEntry(
    id: 'health_hrsa_center',
    category: 'health_routing',
    title: 'Find a Health Center (HRSA)',
    description: 'Federally qualified health center locator.',
    url: 'https://findahealthcenter.hrsa.gov',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'health_findtreatment',
    category: 'health_routing',
    title: 'FindTreatment.gov',
    description: 'SAMHSA treatment facility locator.',
    url: 'https://findtreatment.gov',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'health_samhsa_helpline',
    category: 'health_routing',
    title: 'SAMHSA Helpline',
    description: '24/7 routing for substance use and mental health.',
    url: 'https://www.samhsa.gov/find-help/helplines/national-helpline',
    phone: '1-800-662-4357',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'health_nami',
    category: 'health_routing',
    title: 'NAMI HelpLine',
    description: 'Information and navigation line, weekdays.',
    url: 'https://www.nami.org/help',
    phone: '1-800-950-6264',
    verifiedAt: _verifiedBaseline,
  ),

  // ---- Housing & benefits -------------------------------------------------
  ShieldDirectoryEntry(
    id: 'housing_benefits_gov',
    category: 'housing_benefits',
    title: 'Benefits.gov',
    description: 'Federal benefits eligibility finder.',
    url: 'https://www.benefits.gov',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'housing_hud_rental',
    category: 'housing_benefits',
    title: 'HUD Rental Assistance',
    description: 'HUD rental assistance information.',
    url: 'https://www.hud.gov/topics/rental_assistance',
    verifiedAt: _verifiedBaseline,
  ),
  ShieldDirectoryEntry(
    id: 'housing_211',
    category: 'housing_benefits',
    title: '211',
    description: 'Community service connection by ZIP.',
    url: 'https://www.211.org',
    phone: '211',
    verifiedAt: _verifiedBaseline,
  ),
];

/// Release-visible directory entries (filters out `placeholder: true`).
List<ShieldDirectoryEntry> get shieldDirectoryLiveEntries =>
    shieldDirectoryEntries.where((e) => !e.placeholder).toList(growable: false);

/// Section order for grouping in the UI.
const List<String> advocacySupportCategoryOrder = [
  'crisis_immediate',
  'education_school',
  'veterans',
  'legal_civil_rights',
  'health_routing',
  'housing_benefits',
];

/// UI labels for each [category] id (Aegis voice: routing, not "support").
const Map<String, String> advocacySupportCategoryLabels = {
  'crisis_immediate': 'Crisis channels',
  'education_school': 'School & district',
  'veterans': 'Veterans routing',
  'legal_civil_rights': 'Legal & civil rights',
  'health_routing': 'Health routing',
  'housing_benefits': 'Housing & benefits',
};

// ---------------------------------------------------------------------------
// Legacy shim
// ---------------------------------------------------------------------------
// Some older code and tests consume a `List<Map<String,String>>` named
// `advocacySupportLinks`. Keep a derived view so nothing breaks during the
// migration to `shieldDirectoryEntries`. New code should consume the typed
// entries directly.
final List<Map<String, String>> advocacySupportLinks = shieldDirectoryLiveEntries
    .map((e) => <String, String>{
          'id': e.id,
          'category': e.category,
          'title': e.title,
          'description': e.description,
          'url': e.url,
        })
    .toList(growable: false);
