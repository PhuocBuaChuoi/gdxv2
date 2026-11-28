# Chọn sprite cho chi tiết nào (Sprite Casting)

> Khảo sát trực tiếp 5 file `potential_Assets/` ngày 2026-10-16.
> **3 sheet = 3 skin nhân vật** (không phải địch). Định nghĩa state trong
> `resources/character_skins.gd`; helpers trong `resources/asset_frames.gd`.
> Neon procedural vẫn là visual mặc định (mã màu P1 cyan/P2 cam); skin là
> lớp thay thế khi muốn look pixel-art.

## Skin bird — chim tròn xanh (252x408, 3 cột x 4 hàng, frame 84x102, nền trắng)

| State | Frame | Nội dung | Dùng khi |
|---|---|---|---|
| idle | 0–2 | Nhìn thẳng, 3 nhịp nhún | Đứng yên / mặt trước |
| run_left | 3–5 | Nghiêng trái, 3 nhịp bước | Chạy sang trái |
| run_right | 6–8 | Nghiêng phải, 3 nhịp bước | Chạy sang phải |
| jump | 7 | Giữa nhịp chạy phải | Airborne (giữ 1 frame) |
| flip | 9–11 | Nhìn sau lưng | Đảo trọng lực / đi trần (T6) |

## Skin bunny — thỏ trắng (288x576, 4 cột x 8 hàng, frame 72x72, nền đen)

| State | Frame | Nội dung | Dùng khi |
|---|---|---|---|
| idle | 0–3 | Ngồi thẳng, tai dựng | Đứng yên |
| run | 20–23 | Chu kỳ chạy sang phải | Chạy (trái: `flip_h`) |
| jump | 4–7 | Chu kỳ hop bổng | Airborne (chạy cả chu kỳ cho nảy) |
| crouch | 24–27 | Ngồi xổm thấp | Tiếp đất / nấp |

- 8 hàng là 8 bộ pose (không theo lưới 4 hướng) — state map theo hàng đã
  khảo sát, không suy diễn thêm.

## Skin frog — ếch xanh (640x320, 8 cột x 4 hàng, frame 80x80, nền trắng)

| State | Frame | Nội dung (verify lại hướng trong editor) | Dùng khi |
|---|---|---|---|
| idle | 0–7 | Nhìn thẳng, ộp miệng 8 nhịp | Đứng yên (chu kỳ 1s @8fps) |
| run | 16–23 | Nghiêng bước | Chạy |
| jump | 8–15 | Nghiêng hop | Airborne |
| flip | 24–31 | Nhìn sau | Đảo trọng lực |

## Quy ước chung 3 skins

- **Không có state chết**: chết = `death_explosion` VFX (T2.04) cho cả 3 skin.
- **Xoay Cube**: skin sprite thì TẮT xoay 90° khi bay (agent player T4 lưu ý),
  chỉ xoay khi Dash — nếu không nhân vật trồng cây chuối.
- P1/P2 dùng skin khác nhau (vd. P1 bird, P2 frog) thay vì tint màu lên sprite
  (tint cam lên thân xanh ra màu bùn).
- Scale chuẩn: cao frame về 48px vừa hitbox (`target_height` mặc định).
- Hướng mặt các hàng ếch/thỏ cần confirm lại trong editor khi gắn lần đầu
  (ảnh khảo sát nhỏ, pose complex).

## Background

| Nền | Kích thước | Dùng cho |
|---|---|---|
| BRIGHT (trời xanh, gạch cam) | 735x412 | Màn 1–2 tutorial/ngày |
| FOREST (rừng tối, tia sáng) | 1199x648 | Màn 3+ / cave (hợp glow neon) |

- Chọn theo màn bằng `@export background` của `level_controller`
  (mặc định FOREST).
- `@export dim` (0.4–1.0): hạ sáng nền màn đêm để gameplay neon nổi.

## Pivot / hitbox chuẩn

- Đứng đất: pivot chân `PIVOT_FEET = (0.5, 1.0)`; dạng xoay (Cube/Dash):
  pivot giữa (`centered = true`, mặc định của helpers).
- Hitbox đề xuất: `hitbox_rect(frame, 0.12)` — co 12% khỏi chết oan mép.
