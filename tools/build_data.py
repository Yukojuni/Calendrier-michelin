"""Convertit le JSON extrait du .docx (tools/extract.py) en lib/data/planning_data.dart.

Usage : python3 tools/extract.py planning.docx data.json && python3 tools/build_data.py data.json
"""
import json, sys, pathlib
CODES = {"Entreprise": "E", "École": "S", "École : Examen": "X", "École : Cours": "C", "Férié": "F",
         "TT/congés": "T", "Congé": "K", "TT": "t", "Comité fin d'année": "E",
         "À confirmer · exam ou entreprise": "E", "—": "-"}
d = json.load(open(sys.argv[1], encoding="utf-8"))
people = d["people"]
lines = ["// Fichier généré par tools/build_data.py : ne pas modifier à la main.",
         "// Une lettre par personne et par jour, dans l'ordre de kPeopleRaw :",
         "// E entreprise, S école, X examen, C cours, F férié, T TT/congé, K congé, t télétravail, - pas dans l'équipe.",
         "", "const List<String> kPeopleRaw = ["]
lines += [f"  {json.dumps(p, ensure_ascii=False)}," for p in people]
lines += ["];", "", "const Map<String, String> kDays = {"]
for k, row in sorted(d["days"].items()):
    lines.append(f"  '{k}': '{''.join(CODES[row.get(p, '—')] for p in people)}',")
lines += ["};", ""]
out = pathlib.Path("lib/data/planning_data.dart"); out.parent.mkdir(parents=True, exist_ok=True)
out.write_text("\n".join(lines), encoding="utf-8")
print(f"{out} : {len(people)} personnes, {len(d['days'])} jours")
