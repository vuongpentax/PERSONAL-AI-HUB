# Xử lý sự cố (Troubleshooting)

Bắt đầu bằng cách chạy:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\health-check.ps1
```
Kết quả `[FAIL]` hoặc `[WARN]` sẽ chỉ ra phần cần xem. Tìm mục tương ứng bên dưới.

---

## Docker Desktop không chạy

**Triệu chứng:** `docker info` báo lỗi, `setup.ps1` báo "Docker chưa chạy".

**Cách xử lý:**
1. Mở Docker Desktop từ Start menu, đợi biểu tượng cá voi ở khay hệ thống ngừng nhấp nháy.
2. Nếu vẫn lỗi: chạy `wsl --status`. Nếu WSL báo lỗi, chạy `wsl --update` rồi khởi động lại máy.
3. Đảm bảo ảo hóa được bật trong BIOS (Intel VT-x). Kiểm tra trong Task Manager, tab Performance, CPU: dòng "Virtualization" phải là Enabled.

---

## `docker compose up` lỗi

**Thông báo "Thiếu LITELLM_MASTER_KEY" hoặc "Thiếu WEBUI_SECRET_KEY":**
- File `.env` chưa có hoặc thiếu khóa. Chạy lại `setup.ps1`, hoặc kiểm tra `.env` có đủ hai dòng này không.

**Port 3000 hoặc 4000 đã được dùng:**
- Tìm tiến trình đang chiếm cổng: `netstat -ano | findstr :3000`
- Đóng ứng dụng đó, hoặc đổi cổng trong `docker-compose.yml` (ví dụ `"127.0.0.1:3001:8080"`).

**Lỗi tải image (timeout, denied):**
- Kiểm tra mạng. Thử lại `docker compose pull`.
- Nếu báo `denied`, image có thể đã đổi tên. Kiểm tra `OPEN_WEBUI_IMAGE` và `LITELLM_IMAGE` trong `.env`.

---

## Open WebUI không mở được (`http://127.0.0.1:3000`)

1. Xem container có chạy không: `docker ps`
2. Xem log: `docker compose logs open-webui --tail 100`
3. Thường gặp: container vừa khởi động, cần đợi 1–2 phút ở lần đầu tiên.
4. Nếu log báo lỗi kết nối tới `litellm`: xem mục LiteLLM bên dưới.

---

## LiteLLM báo lỗi hoặc không phản hồi

**Xem log:**
```powershell
docker compose logs litellm --tail 100
```

**Lỗi "config.yaml" hoặc "YAML":**
- Lỗi thụt đầu dòng (indent). YAML dùng dấu cách, không dùng tab.
- Chạy `python scripts/validate_config.py` (ở thư mục gốc `personal-ai-platform`) để kiểm tra.

**Lỗi "Model not found" hoặc "model ... does not exist":**
- Tên model đã đổi phía nhà cung cấp. Vào tài liệu của nhà cung cấp, tìm tên mới và sửa dòng `model:` trong `infrastructure/litellm/config.yaml`.
- Sau khi sửa: `docker compose restart litellm`.

**Lỗi 401 / "Invalid API key":**
- Key sai hoặc đã bị xóa. Kiểm tra lại `.env`, không có khoảng trắng thừa đầu/cuối.
- Sau khi sửa `.env`: `docker compose up -d` (không chỉ `restart`, vì `.env` chỉ được đọc khi tạo container).

---

## Không thấy model nào trong Open WebUI

1. Kiểm tra LiteLLM có trả lời không: mở `http://127.0.0.1:4000/health/liveliness`, phải thấy kết quả thành công.
2. Vào **Admin Panel → Settings → Connections**, kiểm tra OpenAI API trỏ tới `http://litellm:4000/v1`.
3. Bấm nút làm mới (refresh) bên cạnh ô kết nối.
4. Nếu vẫn trống: `docker compose restart open-webui`.

---

## Bị giới hạn lượt (rate limit / 429 / quota)

**Đây là tình huống bình thường** với gói miễn phí. Hệ thống sẽ tự chuyển sang model khác.

- `health-check.ps1` sẽ báo `[WARN] Giới hạn lượt dùng` nếu có lỗi gần đây.
- Nếu thường xuyên xảy ra: giảm số câu hỏi lớn, dùng `ollama-general` cho việc đơn giản, hoặc đăng ký thêm nhà cung cấp.
- Giới hạn thường reset theo phút hoặc theo ngày. Đợi một lúc rồi thử lại.

---

## Ollama không phản hồi

**Kiểm tra:**
```powershell
Invoke-RestMethod http://127.0.0.1:11434/api/tags
```

**Nếu lỗi:**
- Mở ứng dụng Ollama từ Start menu.
- Nếu container không gọi được Ollama, kiểm tra biến `OLLAMA_HOST` đã là `0.0.0.0:11434` chưa (xem `infrastructure/ollama/README.md`). Nhớ **thoát hẳn Ollama rồi mở lại** sau khi đổi biến.

**Container không gọi được Ollama (`host.docker.internal`):**
- Thử từ trong container:
  ```powershell
  docker exec personal-ai-litellm python -c "import urllib.request; print(urllib.request.urlopen('http://host.docker.internal:11434/api/tags', timeout=5).status)"
  ```
- Nếu lỗi, kiểm tra Windows Firewall có chặn cổng 11434 từ Docker không.

---

## Trả lời chậm, máy nóng, quạt quay to

- Model quá lớn cho VRAM. Chạy `ollama ps`, nếu cột PROCESSOR ghi `CPU` hoặc có `CPU/GPU`, đổi sang `llama3.1:8b`.
- Docker dùng quá nhiều RAM: đặt `memory=8GB` trong `.wslconfig` (xem `docs/Install.md`, bước 1).

---

## Điện thoại không vào được

1. Kiểm tra Tailscale trên điện thoại đang **bật** và cùng tài khoản với máy tính.
2. Trên máy tính, chạy `tailscale status`, máy điện thoại phải hiện là online.
3. Chạy `tailscale serve status`. Nếu trống, chạy lại:
   ```powershell
   tailscale serve --bg http://127.0.0.1:3000
   ```
4. Đảm bảo đã bật **HTTPS Certificates** trong trang admin Tailscale.
5. Thử mở `http://127.0.0.1:3000` trên chính máy tính. Nếu không mở được, lỗi nằm ở Docker, không phải Tailscale.

---

## Đã quên mật khẩu admin Open WebUI

Cách an toàn nhất là khôi phục từ bản sao lưu (xem `scripts\restore.ps1`). Đặt lại mật khẩu trực tiếp trong dữ liệu có rủi ro, nên không khuyến khích khi chưa có kinh nghiệm.

---

## Ổ đĩa đầy

- Xem dung lượng: `docker system df`
- Dọn image và container không dùng: `docker system prune`
  - Lệnh này **không** xóa volume (dữ liệu chat). Chỉ xóa khi bạn chắc chắn.
- Xóa model Ollama không dùng: `ollama rm <tên-model>`

---

## Cần khởi động lại toàn bộ

```powershell
docker compose down
docker compose up -d
```
Đây là cách an toàn nhất khi không rõ nguyên nhân.

---

## Lệnh hữu ích

| Việc cần làm | Lệnh |
|---|---|
| Xem trạng thái container | `docker compose ps` |
| Xem log LiteLLM | `docker compose logs litellm --tail 100` |
| Xem log Open WebUI | `docker compose logs open-webui --tail 100` |
| Khởi động lại một dịch vụ | `docker compose restart litellm` |
| Kiểm tra toàn hệ thống | `scripts\health-check.ps1` |
