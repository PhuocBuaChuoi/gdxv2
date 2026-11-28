# Giao thức phối hợp nhiều Agent (+ người) — chống dẫm chân

> Áp dụng cho **mọi agent AI và cả người**. Mục tiêu: không bao giờ 2 bên sửa
> cùng 1 phạm vi cùng lúc, mọi thay đổi đều có test xanh + PR.

## 1. Claim trước khi sửa (bắt buộc)

Registry: `.agents/ownership.json`. Mỗi claim gồm `id`, `owner`, `branch`,
`paths` (file/thư mục phụ trách), `status` (`active`/`done`).

```powershell
# 0. cập nhật thông tin mới nhất (khi đã có remote)
git pull origin main

# 1. đọc registry, kiểm tra paths mình định sửa có trùng claim active nào không
# 2. đăng ký claim (script tự cảnh báo nếu overlap)
powershell -ExecutionPolicy Bypass -File tools/claim.ps1 -Owner "<tên-mình>" -Id "<task-id>" -Paths "<paths,cách-nhau-phẩy>" -Branch "feature/<task>" -Status active

# 3. commit riêng claim để mọi người nhìn thấy
git add .agents/ownership.json
git commit -m "chore(claim): <task-id> giu <paths>"
```

Nếu overlap với claim `active` của người khác → **dừng lại**, thỏa thuận
(chia file, chờ release, hoặc nhận review chéo) rồi mới làm tiếp.

## 2. Vùng sở hữu (bản đồ tĩnh)

| Khu vực | Chế độ | Ghi chú |
|---|---|---|
| `project.godot` | exclusive tuyệt đối | 1 claim active tại 1 thời điểm, review kỹ |
| `autoloads/` | exclusive theo file | thêm autoload mới = claim file mới |
| `scenes/main/` | exclusive | entry point, dễ conflict |
| `characters/player.*` | exclusive | 1 owner cho cả GĐ3–4 (vật lý 2 tay sửa là lệch) |
| `components/` | song song theo file | mỗi component 1 claim riêng |
| `levels/level_*.tscn` | song song theo file | mỗi level 1 claim riêng |
| `vfx/`, `ui/`, `resources/` | song song theo file | trừ file dùng chung phải claim rõ |
| `tests/test_runner.gd`, `tests/gdx_test.gd` | exclusive | sửa khung test phải claim |
| `tests/test_*.gd` | song song theo file | mỗi task khóa spec của mình |
| `.agents/ownership.json` | append-only | chỉ thêm/sửa claim **của mình**, cấm xóa/sửa claim người khác |

## 3. Cửa test (bắt buộc trước push)

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_tests.ps1
# exit code 0 mới được push/PR. Test đỏ → fix trước, cấm merge.
```

`tests/test_collab_registry.gd` tự động fail nếu có 2 claim `active`
overlap nhau — registry sai là biết ngay.

## 4. Release sau merge

Sau khi PR merge vào `main`:

```powershell
powershell -ExecutionPolicy Bypass -File tools/claim.ps1 -Owner "<tên-mình>" -Id "<task-id>" -Status done
git add .agents/ownership.json
git commit -m "chore(claim): release <task-id>"
```

## 5. Quy tắc cho người (human)

Người tuân thủ y hệt agent: claim → branch `feature/*` → test xanh → PR.
Không push thẳng `main`, không force-push, conflict thì resolve tay từng file.
