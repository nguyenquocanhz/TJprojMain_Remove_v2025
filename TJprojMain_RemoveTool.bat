@echo off
setlocal EnableDelayedExpansion
title TJprojMain Advanced Remover (v2.2 - Auto Admin & WMIC Check)
color 0B

:: --- BƯỚC 1: TỰ ĐỘNG XIN QUYỀN ADMIN (AUTO-ELEVATION) ---
fltmc >nul 2>&1 || (
    echo.
    echo [!] Script can quyen Admin de xoa file he thong va diet tien trinh.
    echo [!] Dang tu dong yeu cau quyen Administrator (Run as Administrator)...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)
cd /d "%~dp0"

:: --- BƯỚC 2: KIỂM TRA & CÀI ĐẶT WMIC (QUAN TRỌNG) ---
cls
echo [i] Dang kiem tra moi truong he thong...
where wmic >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [!] CANH BAO: May tinh cua ban thieu cong cu WMIC.
    echo     Script nay can WMIC de phan biet virus svchost.exe gia va that.
    echo.
    echo [?] Ban co muon tai va cai dat WMIC tu dong khong? (Can Internet)
    echo     (Y) Yes: Tu dong tai qua Windows Update/DISM
    echo     (N) No : Tu mo Settings de ban cai thu cong
    echo.
    set /p "choice=Nhap lua chon cua ban (Y/N): "
    
    if /i "!choice!"=="Y" (
        echo.
        echo [*] Dang tai va cai dat WMIC (Vui long cho, co the mat 1-2 phut)...
        dism /Online /Add-Capability /CapabilityName:WMIC~~~~
        
        echo.
        echo [i] Dang kiem tra lai WMIC...
        where wmic >nul 2>&1
        if !errorlevel! neq 0 (
            echo [X] Cai dat tu dong that bai. Vui long cai thu cong trong Settings.
            start ms-settings:optionalfeatures
            pause
            exit /b
        ) else (
            echo [V] Da cai dat WMIC thanh cong!
            timeout /t 3 >nul
        )
    ) else (
        echo.
        echo [!] Vui long cai dat "WMIC" trong Optional Features de tiep tuc.
        start ms-settings:optionalfeatures
        pause
        exit /b
    )
)

cls
echo ========================================================
echo   ADVANCED MALWARE REMOVAL TOOL (TJprojMain / Jeefo)
echo   Target: Fake svchost.exe, spoolsv.exe, explorer.exe
echo   Locations: \Windows\Resources AND \Windows\System
echo   Status: RUNNING AS ADMINISTRATOR | WMIC: DETECTED
echo ========================================================
echo.

:: Danh sách các file độc hại (Relative Paths)
set "files[1]=\Windows\Resources\svchost.exe"
set "files[2]=\Windows\Resources\spoolsv.exe"
set "files[3]=\Windows\Resources\Themes\explorer.exe"
set "files[4]=\Windows\Resources\Themes\icsys.icn.exe"
set "files[5]=\Windows\System\svchost.exe"
set "files[6]=\Windows\System\spoolsv.exe"
set "files[7]=\Windows\System\explorer.exe"
set "files[8]=\Windows\System\icsys.icn.exe"

echo [*] Dang quet toan bo he thong...
echo.

:: --- BƯỚC 3: QUÉT TẤT CẢ CÁC Ổ ĐĨA (A-Z) ---
for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist %%d:\ (
        echo [i] Dang kiem tra o dia %%d:\ ...
        call :ScanDrive %%d
    )
)

echo.
echo ========================================================
echo   HOAN TAT QUA TRINH QUET VA XU LY
echo ========================================================
pause
exit /b

:: --- FUNCTION: XỬ LÝ TỪNG Ổ ĐĨA ---
:ScanDrive
set "drive=%1"

:: Vòng lặp qua danh sách file độc hại đã định nghĩa ở trên
for /L %%i in (1,1,8) do (
    set "targetPath=%drive%:!files[%%i]!"
    
    if exist "!targetPath!" (
        echo     [Phat hien] !targetPath!
        
        :: 1. Tắt tiến trình bằng WMIC (Chính xác 100% đường dẫn)
        set "wmicPath=%drive%:\\!files[%%i]:\=\\!"
        
        wmic process where "ExecutablePath='!wmicPath!'" CALL TERMINATE >nul 2>&1
        if !errorlevel! equ 0 (
            echo         - Da tat tien trinh dang chay.
        )
        
        :: 2. Gỡ bỏ thuộc tính
        attrib -h -r -s "!targetPath!" >nul 2>&1
        
        :: 3. Xóa file
        del /f /q "!targetPath!" >nul 2>&1
        
        if exist "!targetPath!" (
            echo         [X] KHONG THE XOA FILE. (Loi quyen hoac file dang chay)
        ) else (
            echo         [V] Da xoa thanh cong.
        )
    )
)
exit /b