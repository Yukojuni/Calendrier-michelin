import sys, docx, json, re, collections
d = docx.Document(sys.argv[1])
MONTHS = {m:i+1 for i,m in enumerate("Janvier Février Mars Avril Mai Juin Juillet Août Septembre Octobre Novembre Décembre".split())}
heads=[p.text.strip() for p in d.paragraphs if p.text.strip()]
tables=[t for t in d.tables if len(t.rows)>1]
assert len(heads)==len(tables), (len(heads),len(tables))
out={"people":[], "days":{}}
statuses=collections.Counter(); people=[]
for h,t in zip(heads,tables):
    mname,year=h.split(); year=int(year)
    hdr=[c.text.strip() for c in t.rows[0].cells]
    names=hdr[1:-2]
    for n in names:
        if n not in people: people.append(n)
    for r in t.rows[1:]:
        cells=[c.text.strip() for c in r.cells]
        m=re.search(r'(\d\d)/(\d\d)',cells[0]); dd,mm=int(m[1]),int(m[2])
        assert mm==MONTHS[mname]
        key=f"{year}-{mm:02d}-{dd:02d}"
        row={}
        for n,v in zip(names,cells[1:-2]):
            statuses[v]+=1; row[n]=v
        out["days"][key]=row
out["people"]=people
print(people, len(out["days"]), file=sys.stderr)
print(statuses, file=sys.stderr)
json.dump(out, open(sys.argv[2],"w"), ensure_ascii=False)
