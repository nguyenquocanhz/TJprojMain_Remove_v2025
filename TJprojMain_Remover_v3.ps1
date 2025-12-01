<#
.SYNOPSIS
    Advanced Malware Removal Tool for TJprojMain / W32.Jeefo variants
    Author: Nguyen Quoc Anh ( NQA TECH)
    Version: 3.0 (PowerShell Edition)

.DESCRIPTION
    Script này thực hiện các tác vụ chuyên sâu:
    1. Buộc dừng tiến trình độc hại dựa trên ĐƯỜNG DẪN TUYỆT ĐỐI (tránh kill nhầm svchost thật).
    2. Gỡ bỏ thuộc tính Hidden/System/ReadOnly.
    3. Xóa file vĩnh viễn (Force).
    4. [MỚI] Quét và làm sạch Registry (Startup keys) trỏ tới các file này.
    5. Tự động quét tất cả ổ đĩa (Fixed + Removable).

.NOTES
    Yêu cầu quyền Administrator.
#>

# --- 1. TỰ ĐỘNG KIỂM TRA & YÊU CẦU QUYỀN ADMIN ---
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Script can quyen Administrator de can thiep he thong."
    Write-Host "Dang khoi dong lai voi quyen Admin..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# --- CẤU HÌNH GIAO DIỆN ---
$Host.UI.RawUI.WindowTitle = "TJprojMain Advanced Remover (PowerShell v3.0)"
Clear-Host
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   ADVANCED MALWARE REMOVAL TOOL (PowerShell Core)      " -ForegroundColor Cyan
Write-Host "   Target: TJprojMain / Fake System Files               " -ForegroundColor Gray
Write-Host "   Engine: .NET/CIM (No WMIC dependency)                " -ForegroundColor Gray
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

# --- DANH SÁCH MỤC TIÊU (RELATIVE PATHS) ---
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

# --- HÀM 1: TIÊU DIỆT TIẾN TRÌNH THEO ĐƯỜNG DẪN ---
function Stop-MaliciousProcess {
    param([string]$FilePath)
    
    # Lấy tất cả process, lọc ra process có đường dẫn trùng khớp
    # Sử dụng Get-CimInstance thay vì Get-Process để lấy Path chính xác hơn
    try {
        $processes = Get-CimInstance Win32_Process -Filter "ExecutablePath = '$(($FilePath -replace '\\','\\'))'" -ErrorAction SilentlyContinue
        
        foreach ($proc in $processes) {
            Write-Host "   [!!!] PHAT HIEN TIEN TRINH DANG CHAY: " -NoNewline -ForegroundColor Red
            Write-Host $proc.Name -ForegroundColor Yellow
            
            Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
            Write-Host "         -> Da buoc dung (PID: $($proc.ProcessId))" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "Khong the kiem tra process cho: $FilePath"
    }
}

# --- HÀM 2: QUÉT REGISTRY (TÍNH NĂNG MỚI) ---
function Clear-Registry {
    Write-Host "[*] Dang quet Registry (Startup Keys)..." -ForegroundColor Cyan
    
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
                    # Kiểm tra xem value trong Registry có chứa đường dẫn độc hại không
                    foreach ($sig in $MalwareSignatures) {
                        if ($data -like "*$sig*") {
                            Write-Host "   [REG] Phat hien Key doc hai: $name -> $data" -ForegroundColor Red
                            Remove-ItemProperty -Path $key -Name $name -Force
                            Write-Host "         -> Da xoa Registry Key." -ForegroundColor Green
                        }
                    }
                }
            }
        } catch {}
    }
}

# --- HÀM 3: XỬ LÝ FILE TRÊN Ổ ĐĨA ---
function InVoke-ScanDrives {
    # Lấy danh sách ổ đĩa (Fixed và Removable)
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }

    foreach ($drive in $drives) {
        $root = $drive.Root # Ví dụ C:\ hoặc D:\
        Write-Host "[-] Dang quet o dia: $root" -ForegroundColor Gray

        foreach ($sig in $MalwareSignatures) {
            $fullPath = Join-Path -Path $root -ChildPath $sig
            
            if (Test-Path -Path $fullPath) {
                Write-Host "   [FILE] Phat hien: $fullPath" -ForegroundColor Red
                
                # 1. Kill Process
                Stop-MaliciousProcess -FilePath $fullPath

                # 2. Gỡ bỏ Attributes (Hidden, System, ReadOnly)
                try {
                    $item = Get-Item -LiteralPath $fullPath -Force
                    $item.Attributes = "Normal"
                } catch {
                    Write-Host "         -> Loi khi go thuoc tinh (Co the file dang bi khoa)" -ForegroundColor DarkRed
                }

                # 3. Xóa file
                try {
                    Remove-Item -LiteralPath $fullPath -Force -ErrorAction Stop
                    Write-Host "         -> [OK] DA XOA THANH CONG." -ForegroundColor Green
                } catch {
                    Write-Host "         -> [FAILED] Khong the xoa file. Thu khoi dong lai may va quet lai." -ForegroundColor Magenta
                    Write-Host "            Error: $($_.Exception.Message)" -ForegroundColor DarkGray
                }
            }
        }
    }
}

# --- THỰC THI CHÍNH ---
$timeStart = Get-Date

# 1. Quét Registry trước để chặn tự khởi động lại
Clean-Registry

# 2. Quét File và Process
Scan-Drives

$timeEnd = Get-Date
$duration = $timeEnd - $timeStart

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   HOAN TAT QUET VA XU LY" -ForegroundColor White
Write-Host "   Thoi gian thuc thi: $($duration.TotalSeconds) giay" -ForegroundColor Gray
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Nhan Enter de thoat..."
Read-Host