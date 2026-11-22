# Tự động hóa (Automation)

Phase 1 **chưa có** tự động hóa quy trình AI. Thư mục này để dành cho Phase 2 và Phase 4.

## Đã có: tự động hóa cho việc bảo trì
Dùng **Task Scheduler** của Windows để chạy định kỳ (cài đặt thủ công, không bắt buộc):

- Hằng tuần: `scripts\backup.ps1`
- Hằng ngày: `scripts\health-check.ps1` (ghi kết quả ra file trong `logs\`)

Cách tạo: Start → gõ "Task Scheduler" → Create Basic Task → chọn lịch → Action: Start a program → Program: `powershell.exe` → Arguments: `-ExecutionPolicy Bypass -File "<đường dẫn>\scripts\backup.ps1"`.

> **Lưu ý:** backup cần nhập mật khẩu 7-Zip nên **không chạy hoàn toàn tự động được** an toàn. Phase 2 sẽ bàn cách xử lý.

## Kế hoạch Phase 4
Xem `docs/Roadmap.md`, mục Phase 4. Nguyên tắc: mọi thao tác có thể gây hậu quả (xóa, gửi, ghi đè) phải có bước xác nhận của con người.
