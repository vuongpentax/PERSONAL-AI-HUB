#!/usr/bin/env python3
"""
validate_config.py - Kiểm tra cấu hình của Personal AI Platform.

Kiểm tra:
  1. Mọi file YAML đọc được (cú pháp hợp lệ).
  2. docker-compose.yml có đủ dịch vụ và chỉ mở cổng trên 127.0.0.1.
  3. config LiteLLM: mọi tên trong fallbacks đều tồn tại; biến môi trường được tham chiếu đã khai báo.
  4. agents/agents.yaml: model và prompt_file đều tồn tại.
  5. Không có API key hoặc khóa bí mật thật trong mã nguồn.
  6. (Tùy chọn) docker compose config với file .env.example, nếu máy có Docker.

Cách chạy (từ thư mục personal-ai-platform):
    python scripts/validate_config.py

Thoát với mã 0 nếu không có lỗi, mã 1 nếu có lỗi.
"""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover
    print("Thiếu thư viện PyYAML. Cài bằng: pip install pyyaml")
    sys.exit(2)

ROOT = Path(__file__).resolve().parent.parent
ERRORS: list[str] = []
WARNINGS: list[str] = []


def error(msg: str) -> None:
    ERRORS.append(msg)
    print(f"[LỖI]  {msg}")


def warn(msg: str) -> None:
    WARNINGS.append(msg)
    print(f"[CẢNH BÁO] {msg}")


def ok(msg: str) -> None:
    print(f"[OK]   {msg}")


def load_yaml(path: Path):
    try:
        with path.open("r", encoding="utf-8") as fh:
            return yaml.safe_load(fh)
    except yaml.YAMLError as exc:
        error(f"YAML sai cú pháp: {path.relative_to(ROOT)} -> {exc}")
    except OSError as exc:
        error(f"Không đọc được {path.relative_to(ROOT)}: {exc}")
    return None


# --- 1. Cú pháp YAML ----------------------------------------------------------
def check_yaml_syntax() -> None:
    print("\n== 1. Cú pháp YAML ==")
    files = sorted(
        p for p in ROOT.rglob("*")
        if p.suffix in {".yml", ".yaml"} and "backups" not in p.parts
    )
    if not files:
        error("Không tìm thấy file YAML nào")
    for path in files:
        before = len(ERRORS)
        load_yaml(path)  # báo lỗi bên trong nếu sai cú pháp
        if len(ERRORS) == before:
            ok(str(path.relative_to(ROOT)))


# --- 2. Docker Compose --------------------------------------------------------
def check_compose() -> None:
    print("\n== 2. docker-compose.yml ==")
    path = ROOT / "docker-compose.yml"
    data = load_yaml(path)
    if not isinstance(data, dict):
        error("docker-compose.yml không hợp lệ")
        return

    services = data.get("services", {})
    for required in ("litellm", "open-webui"):
        if required not in services:
            error(f"Thiếu dịch vụ '{required}' trong docker-compose.yml")

    for name, svc in services.items():
        for port in svc.get("ports", []) or []:
            port_text = str(port)
            if not port_text.startswith("127.0.0.1:"):
                error(
                    f"Dịch vụ '{name}' mở cổng '{port_text}' ra mọi địa chỉ. "
                    "Phải dùng dạng 127.0.0.1:<cổng>:<cổng> để tránh lộ ra mạng."
                )
            else:
                ok(f"{name}: cổng {port_text} chỉ mở trên 127.0.0.1")

    webui_env = (services.get("open-webui") or {}).get("environment", {}) or {}
    if str(webui_env.get("ENABLE_OLLAMA_API", "")).lower() != "false":
        warn("open-webui: nên đặt ENABLE_OLLAMA_API=false để mọi yêu cầu đi qua LiteLLM")


# --- 3. LiteLLM config --------------------------------------------------------
def check_litellm() -> set[str]:
    print("\n== 3. LiteLLM config ==")
    path = ROOT / "infrastructure" / "litellm" / "config.yaml"
    data = load_yaml(path)
    if not isinstance(data, dict):
        error("infrastructure/litellm/config.yaml không hợp lệ")
        return set()

    model_names: set[str] = set()
    env_refs: set[str] = set()
    for entry in data.get("model_list", []) or []:
        name = entry.get("model_name")
        if not name:
            error("Có model trong model_list thiếu model_name")
            continue
        model_names.add(name)
        for value in (entry.get("litellm_params") or {}).values():
            if isinstance(value, str) and value.startswith("os.environ/"):
                env_refs.add(value.split("/", 1)[1])
    ok(f"{len(model_names)} tên model khai báo trong model_list")

    for rule in (data.get("router_settings", {}) or {}).get("fallbacks", []) or []:
        for source, targets in rule.items():
            if source not in model_names:
                error(f"fallbacks: tên nguồn '{source}' không có trong model_list")
            for target in targets:
                if target not in model_names:
                    error(f"fallbacks: '{source}' trỏ tới '{target}' nhưng '{target}' không có trong model_list")
    ok("Chuỗi fallback tham chiếu đúng tên model")

    compose_env = set()
    compose = load_yaml(ROOT / "docker-compose.yml") or {}
    litellm_env = ((compose.get("services") or {}).get("litellm") or {}).get("environment", {}) or {}
    compose_env.update(litellm_env.keys())
    for ref in sorted(env_refs):
        if ref not in compose_env:
            error(f"config.yaml dùng biến '{ref}' nhưng docker-compose.yml chưa truyền vào service litellm")
    if env_refs and not (env_refs - compose_env):
        ok("Mọi biến môi trường LiteLLM đều được truyền vào container")
    return model_names


