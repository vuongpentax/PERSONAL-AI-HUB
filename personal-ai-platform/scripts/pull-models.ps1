# =============================================================================
# pull-models.ps1 - Tải các model Ollama dùng cho Phase 1
# Mặc định chọn theo RTX 3060 12GB + 32GB RAM:
#   qwen2.5:14b         -> chat chung, tiếng Việt khá tốt (dùng cho "ollama-general")
#   qwen2.5-coder:14b   -> viết và sửa code (dùng cho "ollama-coder" / tên "code")
#   llama3.1:8b         -> model nhỏ, nhanh, dự phòng khi máy bận
# Tổng dung lượng khoảng 20 GB. Cần mạng ổn định.
# Cách chạy:
#   powershell -ExecutionPolicy Bypass -File .\scripts\pull-models.ps1
# =============================================================================

[CmdletBinding()]
param(
    [string[]]$Models = @('qwen2.5:14b', 'qwen2.5-coder:14b', 'llama3.1:8b')
)

$ErrorActionPreference = 'Continue'

if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Host "[X] Chưa cài Ollama. Xem docs/Install.md, mục 3." -ForegroundColor Red
    exit 1
}

foreach ($model in $Models) {
    Write-Host ""
    Write-Host "==> Tải $model" -ForegroundColor Cyan
    ollama pull $model
    if ($LASTEXITCODE -eq 0) { Write-Host "    [OK] $model" -ForegroundColor Green }
    else { Write-Host "    [X] Lỗi khi tải $model. Tên model có thể đã đổi, kiểm tra trên ollama.com/library." -ForegroundColor Red }
}

Write-Host ""
Write-Host "Model hiện có trên máy:" -ForegroundColor White
ollama list
