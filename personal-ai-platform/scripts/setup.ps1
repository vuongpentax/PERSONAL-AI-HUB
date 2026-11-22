# =============================================================================
# setup.ps1 - Cài đặt lần đầu cho Personal AI Platform (Phase 1)
# Việc script làm:
#   1. Kiểm tra Docker Desktop và Ollama
#   2. Tạo file .env với khóa ngẫu nhiên (nếu chưa có)
#   3. Khởi động Open WebUI + LiteLLM
# Cách chạy (PowerShell, đứng trong thư mục personal-ai-platform):
#   powershell -ExecutionPolicy Bypass -File .\scripts\setup.ps1
# =============================================================================

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -Path $ProjectRoot

function Write-Step([string]$Message) { Write-Host ""; Write-Host "==> $Message" -ForegroundColor Cyan }
function Write-Ok([string]$Message)   { Write-Host "    [OK] $Message" -ForegroundColor Green }
function Write-Warn([string]$Message) { Write-Host "    [!]  $Message" -ForegroundColor Yellow }
function Write-Bad([string]$Message)  { Write-Host "    [X]  $Message" -ForegroundColor Red }

# Chạy lệnh bên ngoài (docker, ollama...) mà không để PowerShell coi stderr là lỗi cứng.
function Invoke-Native {
    param([Parameter(Mandatory)][scriptblock]$Command)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $Command 2>&1 | Out-Host
        return $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previous
    }
}

function New-RandomHex([int]$Bytes) {
    $buffer = New-Object byte[] $Bytes
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($buffer)
    $rng.Dispose()
    return ([System.BitConverter]::ToString($buffer) -replace '-', '').ToLowerInvariant()
}

# --- 1. Kiểm tra Docker -------------------------------------------------------
Write-Step "Kiểm tra Docker Desktop"
$code = Invoke-Native { docker info }
if ($code -ne 0) {
    Write-Bad "Docker chưa chạy. Hãy mở Docker Desktop, đợi biểu tượng cá voi ổn định rồi chạy lại script."
    exit 1
}
Write-Ok "Docker đang chạy"

# --- 2. Kiểm tra Ollama -------------------------------------------------------
Write-Step "Kiểm tra Ollama"
if (Get-Command ollama -ErrorAction SilentlyContinue) {
    Write-Ok "Đã cài Ollama"
    try {
        Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 5 | Out-Null
        Write-Ok "Ollama đang chạy ở cổng 11434"
    }
    catch {
        Write-Warn "Ollama chưa chạy. Mở ứng dụng Ollama từ Start menu rồi chạy lại."
    }
}
else {
    Write-Warn "Chưa cài Ollama. Xem mục 3 trong docs/Install.md. Hệ thống vẫn chạy được với API đám mây."
}

# --- 3. Tạo file .env ---------------------------------------------------------
Write-Step "Chuẩn bị file .env"
$envFile    = Join-Path $ProjectRoot '.env'
$envExample = Join-Path $ProjectRoot '.env.example'

if (Test-Path $envFile) {
    Write-Ok "Đã có file .env, giữ nguyên (không ghi đè khóa cũ)"
}
else {
    Copy-Item -Path $envExample -Destination $envFile
    $content = [System.IO.File]::ReadAllText($envFile)
    $content = $content -replace 'LITELLM_MASTER_KEY=.*', ("LITELLM_MASTER_KEY=sk-" + (New-RandomHex 24))
    $content = $content -replace 'WEBUI_SECRET_KEY=.*', ("WEBUI_SECRET_KEY=" + (New-RandomHex 32))
    # Ghi file không có BOM, để Docker đọc đúng dòng đầu tiên.
    [System.IO.File]::WriteAllText($envFile, $content, (New-Object System.Text.UTF8Encoding($false)))
    Write-Ok "Đã tạo .env với khóa ngẫu nhiên"
    Write-Warn "Mở file .env và điền API key miễn phí (GEMINI, GROQ, OPENROUTER) nếu đã có."
}

# Kiểm tra nhanh xem đã điền key đám mây chưa.
$envText = [System.IO.File]::ReadAllText($envFile)
foreach ($name in @('GEMINI_API_KEY', 'GROQ_API_KEY', 'OPENROUTER_API_KEY')) {
    if ($envText -match "(?m)^$name=\s*$") {
        Write-Warn "$name còn trống (bỏ qua nhà cung cấp này cho đến khi bạn điền key)"
    }
}

# --- 4. Khởi động dịch vụ -----------------------------------------------------
Write-Step "Khởi động Open WebUI + LiteLLM (lần đầu có thể mất vài phút để tải image)"
$code = Invoke-Native { docker compose up -d }
if ($code -ne 0) {
    Write-Bad "docker compose lỗi. Xem docs/Troubleshooting.md, mục 'docker compose up lỗi'."
    exit 1
}
Write-Ok "Đã gửi lệnh khởi động"

# --- 5. Đợi Open WebUI sẵn sàng ----------------------------------------------
Write-Step "Đợi Open WebUI sẵn sàng"
$ready = $false
for ($i = 0; $i -lt 60; $i++) {
    try {
        $response = Invoke-WebRequest -Uri 'http://127.0.0.1:3000' -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) { $ready = $true; break }
    }
    catch { Start-Sleep -Seconds 3 }
}

if ($ready) {
    Write-Ok "Open WebUI đã chạy"
}
else {
    Write-Warn "Chưa thấy Open WebUI sau 3 phút. Chạy scripts\health-check.ps1 để xem nguyên nhân."
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor DarkGray
Write-Host " Xong bước cài đặt. Tiếp theo:" -ForegroundColor White
Write-Host "  1. Mở http://127.0.0.1:3000 và tạo tài khoản admin (xem docs/Install.md, bước 8)" -ForegroundColor White
Write-Host "  2. Chạy scripts\pull-models.ps1 để tải model Ollama" -ForegroundColor White
Write-Host "  3. Chạy scripts\health-check.ps1 để kiểm tra toàn bộ hệ thống" -ForegroundColor White
Write-Host "================================================================" -ForegroundColor DarkGray
