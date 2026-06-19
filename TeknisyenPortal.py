import os
import json
import urllib.request
import subprocess
import sys
import ctypes
import tkinter as tk
from tkinter import ttk
import ssl
import time

# SSL bypass (kurumsal ağlar için)
ssl._create_default_https_context = ssl._create_unverified_context

BASE_DIR = os.path.dirname(os.path.abspath(sys.argv[0]))

APP_EXE = os.path.join(BASE_DIR, "WegaApp.exe")
NEW_EXE = os.path.join(BASE_DIR, "WegaApp_new.exe")
PART_FILE = NEW_EXE + ".part"
VERSION_FILE = os.path.join(BASE_DIR, "app_version.txt")

MANIFEST_URL = "https://raw.githubusercontent.com/maakay38/wega-update/main/manifest.json"
FALLBACK_URL = "https://github.com/maakay38/wega-update/releases/latest/download/WegaApp.exe"

def msg(title, text):
    try:
        ctypes.windll.user32.MessageBoxW(0, text, title, 0)
    except:
        pass

def get_local_version():
    if not os.path.exists(VERSION_FILE):
        return "0.0.0"
    return open(VERSION_FILE).read().strip()

def set_local_version(v):
    with open(VERSION_FILE, "w") as f:
        f.write(v)

def ver(v):
    try:
        return tuple(map(int, v.split(".")))
    except:
        return (0,)

def get_manifest():
    try:
        req = urllib.request.Request(MANIFEST_URL, headers={"User-Agent": "Mozilla"})
        with urllib.request.urlopen(req, timeout=10) as r:
            return json.loads(r.read().decode())
    except:
        return {"version": "0.0.0", "download_url": FALLBACK_URL}

def download_with_resume(url, path):
    downloaded = 0
    if os.path.exists(PART_FILE):
        downloaded = os.path.getsize(PART_FILE)

    req = urllib.request.Request(url)
    if downloaded > 0:
        req.add_header('Range', f'bytes={downloaded}-')

    response = urllib.request.urlopen(req)
    total = int(response.headers.get('Content-Length', 0)) + downloaded

    root = tk.Tk()
    root.title("Güncelleme")
    root.geometry("420x180")

    label = tk.Label(root, text="İndiriliyor...", font=("Arial", 11))
    label.pack(pady=5)

    progress = ttk.Progressbar(root, length=350)
    progress.pack()

    percent = tk.Label(root, text="%0")
    percent.pack()

    speed_label = tk.Label(root, text="")
    speed_label.pack()

    start = time.time()

    with open(PART_FILE, "ab") as f:
        while True:
            chunk = response.read(4096)
            if not chunk:
                break
            f.write(chunk)
            downloaded += len(chunk)

            pct = int(downloaded / total * 100)
            progress["value"] = pct
            percent.config(text=f"%{pct}")

            elapsed = time.time() - start
            if elapsed > 0:
                speed = downloaded / elapsed / 1024
                speed_label.config(text=f"{int(speed)} KB/s")

            root.update()

    os.rename(PART_FILE, path)
    root.destroy()

def valid_exe(path):
    return os.path.exists(path) and os.path.getsize(path) > 5 * 1024 * 1024

def update():
    try:
        data = get_manifest()
        latest = data.get("version", "0.0.0")
        url = data.get("download_url", "").strip()

        local = get_local_version()

        if url and ver(latest) > ver(local):

            msg("Güncelleme", f"Yeni sürüm: {latest}")

            try:
                download_with_resume(url, NEW_EXE)
            except:
                download_with_resume(FALLBACK_URL, NEW_EXE)

            if valid_exe(NEW_EXE):
                backup = APP_EXE + ".bak"

                if os.path.exists(APP_EXE):
                    os.replace(APP_EXE, backup)

                try:
                    os.replace(NEW_EXE, APP_EXE)
                    set_local_version(latest)
                    if os.path.exists(backup):
                        os.remove(backup)
                    msg("Başarılı", "Güncelleme tamamlandı")
                except:
                    if os.path.exists(backup):
                        os.replace(backup, APP_EXE)
                    msg("Hata", "Güncelleme başarısız, eski sürüm geri yüklendi")

            else:
                msg("Hata", "Dosya bozuk, güncelleme iptal")

    except Exception as e:
        msg("Hata", str(e))

def main():
    update()
    if not os.path.exists(APP_EXE):
        msg("Bilgi", "İndiriliyor...")
        download_with_resume(FALLBACK_URL, APP_EXE)

    subprocess.Popen(APP_EXE, cwd=BASE_DIR)
    sys.exit()

if __name__ == "__main__":
    main()
