# =============================================================================
# backup.ps1 - Sao lưu MÃ HÓA toàn bộ dữ liệu của Personal AI Platform
# Sao lưu gồm:
#   - Dữ liệu Open WebUI (lịch sử chat, tài khoản, cài đặt, file đã tải lên)
#   - Cấu hình LiteLLM, agents, prompts, docker-compose.yml
#   - File .env (chứa API key và khóa bí mật)
# Kết quả: một file .7z mã hóa AES-256 trong thư mục backups\ (không lên GitHub).
#
# YÊU CẦU: đã cài 7-Zip (https://www.7-zip.org). Mật khẩu sẽ được HỎI khi chạy.
# Cách chạy:
#   powershell -ExecutionPolicy Bypass -File .\scripts\backup.ps1
#   powershell -ExecutionPolicy Bypass -File .\scripts\backup.ps1 -KeepLast 5
# =============================================================================

[CmdletBinding()]
param(
    [int]$KeepLast = 7,
    [switch]$NoStop          # không dừng container (nhanh hơn nhưng có thể chụp dữ liệu đang ghi dở)
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -Path $ProjectRoot

$VolumeName = 'personal-ai-openwebui-data'
$BackupDir  = Join-Path $ProjectRoot 'backups'
$Stamp      = Get-Date -Format 'yyyyMMdd-HHmmss'
$Staging    = Join-Path $BackupDir "staging\$Stamp"
$Archive    = Join-Path $BackupDir "personal-ai-backup-$Stamp.7z"

function Write-Step([string]$Message) { Write-Host ""; Write-Host "==> $Message" -ForegroundColor Cyan }
function Write-Ok([string]$Message)   { Write-Host "    [OK] $Message" -ForegroundColor Green }
function Write-Bad([string]$Message)  { Write-Host "    [X]  $Message" -ForegroundColor Red }

function Find-SevenZip {
    $cmd = Get-Command 7z -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidates = @(
        'C:\Program Files\7-Zip\7z.exe',
        'C:\Program Files (x86)\7-Zip\7z.exe'
    )
    foreach ($path in $candidates) { if (Test-Path $path) { return $path } }
    return $null
}

function Invoke-Native {
    param([Parameter(Mandatory)][scriptblock]$Command)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & $Command | Out-Host; return $LASTEXITCODE }
    finally { $ErrorActionPreference = $previous }
}

# --- 0. Kiểm tra công cụ ------------------------------------------------------
$SevenZip = Find-SevenZip
if (-not $SevenZip) {
    Write-Bad "Chưa cài 7-Zip. Tải tại https://www.7-zip.org rồi chạy lại."
    exit 1
}
if ((Invoke-Native { docker info *> $null }) -ne 0) {
    Write-Bad "Docker chưa chạy. Mở Docker Desktop rồi thử lại."
    exit 1
}

New-Item -ItemType Directory -Force -Path $Staging | Out-Null

try {
    # --- 1. Dừng dịch vụ để dữ liệu nhất quán -------------------------------
    if (-not $NoStop) {
        Write-Step "Tạm dừng dịch vụ để đảm bảo dữ liệu không bị ghi dở"
        Invoke-Native { docker compose stop } | Out-Null
        Write-Ok "Đã dừng"
    }

    # --- 2. Xuất dữ liệu Open WebUI từ Docker volume ------------------------
    Write-Step "Xuất dữ liệu Open WebUI"
    $code = Invoke-Native {
        docker run --rm `
            -v "${VolumeName}:/data:ro" `
            -v "${Staging}:/backup" `
            alpine tar czf /backup/openwebui-data.tar.gz -C /data .
    }
    if ($code -ne 0) { throw "Không xuất được volume $VolumeName. Kiểm tra tên volume bằng: docker volume ls" }
    Write-Ok "Đã xuất volume $VolumeName"

    # --- 3. Sao chép cấu hình ----------------------------------------------
    Write-Step "Sao chép cấu hình"
    $configItems = @('docker-compose.yml', 'infrastructure', 'agents', 'prompts', '.env.example', '.env')
    foreach ($item in $configItems) {
        $src = Join-Path $ProjectRoot $item
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $Staging -Recurse -Force
            Write-Ok "Đã chép $item"
        }
    }

    # --- 4. Nén và mã hóa ---------------------------------------------------
    Write-Step "Nén và mã hóa (7-Zip sẽ hỏi mật khẩu)"
    Write-Host "    Ghi nhớ mật khẩu này. QUÊN MẬT KHẨU = KHÔNG KHÔI PHỤC ĐƯỢC." -ForegroundColor Yellow
    # -mhe=on: mã hóa cả tên file bên trong; -p (không kèm giá trị): hỏi mật khẩu trong console
    $code = Invoke-Native { & $SevenZip a -t7z -mhe=on -mx=5 -p $Archive "$Staging\*" }
    if ($code -ne 0 -or -not (Test-Path $Archive)) { throw "Nén/mã hóa thất bại." }
    Write-Ok "Đã tạo $Archive"
}
finally {
    # Xóa thư mục tạm chứa dữ liệu chưa mã hóa
    if (Test-Path $Staging) { Remove-Item -Path $Staging -Recurse -Force }
    if (Test-Path (Join-Path $BackupDir 'staging')) {
        $leftover = Get-ChildItem -Path (Join-Path $BackupDir 'staging') -ErrorAction SilentlyContinue
        if (-not $leftover) { Remove-Item -Path (Join-Path $BackupDir 'staging') -Force -ErrorAction SilentlyContinue }
    }
    # Khởi động lại dịch vụ
    if (-not $NoStop) {
        Write-Step "Khởi động lại dịch vụ"
        Invoke-Native { docker compose start } | Out-Null
    }
}

# --- 5. Giữ lại N bản sao lưu gần nhất ----------------------------------------
Write-Step "Dọn bản sao lưu cũ (giữ $KeepLast bản gần nhất)"
$old = Get-ChildItem -Path $BackupDir -Filter 'personal-ai-backup-*.7z' |
    Sort-Object LastWriteTime -Descending |
    Select-Object -Skip $KeepLast
foreach ($file in $old) {
    Remove-Item -Path $file.FullName -Force
    Write-Ok "Đã xóa bản cũ: $($file.Name)"
}

Write-Host ""
Write-Host "Sao lưu xong. Hãy copy file .7z sang ổ ngoài hoặc đám mây cá nhân (ví dụ Google Drive riêng)." -ForegroundColor White
Write-Host "KHÔNG đưa file này lên GitHub." -ForegroundColor Yellow
