"""Remplace le bloc de données de index.html par le contenu d'un fichier data.js."""
import re, sys
html = open("index.html", encoding="utf-8").read()
data = open(sys.argv[1], encoding="utf-8").read().strip()
html = re.sub(r"/\*__DATA_START__\*/.*?/\*__DATA_END__\*/",
              lambda m: "/*__DATA_START__*/\n" + data + "\n/*__DATA_END__*/", html, flags=re.S)
open("index.html", "w", encoding="utf-8").write(html)
