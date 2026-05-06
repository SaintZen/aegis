import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anxiety_anchor/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:anxiety_anchor/screens/anxiety_lab_screen.dart';
import 'package:anxiety_anchor/screens/advocacy_screen.dart';
import 'package:anxiety_anchor/screens/audio_player_screen.dart';
import 'package:anxiety_anchor/screens/four_gates_screen.dart';
import 'package:anxiety_anchor/screens/calibration_screen.dart';
import 'package:anxiety_anchor/screens/bridge_screen.dart';
import 'package:anxiety_anchor/screens/circuit_breaker_screen.dart';
import 'package:anxiety_anchor/screens/frost_screen.dart';
import 'package:anxiety_anchor/screens/hollow_screen.dart';
import 'package:anxiety_anchor/screens/home_screen.dart';
import 'package:anxiety_anchor/screens/fiduciary_truth_screen.dart';
import 'package:anxiety_anchor/screens/island_screen.dart';
import 'package:anxiety_anchor/screens/kinetic_voice_drills_screen.dart';
import 'package:anxiety_anchor/screens/kinetic_armory_screen.dart';
import 'package:anxiety_anchor/screens/kinetic_action_screen.dart';
import 'package:anxiety_anchor/screens/safety_gate_screen.dart';
import 'package:anxiety_anchor/services/calibration_service.dart';
import 'package:anxiety_anchor/screens/system_initialization_screen.dart';
import 'package:anxiety_anchor/screens/personal_audio_library_screen.dart';
import 'package:anxiety_anchor/screens/resource_detail_screen.dart';
import 'package:anxiety_anchor/screens/resources_screen.dart';
import 'package:anxiety_anchor/widgets/dictionary_screen.dart';
import 'package:anxiety_anchor/screens/rescue_breathing_screen.dart';
import 'package:anxiety_anchor/screens/rules_of_engagement_screen.dart';
import 'package:anxiety_anchor/screens/sonic_pharmacy.dart';
import 'package:anxiety_anchor/screens/success_screen.dart';
import 'package:anxiety_anchor/screens/terms_of_use_screen.dart';
import 'package:anxiety_anchor/screens/privacy_policy_screen.dart';
import 'package:anxiety_anchor/screens/tabs/affirmations_tab.dart';
import 'package:anxiety_anchor/screens/tabs/pmr_body_scan_tab.dart';
import 'package:anxiety_anchor/screens/unified_exercise_screen.dart';
import 'package:anxiety_anchor/screens/vault_lock_screen.dart';
import 'package:anxiety_anchor/screens/wall_pushes_screen.dart';
import 'package:anxiety_anchor/screens/worry_vault_screen.dart';
import 'package:anxiety_anchor/screens/wormhole_screen.dart';
import 'package:anxiety_anchor/lifelines/not_today_screen.dart';
import 'package:anxiety_anchor/models/exercise.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CalibrationService.preload();
  runApp(const AnxietyAnchorApp());
}

