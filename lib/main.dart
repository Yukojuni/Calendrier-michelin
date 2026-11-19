import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_state.dart';
import 'games/score_store.dart';
import 'store.dart';
import 'theme.dart';
import 'ui/confetti.dart';
import 'ui/home_page.dart';
import 'ui/intro_trailer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'fr_FR';
  await initializeDateFormatting('fr_FR');
  final prefs = await SharedPreferences.getInstance();
  final (store, scores) = await _openStores(prefs);
  final state = AppState(store, prefs, scores: scores);
  runApp(GuideApp(state: state));
}

/// Configuration Supabase, passée à la compilation :
/// `--dart-define-from-file=supabase.json` (voir supabase.example.json).
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

/// Stockage partagé Supabase si configuré, sinon stockage sur l'appareil.
Future<(AbsenceStore, ScoreStore)> _openStores(SharedPreferences prefs) async {
  if (_supabaseUrl.isEmpty || _supabaseKey.isEmpty) return (LocalAbsenceStore(prefs), LocalScoreStore(prefs));
  await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseKey);
  final db = Supabase.instance.client;
  return (SupabaseAbsenceStore(db), SupabaseScoreStore(db));
}

class GuideApp extends StatelessWidget {
  const GuideApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Le Guide des Congés',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      darkTheme: buildTheme(),
      themeMode: ThemeMode.dark,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Les confettis passent au-dessus de tout, boîtes de dialogue comprises.
      builder: (context, child) => Stack(children: [
        ?child,
        Positioned.fill(child: IgnorePointer(child: ConfettiLayer(trigger: state.confetti))),
        const Positioned.fill(child: IntroTrailer()),
      ]),
      home: HomePage(state: state),
    );
  }
}
