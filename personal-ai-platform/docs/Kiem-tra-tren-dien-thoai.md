# Checklist thử nghiệm (đọc được trên điện thoại)

Dùng tài liệu này khi bạn về nhà và ngồi trước máy Windows. Làm từng bước theo thứ tự. Mỗi bước có **kết quả mong đợi**. Nếu khác, dừng lại và gửi mẫu báo lỗi ở cuối trang.

---

## Trước khi bắt đầu (trên điện thoại, ngoài đường)
- [ ] Đọc xong `docs/Install.md` một lần để biết các bước.
- [ ] Đã có API key Gemini / Groq / OpenRouter, hoặc chấp nhận chạy chỉ bằng Ollama.
- [ ] Đã có tài khoản Tailscale (đăng nhập bằng Google, Microsoft hoặc GitHub).

> Lúc ở ngoài đường, **đừng** thử cài đặt trên điện thoại. Chỉ cài Tailscale trên điện thoại. Phần còn lại làm trên máy Windows.

---

## Phần A: Trên máy Windows (ở nhà)

| # | Việc làm | Kết quả mong đợi | ☐ |
|---|---|---|---|
| A1 | Mở PowerShell, chạy `wsl --status` | Có dòng `Default Version: 2` | ☐ |
| A2 | Mở Docker Desktop, chạy `docker run --rm hello-world` | Có dòng `Hello from Docker!` | ☐ |
| A3 | Mở Ollama, chạy `Invoke-RestMethod http://127.0.0.1:11434/api/tags` | Có kết quả (dù rỗng) | ☐ |
| A4 | Chạy `scripts\pull-models.ps1` | Tải xong 3 model, không có dòng `[X]` | ☐ |
| A5 | Mở `.env`, điền API key, rồi `docker compose up -d` | Không có lỗi `Thiếu ...` | ☐ |
| A6 | Chạy `scripts\setup.ps1` | Có dòng "Xong bước cài đặt" | ☐ |
| A7 | Mở `http://127.0.0.1:3000`, tạo tài khoản admin | Vào được màn hình chat | ☐ |
| A8 | Chạy `scripts\health-check.ps1` | Không có dòng `[FAIL]` | ☐ |
| A9 | Chat thử một câu với model `main` | Có câu trả lời | ☐ |
| A10 | Chat thử một câu với model `code` | Có câu trả lời (có thể chậm lần đầu) | ☐ |
| A11 | Chạy `scripts\backup.ps1` | Có file `.7z` trong thư mục `backups\` | ☐ |
| A12 | Chạy `tailscale serve --bg http://127.0.0.1:3000` | Không báo lỗi, `tailscale serve status` có địa chỉ | ☐ |

---

## Phần B: Trên điện thoại (sau khi xong phần A)

| # | Việc làm | Kết quả mong đợi | ☐ |
|---|---|---|---|
| B1 | Cài app Tailscale (Android: Google Play, iPhone: App Store) | Đăng nhập được | ☐ |
| B2 | Kiểm tra cùng tài khoản với máy Windows | Thấy máy Windows trong danh sách | ☐ |
| B3 | Bật Tailscale, mở trình duyệt, vào `https://<tên-máy>.<tailnet>.ts.net` | Hiện màn hình đăng nhập Open WebUI | ☐ |
| B4 | Đăng nhập bằng tài khoản admin, gửi một câu hỏi | Có câu trả lời | ☐ |
| B5 | Thêm vào màn hình chính (Add to Home Screen) | Có biểu tượng trên màn hình | ☐ |
| B6 | Tắt Wi-Fi, dùng 4G, mở lại trang | Vẫn vào được (vì Tailscale đi qua mạng) | ☐ |

> **Không** dùng `tailscale funnel`. Chỉ dùng `tailscale serve`.

---

## Phần C: Nếu có lỗi, gửi mẫu này cho mình

Copy đoạn dưới, điền và gửi:

```text
Bước lỗi: (ví dụ A5, B3)
Lệnh đã chạy: (ví dụ docker compose up -d)
Thông báo lỗi: (chụp màn hình hoặc chép nguyên văn)
Kết quả health-check: (chép các dòng [PASS] / [FAIL] / [WARN])
Cấu hình máy: (ví dụ Windows 11, RAM 32GB, RTX 3060)
```

Chỉ cần gửi phần liên quan. Không gửi nội dung file `.env` và không gửi API key.

---

## Lưu ý khi thử nghiệm
- Trước khi thử, chạy `scripts\backup.ps1` để có bản sao lưu (nếu có lỗi, dữ liệu vẫn an toàn).
- Nếu lỗi nặng, chạy `docker compose down` để dừng hệ thống, rồi báo lại cho mình.
- Ghi lại thời gian trả lời của model `main` và `code`. Thông tin này giúp mình chọn model phù hợp hơn.