class AnxietyAnchorApp extends StatelessWidget {
  const AnxietyAnchorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: CalibrationService.highVisibilityNotifier,
      builder: (context, highVisibility, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: CalibrationService.sootheModeNotifier,
          builder: (context, sootheMode, _) {
            return MaterialApp(
              theme: _buildTheme(highVisibility: highVisibility, sootheMode: sootheMode),
              localizationsDelegates:
                  AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const LegalGate(),
              builder: (context, child) {
                if (child == null) return const SizedBox.shrink();
                return Stack(
                  children: [
                    child,
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: Builder(
                            builder: (ctx) => _AegisHudHeader(context: ctx),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              routes: {
                '/calibration': (_) => const CalibrationScreen(),
                '/bridge': (_) => const BridgeScreen(),
                '/vault': (_) => const WorryVaultScreen(),
                '/scraper': (_) => const FrostScreen(),
                '/hollow': (_) => const HollowScreen(),
                '/pharmacy': (_) => const SonicPharmacyScreen(),
                '/audio-library': (_) => const PersonalAudioLibraryScreen(),
                '/resource-detail': (_) => const ResourceDetailScreen(),
                '/resources': (_) => const ResourcesScreen(),
                '/dictionary': (_) => const DictionaryScreen(),
                '/not-today': (_) => const NotTodayScreen(),
                '/pmr-body': (_) => Scaffold(
                      appBar: AppBar(title: const Text('PMR & Body')),
                      body: const PmrBodyScanTab(),
                    ),
                '/wall-pushes': (_) => const WallPushesScreen(),
                '/kinetic-voice': (_) => const KineticVoiceDrillsScreen(),
                '/kinetic-armory': (_) => const KineticArmoryScreen(),
                '/advocacy': (_) => const AdvocacyScreen(),
                '/fiduciary-truth': (_) => const FiduciaryTruthScreen(),
                '/rules-of-engagement': (_) => const RulesOfEngagementScreen(),
                '/four-gates': (_) => const FourGatesScreen(),
                '/wormhole': (_) => const WormholeScreen(),
                '/circuit-breaker': (_) => const CircuitBreakerScreen(),
                '/lab': (_) => const AnxietyLabScreen(),
                '/island': (_) => const IslandScreen(),
                '/home': (_) => const HomeScreen(),
                '/terms-of-use': (_) => const TermsOfUseScreen(),
                '/privacy': (_) => const PrivacyPolicyScreen(),
                '/affirmations': (_) => Scaffold(
                      appBar: AppBar(title: const Text('Affirmations')),
                      body: const AffirmationsTab(),
                    ),
              },
              onGenerateRoute: _onGenerateRoute,
            );
          },
        );
      },
    );
  }

  static ThemeData _buildTheme({required bool highVisibility, required bool sootheMode}) {
    // Monochrome palette: Obsidian, Slate, Silver — zero indigo/blue for panic-friendly mode
    const obsidian = Color(0xFF0A0A0A);
    const obsidianMid = Color(0xFF1A1A1A);
    const slate = Color(0xFF4A5568);
    const slateDark = Color(0xFF2D3748);
    const silver = Color(0xFF94A3B8);
    const silverLight = Color(0xFFCBD5E1);

    const baseBody = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 14,
      fontFamily: 'Inter',
    );
    final bodyLarge = highVisibility
        ? baseBody.copyWith(
            color: const Color(0xFFFFFFFF),
            shadows: [
              Shadow(color: Colors.black, blurRadius: 2, offset: const Offset(0, 1)),
              Shadow(color: Colors.black54, blurRadius: 4, offset: const Offset(0, 2)),
            ],
          )
        : baseBody.copyWith(color: Colors.white70);
    final bodyMedium = highVisibility
        ? baseBody.copyWith(
            color: const Color(0xFFFFFFFF),
            shadows: [
              Shadow(color: Colors.black, blurRadius: 2, offset: const Offset(0, 1)),
              Shadow(color: Colors.black54, blurRadius: 4, offset: const Offset(0, 2)),
            ],
          )
        : baseBody.copyWith(color: Colors.white70);
    final bodySmall = highVisibility
        ? baseBody.copyWith(
            color: const Color(0xFFFFFFFF),
            shadows: [
              Shadow(color: Colors.black, blurRadius: 2, offset: const Offset(0, 1)),
              Shadow(color: Colors.black54, blurRadius: 4, offset: const Offset(0, 2)),
            ],
          )
        : baseBody.copyWith(color: Colors.white60);

    return ThemeData(
        brightness: Brightness.dark,
        primaryColor: sootheMode ? silver : const Color(0xFFFFBF00),
        scaffoldBackgroundColor: sootheMode ? obsidian : const Color(0xFF121212),
        cardColor: sootheMode ? obsidianMid : const Color(0xFF1A1A1A),
        colorScheme: sootheMode
            ? const ColorScheme.dark(
                primary: Color(0xFF94A3B8),
                secondary: Color(0xFFCBD5E1),
                surface: Color(0xFF1A1A1A),
              )
            : const ColorScheme.dark(
                primary: Color(0xFFFFBF00),
                secondary: Color(0xFF00FFFF),
                surface: Color(0xFF1A1A1A),
              ),
        textTheme: TextTheme(
          displayLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontFamily: 'Roboto',
          ),
          displayMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontFamily: 'Roboto',
          ),
          displaySmall: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontFamily: 'Roboto',
          ),
          headlineMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontFamily: 'Roboto',
          ),
          headlineSmall: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontFamily: 'Roboto',
          ),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontFamily: 'Roboto',
          ),
          titleMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontFamily: 'Roboto',
          ),
          titleSmall: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontFamily: 'Roboto',
          ),
          bodyLarge: bodyLarge,
          bodyMedium: bodyMedium,
          bodySmall: bodySmall,
        ),
        cardTheme: CardThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          shadowColor: Colors.black45,
          color: Colors.white.withOpacity(0.05),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 0,
          foregroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: Colors.transparent),
          titleTextStyle: TextStyle(
            color: Colors.transparent,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 2,
            fontFamily: 'Roboto',
          ),
        ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/rescue-breathing':
        final preset = _readPreset(settings.arguments);
        return MaterialPageRoute(
          builder: (_) => RescueBreathingScreen(preset: preset),
        );
      case '/audio-player':
        final args = settings.arguments as Map<dynamic, dynamic>?;
        final track = args?['track'] as String?;
        final title = args?['title'] as String?;
        if (track == null || title == null) {
          return _buildMissingArgsRoute('Audio player');
        }
        return MaterialPageRoute(
          builder: (_) => AudioPlayerScreen(track: track, title: title),
        );
      case '/exercise-detail':
        final exercise = settings.arguments as Exercise?;
        if (exercise == null) {
          return _buildMissingArgsRoute('Exercise detail');
        }
        return MaterialPageRoute(
          builder: (_) => UnifiedExerciseScreen(exercise: exercise),
        );
      case '/blackout':
        final args = settings.arguments as Map<dynamic, dynamic>?;
        final initialLoad = args?['initialLoad'] as num?;
        final durationSeconds = args?['durationSeconds'] as int?;
        if (initialLoad == null || durationSeconds == null) {
          return _buildMissingArgsRoute('Blackout');
        }
        return MaterialPageRoute(
          builder: (_) => BlackoutCountdownScreen(
            initialLoad: initialLoad.toDouble(),
            durationSeconds: durationSeconds,
          ),
        );
      case '/kinetic-action':
        final exerciseType = settings.arguments as String?;
        if (exerciseType == null) {
          return _buildMissingArgsRoute('Kinetic action');
        }
        return MaterialPageRoute(
          builder: (_) => KineticActionScreen(exerciseType: exerciseType),
        );
      case '/success':
        final args = settings.arguments as Map<dynamic, dynamic>?;
        final tool = args?['tool'] as String?;
        final initialStressLevel = args?['initialStressLevel'] as num?;
        if (tool == null || initialStressLevel == null) {
          return _buildMissingArgsRoute('Success');
        }
        return MaterialPageRoute(
          builder: (_) => SuccessScreen(
            tool: tool,
            initialStressLevel: initialStressLevel.toDouble(),
          ),
        );
      case '/vault-lock':
        final routeName = settings.arguments as String?;
        if (routeName == null) {
          return _buildMissingArgsRoute('Vault lock');
        }
        return MaterialPageRoute(
          builder: (context) => VaultLockScreen(
            onAuthenticated: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, routeName);
            },
          ),
        );
    }
    return null;
  }

  String? _readPreset(Object? arguments) {
    if (arguments is String) return arguments;
    if (arguments is Map) return arguments['preset'] as String?;
    return null;
  }

  Route<dynamic> _buildMissingArgsRoute(String label) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            '$label route arguments missing.',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }
}

