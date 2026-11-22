# Open WebUI - Giao diện trung tâm

Open WebUI là nơi bạn chat hằng ngày, trên máy tính và điện thoại. Mọi yêu cầu đi qua LiteLLM, nên bạn không phải chọn nhà cung cấp thủ công.

## 1. Sau lần đăng nhập đầu tiên

1. Vào **Admin Panel → Settings → General**, tắt đăng ký mới nếu không cần (hoặc đặt `ENABLE_SIGNUP=false` trong `.env`).
2. Vào **Settings → Connections** và kiểm tra:
   - OpenAI API: `http://litellm:4000/v1` (đã cấu hình sẵn qua Docker)
   - Ollama API: đã tắt (mọi thứ đi qua LiteLLM)
3. Vào **Models** và kiểm tra danh sách có các tên `main`, `code`, `gemini-flash`, `groq-llama`, `openrouter-free`, `ollama-general`, `ollama-coder`.

Nếu danh sách trống: xem `docs/Troubleshooting.md`, mục "Không thấy model nào".

## 2. Tạo 4 Agent mặc định

Trong **Workspace → Models → +** (Create a model), tạo lần lượt:

| Tên hiển thị | Base model | System prompt (copy từ file) |
|---|---|---|
| Researcher | `main` | `prompts/researcher.md` |
| Coder | `code` | `prompts/coder.md` |
| Writer | `main` | `prompts/writer.md` |
| Assistant | `main` | `prompts/assistant.md` |

Khi tạo xong, bạn sẽ thấy 4 agent trong danh sách chọn model khi chat.

## 3. Bật tính năng nhớ dài hạn (Long-term Memory)

**Settings → Personalization → Memory**: bật. Ghi vào đây những thông tin bạn muốn AI nhớ lâu dài, ví dụ:
- Sở thích: "Tôi thích câu trả lời ngắn gọn, có gạch đầu dòng."
- Dự án đang làm: "Tôi đang xây dựng trang bán hàng bằng React."

Không ghi thông tin nhạy cảm (số thẻ, mật khẩu, số CCCD) vào memory.

## 4. Tìm lịch sử chat và nhiều workspace
- Thanh tìm kiếm bên trái tìm trong toàn bộ lịch sử chat.
- Tạo thư mục (Folder) để gom chat theo dự án.
- Upload file: nút đính kèm trong ô chat (PDF, DOCX, TXT...).

## 5. Cảnh báo
- Đừng upload tài liệu bí mật của công ty hoặc khách hàng lên các nhà cung cấp đám mây miễn phí. Dữ liệu có thể được dùng để cải thiện dịch vụ theo điều khoản của họ.
- Dùng model local (`ollama-general`, `ollama-coder`) cho tài liệu nhạy cảm. Dữ liệu không rời khỏi máy bạn.
