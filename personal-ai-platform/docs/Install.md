# Hướng dẫn cài đặt (Windows 11)

Thời gian ước tính: 1–2 giờ cho lần đầu (phần lớn là tải dữ liệu).
Dung lượng cần: khoảng **50 GB** ổ trống (Docker ~10 GB, model Ollama ~20 GB, dự phòng).

> **Cấu hình máy bạn đã cung cấp:** i7-12700, RAM 32 GB, RTX 3060 12 GB. Đủ cho Phase 1.

Làm theo đúng thứ tự. Mỗi bước có cách kiểm tra "xong chưa" ngay bên dưới.

---

## Bước 1. Bật WSL2 (môi trường Linux trong Windows)

Docker Desktop cần WSL2.

1. Nhấn `Windows + X`, chọn **Terminal (Admin)** hoặc **PowerShell (Admin)**.
2. Gõ:
   ```powershell
   wsl --install
   ```
3. **Khởi động lại máy** khi được yêu cầu.
4. Sau khi khởi động lại, Windows có thể mở cửa sổ Ubuntu để tạo tài khoản Linux. Đặt tên người dùng và mật khẩu đơn giản, ghi nhớ lại.
5. Kiểm tra:
   ```powershell
   wsl --status
   ```
   Thấy dòng `Default Version: 2` là đúng.

**Giới hạn RAM cho WSL2** (để còn RAM cho Ollama): tạo file `C:\Users\<tên-bạn>\.wslconfig` với nội dung:
```ini
[wsl2]
memory=8GB
processors=8
```
Sau đó chạy `wsl --shutdown` rồi mở lại Docker Desktop.

> **Lưu ý:** `wsl --shutdown` sẽ tắt Docker. Đây là bình thường.

---

## Bước 2. Cài Docker Desktop

1. Tải tại: https://www.docker.com/products/docker-desktop
2. Cài đặt, chọn **Use WSL 2 based engine** (mặc định đã chọn).
3. Mở Docker Desktop, chấp nhận điều khoản. Đăng nhập không bắt buộc.
4. Vào **Settings → General**, bật **Start Docker Desktop when you sign in to your computer** để tự khởi động.
5. Kiểm tra trong PowerShell:
   ```powershell
   docker run --rm hello-world
   ```
   Thấy dòng `Hello from Docker!` là đúng.

> **Lưu ý về bản quyền:** Docker Desktop miễn phí cho cá nhân và doanh nghiệp nhỏ. Nếu dùng cho công ty lớn, cần kiểm tra điều kiện bản quyền của Docker.

---

## Bước 3. Cài Ollama (AI chạy trên máy bạn)

1. Tải tại: https://ollama.com/download (chọn Windows).
2. Cài đặt. Ollama sẽ tự chạy khi khởi động máy.
3. Kiểm tra trong PowerShell:
   ```powershell
   ollama --version
   ```
4. **Cho phép container gọi Ollama.** Chạy lệnh sau một lần:
   ```powershell
   [Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0:11434", "User")
   ```
5. Thoát hẳn Ollama (khay hệ thống, chuột phải, **Quit Ollama**), rồi mở lại.
6. Kiểm tra:
   ```powershell
   Invoke-RestMethod http://127.0.0.1:11434/api/tags
   ```
   Thấy kết quả (dù rỗng) là Ollama đang chạy.

> **RỦI RO BẢO MẬT:** Bước 4 làm Ollama lắng nghe trên mọi địa chỉ mạng. Chỉ thực hiện khi bạn đã đọc `docs/Security.md`, mục "Ollama". Mình khuyến nghị dùng mạng Wi-Fi gia đình có mật khẩu WPA2/WPA3 và không mở cổng nào trên router.

---

## Bước 4. Tải model Ollama

Đứng trong thư mục `personal-ai-platform` và chạy:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\pull-models.ps1
```
Quá trình mất khoảng 20–60 phút tùy tốc độ mạng.

Kiểm tra GPU đã được dùng chưa (xem thêm `infrastructure/ollama/README.md`):
```powershell
ollama run qwen2.5:14b "Xin chào, bạn là ai?"
```
Mở cửa sổ khác và chạy `ollama ps`. Cột PROCESSOR nên ghi `100% GPU`.

---

## Bước 5. Lấy API key miễn phí

Đây là các nhà cung cấp dùng trong Phase 1. Mỗi nơi cần đăng ký tài khoản riêng.

| Nhà cung cấp | Nơi lấy key | Ghi chú |
|---|---|---|
| Google Gemini | https://aistudio.google.com/apikey | Dùng cho `main` (ưu tiên đầu tiên) |
| Groq | https://console.groq.com/keys | Dự phòng nhanh |
| OpenRouter | https://openrouter.ai/keys | Chọn các model có đuôi `:free` |

**Cách giữ key an toàn:**
- Chỉ dán key vào file `.env`, không dán vào chat, email, hay ghi chú trên điện thoại.
- Đặt giới hạn chi tiêu (nếu nhà cung cấp có) để tránh tính phí ngoài ý muốn.
- Nếu nghi ngờ key bị lộ: vào trang nhà cung cấp và **xóa key cũ** ngay, tạo key mới.

> **Cảnh báo:** Gói miễn phí có giới hạn số lượt và có thể thay đổi bất cứ lúc nào. "0 đồng" có thể không ổn định mãi mãi. Hệ thống được thiết kế để tự chuyển sang Ollama khi hết lượt.

---

## Bước 6. Tải dự án về máy

Cài Git nếu chưa có: https://git-scm.com/download/win

```powershell
cd $HOME\Documents
git clone https://github.com/vuongpentax/PERSONAL-AI-HUB.git
cd PERSONAL-AI-HUB\personal-ai-platform
```

---

## Bước 7. Chạy script cài đặt

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup.ps1
```

