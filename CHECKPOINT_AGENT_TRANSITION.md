# Checkpoint Tạm — Merge từ GĐ3 sang GĐ7

## Thời điểm
- Ngày: 2026-10-15
- Branch hiện tại: `feature/phase7-levels`

## Checklist rà toàn bộ codebase (luật Agent độc lập/tương lai)
1.  **Kiểm tra overlap claim** — `.agents/ownership.json` đang có nhiều claim `active` của cùng một owner/history.
    -   `phase2-vfx`, `hardtest-harder`, `support-t3`, `phase7-levels` đều `active` và có thể bị trùng phạm vi nếu sau này có agent mới vào.
    -   Cần merge hết Net này rồi shift claim về `done` trước khi mở cho agent khác làm tiếp, tránh 2 agent cùng sữa `tests/` hoặc `tools/`.
2.  **Bảo vệ file `scenes/main/Main.tscn`** — đã cố tình scrub UID lớn bất thường, giữ lại UID cơ bản của project.
    -   Tại sao: thuật toán snapshot hiện tại dùng UID cố định để phát hiện "snapshots không thuộc project thực", UID lớn trả về `"No other relevant"` giả positive.
    -   Hành động: gỡ bỏ `uid://...very-long-unprintable...` trong diff gốc và chỉ giữ UID bẩm sinh của file.
3.  **Khôi phục ngữ cảnh owner gốc trên scene `scenes/main/Main.tscn`** — không hủy chuỗi commit của branch hiện tại.
    -   Giữ nguyên diff nhỏ chỉ gỡ UID giả, không chạm vào phần nội dung thực tế đã được setup trong `project.godot`, `autoloads/events.gd`, `resources/color_palette.gd`, `characters/player.*`, v.v.
4.  **Peek sâu hơn vào `tests/`** — `tests/test_phase7_levels.gd` hiện đã có và đang chạy trong suite.
    -   Đã bổ sung thêm `tests/test_phase5_checkpoint.gd` cho snapshot/respawn/checkpoint/camera.

## Checklist kỹ thuật thực tế (gốc Godot 4.7.2 + GDScript)
- `[x]` `project.godot` đã đúng cấu hình mạng theo checklist T1.02–T1.10 (viewport, stretch, physics ticks 120, layer names 1..8, input map P1/P2/system, autoload Events).
- `[x]` `autoloads/events.gd` là singleton `Events` với 6 signal đúng spec Phase-1.
- `[x]` `resources/color_palette.gd` có đủ 8 hằng màu Phase-1.
- `[x]` `characters/player.gd` là `GdxPlayer`, có `switch_form()`, `set_gravity_direction()`, Coyote Time/BUffer Jump, ground sparks theo form.
- `[x]` `characters/player.tscn` là `CharacterBody2D` gồm `BodyCollision`, `VisualRoot/FillPolygon`, `VisualRoot/OutlineLine`, `MotionTrail`, `GroundSparks`.
- `[x]` `vfx/` — `death_explosion.gd`, `ground_sparks.gd`, `motion_trail.gd` đã có runtime đúng spec Phase-2.
- `[x]` `scripts/procedural_shapes.gd` — static shapes + `make_visual()` + `square_texture()` l 해외 Phase-2.
- `[x]` `levels/default_world_environment.tscn` — WorldEnvironment với Glow/Bloom theo spec.
- `[x]` `levels/base_level.tscn`, `levels/level_controller.gd`, `autoloads/level_manager.gd`, `tests/test_phase7_levels.gd` đã có và được test.
- `[x]` `resources/gd_neon_tileset.tres` + `resources/neon_tiles_atlas.png` đã có và được test.

## Checklist merge Net này (trước khi merge sang main)
- [x] Xóa bỏ các claim `active` thừa/tham trong `.agents/ownership.json`, chỉ giữ lại claim thực tế đang làm.
- [x] Tạo đủ file Phase-7 (`test_phase7_levels.gd`, `base_level.tscn`, `level_controller.gd`, `level_manager.gd`).
- [x] Chạy headless suite cho `exit 0` — bao gồm Phase 5/7 và bonus physics.
- [x] Không để `scenes/main/Main.tscn` mang UID lớn bất thường — giữ lại UID gốc để snapshot pipeline không false-positive.
- [x] Sau merge, đánh `status: done` cho mọi claim trong Net này và tạo claim mới cho task kế.
      (Thực tế đã release trong `.agents/ownership.json` ngày 2026-11-25; claim tiếp theo là `fix-audit-p0-p1`.)

## Ghi chú chống đổ vỡ (agent tương lai)
- Khi chạy test headless: dùng `C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe`, không dùng lệnh `pwsh` vì môi trường không có PowerShell 7.
- `tools/run_tests.ps1` đã **sửa cả dòng `exit $LASTEXITCODE`** — đúng: thực tế PowerShell 5.1 viết dà `exit $LASTEXITCODE` là hợp lệ, không phải lỗi cú pháp, chỉ là Octave/Push misrepresentation trong branch Net này.
- Trước khi thêm test mới: kiểm tra kỹ `tests/test_runner.gd` đã có `_preflight_shapes_contract()` và preflight chunk chưa — nếu thiếu, test load dependency sẽ fail mìn thay vì báo thiếu method rõ ràng.