class _AegisHudHeader extends StatelessWidget {
  const _AegisHudHeader({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(this.context);
    final accent = theme.colorScheme.primary;
    final textColor = theme.colorScheme.primary == const Color(0xFF94A3B8)
        ? const Color(0xFF94A3B8)
        : Colors.white70;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, size: 18, color: accent),
        const SizedBox(width: 8),
        Text(
          'AEGIS',
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }
}

class LegalGate extends StatefulWidget {
  const LegalGate({super.key});

  @override
  State<LegalGate> createState() => _LegalGateState();
}

class _LegalGateState extends State<LegalGate> {
  bool _hasAgreed = false;
  bool _assetsBootstrapped = false;
  bool _initChecked = false;
  bool _systemInitialized = false;

  @override
  void initState() {
    super.initState();
    unawaited(CalibrationService.preload());
    _bootstrapVideoAssets();
    _loadInitializationState();
    _loadSafetyGateState();
  }

  Future<void> _loadSafetyGateState() async {
    final accepted = await SafetyGateScreen.hasAccepted();
    if (mounted && accepted) {
      setState(() => _hasAgreed = true);
    }
  }

  Future<void> _loadInitializationState() async {
    final prefs = await SharedPreferences.getInstance();
    final initialized = prefs.getBool('system_initialized') ?? false;
    if (mounted) {
      setState(() {
        _systemInitialized = initialized;
        _initChecked = true;
      });
    }
  }

