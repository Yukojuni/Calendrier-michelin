# Le Guide des Congés

Planning de présence de l'équipe alternance (nov. 2026 → août 2028), en **Flutter** :
une seule base de code pour le **site web** et les **apps iOS et Android**.

Chacun choisit son nom, puis sélectionne ses journées « Entreprise » pour poser un congé
ou du télétravail. Il y a aussi un encart « Aujourd'hui », le compte à rebours du départ de Quentin et
un formulaire pour les longues périodes.
Une « Salle d'arcade » propose deux mini-jeux (Attrape Quentin, Route des congés) avec un classement d'équipe.

## Lancer en local

```bash
flutter pub get
flutter run -d chrome          # web
flutter run                    # téléphone ou émulateur branché
flutter test                   # tests
```

Version de Flutter utilisée : **3.47.9** (stable).

## Base de données (Supabase)

1. Créer un projet sur supabase.com.
2. Dans **SQL Editor**, coller et lancer `supabase/schema.sql` (crée les tables `absences` et `scores`, leurs règles et le temps réel).
3. Récupérer dans **Project Settings > API** l'URL du projet et la **clé publishable** (`sb_publishable_…`).
   Cette clé est faite pour être embarquée dans l'app ; ne jamais utiliser la clé *secret* / *service_role*.
4. En local : copier `supabase.example.json` en `supabase.json` (ignoré par git), le remplir, puis
   `flutter run --dart-define-from-file=supabase.json`.
5. Sur Netlify : ajouter les variables `SUPABASE_URL` et `SUPABASE_PUBLISHABLE_KEY`
   (Site configuration > Environment variables), puis redéployer.

Sans configuration, l'app enregistre les congés sur l'appareil.

## Déploiement web (Netlify)

`netlify.toml` lance `tools/netlify_build.sh`, qui installe Flutter et compile vers `build/web`.
Rien à régler côté Netlify.

## Apps mobiles

Pour les apps, ajouter `--dart-define-from-file=supabase.json` aux commandes de build.

- **Android** : `flutter build appbundle` puis envoi sur la Google Play Console (compte développeur : 25 $ une fois).
- **iOS** : il faut un Mac avec Xcode et un compte Apple Developer (99 $/an) : `flutter build ipa` puis envoi sur App Store Connect.

Identifiant de l'app : `com.calendrieralternant.calendrier_alternant`.

## Organisation du code

- `lib/data/planning_data.dart` : planning d'origine (généré, ne pas modifier à la main).
- `lib/planning.dart` : règles (qui est où, ce qu'on peut modifier), photos de profil.
- `lib/store.dart` : stockage des congés. **Supabase** (partagé, temps réel) si configuré,
  sinon sur l'appareil.
- `lib/app_state.dart` : état de l'app. `lib/ui/` : écrans.
- `assets/photos/` : photos de profil (prénom en minuscules).

## Mettre à jour le planning depuis le .docx

```bash
python3 tools/extract.py planning.docx data.json
python3 tools/build_data.py data.json      # régénère lib/data/planning_data.dart
python3 tools/make_icons.py                # régénère les icônes si besoin
```
