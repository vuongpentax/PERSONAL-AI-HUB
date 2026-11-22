# Lộ trình (Roadmap) và đánh giá kiến trúc

## 1. Đánh giá kiến trúc Phase 1 (thang điểm 10)

| Tiêu chí | Điểm | Nhận xét |
|---|---|---|
| Chi phí 0 đồng/tháng | 8/10 | Gói miễn phí đủ cho cá nhân, nhưng không đảm bảo mãi mãi. Tiền điện máy là chi phí ẩn. |
| Độ ổn định | 6/10 | Phụ thuộc một máy Windows, Docker Desktop, và các gói miễn phí. |
| Dễ sử dụng trên điện thoại | 8/10 | Tailscale + Open WebUI có giao diện web tốt. Cần cài Tailscale một lần. |
| Dễ bảo trì | 7/10 | Script rõ ràng, cấu hình tập trung. Phụ thuộc bạn tự chạy lệnh định kỳ. |
| Tận dụng AI miễn phí | 8/10 | Failover nhiều nhà cung cấp và Ollama GPU. |
| Bảo mật | 7/10 | Chặn đúng cổng, mã hóa backup. Ollama `0.0.0.0` và chưa có giám sát là điểm yếu. |
| **Tổng** | **7.3/10** | Đủ tốt cho Phase 1. Chưa đủ cho dữ liệu công ty quan trọng. |

## 2. Điểm yếu

1. **Một điểm lỗi duy nhất:** máy Windows tắt là mất hết.
2. **Chưa có giám sát tự động:** `health-check.ps1` chỉ chạy khi bạn nhớ chạy.
3. **Backup thủ công:** phụ thuộc kỷ luật của bạn.
4. **Chọn agent thủ công:** chưa tự nhận biết ý định.
5. **Tên model cần kiểm tra định kỳ:** nhà cung cấp đổi tên model mà không báo trước.
6. **Chưa có HTTPS nội bộ cho LiteLLM và Ollama:** chấp nhận được khi chỉ dùng trên máy.

## 3. Đề xuất phiên bản v2

- **Thay Windows bằng máy mini hoặc NAS** bật 24/7 (chi phí điện thấp hơn). Chạy Docker trên Linux, bỏ WSL2.
- **Đặt Ollama trong Docker** với GPU để gom toàn bộ vào một nơi, thay vì tách hai môi trường.
- **Thêm bộ phân loại ý định nhỏ** (có thể là một model local nhỏ) để tự chọn agent.
- **Lên lịch tự động** cho backup và health-check bằng Task Scheduler của Windows.
- **Thêm Grafana + Prometheus** khi số dịch vụ đủ nhiều để cần theo dõi.
- **Chuyển LiteLLM sang dùng PostgreSQL** để có thống kê chi tiêu và quota theo ngày.

## 4. Các giai đoạn mở rộng

### Phase 2 - Công cụ (MCP)
- **MCP Servers:** cho AI truy cập công cụ bên ngoài một cách có kiểm soát.
- **GitHub MCP:** đọc issue, PR, code trong repo của bạn.
- **Filesystem MCP:** đọc và ghi một thư mục được chỉ định.
- **Bộ phân loại ý định:** tự chọn agent khi bạn chat.
- **Rủi ro:** MCP có thể làm AI đọc/ghi file thật. Chỉ cấp quyền thư mục cần thiết, không cấp quyền toàn bộ ổ đĩa.

### Phase 3 - Tìm kiếm tài liệu (RAG)
- **Vector database** (ví dụ Qdrant hoặc Chroma chạy local, miễn phí).
- **Embedding** bằng model local để không gửi tài liệu lên cloud.
- **Tìm kiếm trong tài liệu** của bạn: PDF, ghi chú, email đã xuất.
- **Rủi ro:** chất lượng phụ thuộc vào cách chia nhỏ tài liệu. Cần thử nghiệm nhiều.

### Phase 4 - Tự động hóa và đa agent
- **Điều phối nhiều agent:** một agent lập kế hoạch, agent khác thực hiện.
- **Quy trình tự động:** ví dụ mỗi sáng tóm tắt tin và gửi vào Telegram.
- **Rủi ro lớn nhất:** agent tự làm việc có thể gây hậu quả khó đảo ngược (xóa file, gửi email). Bắt buộc có bước xác nhận của con người cho thao tác quan trọng.

## 5. Roadmap 6 tháng

| Tháng | Việc cần làm | Kết quả đo được |
|---|---|---|
| 1 | Cài Phase 1, dùng hằng ngày, ghi lại lỗi | Hệ thống chạy 2 tuần liên tục không cần can thiệp |
| 2 | Khôi phục thử từ backup, sửa tên model | Đã khôi phục thành công một lần |
| 3 | Thiết lập Task Scheduler cho backup và health-check | Backup tự động mỗi tuần |
| 4 | Thêm Prometheus/Grafana nếu cần, hoặc giữ đơn giản | Quyết định có/không và lý do |
| 5 | Bắt đầu Phase 2: thử một MCP (Filesystem, chỉ một thư mục) | Một tác vụ được tự động hóa an toàn |
| 6 | Đánh giá lại, quyết định v2 (máy riêng 24/7 hay không) | Bản đánh giá có số liệu |

## 6. Roadmap 12 tháng

| Quý | Trọng tâm |
|---|---|
| Q1 | Ổn định Phase 1, chuẩn hóa backup và tài liệu |
| Q2 | Phase 2: MCP có kiểm soát, bộ phân loại ý định |
| Q3 | Phase 3: RAG trên tài liệu cá nhân, chỉ dùng model local cho dữ liệu nhạy cảm |
| Q4 | Đánh giá v2, quyết định về phần cứng và Phase 4 |

## 7. Ưu tiên mục tiêu

| Mục tiêu | Ưu tiên | Ghi chú |
|---|---|---|
| Chi phí 0 đồng/tháng | Cao | Chấp nhận tiền điện. Gói miễn phí có thể thay đổi. |
| Độ ổn định | Cao | Cần giám sát tự động và backup định kỳ. |
| Dễ dùng trên điện thoại | Cao | Đã làm được qua Tailscale. |
| Dễ bảo trì | Trung bình | Giữ cấu hình đơn giản, ít thành phần hơn. |
| Tận dụng AI miễn phí | Trung bình | Thêm nhà cung cấp khi có nhu cầu thực tế. |

> **Lời khuyên cuối:** đừng thêm thành phần mới khi thành phần cũ chưa ổn định. Dùng Phase 1 ít nhất một tháng rồi mới nâng cấp.
