"""Convertit le JSON extrait du .docx en données compactes pour index.html."""
import json, sys
CODES = {"Entreprise":"E","École":"S","École : Examen":"X","École : Cours":"C","Férié":"F",
         "TT/congés":"T","Congé":"K","TT":"t","Comité fin d'année":"M",
         "À confirmer · exam ou entreprise":"Q","—":"-"}
d = json.load(open(sys.argv[1]))
people = d["people"]
days = {k: "".join(CODES[row.get(p, "—")] for p in people) for k, row in sorted(d["days"].items())}
print("const PEOPLE=" + json.dumps(people, ensure_ascii=False) + ";")
print("const DAYS=" + json.dumps(days, separators=(",", ":")) + ";")
