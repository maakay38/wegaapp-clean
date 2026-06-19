@echo off
title WEGA STABLE BUILD SYSTEM
color 0A

echo ========================================
echo WEGA BUILD BASLADI
echo ========================================

:: =========================
:: VERSION GIR
:: =========================
python version_prompt.py

for /f %%i in (version.txt) do set VERSION=%%i
set TAG=v%VERSION%

echo Yeni surum: %VERSION%

:: =========================
:: TEMIZLIK
:: =========================
echo ========================================
echo TEMIZLIK
echo ========================================

rmdir /s /q build 2>nul
rmdir /s /q dist 2>nul
rmdir /s /q release 2>nul

del /q *.spec 2>nul

mkdir release

:: =========================
:: BUILD
:: =========================
echo ========================================
echo EXE BUILD
echo ========================================

pyinstaller --onefile --noconsole --icon=wega.ico WegaApp.py
pyinstaller --onefile --noconsole --icon=wega.ico TeknisyenPortal.py

if not exist dist\WegaApp.exe (
    echo HATA: WegaApp.exe yok!
    pause
    exit
)

if not exist dist\TeknisyenPortal.exe (
    echo HATA: TeknisyenPortal.exe yok!
    pause
    exit
)

:: =========================
:: RELEASE DOSYALARI
:: =========================
echo ========================================
echo RELEASE HAZIRLANIYOR
echo ========================================

copy dist\WegaApp.exe release\WegaApp.exe
copy dist\TeknisyenPortal.exe release\TeknisyenPortal.exe

:: =========================
:: GIT PUSH
:: =========================
echo ========================================
echo GIT PUSH
echo ========================================

git add manifest.json version.txt app_version.txt
git commit -m "release %VERSION%"
git push origin main

:: =========================
:: RELEASE OLUSTUR
:: =========================
echo ========================================
echo GITHUB RELEASE
echo ========================================

gh release delete %TAG% -y 2>nul

gh release create %TAG% release\WegaApp.exe release\TeknisyenPortal.exe ^
--title "Wega %VERSION%" ^
--notes "Version %VERSION%"

echo ========================================
echo TAMAMLANDI
echo ========================================

pause