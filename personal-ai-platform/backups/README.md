# Thư mục backups

Nơi lưu file sao lưu mã hóa do `scripts\backup.ps1` tạo ra.

- Tên file: `personal-ai-backup-YYYYMMDD-HHMMSS.7z`
- Mã hóa AES-256, có mã hóa cả tên file bên trong.
- Thư mục này đã được `.gitignore` chặn. **Không bao giờ** đưa file `.7z` lên GitHub.

## Quy tắc 3-2-1 (gợi ý)
- **3** bản sao dữ liệu
- **2** loại thiết bị khác nhau (ví dụ: ổ cứng ngoài + Google Drive riêng)
- **1** bản để ngoài nhà (tùy chọn)

## Ghi nhớ mật khẩu
Mật khẩu backup **không có cách lấy lại**. Lưu trong trình quản lý mật khẩu (ví dụ Bitwarden miễn phí) hoặc sổ giấy để trong két.

## Lịch gợi ý
- Hằng tuần: chạy `scripts\backup.ps1`
- Trước mỗi lần chạy `scripts\update.ps1`
