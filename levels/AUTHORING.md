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
6. Chạy test: `powershell -ExecutionPolicy Bypass -File tools/run_tests.ps1`
   (xanh mới push).

## Quy ước bắt buộc

- Tile physics đã gán sẵn layer 1 `World_Terrain` — không sửa collision trong
  TileSet khi chưa claim (hỏi Tech Lead).
- `base_level.tscn` là template: sửa cấu trúc cây phải báo cả team
  (mọi màn duplicate đều ảnh hưởng).
- Muốn đổi tileset: sửa `tools/gen_neon_tileset.gd` rồi chạy
  `tools/build_tileset.ps1` để tái sinh `neon_tiles_atlas.png` + `.tres`.
- Background minh họa: instance thêm `levels/stage_background.tscn`
  (Parallax2D thuần visual, không chạm gameplay).
