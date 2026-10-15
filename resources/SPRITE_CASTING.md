# Chọn sprite cho chi tiết nào (Sprite Casting)

> Khảo sát trực tiếp 5 file `potential_Assets/` ngày 2026-10-16.
> Nguyên tắc: neon procedural vẫn là visual chính (mã màu P1 cyan/P2 cam);
> sprite là skin thay thế + enemy. Code: `resources/asset_frames.gd`.

## Nhân vật chính — chim tròn xanh (252x408, 3 cột x 4 hàng, frame 84x102)

| Hàng | Frame | Nội dung | Dùng cho |
|---|---|---|---|
| 0 | 0–2 | Nhìn thẳng, 3 nhịp nhún | Idle / mặt trước Cube |
| 1 | 3–5 | Nghiêng trái, 3 nhịp bước | Chạy sang trái |
| 2 | 6–8 | Nghiêng phải, 3 nhịp bước | Chạy sang phải |
| 3 | 9–11 | Nhìn sau lưng | Đảo trọng lực / leo trần |

- Dáng tròn ~84px, scale về cao 48px vừa hitbox (`make_animated_visual(..., 48.0)`).
- LƯU Ý cho agent player (T4): Cube xoay 90° khi bay — skin sprite thì TẮT xoay
  hoặc chỉ xoay khi ở dạng Dash, nếu không nhân vật sẽ trồng cây chuối.
- P1/P2 phân biệt bằng modulate nhẹ hoặc giữ nguyên (xanh ≈ cyan); đừng tint
  cam lên thân xanh (nhân ra màu bùn).

## Địch loại A — ếch xanh (640x320, 8 cột x 4 hàng, frame 80x80, nền trắng)

| Hàng | Frame | Nội dung (xác minh lại trong editor) | Dùng cho |
|---|---|---|---|
| 0 | 0–7 | Nhìn thẳng, biến thể miệng/nhảy | Ếch đứng gác / idle |
| 1–2 | 8–23 | Nghiêng các tư thế nhảy | Ếch nhảy qua hố gai |
| 3 | 24–31 | Nhìn sau | Quay lưng / trinh sát |

- Nền trắng → dùng `keyed_frame()` (đã tách nền, test khóa).
- Màu xanh lá nổi trên nền tối — hợp vai hazard/critter, KHÔNG nên làm P2
  (xanh lá dễ lẫn vùng an toàn P1... thực tế P1 là cyan, vẫn phân biệt được;
  quyết định cuối thuộc về design).

## Địch loại B / trang trí — thỏ trắng (288x576, 4 cột x 8 hàng, frame 72x72)

- 8 hàng = 8 bộ pose (ngồi, nhảy, chạy), mỗi hàng 4 frame — KHÔNG theo lưới
  4 hướng như 2 sheet kia, dùng nguyên hàng làm 1 chu kỳ (`row_frames`).
- Trắng trên nền tối cực nổi — hợp làm collectible/linh vật dẫn đường.
- Nền đen → `white_to_alpha` tách theo pixel góc (đã test).

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
