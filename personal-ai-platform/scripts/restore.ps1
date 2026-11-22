# =============================================================================
# restore.ps1 - Khôi phục từ một file sao lưu .7z (do backup.ps1 tạo ra)
# CẢNH BÁO: thao tác này GHI ĐÈ dữ liệu Open WebUI hiện có.
# Cách chạy:
#   powershell -ExecutionPolicy Bypass -File .\scripts\restore.ps1 -Archive .\backups\personal-ai-backup-XXXX.7z
# =============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Archive,
    [switch]$Force           # bỏ qua câu hỏi xác nhận
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -Path $ProjectRoot

$VolumeName = 'personal-ai-openwebui-data'
$TmpDir     = Join-Path $ProjectRoot 'backups\restore-tmp'

function Write-Step([string]$Message) { Write-Host ""; Write-Host "==> $Message" -ForegroundColor Cyan }
function Write-Ok([string]$Message)   { Write-Host "    [OK] $Message" -ForegroundColor Green }
function Write-Bad([string]$Message)  { Write-Host "    [X]  $Message" -ForegroundColor Red }

function Find-SevenZip {
    $cmd = Get-Command 7z -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach ($path in @('C:\Program Files\7-Zip\7z.exe', 'C:\Program Files (x86)\7-Zip\7z.exe')) {
        if (Test-Path $path) { return $path }
    }
    return $null
}

function Invoke-Native {
    param([Parameter(Mandatory)][scriptblock]$Command)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & $Command | Out-Host; return $LASTEXITCODE }
    finally { $ErrorActionPreference = $previous }
}

# --- 0. Kiểm tra đầu vào --------------------------------------------------------
$ArchivePath = Resolve-Path -Path $Archive -ErrorAction SilentlyContinue
if (-not $ArchivePath) { Write-Bad "Không tìm thấy file: $Archive"; exit 1 }
$SevenZip = Find-SevenZip
if (-not $SevenZip) { Write-Bad "Chưa cài 7-Zip."; exit 1 }

if (-not $Force) {
    Write-Host ""
    Write-Host "CẢNH BÁO: dữ liệu chat và tài khoản hiện tại sẽ bị GHI ĐÈ." -ForegroundColor Yellow
    $answer = Read-Host "Gõ YES (viết hoa) để tiếp tục"
    if ($answer -cne 'YES') { Write-Host "Đã hủy."; exit 0 }
}

try {
    # --- 1. Giải nén (7-Zip sẽ hỏi mật khẩu) ----------------------------------
    Write-Step "Giải nén (nhập mật khẩu khi 7-Zip hỏi)"
    if (Test-Path $TmpDir) { Remove-Item -Path $TmpDir -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $TmpDir | Out-Null
    $code = Invoke-Native { & $SevenZip x -p -o"$TmpDir" $ArchivePath -y }
    if ($code -ne 0) { throw "Giải nén thất bại. Kiểm tra lại mật khẩu." }
    Write-Ok "Đã giải nén"

    # --- 2. Dừng dịch vụ -------------------------------------------------------
    Write-Step "Dừng dịch vụ"
    Invoke-Native { docker compose down } | Out-Null
    Write-Ok "Đã dừng"

    # --- 3. Khôi phục dữ liệu Open WebUI ---------------------------------------
    Write-Step "Khôi phục dữ liệu Open WebUI vào volume $VolumeName"
    $dataTar = Join-Path $TmpDir 'openwebui-data.tar.gz'
    if (-not (Test-Path $dataTar)) { throw "Trong bản sao lưu không có openwebui-data.tar.gz" }
    $code = Invoke-Native {
        docker run --rm `
            -v "${VolumeName}:/data" `
            -v "${TmpDir}:/backup:ro" `
            alpine sh -c "rm -rf /data/* /data/.[!.]* 2>/dev/null; tar xzf /backup/openwebui-data.tar.gz -C /data"
    }
    if ($code -ne 0) { throw "Khôi phục volume thất bại." }
    Write-Ok "Đã khôi phục dữ liệu chat và tài khoản"

    # --- 4. Khôi phục cấu hình (hỏi trước khi ghi đè) -------------------------
    Write-Step "Khôi phục cấu hình"
    foreach ($item in @('docker-compose.yml', 'infrastructure', 'agents', 'prompts')) {
        $src = Join-Path $TmpDir $item
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $ProjectRoot -Recurse -Force
            Write-Ok "Đã khôi phục $item"
        }
    }
    $envSrc = Join-Path $TmpDir '.env'
    if (Test-Path $envSrc) {
        Copy-Item -Path $envSrc -Destination (Join-Path $ProjectRoot '.env') -Force
        Write-Ok "Đã khôi phục .env (chứa API key và khóa bí mật)"
    }
}
catch {
    Write-Bad $_.Exception.Message
    Write-Host "Dữ liệu hiện tại có thể chưa được khôi phục hoàn toàn. Chạy lại restore.ps1 với file sao lưu khác nếu cần." -ForegroundColor Yellow
    exit 1
}
finally {
    if (Test-Path $TmpDir) { Remove-Item -Path $TmpDir -Recurse -Force -ErrorAction SilentlyContinue }
}

# --- 5. Khởi động lại ------------------------------------------------------------
Write-Step "Khởi động lại dịch vụ"
$code = Invoke-Native { docker compose up -d }
if ($code -ne 0) { Write-Bad "Khởi động thất bại. Chạy scripts\health-check.ps1."; exit 1 }
Write-Ok "Đã khôi phục xong"
Write-Host "Kiểm tra: mở http://127.0.0.1:3000 và đăng nhập bằng tài khoản cũ." -ForegroundColor White
