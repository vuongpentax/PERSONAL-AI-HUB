# =============================================================================
# health-check.ps1 - Kiểm tra sức khỏe toàn bộ hệ thống
# Kiểm tra: Docker, Ollama, LiteLLM, Open WebUI, số lần lỗi giới hạn (rate limit)
# Cách chạy:
#   powershell -ExecutionPolicy Bypass -File .\scripts\health-check.ps1
# =============================================================================

[CmdletBinding()]
param(
    [int]$LogLines = 500
)

$ErrorActionPreference = 'Continue'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -Path $ProjectRoot

$script:Problems = 0
function Show-Pass([string]$Name, [string]$Detail = '') { Write-Host ("[PASS] {0,-22} {1}" -f $Name, $Detail) -ForegroundColor Green }
function Show-Fail([string]$Name, [string]$Detail = '') { $script:Problems++; Write-Host ("[FAIL] {0,-22} {1}" -f $Name, $Detail) -ForegroundColor Red }
function Show-Warn([string]$Name, [string]$Detail = '') { Write-Host ("[WARN] {0,-22} {1}" -f $Name, $Detail) -ForegroundColor Yellow }

function Test-Http([string]$Url) {
    try {
        $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 8
        return [int]$r.StatusCode
    }
    catch {
        if ($_.Exception.Response) { return [int]$_.Exception.Response.StatusCode }
        return 0
    }
}

Write-Host "=== Kiểm tra Personal AI Platform ===" -ForegroundColor Cyan

# 1. Docker
$dockerOk = $false
docker info *> $null
if ($LASTEXITCODE -eq 0) { Show-Pass 'Docker' 'đang chạy'; $dockerOk = $true }
else { Show-Fail 'Docker' 'chưa chạy. Mở Docker Desktop.' }

# 2. Container
if ($dockerOk) {
    foreach ($name in @('personal-ai-litellm', 'personal-ai-openwebui')) {
        $state = (docker inspect -f '{{.State.Status}}' $name 2>$null)
        if ($state -eq 'running') { Show-Pass $name 'running' }
        elseif ($state) { Show-Fail $name "trạng thái: $state" }
        else { Show-Fail $name 'chưa được tạo. Chạy scripts\setup.ps1.' }
    }
}

# 3. Ollama
$ollamaCode = Test-Http 'http://127.0.0.1:11434/api/tags'
if ($ollamaCode -eq 200) {
    $models = (Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 5).models.name
    $count = @($models).Count
    if ($count -gt 0) { Show-Pass 'Ollama' "$count model đã tải" }
    else { Show-Warn 'Ollama' 'đang chạy nhưng chưa có model. Chạy scripts\pull-models.ps1.' }
}
else { Show-Warn 'Ollama' 'không phản hồi ở 127.0.0.1:11434 (lớp dự phòng cuối sẽ không hoạt động)' }

# 4. LiteLLM
$litellmCode = Test-Http 'http://127.0.0.1:4000/health/liveliness'
if ($litellmCode -eq 200) { Show-Pass 'LiteLLM' 'phản hồi tốt' }
else { Show-Fail 'LiteLLM' "HTTP $litellmCode. Xem log: docker compose logs litellm" }

# 5. Open WebUI
$webuiCode = Test-Http 'http://127.0.0.1:3000'
if ($webuiCode -eq 200) { Show-Pass 'Open WebUI' 'phản hồi tốt' }
else { Show-Fail 'Open WebUI' "HTTP $webuiCode. Xem log: docker compose logs open-webui" }

# 6. Lỗi giới hạn lượt dùng gần đây (rate limit / hết quota)
if ($dockerOk) {
    $logs = docker logs --tail $LogLines personal-ai-litellm 2>&1
    $rateLimit = @($logs | Select-String -Pattern 'RateLimit|429|quota').Count
    if ($rateLimit -eq 0) { Show-Pass 'Giới hạn lượt dùng' "không có lỗi trong $LogLines dòng log gần nhất" }
    else { Show-Warn 'Giới hạn lượt dùng' "$rateLimit lần bị giới hạn gần đây. Hệ thống đã tự chuyển model, nhưng nếu thường xuyên hãy giảm lượt dùng." }
}

# 7. Dung lượng ổ đĩa
$drive = (Get-PSDrive -Name ((Get-Location).Drive.Name) -ErrorAction SilentlyContinue)
if ($drive) {
    $freeGb = [math]::Round($drive.Free / 1GB, 1)
    if ($freeGb -lt 20) { Show-Warn 'Ổ đĩa' "chỉ còn $freeGb GB. Docker và model cần nhiều chỗ, nên dọn bớt." }
    else { Show-Pass 'Ổ đĩa' "còn $freeGb GB" }
}

Write-Host ""
if ($script:Problems -eq 0) { Write-Host "Kết luận: hệ thống hoạt động bình thường." -ForegroundColor Green }
else { Write-Host "Kết luận: có $($script:Problems) lỗi cần xử lý. Xem docs/Troubleshooting.md." -ForegroundColor Red }
exit ([int]($script:Problems -gt 0))
