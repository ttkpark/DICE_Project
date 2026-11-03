"""1020_RISC 폴더 -> 1020_RISC.zip / 1020_RISC.tar.gz (서버 업로드용).  python make_pkg.py
   텍스트는 LF 로, .sh 는 755 로 넣는다. build/, 합성 work/, __pycache__, 이전 압축본은 제외."""
import io
import os
import tarfile
import time
import zipfile

ROOT = os.path.dirname(os.path.abspath(__file__))
NAME = os.path.basename(ROOT)
TEXT = (".v", ".sh", ".f", ".tcl", ".sdc", ".md", ".s", ".py", ".txt", ".hex", ".lst", ".json", ".csv", ".ps1")
SKIP_DIRS = {"build", "work", "__pycache__", ".git"}
SKIP_EXT = (".zip", ".tar.gz", ".tar", ".vcd", ".saif", ".fsdb", ".log")

files = []
for d, dirs, fs in os.walk(ROOT):
    dirs[:] = sorted(x for x in dirs if x not in SKIP_DIRS)
    for f in sorted(fs):
        if not f.endswith(SKIP_EXT):
            files.append(os.path.relpath(os.path.join(d, f), ROOT).replace(os.sep, "/"))
now = time.time()


def data(p):
    b = open(os.path.join(ROOT, p), "rb").read()
    return b.replace(b"\r\n", b"\n") if p.endswith(TEXT) else b


def mode(p):
    return 0o755 if p.endswith(".sh") else 0o644


with tarfile.open(os.path.join(ROOT, NAME + ".tar.gz"), "w:gz") as t:
    seen = set()
    for p in files:
        parts = (NAME + "/" + p).split("/")
        for i in range(1, len(parts)):
            d = "/".join(parts[:i])
            if d not in seen:
                ti = tarfile.TarInfo(d); ti.type = tarfile.DIRTYPE; ti.mode = 0o755; ti.mtime = now
                t.addfile(ti); seen.add(d)
        b = data(p)
        ti = tarfile.TarInfo(NAME + "/" + p); ti.size = len(b); ti.mode = mode(p); ti.mtime = now
        t.addfile(ti, io.BytesIO(b))

with zipfile.ZipFile(os.path.join(ROOT, NAME + ".zip"), "w", zipfile.ZIP_DEFLATED) as z:
    for p in files:
        zi = zipfile.ZipInfo(NAME + "/" + p, time.localtime(now)[:6])
        zi.compress_type = zipfile.ZIP_DEFLATED
        zi.create_system = 3
        zi.external_attr = (0o100000 | mode(p)) << 16
        z.writestr(zi, data(p))

print(len(files), "files ->", NAME + ".zip,", NAME + ".tar.gz")
