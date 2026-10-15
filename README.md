# 🎮 gdxv2 — Godot 4 2D Game Project

> **Engine:** Godot 4.7.2 · **Language:** GDScript 2.0 · **Type:** 2D Game

---

## 📋 Mục lục
- [Giới thiệu](#giới-thiệu)
- [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
- [Cài đặt & Khởi chạy](#cài-đặt--khởi-chạy)
- [Cấu trúc dự án](#cấu-trúc-dự-án)
- [🤖 Hướng dẫn cho AI Agents](#-hướng-dẫn-cho-ai-agents)
- [Git Workflow](#git-workflow)
- [Quy ước code](#quy-ước-code)

---

## Giới thiệu

Dự án game 2D được xây dựng trên **Godot Engine 4.7.2** sử dụng GDScript 2.0.

---

## Yêu cầu hệ thống

| Thành phần | Yêu cầu |
|---|---|
| Godot Engine | 4.7.2 stable |
| OS | Windows 10/11, Linux, macOS |
| GPU | Vulkan 1.0+ (khuyến nghị) hoặc OpenGL 3.3+ |
| RAM | ≥ 4 GB |

---

## Cài đặt & Khởi chạy

`ash
# 1. Clone repo
git clone <repo-url>
cd gdxv2

# 2. Mở Godot 4.7.2 và import project.godot
# Godot > Import > chọn file project.godot trong thư mục này

# 3. Nhấn F5 hoặc Play để chạy
`

---

## Cấu trúc dự án

`
gdxv2/
├── project.godot          # File cấu hình Godot (KHÔNG xóa/sửa tùy tiện)
├── README.md              # File này
├── .gitignore             # Bỏ qua file Godot cache
├── .gitattributes         # Xử lý line endings
│
├── scenes/                # Tất cả Scene (.tscn)
│   ├── main/              # Scene chính
│   ├── ui/                # UI scenes
│   └── levels/            # Level scenes
│
├── scripts/               # GDScript (.gd) độc lập
├── assets/                # Tài nguyên (ảnh, âm thanh, font)
│   ├── sprites/
│   ├── audio/
│   └── fonts/
│
├── autoloads/             # Singleton / Autoload scripts
└── addons/                # Plugin Godot
`

---

## 🤖 Hướng dẫn cho AI Agents

> **⚠️ ĐỌC KỸ TRƯỚC KHI BẮT ĐẦU** — Phần này dành riêng cho các AI agent làm việc trên dự án này.

### Nguyên tắc tuyệt đối

1. **LUÔN LUÔN commit trước khi bắt đầu task mới**
   - Kiểm tra trạng thái: `git status`
   - Nếu có file chưa commit → commit hoặc stash TRƯỚC
   - Không bao giờ bắt đầu task mới trên working tree bẩn

2. **Làm việc trên branch riêng, KHÔNG commit thẳng vào `main`**
   `ash
   # Tạo branch cho từng task
   git checkout -b feature/<tên-task>
   # hoặc
   git checkout -b fix/<tên-bug>
   `

3. **Commit thường xuyên và có ý nghĩa**
   `ash
   # Format commit message
   git commit -m "<type>(<scope>): <mô tả ngắn>"
   
   # Các type hợp lệ:
   # feat     — thêm tính năng mới
   # fix      — sửa bug
   # refactor — tái cấu trúc code
   # docs     — cập nhật tài liệu
   # assets   — thêm/sửa tài nguyên
   # config   — thay đổi cấu hình
   
   # Ví dụ:
   git commit -m "feat(player): thêm hệ thống nhảy double-jump"
   git commit -m "fix(ui): sửa lỗi health bar không cập nhật"
   `

### Quy tắc chống đụng độ (Anti-Conflict Rules)

**KHÔNG bao giờ:**
- Sửa cùng một .tscn file với agent khác đang làm
- Commit file .godot/ (cache) hoặc .import/
- Force push lên main
- Merge mà không resolve conflict

**LUÔN LUÔN:**
- Pull origin trước khi bắt đầu: `git pull origin main`
- Rebase hoặc merge thường xuyên với main
- Tạo PR/MR thay vì push thẳng
- Thông báo (trong commit message) file nào đang được sửa

### Lock File Convention (Quy ước khóa file)

Khi đang sửa một scene hoặc script lớn, tạo file lock để thông báo:
`ash
# Tạo lock file (Windows PowerShell)
"Agent: <tên-agent> | Task: <mô tả> | Started: 10/15/2026 19:59:00" | Out-File scenes/main/MainScene.tscn.lock

# Xóa lock file sau khi hoàn thành và commit
Remove-Item scenes/main/MainScene.tscn.lock
git commit -m "chore: release lock on MainScene.tscn"
`

### Workflow chuẩn cho AI Agent

`
1. git pull origin main              # Lấy code mới nhất
2. git checkout -b feature/<task>    # Tạo branch mới
3. [Làm việc, sửa file]
4. git add -p                        # Review từng thay đổi
5. git commit -m "..."               # Commit với message rõ ràng
6. git push origin feature/<task>    # Push branch
7. [Tạo Pull Request]
8. [Sau khi merge] git checkout main && git pull
`

### Files quan trọng — Cẩn thận khi sửa

| File | Mức độ rủi ro | Ghi chú |
|---|---|---|
| `project.godot` | 🔴 Rất cao | Chỉ sửa khi cần thiết, luôn review kỹ |
| `autoloads/*.gd` | 🟠 Cao | Ảnh hưởng toàn dự án |
| `scenes/main/*.tscn` | 🟠 Cao | Scene gốc, dễ conflict |
| `scripts/globals.gd` | 🟠 Cao | Global constants |
| `scenes/levels/*.tscn` | 🟡 Trung bình | Mỗi level là file riêng |
| `assets/*` | 🟢 Thấp | Thường không conflict |

### Kiểm thử tự động & phối hợp nhiều agent

- Chạy test trước khi push (bắt buộc xanh): `powershell -ExecutionPolicy Bypass -File tools/run_tests.ps1`
- Đọc `.agents/COLLAB.md` và đăng ký claim trong `.agents/ownership.json` trước khi sửa file — áp dụng cho cả agent và người.

---

## Git Workflow

### Branch naming
`
main            — production, luôn hoạt động
develop         — branch phát triển chính  
feature/<name>  — tính năng mới
fix/<name>      — sửa bug
hotfix/<name>   — sửa gấp trên production
`

### Merge Strategy
- Dùng **Squash and Merge** cho các feature branch nhỏ
- Dùng **Merge Commit** cho các feature branch lớn có nhiều commits có ý nghĩa
- **KHÔNG dùng Rebase** trên shared branches

---

## Quy ước code

### GDScript Style Guide

`gdscript
# ✅ Đúng: snake_case cho biến và hàm
var player_speed: float = 200.0
var is_jumping: bool = false

func move_player(delta: float) -> void:
    pass

# ✅ Đúng: PascalCase cho class
class_name PlayerController
extends CharacterBody2D

# ✅ Đúng: SCREAMING_SNAKE_CASE cho constants
const MAX_JUMP_HEIGHT: int = 150
const GRAVITY: float = 980.0

# ✅ Đúng: Luôn khai báo type
var health: int = 100
@export var speed: float = 200.0
`

### Scene / Node naming
- Nodes: PascalCase (e.g., PlayerSprite, HealthBar)
- Scene files: snake_case.tscn (e.g., main_menu.tscn, level_01.tscn)
- Script files: snake_case.gd (e.g., player_controller.gd)

---

## License

*Chưa xác định — cập nhật sau*

---

*Cập nhật lần cuối: 2026-10-15*


---

## 🤖 MCP Server — Godot Engine Integration

### Cài đặt đã thực hiện

| Thành phần | Chi tiết |
|---|---|
| Package | `@coding-solo/godot-mcp` v0.1.1 |
| Cài đặt | Global npm (`%APPDATA%\npm\godot-mcp`) |
| Config | `.agents/mcp_config.json` |
| Godot Path | `%LOCALAPPDATA%\Programs\Godot\godot.exe` |

### Godot MCP cho phép AI agent làm gì?

- **Launch editor**: Mở Godot editor lên từ code
- **Run project**: Chạy game ở debug mode, capture output
- **Scene management**: Tạo scene, thêm node, set properties
- **Script editing**: Viết/sửa GDScript file trực tiếp
- **Debug output**: Đọc console log, stack trace realtime
- **UID management**: Quản lý resource UIDs (Godot 4.4+)

### Cách dùng MCP với Antigravity IDE

Config tại `.agents/mcp_config.json` sẽ tự động được load khi làm việc trong workspace này.

### Cài thủ công (nếu máy khác)

```bash
# 1. Cài Godot 4.7.2 và để path vào biến môi trường GODOT_PATH
# 2. Cài MCP server
npm install -g @coding-solo/godot-mcp

# 3. Đảm bảo .agents/mcp_config.json có đường dẫn đúng
```
