#!/usr/bin/env python3
import argparse, json, zipfile, tempfile, shutil, re
from datetime import datetime
from pathlib import Path

def read_export_root(path: Path) -> Path:
    if path.is_file() and path.suffix.lower() == ".zip":
        tmp = Path(tempfile.mkdtemp(prefix="chatgpt_export_"))
        with zipfile.ZipFile(path, 'r') as z: z.extractall(tmp)
        return tmp
    return path

def iter_conversation_jsons(root: Path):
    singles = list(root.rglob("conversations.json"))
    if singles:
        for conv in json.loads(singles[0].read_text(encoding="utf-8")): yield conv; return
    conv_dirs = [p for p in root.rglob("conversations") if p.is_dir()]
    if conv_dirs:
        for p in sorted(conv_dirs[0].glob("*.json")):
            try: yield json.loads(p.read_text(encoding="utf-8"))
            except: pass
        return
    raise FileNotFoundError("conversations.json も conversations/*.json も見つかりません")

def safe_name(s:str)->str:
    s=re.sub(r'[\\/:*?"<>|]+','',s); s=re.sub(r'\s+','-',s); return s[:80]

def get_datetime(conv:dict)->datetime:
    ct=conv.get("create_time");  ms=conv.get("create_time_ms")
    if ct: 
        try: return datetime.fromtimestamp(ct)
        except: pass
    if ms:
        try: from datetime import datetime as dt; return datetime.fromtimestamp(int(ms)/1000)
        except: pass
    return datetime.now()

def extract_texts(conv:dict)->str:
    texts=[]
    mapping=conv.get("mapping")
    if mapping:
        for node in mapping.values():
            msg=node.get("message") if isinstance(node,dict) else None
            if not msg: continue
            content=msg.get("content") or {}
            parts=content.get("parts")
            if parts: texts.append("\n".join(str(p) for p in parts))
            elif "text" in content: texts.append(str(content["text"]))
    else:
        for msg in conv.get("messages",[]):
            content=msg.get("content") or {}
            if isinstance(content,dict) and "text" in content: texts.append(str(content["text"]))
            elif isinstance(content,list):
                for it in content:
                    if isinstance(it,dict):
                        t=it.get("text") or it.get("value")
                        if t: texts.append(str(t))
    return "\n\n".join(t.replace("\r","") for t in texts)

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("export_path")
    ap.add_argument("out_dir")
    ap.add_argument("--max-chars",type=int,default=4000)
    a=ap.parse_args()
    root=read_export_root(Path(a.export_path).expanduser())
    out_dir=Path(a.out_dir).expanduser(); out_dir.mkdir(parents=True,exist_ok=True)
    c=0
    for conv in iter_conversation_jsons(root):
        title=conv.get("title") or conv.get("gizmo",{}).get("title") or "untitled"
        dt=get_datetime(conv); body=extract_texts(conv)
        if len(body)>a.max_chars: body=body[:a.max_chars]+" …(略)"
        fname=f"{dt:%Y%m%d}-{safe_name(title)}.md"
        md="\n".join([
            f"# {title}", f"date: {dt:%Y-%m-%d %H:%M}", "",
            "## Summary", body, "", "## Link",
            f"conversation_id: {conv.get('conversation_id','')}" if conv.get("conversation_id") else ""
        ])
        (out_dir/fname).write_text(md,encoding="utf-8"); c+=1
    print(f"Created {c} files in {out_dir}")
    if root.name.startswith("chatgpt_export_"): shutil.rmtree(root,ignore_errors=True)

if __name__=="__main__": main()
