import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';
import 'store.dart';
import 'theme.dart';
import 'ui/confetti.dart';
import 'ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'fr_FR';
  await initializeDateFormatting('fr_FR');
  final prefs = await SharedPreferences.getInstance();
  final state = AppState(LocalAbsenceStore(prefs), prefs);
  runApp(GuideApp(state: state));
}

class GuideApp extends StatelessWidget {
  const GuideApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Le Guide des Congés',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Les confettis passent au-dessus de tout, boîtes de dialogue comprises.
      builder: (context, child) => Stack(children: [
        ?child,
        Positioned.fill(child: IgnorePointer(child: ConfettiLayer(trigger: state.confetti))),
      ]),
      home: HomePage(state: state),
    );
  }
}
