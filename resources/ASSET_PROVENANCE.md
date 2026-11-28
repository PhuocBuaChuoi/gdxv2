# Nguồn gốc assets visual (Provenance)

> Tổng hợp từ `resources/potential_assets.gd` (quyền do chủ project xác nhận
> ngày 2026-10-15) và `BONUS_CHECKLIST.md`. File này chỉ ghi nhận hiện trạng,
> không thay thế xác minh pháp lý.

## Đã duyệt dùng cho project giáo dục phi thương mại

| Asset | File | Metadata | Quyền |
|---|---|---|---|
| Character sheet | `potential_Assets/414106291_..._n.png` (252x408) | 3x4 frames 84x102, nền trắng | Chủ project duyệt 2026-10-15 |
| Background platformer | `potential_Assets/662472400_..._n.png` (735x412) | ảnh nền | Dùng tự do trong project |
| Background rừng | `potential_Assets/846136344_..._n.png` (1199x648) | ảnh nền | Dùng tự do trong project |
| Bunny sheet | `potential_Assets/843571651_..._n.png` (288x576) | 4x8 frames 72x72, có alpha | Nhóm cho phép / đã xin phép |
| Frog sheet | `potential_Assets/849134050_..._n.png` (640x320) | 8x4 frames 80x80, nền trắng | Nhóm cho phép / đã xin phép |

## Quy tắc sử dụng trong code

- Thư mục `potential_Assets/` là **chỉ đọc** — không sửa, không ghi đè, không
  tách frame thủ công vào đó.
- Mọi xử lý (tách frame, nền trắng → alpha, pivot/hitbox) qua
  `resources/asset_frames.gd` lúc runtime + cache RAM.
- Background dùng qua `levels/stage_background.tscn` (Parallax2D thuần visual).
- Test khóa: `tests/test_bonus_assets.gd` (kích thước file, bounds frame,
  tách nền) + `tests/test_asset_catalog.gd` (tồn tại file).

## Trước bản public

- [ ] Xác nhận lại nguồn/license từng sheet bằng văn bản (bonus box cuối).
- [ ] Ghi tác giả/nguồn vào màn hình Credits (T8).
