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

pyinstaller --onefile --noconsole --clean --name WegaApp --icon=wega.ico ^
--collect-all selenium ^
--collect-submodules selenium ^
--collect-all numpy ^
--collect-all pandas ^
--hidden-import selenium.webdriver.chrome.options ^
--hidden-import selenium.webdriver.chrome.service ^
--hidden-import selenium.webdriver.common.by ^
--hidden-import selenium.webdriver.common.keys ^
--hidden-import selenium.webdriver.support.ui ^
--hidden-import selenium.webdriver.support.expected_conditions ^
WegaApp.py
pyinstaller --onefile --noconsole --clean --name TeknisyenPortal --icon=wega.ico ^
--collect-all selenium ^
--collect-submodules selenium ^
--hidden-import selenium.webdriver.chrome.options ^
--hidden-import selenium.webdriver.chrome.service ^
--hidden-import selenium.webdriver.common.by ^
--hidden-import selenium.webdriver.common.keys ^
--hidden-import selenium.webdriver.support.ui ^
--hidden-import selenium.webdriver.support.expected_conditions ^
TeknisyenPortal.py

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
