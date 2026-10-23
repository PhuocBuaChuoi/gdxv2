# Thêm màn chơi bằng tay (60 giây)

> Template: `levels/base_level.tscn` · Controller: `levels/level_controller.gd`
> Tiles: paint bằng `resources/gd_neon_tileset.tres` (grid 48px)

## Tạo màn mới

1. Trong Godot Editor: chuột phải `levels/` → **Duplicate** `base_level.tscn`
   → đổi tên `level_05.tscn` (giữ tiền tố `level_`, LevelManager tự quét).
2. Mở màn mới → chọn node `TerrainLayer` → vẽ tile lên lưới 48px:
   - Cột 0: khối đặc · Cột 1: khối viền neon (cùng collision)
   - Cột 2: bệ một chiều (đứng xuyên từ dưới) · Cột 3: trang trí (không collision)
3. Kéo 2 marker `SpawnP1` (trái) / `SpawnP2` (phải) tới vị trí xuất phát.
4. (Khi có player, T3) Kéo 2 instance `characters/player.tscn` vào node
   `Players`, đặt `player_id` = 1 và 2.
5. Đặt object T6 vào đúng container: gai → `Hazards`, cổng → `Portals`,
   nút/cửa → `Mechanisms`, checkpoint → `Checkpoints`.
   `base_level.tscn` đã gắn sẵn 10 object mẫu — duplicate xong xoá/di chuyển
   theo bàn chơi:
   - `Portals/`: `GravityPortal`, `FormPortal` (đổi dạng, lọc P1_ONLY/P2_ONLY)
   - `Mechanisms/`: `DashOrb`, `CoopBox`, `FloatPair`, `DualExitGate`,
     `JumpPad` (Vàng/Hồng/Đỏ), `JumpOrb` (YELLOW/BLUE/DASH),
     `PressureButton` (HOLD/TOGGLE/SIMULTANEOUS) + `MechanizedPlatform`
     nối `linked_triggers`, `BreakableDashBlock` (chỉ Dash lướt phá được)
   - `Hazards/`: `SpikeHazard` (NEUTRAL/CYAN_SAFE_P1/ORANGE_SAFE_P2 —
     Detector của player tự bắt theo mask), `LaserHazard` (chớp tắt theo chu kỳ)
   > Muốn neon nổi kiểu GD: `background = "FOREST"` + `dim` 0.4–0.6 trên
   > `StageBackground`, mặt đi được vẽ bằng tile `=` (viền neon), tile `#`
   > chỉ dùng lót bên dưới.
6. Chạy test: `powershell -ExecutionPolicy Bypass -File tools/run_tests.ps1`
   (xanh mới push).

## Vẽ terrain bằng text (khuyên dùng)

Thay vì vẽ tile trong editor, điền export `ascii_map` của LevelRoot
(xem `levels/level_01.tscn` làm mẫu). Mỗi chuỗi = 1 hàng tile 48px:

| Ký tự | Tile | Collision |
|---|---|---|
| `#` | (0,0) khối đặc | full ô |
| `=` | (1,0) khối viền neon | full ô |
| `-` | (2,0) bệ mỏng | một chiều (nhảy xuyên từ dưới) |
| `.` | (3,0) trang trí | không |
| ` ` (cách) | trống | không |

`#` và `=` tự chọn biến thể viền neon theo hàng xóm (16 biến thể: viền ở
cạnh nào thì vẽ cạnh đó) — không cần căn tay từng ô. Ô `#`/`=` không có
hàng xóm ở trên vẫn có viền trên, nên sàn 1 hàng trông đúng kiểu GD.

Controller tự `paint_terrain()` trong `_ready` — diff review được,
test đọc lại cell để khóa layout.

## Số liệu thiết kế (đo thực, 120 Hz)

| Đại lượng | Giá trị | Dùng để |
|---|---|---|
| Cao nhảy | ~120 px (2.5 ô) | bậc leo tối đa 2 ô |
| Xa nhảy | ~303 px | hố an toàn ≤ 6 ô, hố 7 ô (336) bắt buộc coop |
| Đứng trên đầu đồng đội | +51 px → cao ~171 px | bậc 3 ô (144) chỉ leo được khi cõng nhau |
| Tile | 48 px | |

## Thiết kế 4 màn (T7.05–T7.08)

### `level_01` — Bàn nhập môn (48×12, sàn hàng 9)
Dạy 3 cơ chế coop theo thứ tự, mỗi bên có 1 hố chỉ mình qua được:

1. **Hố Cyan (cột 9–15)**: P1 đi xuyên (gai cyan an toàn cho P1). P2 đứng
   chờ bên trái. P1 bấm `ButtonA` (TOGGLE, P1_ONLY) → 5 nhịp
   `WalkwayCyan*` hạ từ y240 → y360, P2 nhảy lên băng qua.
   Đường phụ: P2 đứng trên đầu P1 (không khuyến khích — P1 nhảy là rơi).
2. **Hố Orange (cột 23–29)**: ngược lại — P2 đi xuyên gai orange, bấm
   `ButtonB` (TOGGLE, P2_ONLY) → `WalkwayOrange*` hạ, P1 băng qua.
3. **Leo cao nguyên (cột 40–47, mặt y288)**: mép cao 3 ô (144 px) — không
   ai nhảy một mình tới; P2 đứng đầu P1 rồi nhảy (171 px). P2 bấm giữ
   `ButtonC` (HOLD) → `Lift` ở rãnh cột 38–39 nâng P1 lên cùng độ cao,
   `DualExitGate` ở (2220, 232) kết thúc màn.

Đồ trang trí/bí mật: `JumpPadStart` (72,416) + `GravityJumpOrb` (72,170) +
`GravityPortal` (216,140, `toggle_mode`) tạo đường tắt trên trần;
`DashOrb` (540,160), `CoopBox` (1760,250) nằm trên bệ một chiều, `FloatPair`
(280,190). Checkpoint: (888,380) và (1704,380).

## Quy ước bắt buộc

- Tile physics đã gán sẵn layer 1 `World_Terrain` — không sửa collision trong
  TileSet khi chưa claim (hỏi Tech Lead).
- `base_level.tscn` là template: sửa cấu trúc cây phải báo cả team
  (mọi màn duplicate đều ảnh hưởng).
- Muốn đổi tileset: sửa `tools/gen_neon_tileset.gd` rồi chạy
  `tools/build_tileset.ps1` để tái sinh `neon_tiles_atlas.png` + `.tres`.
- Background minh họa: instance thêm `levels/stage_background.tscn`
  (Parallax2D thuần visual, không chạm gameplay).
