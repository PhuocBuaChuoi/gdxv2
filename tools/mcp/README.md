# Godot MCP live-play harness (real input, real window, real logs)

Bộ này là cách **chơi thật** game qua MCP: inject input vào cửa sổ Godot đang chạy,
chụp ảnh màn hình, đọc `get_errors` / `get_debug_output`, rồi sửa lỗi tìm được.

## Server đang dùng

| | |
|---|---|
| Server | [`leftos/godot-mcp`](https://github.com/leftos/godot-mcp) `0.47.1+8b43bba` (77 tool) |
| Runtime | .NET 10 (`winget install Microsoft.DotNet.SDK.10`, đã test `10.0.15`) |
| Binary | `%LOCALAPPDATA%\godot-mcp\godot-mcp.exe` |
| Engine | repo tự chứa: `godot_engine/Godot_v4.7.2-stable_win64_console.exe` |

Lý do chọn leftos: nó thật sự **inject input** (`simulate_action`, `simulate_input`,
`stress_input`), **chụp màn hình** (`take_screenshot`) và **đọc lỗi runtime**
(`get_errors`, `get_debug_output`) trên tiến trình game đang chạy — khác với
harness in-engine (chỉ chạy kịch bản trong game, không có input thật).

### Cài lại từ đầu (một lần)

```powershell
winget install --id Microsoft.DotNet.SDK.10 -e          # runtime .NET 10
# tải installer của leftos/godot-mcp rồi chạy; nếu thư mục đích đã có
# %LOCALAPPDATA%\godot-mcp\update-check.json thì move nó đi trước (installer từ chối
# thư mục có file lạ):
#   mv "$env:LOCALAPPDATA\godot-mcp\update-check.json" "$env:LOCALAPPDATA\godot-mcp-update-check.bak.json"
```

Cấu hình MCP đã wire sẵn ở `.agents/mcp_config.json` (entry `godot-live`), với
`GODOT_PATH` trỏ engine console trong repo và `GODOT_PROJECT_PATH` trỏ repo.

## Chạy trong một lệnh

Client tự spawn server, tự `run_project`, và tự `stop_project` khi xong:

```bash
# 1) chơi thật: giữ phím chạy + nhảy nhịp đều, chụp ảnh mỗi 120 frame, đọc lỗi
node tools/mcp/godot_mcp_client.mjs --play res://levels/e2e_gallery.tscn --frames 840

# 2) kịch bản có sẵn (laser bật lại khi player đứng trong tia — bug đã fix)
node tools/mcp/godot_mcp_client.mjs --script tools/mcp/session_laser2.json

# 3) xem tool / schema
node tools/mcp/godot_mcp_client.mjs --list
node tools/mcp/godot_mcp_client.mjs --schema take_screenshot
```

`--play` nhận thêm `--jump-every`, `--shot-every`, `--hold p1_left|p1_right`,
`--session`, `--out .tmp/mcp`. Ảnh + log nằm trong `.tmp/mcp/` (đã gitignore).

## Recipe có sẵn

| File | Dùng để |
|---|---|
| `session_probe.json` | smoke test level_01: chạy, nhảy, 3 ảnh, đọc lỗi |
| `session_diag.json` | ground truth vị trí/velocity/form của P1 ở level_04 |
| `session_hunt_level04.json` | đi xuyên level_04: portal, dash, laser, respawn |
| `session_hunt2.json` | jump + `switch_form` giữa cú nhảy, chết vì laser, spam input lúc respawn |
| `session_laser2.json` | **hồi quy**: đứng sẵn trong tia lúc TẮT, chờ tia BẬT → phải chết |
| `session_laser3.json` | chẩn đoán: in `get_overlapping_areas()` của `HazardDetector` |
| `session_fuzz_gallery.json` | 500 input ngẫu nhiên trên gallery, đọc lỗi |
| `session_laser_reactivate.json` | bản đầu của phép thử laser (giữ làm lịch sử) |
| `session_gate_blocked.json` | level_03: P1 đi trên trần đâm vào vách ngăn (trước fix: kẹt `x=1225.9`) |
| `session_gate_open.json` | level_03: bấm cả 2 nút đồng thời rồi đi qua cửa (sau fix: `x=1908`) |
| `session_gate_open_06.json` | level_06: bản tương tự (sau fix: `x=1801.9`) |

Mẫu một bước trong `--script`:

```json
{ "tool": "simulate_action", "args": { "action": "p1_jump", "options": { "mode": "tap" }, "session": "gdx-hunt" } }
```

`${REPO}` và `${GODOT}` trong JSON được thay bằng đường dẫn thật lúc chạy.

## Bug tìm được bằng vòng live này

**Tia laser bật lại không giết người đứng sẵn trong tia** (level_04, `LaserGate`
tại `x=1150`). Đo live: player đứng trong tia lúc TẮT, chờ `is_on == true`
+ 8 frame → `attempt_count` vẫn `0`, `get_overlapping_areas()` của
`HazardDetector` rỗng dù tia BẬT / `monitorable = true` / layer `8`. Nguyên nhân:
tắt `monitoring`/`monitorable`/layer thì Godot gỡ cặp area nhưng **không dựng lại**
khi bật lại. Fix: giữ tia luôn discoverable, gỡ/ráp `CollisionShape2D` mới là thứ
làm cặp va chạm được tạo lại; player quét lại hazard đang trùng mỗi frame.

Hồi quy: `tests/test_phase6_tools.gd::test_laser_reactivation_stays_discoverable`
(unit) và bước cuối của `levels/e2e_driver.gd` (physics thật).

**Vách ngăn màn 3/6 chôn trong cột đá tĩnh (màn không thể hoàn thành)**. Cả
`level_03` và `level_06` có một cột đá 2x6 nằm đúng chỗ `MiddleWall`/
`LowerWall`, chắn ngang làn trần. Đo live: bấm đủ 2 nút (cả hai `is_on = true`,
cửa đã trượt lên) nhưng P1 đảo trọng lực vẫn kẹt ở `x=1225.9` (level_03) —
cột tĩnh dày 96px chặn đường tới `ExitGravityPortal`. Fix: bỏ cột tĩnh khỏi
`ascii_map`, đặt `MiddleWall` ở `y=118` để nó đóng đúng làn trần và rút hẳn vào
trần khi mở. Hồi quy: `tests/test_phase7_levels.gd::test_gate_is_not_walled_off`
+ 3 session ở bảng trên.
