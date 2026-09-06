"""Normal: cached guide only. --rescan: hash inventory and queue visual analysis.

After inspecting pending images, update the guide, then --accept-analysis.
Never marks an image analysed merely because it was scanned.
"""
import argparse, hashlib, json
from datetime import datetime, timezone
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
REF = ROOT / 'art/references'
MAN = REF / 'REFERENCE_MANIFEST.json'
GUIDE = REF / 'DUNGEON_STYLE_GUIDE.md'

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--rescan', action='store_true')
    p.add_argument('--accept-analysis', action='store_true')
    a = p.parse_args()
    if not a.rescan and not a.accept_analysis:
        print(GUIDE.read_text(encoding='utf-8') if GUIDE.exists() else 'No cached guide. Run --rescan and visually inspect pending references.')
        return
    old = json.loads(MAN.read_text()) if MAN.exists() else {}
    lookup = {r['relative_path']: r for r in old.get('references', [])}
    entries, pending = [], []
    for f in sorted((REF/'iron-soul-dungeon').rglob('*')):
        if f.suffix.lower() not in {'.png','.jpg','.jpeg','.webp'}: continue
        rel = f.relative_to(ROOT).as_posix()
        stat = f.stat()
        digest = hashlib.sha256(f.read_bytes()).hexdigest()
        prev = lookup.get(rel, {})
        changed = digest != prev.get('sha256')
        e = dict(relative_path=rel, size_bytes=stat.st_size, modified_time_ns=stat.st_mtime_ns,
                 modified_time=datetime.fromtimestamp(stat.st_mtime, timezone.utc).isoformat(),
                 sha256=digest, analysed=prev.get('analysed',False) and not changed,
                 analysed_at=prev.get('analysed_at') if not changed else None)
        if not e['analysed']: pending.append(rel)
        entries.append(e)
    removed = sorted(set(lookup)-{r['relative_path'] for r in entries})
    now = datetime.now(timezone.utc).isoformat()
    if a.accept_analysis:
        if not GUIDE.exists(): raise SystemExit('Write the visual observations to the style guide before accepting analysis.')
        # A changed file after scan must be inspected in a new scan first.
        if any(lookup.get(e['relative_path'],{}).get('sha256') != e['sha256'] for e in entries):
            raise SystemExit('Inventory changed since scan; rescan and inspect before accepting.')
        for e in entries:
            if not e['analysed']: e.update(analysed=True, analysed_at=now)
    signature = hashlib.sha256(json.dumps([(e['relative_path'],e['sha256']) for e in entries]).encode()).hexdigest()
    rebuild = signature != old.get('contact_sheet_signature') or not (REF/'reference_contact_sheet.jpg').exists()
    if rebuild:
        sheet = Image.new('RGB', (1800, ((len(entries)+2)//3)*370), '#171c23')
        d = ImageDraw.Draw(sheet)
        for i,e in enumerate(entries):
            with Image.open(ROOT/e['relative_path']) as im:
                tile = ImageOps.contain(im.convert('RGB'), (588,330))
            x,y = (i%3)*600, (i//3)*370
            sheet.paste(tile,(x+(600-tile.width)//2,y))
            d.text((x+8,y+334),f"{i+1:02d}  {Path(e['relative_path']).name}",fill='white')
        sheet.save(REF/'reference_contact_sheet.jpg',quality=94)
    result = dict(schema_version=1,last_scan=old.get('last_scan',now) if a.accept_analysis else now,
                  total_references=len(entries),new_changed_count=old.get('new_changed_count',len(pending)) if a.accept_analysis else len(pending),
                  pending_analysis=[] if a.accept_analysis else pending,removed_paths=removed,
                  contact_sheet_signature=signature,references=entries)
    MAN.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:v for k,v in result.items() if k!='references'},indent=2))

if __name__ == '__main__': main()
