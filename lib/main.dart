import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';
import 'games/score_store.dart';
import 'remote.dart';
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

/// Adresse de l'API (netlify/functions/api.mts).
/// - Web : le site appelle sa propre adresse `/api/`, rien à configurer.
/// - Apps iOS / Android : `--dart-define=API_URL=https://calendrier-alternant.netlify.app/api`.
const _apiUrl = String.fromEnvironment('API_URL');

Uri? _apiBase() {
  if (_apiUrl.isNotEmpty) return Uri.parse(_apiUrl);
  if (!kIsWeb) return null;
  final host = Uri.base.host;
  // En développement local, pas de serveur : stockage sur l'appareil.
  if (host == 'localhost' || host == '127.0.0.1') return null;
  return Uri.base.resolve('/api/');
}

/// Stockage partagé via l'API Netlify si elle est joignable, sinon stockage sur l'appareil.
Future<(AbsenceStore, ScoreStore)> _openStores(SharedPreferences prefs) async {
  final base = _apiBase();
  if (base == null) return (LocalAbsenceStore(prefs), LocalScoreStore(prefs));
  final api = ApiClient(base);
  return (HttpAbsenceStore(api), HttpScoreStore(api));
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
