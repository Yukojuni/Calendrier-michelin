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

## Données partagées (Netlify)

Les congés et les scores sont partagés via une petite API hébergée sur Netlify, gratuite :
`netlify/functions/api.mts` (Netlify Functions) stocke deux documents JSON dans **Netlify Blobs**.
Rien à créer ni à configurer : Netlify active Functions et Blobs tout seul au déploiement.

- Le site web appelle `/api` sur sa propre adresse.
- Pas de temps réel : l'app relit le planning toutes les 20 secondes et juste après chaque modification.
- Chaque écriture vérifie que personne n'a écrit entre-temps : deux modifications simultanées ne se perdent pas.
- L'API est ouverte (pas de comptes) : quiconque a l'adresse du site peut modifier le planning.

Tests de l'API : `npm install && npm test`.

En local, sans Netlify : `flutter build web --dart-define=API_URL=http://localhost:8787/api`
puis `node --experimental-strip-types tools/dev_server.mts` (données en mémoire).
Avec `flutter run -d chrome` (sans API), l'app enregistre sur l'appareil.

## Déploiement web (Netlify)

`netlify.toml` lance `tools/netlify_build.sh`, qui installe Flutter et compile vers `build/web`.
Rien à régler côté Netlify.

## Apps mobiles

Pour les apps, ajouter `--dart-define=API_URL=https://calendrier-alternant.netlify.app/api` aux commandes de build (sinon l'app enregistre sur l'appareil).

- **Android** : `flutter build appbundle` puis envoi sur la Google Play Console (compte développeur : 25 $ une fois).
- **iOS** : il faut un Mac avec Xcode et un compte Apple Developer (99 $/an) : `flutter build ipa` puis envoi sur App Store Connect.

Identifiant de l'app : `com.calendrieralternant.calendrier_alternant`.

## Organisation du code

- `lib/data/planning_data.dart` : planning d'origine (généré, ne pas modifier à la main).
- `lib/planning.dart` : règles (qui est où, ce qu'on peut modifier), photos de profil.
- `lib/store.dart`, `lib/remote.dart` : stockage des congés et des scores, via l'API Netlify ou sur l'appareil.
- `netlify/functions/api.mts` : l'API.
- `lib/app_state.dart` : état de l'app. `lib/ui/` : écrans.
- `assets/photos/` : photos de profil (prénom en minuscules).

## Mettre à jour le planning depuis le .docx

```bash
python3 tools/extract.py planning.docx data.json
python3 tools/build_data.py data.json      # régénère lib/data/planning_data.dart
python3 tools/make_icons.py                # régénère les icônes si besoin
```
