# Bảo mật (Security)

Hệ thống này giữ **API key**, **lịch sử chat**, và có thể truy cập từ điện thoại. Đọc kỹ các rủi ro dưới đây trước khi dùng thật.

## Rủi ro chính và cách giảm

| # | Rủi ro | Mức độ | Cách giảm |
|---|---|---|---|
| 1 | API key bị lộ lên GitHub | Cao | `.gitignore` đã chặn `.env`; workflow kiểm tra key trước khi merge |
| 2 | Người lạ dùng Open WebUI | Cao | Mật khẩu mạnh, tắt đăng ký, chỉ mở qua Tailscale |
| 3 | Ollama bị truy cập từ mạng Wi-Fi chung | Trung bình | Tường lửa Windows, chỉ dùng Wi-Fi tin cậy |
| 4 | File backup bị lộ | Cao | Mã hóa 7-Zip AES-256, không đưa lên GitHub |
| 5 | Thiết bị điện thoại bị mất | Trung bình | Đăng xuất Tailscale từ xa, đổi mật khẩu Open WebUI |
| 6 | Dữ liệu nhạy cảm gửi tới nhà cung cấp đám mây | Trung bình | Dùng model local cho tài liệu bí mật |
| 7 | Tài khoản Tailscale/Google bị chiếm | Cao | Bật 2FA cho mọi tài khoản |
| 8 | Tiết lộ dữ liệu qua Tailscale Funnel | Rất cao nếu bật | **Không bao giờ bật Funnel** |

## Checklist trước khi dùng thật

### Bí mật và key
- [ ] File `.env` không xuất hiện trong `git status` (đã `.gitignore`)
- [ ] `LITELLM_MASTER_KEY` và `WEBUI_SECRET_KEY` do `setup.ps1` tạo, không tự nghĩ
- [ ] API key đám mây được đặt giới hạn chi tiêu (nếu nhà cung cấp hỗ trợ)
- [ ] Không dán key vào chat, email, ảnh chụp màn hình

### Open WebUI
- [ ] Tài khoản admin có mật khẩu từ 12 ký tự trở lên
- [ ] `ENABLE_SIGNUP=false` sau khi tạo admin
- [ ] Không chia sẻ tài khoản admin

### Mạng và Tailscale
- [ ] Container chỉ bind `127.0.0.1` (xem `docker-compose.yml`)
- [ ] Đã dùng `tailscale serve`, **không** dùng `tailscale funnel`
- [ ] Chỉ có các thiết bị bạn tin tưởng trong tailnet
- [ ] 2FA bật cho tài khoản Tailscale

### Ollama
- [ ] Đã đọc phần dưới đây trước khi đặt `OLLAMA_HOST=0.0.0.0`
- [ ] Tường lửa Windows không cho phép cổng 11434 từ mạng ngoài

### Backup
- [ ] Đã thử khôi phục ít nhất một lần (backup chưa thử khôi phục thì chưa đáng tin)
- [ ] Mật khẩu backup được lưu ở nơi an toàn
- [ ] Bản backup không nằm trong thư mục repo được đồng bộ (OneDrive, Dropbox của repo)

---

## Ollama và `OLLAMA_HOST=0.0.0.0`

Container Docker cần gọi Ollama trên Windows. Cách đơn giản nhất là cho Ollama lắng nghe trên mọi địa chỉ (`0.0.0.0`). Điều này có nghĩa là **thiết bị khác trên cùng mạng Wi-Fi có thể gọi tới Ollama** nếu tường lửa không chặn.

**Cách kiểm tra từ một thiết bị khác trên cùng Wi-Fi (ví dụ điện thoại, không dùng Tailscale):**
- Mở `http://<IP-máy-Windows>:11434/api/tags`
- Nếu thấy danh sách model, **Ollama đang bị lộ ra mạng nội bộ**. Thêm quy tắc chặn cổng 11434 trong Windows Defender Firewall.

**Lựa chọn thay thế (nâng cao):** giữ Ollama ở `127.0.0.1` và đưa LiteLLM ra ngoài Docker. Cách này phức tạp hơn, dành cho Phase 2.

## Dữ liệu gửi tới nhà cung cấp đám mây

Khi dùng `main` hoặc `code` với các nhà cung cấp đám mây, nội dung câu hỏi và tài liệu tải lên **được gửi đến máy chủ của nhà cung cấp**. Điều khoản của từng nơi quy định cách họ dùng dữ liệu (có thể dùng để cải thiện dịch vụ nếu bạn dùng gói miễn phí).

**Quy tắc đề xuất:**
- Thông tin công khai, bài viết, code thông thường: dùng cloud được.
- Tài liệu công ty, dữ liệu khách hàng, thông tin cá nhân nhạy cảm: dùng `ollama-general` hoặc `ollama-coder`.

## Khi nghi ngờ bị lộ key

1. Vào trang nhà cung cấp, **xóa key cũ ngay**.
2. Tạo key mới, dán vào `.env`.
3. Chạy `docker compose up -d`.
4. Kiểm tra `git log` xem key có lỡ được commit không. Nếu có, cần xóa lịch sử và coi như key đã mất.

## Khi mất điện thoại

1. Vào https://login.tailscale.com/admin/machines, xóa thiết bị đó.
2. Đổi mật khẩu tài khoản Open WebUI.
3. Đổi mật khẩu tài khoản Google/GitHub dùng để đăng nhập Tailscale.

## Điều không bảo vệ được

- Máy tính bị nhiễm mã độc. Hãy dùng Windows Defender và cập nhật Windows thường xuyên.
- Người có quyền truy cập vật lý vào máy đã mở khóa.
- Lỗi chưa biết trong Open WebUI, LiteLLM hoặc Docker. Hãy cập nhật phiên bản khi có thông báo bảo mật.
