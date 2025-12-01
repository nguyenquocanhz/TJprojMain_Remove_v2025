<#
.SYNOPSIS
    TJprojMain_Remove_v2025 - Công cụ loại bỏ Malware TJprojMain / W32.Jeefo (Phiên bản 2025)
    Author: Nguyen Quoc Anh ( NQA TECH)
    Version: 2025.1.5 (PowerShell Edition + Custom Messages)

.DESCRIPTION
    Phiên bản này tích hợp hệ thống Logging và Hiển thị chi tiết quá trình quét (Verbose) lên màn hình console.
    File log sẽ được lưu tại cùng thư mục với script.

.NOTES
    - Yêu cầu quyền: Administrator.
    - Log file format: ScanLog_yyyyMMdd_HHmmss.txt
#>

# --- 1. TỰ ĐỘNG KIỂM TRA & YÊU CẦU QUYỀN ADMIN ---
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Script can quyen Administrator de can thiep he thong."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# --- 2. THIẾT LẬP HỆ THỐNG LOGGING ---
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $ScriptPath) { $ScriptPath = Get-Location } 
$LogTimeTag = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = Join-Path -Path $ScriptPath -ChildPath "ScanLog_$LogTimeTag.txt"

# Biến toàn cục để theo dõi trạng thái nhiễm virus
$global:VirusDetected = $false

# Hàm ghi log: Vừa hiện lên màn hình, vừa ghi vào file
function Write-Log {
    param(
        [string]$Message,
        [ConsoleColor]$Color = "White",
        [switch]$NoNewline
    )

    # 1. Hiển thị lên màn hình (Console)
    if ($NoNewline) {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Message -ForegroundColor $Color
    }

    # 2. Ghi vào file (Strip color, add timestamp)
    $TimeStr = Get-Date -Format "HH:mm:ss"
    $LogContent = "[$TimeStr] $Message"
    $LogContent | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# --- CẤU HÌNH GIAO DIỆN ---
$Host.UI.RawUI.WindowTitle = "TJprojMain_Remove_v2025 (Logging Enabled)"
Clear-Host
Write-Log "========================================================" -Color Cyan
Write-Log "   TJprojMain_Remove_v2025 (Advanced Removal Tool)      " -Color Cyan
Write-Log "   Author: Nguyen Quoc Anh ( NQA TECH)                  " -Color Yellow
Write-Log "   Log File: $LogFile                                   " -Color Gray
Write-Log "========================================================" -Color Cyan
Write-Log ""

# --- DANH SÁCH MỤC TIÊU ---
$MalwareSignatures = @(
    "\Windows\Resources\svchost.exe",
    "\Windows\Resources\spoolsv.exe",
    "\Windows\Resources\Themes\explorer.exe",
    "\Windows\Resources\Themes\icsys.icn.exe",
    "\Windows\System\svchost.exe",
    "\Windows\System\spoolsv.exe",
    "\Windows\System\explorer.exe",
    "\Windows\System\icsys.icn.exe"
)

# --- HÀM 1: TIÊU DIỆT TIẾN TRÌNH ---
function Stop-MaliciousProcess {
    param([string]$FilePath)
    
    try {
        $processes = Get-CimInstance Win32_Process -Filter "ExecutablePath = '$(($FilePath -replace '\\','\\'))'" -ErrorAction SilentlyContinue
        
        foreach ($proc in $processes) {
            Write-Host "`n" # Xuống dòng để tránh bị ghi đè lên dòng Checking
            Write-Log "   [!!!] PHAT HIEN TIEN TRINH DANG CHAY: " -Color Red -NoNewline
            Write-Log "$($proc.Name) (PID: $($proc.ProcessId))" -Color Yellow
            
            Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
            Write-Log "         -> Da buoc dung process." -Color Green
        }
    }
    catch {
        Write-Log "   [WARN] Khong the kiem tra process cho: $FilePath" -Color Magenta
    }
}

# --- HÀM 2: QUÉT REGISTRY ---
function Clear-Registry {
    Write-Log "[*] Dang quet Registry (Startup Keys)..." -Color Cyan
    
    $RegKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    )

    foreach ($key in $RegKeys) {
        try {
            $values = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
            foreach ($name in $values.PSObject.Properties.Name) {
                $data = $values.$name
                if ($data -is [string]) {
                    foreach ($sig in $MalwareSignatures) {
                        if ($data -like "*$sig*") {
                            $global:VirusDetected = $true
                            Write-Log "   [REG] Phat hien Key doc hai: $name -> $data" -Color Red
                            Remove-ItemProperty -Path $key -Name $name -Force
                            Write-Log "         -> Da xoa Registry Key." -Color Green
                        }
                    }
                }
            }
        } catch {}
    }
}

# --- HÀM 3: XỬ LÝ FILE TRÊN Ổ ĐĨA ---
function Invoke-DriveScan {
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }

    foreach ($drive in $drives) {
        $root = $drive.Root 
        Write-Log "[-] Dang quet o dia: $root" -Color Gray

        foreach ($sig in $MalwareSignatures) {
            $fullPath = Join-Path -Path $root -ChildPath $sig
            
            # [UPDATE] In ra màn hình file đang kiểm tra (Chỉ hiện console, không ghi vào log để tránh spam file log)
            Write-Host "   [?] Dang kiem tra: $fullPath" -ForegroundColor DarkGray
            
            if (Test-Path -Path $fullPath) {
                $global:VirusDetected = $true
                Write-Host "" # Xuống dòng để làm nổi bật cảnh báo
                Write-Log "   [FILE] Phat hien: $fullPath" -Color Red
                
                # 1. Kill Process
                Stop-MaliciousProcess -FilePath $fullPath

                # 2. Gỡ bỏ Attributes
                try {
                    $item = Get-Item -LiteralPath $fullPath -Force
                    $item.Attributes = "Normal"
                } catch {
                    Write-Log "         -> Loi khi go thuoc tinh (File bi khoa/quyen he thong)" -Color DarkRed
                }

                # 3. Xóa file
                try {
                    Remove-Item -LiteralPath $fullPath -Force -ErrorAction Stop
                    # [CUSTOM MESSAGE] Thông báo theo yêu cầu của người dùng
                    Write-Log "         -> Oh thay virus ne ! Da xoa virus: $fullPath" -Color Yellow
                } catch {
                    Write-Log "         -> [FAILED] Khong the xoa file." -Color Magenta
                    Write-Log "            Error: $($_.Exception.Message)" -Color DarkGray
                }
            }
        }
    }
}

# --- THỰC THI CHÍNH ---
$timeStart = Get-Date
Write-Log "Bat dau quet vao luc: $($timeStart.ToString())" -Color White

# 1. Quét Registry
Clear-Registry

# 2. Quét File
Invoke-DriveScan

$timeEnd = Get-Date
$duration = $timeEnd - $timeStart

Write-Log ""
Write-Log "========================================================" -Color Cyan
Write-Log "   HOAN TAT QUET VA XU LY" -Color White
Write-Log "   Thoi gian thuc thi: $($duration.TotalSeconds) giay" -Color Gray

# [CUSTOM MESSAGE] Kiểm tra kết quả cuối cùng
if (-not $global:VirusDetected) {
    Write-Log "   [SAFE] May cua ban khong bi nhiem virus." -Color Green
} else {
    Write-Log "   [DONE] Da xu ly xong cac moi nguy hiem tren may." -Color Yellow
}

Write-Log "   File log da duoc luu tai: $LogFile" -Color Yellow
Write-Log "========================================================" -Color Cyan
Write-Host "Nhan Enter de thoat..."
Read-Host