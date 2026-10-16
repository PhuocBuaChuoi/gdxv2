# Bonus Checklist — Co-op Physics Extensions

Các mục dưới đây mở rộng WBS chính, không thay thế trạng thái T1–T9.

## T3 / T4 — Player và dạng Tàu

- [x] Test compile toàn bộ state factory Cube/Ship/UFO/Dash.
- [x] Tách body collision khỏi hazard detector theo mask P1/P2.
- [x] Test `TetherBeam` của Ship: sensor 140px và visual line.
- [x] Tether có action gate và áp dụng lực kéo lên `CharacterBody2D`/`RigidBody2D` (test hành vi T4).
- [x] Carrier platform one-way có truyền vận tốc nền cho đồng đội.

## T5 — Checkpoint và camera co-op

- [x] Snapshot giữ vị trí spawn, form và gravity riêng của cả hai player.
- [x] Restore point có thứ tự, chặn kích hoạt checkpoint cũ hơn và hỗ trợ `require_both_players`.
- [x] Event checkpoint phát đúng spawn P1/P2 từ marker thực tế.
- [x] Respawn đồng bộ cả hai player sau `0.35s`, tăng attempt count, khóa input và ẩn/hiện visual.
- [x] Phát `level_reset_to_checkpoint` sau khi restore.
- [x] Base level nối player, coordinator và camera midpoint/zoom.
- [x] Camera có giới hạn theo TileMap, cảnh báo khoảng cách, và screen shake khi respawn.
- [x] HUD Attempt và phím `R` nối vào respawn coordinator.
- [x] Test suite Phase 5 độc lập (`tests/test_phase5_checkpoint.gd`).
- [x] `HazardDetector` phát `death_requested` và coordinator bắt sự kiện để respawn co-op đồng bộ.

## T4 — Integration regression coverage

- [x] Test head platform vật lý one-way và mask P1/P2.
- [x] Test Ship tether action gate/lực kéo.
- [x] Test Dash consume/recharge/indicator.
- [x] Dash hồi charge khi chạm carrier platform của đồng đội hoặc `DashOrb`.
- [x] Test UFO hop wave và visibility theo form.
- [x] Regression test trọng lực: Ship bám đúng `gravity_direction`, UFO chỉ nhận trọng lực một lần mỗi frame.

## T6 — Portal

- [x] `GravityPortal` đảo gravity cho Player và RigidBody2D.
- [x] Portal có `one_shot` và reset body state.
- [x] VFX/âm thanh portal và khóa đổi hướng lặp khi đứng trong vùng.

## Bonus — Cân bằng vật lý

- [x] `CoopBox` thuộc physics layer `Pushable_Blocks`.
- [x] `BalancedFloatPair` giữ hai hộp ở độ cao và khoảng cách ổn định bằng spring-damper.
- [x] Test hai hộp được chuyển sang `gravity_scale = 0` khi pair configure.
- [x] Test gameplay qua hố gai với lực kéo của Ship và checkpoint restore.

## Asset provenance / import gate

- [x] Character sheet, hai background, bunny sheet và frog sheet đều được chủ dự án xác nhận thuộc nhóm hoặc đã xin phép.
- [x] Catalog kiểm tra file tồn tại, kích thước và metadata frame trước khi tích hợp.
- [x] Background đã được tách khỏi gameplay logic qua `Parallax2D`; character sheets đi qua frame/cache pipeline.

## Visual Assets — Đã duyệt nhưng chưa gắn vào gameplay

- [x] Xác nhận quyền sử dụng sprite sheet nhân vật cho dự án giáo dục phi thương mại.
- [x] Xác nhận hai background platformer/rừng được phép sử dụng trong project.
- [x] Xác nhận sprite sheet thỏ và ếch được nhóm cho phép hoặc đã xin phép sử dụng.
- [x] Tách đường dẫn và vai trò asset vào `resources/potential_assets.gd`.
- [x] Test catalog và kiểm tra file tồn tại trước khi import vào scene.
- [x] Ghi metadata frame cho character sheet, bunny (`72x72`) và frog (`80x80`).
- [x] Chuẩn hóa sprite sheet: tách frame, xử lý nền trắng thành alpha, đặt pivot/hitbox.
- [x] Tích hợp background qua lớp `Parallax2D`, không phụ thuộc gameplay logic.
- [ ] Xác nhận metadata/provenance cụ thể trước bản phát hành public.
