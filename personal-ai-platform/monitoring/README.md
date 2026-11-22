# Giám sát (Monitoring)

## Phase 1: đang dùng
- `scripts\health-check.ps1`: kiểm tra Docker, container, Ollama, LiteLLM, Open WebUI, dung lượng ổ đĩa và số lần bị giới hạn lượt dùng gần đây (đọc từ log).
- Log: `docker compose logs litellm` và `docker compose logs open-webui`.

## Phase 1+: đề xuất khi cần
- **Prometheus** (thu thập số liệu) và **Grafana** (vẽ biểu đồ). Đều miễn phí, mã nguồn mở.
- LiteLLM có endpoint `/metrics` khi bật tính năng tương ứng. Cần kiểm tra tài liệu LiteLLM phiên bản đang dùng.
- **Cảnh báo:** Prometheus và Grafana tốn khoảng 1–2 GB RAM. Chỉ nên thêm khi Phase 1 đã ổn định.

## Số liệu nên theo dõi
| Số liệu | Ngưỡng cảnh báo gợi ý |
|---|---|
| Số lần bị giới hạn lượt (rate limit) mỗi ngày | Trên 20 lần/ngày |
| Số lần chuyển sang Ollama mỗi ngày | Trên 50% tổng lượt |
| Dung lượng ổ đĩa còn trống | Dưới 20 GB |
| Thời gian trả lời trung bình | Trên 30 giây |
