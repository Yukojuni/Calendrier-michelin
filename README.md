# Le Guide des Congés

Calendrier de présence interactif de l'équipe alternance (nov. 2026 → août 2028).
Chacun choisit son nom, puis clique sur ses journées « Entreprise » pour poser un congé
ou du télétravail, ou pose une période complète depuis le panneau de droite.

- `index.html` : le site (une seule page, aucune dépendance). Publié en artifact claude.ai,
  les congés sont partagés en direct entre tout le monde ; ouvert en local, ils restent
  enregistrés dans le navigateur.
- `tools/extract.py` : lit le .docx du planning et produit un JSON (`python3 tools/extract.py planning.docx data.json`).
- `tools/build_data.py` + `tools/inject.py` : régénèrent les données intégrées à `index.html`
  (`python3 tools/build_data.py data.json > data.js && python3 tools/inject.py data.js`).
