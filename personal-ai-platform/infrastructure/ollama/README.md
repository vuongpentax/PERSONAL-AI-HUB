# Ollama - Lớp dự phòng cuối (chạy trên Windows)

Ollama chạy **trực tiếp trên Windows**, không nằm trong Docker, để dùng được card RTX 3060 mà không cần cấu hình thêm NVIDIA Container Toolkit.

## Vai trò
Khi tất cả nhà cung cấp đám mây đều hết lượt hoặc mất mạng, LiteLLM tự chuyển sang Ollama. Bạn không cần làm gì thêm.

## Model dùng trong Phase 1

| Tên trong LiteLLM | Model Ollama | Dùng cho | Ghi chú |
|---|---|---|---|
| `ollama-general` | `qwen2.5:14b` | Chat chung, dự phòng cho `main` | Khoảng 9 GB VRAM |
| `ollama-coder` | `qwen2.5-coder:14b` | Viết code (tên `code`) | Khoảng 9 GB VRAM |
| (dự phòng nhanh) | `llama3.1:8b` | Khi cần phản hồi nhanh | Nhẹ hơn, khoảng 5 GB |

Tải model: `scripts\pull-models.ps1`. Kiểm tra: `ollama list`.

## Cấu hình để container gọi được Ollama

Container Docker gọi Ollama qua địa chỉ `host.docker.internal:11434`. Ollama mặc định chỉ lắng nghe trên `127.0.0.1`, nên cần đổi một biến môi trường:

```powershell
[Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0:11434", "User")
```

Sau đó **thoát hẳn Ollama** (khay hệ thống, chuột phải, Quit) và mở lại.

> **RỦI RO:** `0.0.0.0` nghĩa là Ollama lắng nghe trên mọi địa chỉ mạng, kể cả Wi-Fi nhà bạn.
> Nên kiểm tra Windows Defender Firewall không cho phép cổng 11434 từ mạng ngoài.
> Xem thêm `docs/Security.md`.

## Kiểm tra GPU có được dùng không
1. Chạy một câu hỏi bất kỳ bằng `ollama run qwen2.5:14b`.
2. Mở cửa sổ khác, chạy `ollama ps`. Cột `PROCESSOR` nên ghi `100% GPU`.
3. Nếu ghi `CPU` hoặc có phần `CPU/GPU`, model quá lớn cho VRAM và sẽ chậm. Thử model nhỏ hơn (`llama3.1:8b`).
