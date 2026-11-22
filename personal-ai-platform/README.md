# Personal AI Platform

Nền tảng AI cá nhân: **miễn phí, tự host, chạy trên Windows 11, truy cập từ điện thoại qua Tailscale.**

Bạn mở một giao diện duy nhất (Open WebUI). Phía sau, hệ thống tự chọn model, tự chuyển model khi lỗi, và tận dụng gói miễn phí của nhà cung cấp.

> **Trạng thái:** Phase 1 (cài đặt và dùng hằng ngày). Phase 2–4 xem `docs/Roadmap.md`.

## Kiến trúc nhanh

```text
Điện thoại / Máy tính
        │  (Tailscale - mạng riêng)
        ▼
  Open WebUI  ──►  LiteLLM  ──►  Gemini → Groq → OpenRouter   (cloud miễn phí)
                      │
                      └──────►  Ollama trên máy (GPU RTX 3060)  (dự phòng cuối)
```

Chi tiết và sơ đồ: `docs/Architecture.md` và `diagrams/architecture.mmd`.

## Bắt đầu nhanh

1. Đọc và làm theo **`docs/Install.md`** (từ bước 1 đến bước 11).
2. Chạy kiểm tra:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\health-check.ps1
   ```
3. Gặp lỗi: xem **`docs/Troubleshooting.md`**.

## Cấu trúc thư mục

```text
personal-ai-platform/
├── README.md                 ← bạn đang đọc
├── docker-compose.yml        ← Open WebUI + LiteLLM
├── .env.example              ← mẫu biến môi trường (KHÔNG chứa key thật)
├── docs/                     ← cài đặt, kiến trúc, bảo mật, xử lý lỗi, lộ trình
├── infrastructure/
│   ├── litellm/config.yaml   ← định tuyến và failover model
│   ├── ollama/README.md      ← hướng dẫn Ollama trên Windows
│   └── openwebui/README.md   ← cấu hình giao diện và agent
├── agents/agents.yaml        ← danh sách agent (Researcher, Coder, Writer, Assistant)
├── prompts/                  ← hướng dẫn vai trò cho từng agent
├── scripts/                  ← PowerShell: setup, update, health-check, backup, restore
├── backups/                  ← nơi chứa bản sao lưu mã hóa (không lên GitHub)
├── diagrams/                 ← sơ đồ Mermaid
├── monitoring/               ← kế hoạch giám sát (Phase 1+)
├── automation/               ← kế hoạch tự động hóa (Phase 2+)
└── .github/workflows/        ← kiểm tra tự động trên GitHub
```

## Script chính

| Việc | Script |
|---|---|
| Cài đặt lần đầu | `scripts\setup.ps1` |
| Tải model Ollama | `scripts\pull-models.ps1` |
| Kiểm tra hệ thống | `scripts\health-check.ps1` |
| Cập nhật | `scripts\update.ps1` |
| Sao lưu mã hóa | `scripts\backup.ps1` |
| Khôi phục | `scripts\restore.ps1` |

## Bảo mật (đọc trước khi dùng thật)

- **Không bao giờ commit file `.env`.** Nó chứa API key.
- **Không bao giờ bật `tailscale funnel`.** Funnel mở ứng dụng ra Internet công cộng.
- Dữ liệu nhạy cảm nên dùng model local (`ollama-general`, `ollama-coder`).

Chi tiết: `docs/Security.md`.

## Hạn chế đã biết

- Chạy trên một máy Windows. Tắt máy là hệ thống ngừng.
- Gói miễn phí của nhà cung cấp có giới hạn và có thể thay đổi.
- Phase 1 chưa tự nhận biết ý định; bạn tự chọn agent.
- GitHub Actions chỉ **kiểm tra cấu hình**. Không sao lưu được dữ liệu trên máy bạn (dữ liệu chỉ nằm trên máy, backup do `backup.ps1` thực hiện).

## Đóng góp và kiểm tra

Mỗi lần đẩy code lên GitHub, workflow `validate.yml` sẽ kiểm tra:
- Cú pháp YAML và cấu hình Docker Compose
- Không có API key hay mật khẩu thật trong mã nguồn
- Cú pháp PowerShell (PSScriptAnalyzer)

Chạy kiểm tra trên máy của bạn:
```powershell
python scripts\validate_config.py
```
