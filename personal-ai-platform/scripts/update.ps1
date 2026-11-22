# =============================================================================
# update.ps1 - Cập nhật Open WebUI, LiteLLM và cấu hình của dự án
# Trước khi cập nhật, script TỰ ĐỘNG sao lưu cấu hình nhẹ (không có dữ liệu chat).
# Cách chạy:
#   powershell -ExecutionPolicy Bypass -File .\scripts\update.ps1
#   powershell -ExecutionPolicy Bypass -File .\scripts\update.ps1 -SkipGitPull
# =============================================================================

[CmdletBinding()]
param(
    [switch]$SkipGitPull,
    [switch]$SkipBackup
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -Path $ProjectRoot

function Write-Step([string]$Message) { Write-Host ""; Write-Host "==> $Message" -ForegroundColor Cyan }
function Write-Ok([string]$Message)   { Write-Host "    [OK] $Message" -ForegroundColor Green }
function Write-Warn([string]$Message) { Write-Host "    [!]  $Message" -ForegroundColor Yellow }
function Write-Bad([string]$Message)  { Write-Host "    [X]  $Message" -ForegroundColor Red }

function Invoke-Native {
    param([Parameter(Mandatory)][scriptblock]$Command)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & $Command 2>&1 | Out-Host; return $LASTEXITCODE }
    finally { $ErrorActionPreference = $previous }
}

# --- 1. Sao lưu nhanh (cấu hình, không có dữ liệu chat) -----------------------
if (-not $SkipBackup) {
    Write-Step "Sao lưu cấu hình trước khi cập nhật"
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $configBackup = Join-Path $ProjectRoot "backups\config-before-update-$stamp.zip"
    $items = @(
        (Join-Path $ProjectRoot 'infrastructure'),
        (Join-Path $ProjectRoot 'agents'),
        (Join-Path $ProjectRoot 'prompts'),
        (Join-Path $ProjectRoot 'docker-compose.yml')
    ) | Where-Object { Test-Path $_ }
    if (Test-Path (Join-Path $ProjectRoot '.env')) {
        Write-Warn "File .env chứa khóa bí mật nên KHÔNG được đưa vào bản sao lưu nhanh. Hãy dùng scripts\backup.ps1 để có bản mã hóa đầy đủ."
    }
    Compress-Archive -Path $items -DestinationPath $configBackup -Force
    Write-Ok "Đã lưu $configBackup"
}

# --- 2. Cập nhật mã nguồn từ GitHub -------------------------------------------
if (-not $SkipGitPull) {
    Write-Step "Lấy phiên bản mới từ GitHub"
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $code = Invoke-Native { git pull --ff-only }
        if ($code -ne 0) { Write-Warn "git pull không thành công (có thể bạn đã sửa file cục bộ). Tiếp tục với cấu hình hiện có." }
        else { Write-Ok "Đã cập nhật mã nguồn" }
    }
    else {
        Write-Warn "Chưa cài Git. Bỏ qua bước này."
    }
}

# --- 3. Tải image mới và khởi động lại ----------------------------------------
Write-Step "Tải image mới"
$code = Invoke-Native { docker compose pull }
if ($code -ne 0) { Write-Bad "Không tải được image. Kiểm tra mạng và thử lại."; exit 1 }
Write-Ok "Đã tải image"

Write-Step "Khởi động lại dịch vụ"
$code = Invoke-Native { docker compose up -d }
if ($code -ne 0) { Write-Bad "Khởi động thất bại. Xem docs/Troubleshooting.md."; exit 1 }
Write-Ok "Dịch vụ đã chạy phiên bản mới"

Write-Step "Dọn image cũ không còn dùng"
Invoke-Native { docker image prune -f } | Out-Null
Write-Ok "Đã dọn xong"

Write-Host ""
Write-Host "Cập nhật xong. Chạy scripts\health-check.ps1 để kiểm tra lại." -ForegroundColor White