  Future<void> _bootstrapVideoAssets() async {
    try {
      if (kIsWeb) {
        return;
      }
      final directory = await getApplicationDocumentsDirectory();
      await _copyAssetIfMissing(
        assetPath: 'assets/videos/monastery.mp4',
        targetPath: '${directory.path}/monastery.mp4',
      );
      await _copyAssetIfMissing(
        assetPath: 'assets/videos/desert_oasis.mp4',
        targetPath: '${directory.path}/desert_oasis.mp4',
      );
      await _copyAssetIfMissing(
        assetPath: 'assets/videos/mountain_bell.mp4',
        targetPath: '${directory.path}/mountain_bell.mp4',
      );
      await _copyAssetIfMissing(
        assetPath: 'assets/videos/vault_door.mp4',
        targetPath: '${directory.path}/vault_door.mp4',
      );
      for (var i = 1; i <= 19; i++) {
        final frame =
            'assets/images/frost/frost_screen_${i.toString().padLeft(2, '0')}.jpg';
        await _copyAssetIfMissing(
          assetPath: frame,
          targetPath:
              '${directory.path}/frost_screen_${i.toString().padLeft(2, '0')}.jpg',
        );
      }
    } catch (e) {
      debugPrint('Asset bootstrap error: $e');
    } finally {
      if (mounted) {
        setState(() => _assetsBootstrapped = true);
      }
    }
  }

  Future<void> _copyAssetIfMissing({
    required String assetPath,
    required String targetPath,
  }) async {
    final file = File(targetPath);
    if (await file.exists() && await file.length() > 0) {
      return;
    }
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAgreed) {
      return SafetyGateScreen(
        onAccepted: () => setState(() => _hasAgreed = true),
      );
    }
    if (!_assetsBootstrapped) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white70),
        ),
      );
    }
    if (!_initChecked) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white70),
        ),
      );
    }
    if (!_systemInitialized) {
      return SystemInitializationScreen(
        onComplete: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('system_initialized', true);
          if (!mounted) return;
          setState(() => _systemInitialized = true);
        },
      );
    }
    return const MainTabController();
  }

}

class MainTabController extends StatefulWidget {
  const MainTabController({super.key});

  @override
  State<MainTabController> createState() => _MainTabControllerState();
}

class _MainTabControllerState extends State<MainTabController> {
  int _selectedIndex = 0;

  // Four pillars: 0 Anchor, 1 Vistas, 2 Lab, 3 Bridge (MAINTENANCE / LEDGER opens stacked tabs)
  static const List<Widget> _pages = [
    HomeScreen(),             // 0: Anchor Pillar — anchor + breathing
    IslandScreen(),           // 1: Vista Pillar — Vistas, Kinetic, Affirmations
    AnxietyLabScreen(),       // 2: Lab Pillar — Hollow, Void, Vault, Frost
    BridgeScreen(),           // 3: Bridge — monolith; ledger tabs from MAINTENANCE / LEDGER
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final hideBottomNav = isLandscape && _selectedIndex == 1;
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: hideBottomNav
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: BottomNavigationBar(
                      currentIndex: _selectedIndex,
                      onTap: _onItemTapped,
                      selectedItemColor: Colors.white,
                      unselectedItemColor: Colors.white54,
                      backgroundColor: Colors.transparent,
                      type: BottomNavigationBarType.fixed,
                      elevation: 0,
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.anchor),
                          label: 'Anchor',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.landscape_outlined),
                          label: 'Vistas',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.science_outlined),
                          label: 'Lab',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.handshake_outlined),
                          label: 'Bridge',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
