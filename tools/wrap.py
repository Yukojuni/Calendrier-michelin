"""Produit dist/ : index.html enveloppé dans un squelette HTML complet + les photos (pour Netlify ou tout hébergeur statique)."""
import pathlib, shutil
src = pathlib.Path("index.html").read_text(encoding="utf-8")
head = ('<!doctype html><html lang="fr"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">'
        '<style>:root{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}'
        'body{margin:0}img{max-width:100%}[hidden]{display:none!important}</style></head><body>')
out = pathlib.Path("dist"); out.mkdir(exist_ok=True)
(out / "index.html").write_text(head + src + "</body></html>", encoding="utf-8")
if pathlib.Path("photos").is_dir():
    shutil.copytree("photos", out / "photos", dirs_exist_ok=True)
print("dist/ généré")