Script sẽ:
1. Kiểm tra Docker và Ollama.
2. Tạo file `.env` với khóa bí mật ngẫu nhiên.
3. Khởi động Open WebUI và LiteLLM.

**Sau khi script chạy xong**, mở file `.env` bằng Notepad và điền API key ở bước 5:
```powershell
notepad .\.env
```
Rồi khởi động lại dịch vụ để nhận key mới:
```powershell
docker compose up -d
```

---

## Bước 8. Tạo tài khoản admin

1. Mở trình duyệt: **http://127.0.0.1:3000**
2. Nếu chưa có tài khoản nào, bấm **Sign up**. Tài khoản đầu tiên sẽ là admin.
3. Nếu **không thấy nút Sign up**: mở `.env`, đổi `ENABLE_SIGNUP=true`, chạy `docker compose up -d`, tạo tài khoản, rồi đổi lại `ENABLE_SIGNUP=false` và chạy lại `docker compose up -d`.
4. Đặt mật khẩu mạnh (ít nhất 12 ký tự, có chữ hoa, số, ký tự đặc biệt). Lưu vào trình quản lý mật khẩu.

Sau đó làm theo `infrastructure/openwebui/README.md` để tạo 4 agent.

---

## Bước 9. Kiểm tra toàn hệ thống

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\health-check.ps1
```

Kết quả mong đợi: các dòng `[PASS]` cho Docker, container, Ollama, LiteLLM, Open WebUI.

Nếu có `[FAIL]` hoặc `[WARN]`, xem `docs/Troubleshooting.md`.

---

## Bước 10. Truy cập từ điện thoại bằng Tailscale

Tailscale tạo một "đường hầm riêng" giữa điện thoại và máy tính của bạn. **Không mở cổng ra Internet, không cần VPS, không cần port forwarding.**

### 10.1 Cài trên Windows
1. Tải tại https://tailscale.com/download/windows và cài đặt.
2. Đăng nhập bằng tài khoản Google, Microsoft hoặc GitHub (gói cá nhân miễn phí).

### 10.2 Bật HTTPS cho tailnet (chỉ làm một lần)
1. Vào https://login.tailscale.com/admin/dns
2. Bật **HTTPS Certificates**.
3. Ghi lại tên máy (ví dụ `may-cua-minh.tailxxxx.ts.net`) hiển thị trong trang Machines.

### 10.3 Phơi Open WebUI ra tailnet (chỉ trong mạng riêng Tailscale)
Trong PowerShell:
```powershell
tailscale serve --bg http://127.0.0.1:3000
```
Kiểm tra trạng thái:
```powershell
tailscale serve status
```
Nếu lệnh báo lỗi cú pháp với phiên bản Tailscale của bạn, chạy `tailscale serve --help` để xem cách dùng đúng.

> **KHÔNG dùng `tailscale funnel`.** Funnel mở ứng dụng ra toàn Internet. Đây là rủi ro lớn nhất của cấu hình này.

### 10.4 Cài trên điện thoại
- **Android:** cài Tailscale từ Google Play. **iPhone:** cài từ App Store.
- Đăng nhập **cùng một tài khoản** với máy tính.
- Bật kết nối Tailscale (VPN).
- Mở trình duyệt điện thoại: `https://<tên-máy>.<tailnet>.ts.net` (ví dụ bước 10.2).
- Thêm vào màn hình chính: Chrome/Safari → menu chia sẻ → **Add to Home Screen**.

### 10.5 Kiểm soát ai được truy cập
Trong trang admin Tailscale, chỉ giữ các thiết bị bạn tin tưởng. Bật **xác thực hai lớp (2FA)** cho tài khoản Tailscale và tài khoản Google/GitHub dùng để đăng nhập.

---

## Bước 11. Sao lưu lần đầu

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\backup.ps1
```
- Cần cài 7-Zip trước: https://www.7-zip.org
- Script sẽ hỏi mật khẩu mã hóa. Ghi nhớ mật khẩu này.
- File backup nằm trong thư mục `backups\`. Copy sang ổ ngoài.

---

## Tự khởi động sau khi bật máy

| Thành phần | Cách tự chạy |
|---|---|
| Docker Desktop | Bật ở bước 2, mục 4 |
| Container (Open WebUI, LiteLLM) | `restart: unless-stopped` trong docker-compose.yml, tự chạy lại khi Docker chạy |
| Ollama | Tự chạy khi đăng nhập Windows |
| Tailscale | Tự chạy khi đăng nhập |
| Lệnh `tailscale serve` | Đã lưu với tùy chọn `--bg`, thường vẫn còn sau khi khởi động lại. Kiểm tra bằng `tailscale serve status` sau mỗi lần bật máy lần đầu. |

---

## Cập nhật hệ thống sau này
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\update.ps1
```

## Khi gặp lỗi
Xem `docs/Troubleshooting.md`.