# --- 4. Agents ----------------------------------------------------------------
def check_agents(model_names: set[str]) -> None:
    print("\n== 4. agents/agents.yaml ==")
    data = load_yaml(ROOT / "agents" / "agents.yaml")
    if not isinstance(data, dict):
        error("agents/agents.yaml không hợp lệ")
        return
    for agent in data.get("agents", []) or []:
        aid = agent.get("id", "?")
        if agent.get("model") not in model_names:
            error(f"Agent '{aid}' dùng model '{agent.get('model')}' không có trong LiteLLM")
        prompt = agent.get("prompt_file")
        if not prompt or not (ROOT / prompt).is_file():
            error(f"Agent '{aid}' trỏ tới prompt_file không tồn tại: {prompt}")
        else:
            ok(f"Agent '{aid}' hợp lệ")


# --- 5. Quét bí mật -----------------------------------------------------------
SECRET_PATTERNS = {
    "Google API key": re.compile(r"AIza[0-9A-Za-z_\-]{35}"),
    "Groq API key": re.compile(r"gsk_[A-Za-z0-9]{20,}"),
    "OpenRouter API key": re.compile(r"sk-or-v1-[A-Za-z0-9]{20,}"),
    "OpenAI-style key": re.compile(r"sk-[A-Za-z0-9]{32,}"),
    "Khóa riêng tư": re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
}
# Chấp nhận các giá trị giữ chỗ trong file mẫu
PLACEHOLDER_HINTS = ("REPLACE", "xxxxx", "your-", "<")
SCAN_SUFFIXES = {".yml", ".yaml", ".md", ".ps1", ".py", ".json", ".mmd", ".txt", ".example", ".env"}


def check_secrets() -> None:
    print("\n== 5. Quét bí mật trong mã nguồn ==")
    found = 0
    for path in ROOT.rglob("*"):
        if not path.is_file() or ".git" in path.parts or "backups" in path.parts:
            continue
        if path.name == "validate_config.py":
            continue
        if path.suffix not in SCAN_SUFFIXES and path.name not in {".env", ".env.example"}:
            continue
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for label, pattern in SECRET_PATTERNS.items():
            for match in pattern.finditer(text):
                if any(h in match.group(0) for h in PLACEHOLDER_HINTS):
                    continue
                found += 1
                error(f"Có vẻ là {label} trong {path.relative_to(ROOT)}. Xóa ngay và xoay key mới.")

    # Cảnh báo khi .env thật tồn tại trong thư mục (không lỗi, vì là bình thường trên máy bạn)
    if (ROOT / ".env").exists():
        warn(".env đang có trên máy này. Đảm bảo nó KHÔNG được commit (đã có trong .gitignore).")
    if found == 0:
        ok("Không phát hiện API key hay khóa riêng tư trong mã nguồn")


# --- 6. Docker Compose config (tùy chọn) --------------------------------------
def check_compose_render() -> None:
    print("\n== 6. docker compose config (tùy chọn) ==")
    if not shutil.which("docker"):
        warn("Không có Docker trên máy này, bỏ qua bước render docker-compose")
        return
    env_example = ROOT / ".env.example"
    cmd = ["docker", "compose", "--env-file", str(env_example), "-f", str(ROOT / "docker-compose.yml"), "config", "-q"]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60, cwd=ROOT)
    except (OSError, subprocess.TimeoutExpired) as exc:
        warn(f"Không chạy được docker compose: {exc}")
        return
    if result.returncode == 0:
        ok("docker compose config chạy thành công với .env.example")
    else:
        error(f"docker compose config lỗi: {result.stderr.strip()[:500]}")


def main() -> int:
    print(f"Kiểm tra cấu hình trong: {ROOT}")
    check_yaml_syntax()
    check_compose()
    model_names = check_litellm()
    check_agents(model_names)
    check_secrets()
    if os.environ.get("SKIP_COMPOSE_RENDER") != "1":
        check_compose_render()

    print("\n==================================================")
    if ERRORS:
        print(f"KẾT QUẢ: {len(ERRORS)} lỗi, {len(WARNINGS)} cảnh báo. Cần sửa trước khi tiếp tục.")
        return 1
    print(f"KẾT QUẢ: đạt. {len(WARNINGS)} cảnh báo.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
