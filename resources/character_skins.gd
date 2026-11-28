class_name CharacterSkins
extends RefCounted

## 3 skin nhân vật (nghiên cứu từ ảnh sheet thật, 2026-10-16).
## Mỗi skin pick state hợp lý nhất từ frame có sẵn:
##  - bird  (chim xanh 3x4): idle trước / chạy trái-phải / nhảy / lộn (trọng lực đảo)
##  - bunny (thỏ trắng 4x8): ngồi idle / chạy / nhảy (hop) / ngồi xổm (tiếp đất)
##  - frog  (ếch xanh 8x4):  idle ộp / chạy / nhảy / lộn lưng
## Chết KHÔNG có state riêng (dùng death_explosion VFX theo T2.04).
## Hướng mặt trong sheet cần verify lại trong editor khi gắn (ghi trong
## resources/SPRITE_CASTING.md).

const Frames = preload("res://resources/asset_frames.gd")
const Catalog = preload("res://resources/potential_assets.gd")

const BIRD := "bird"
const BUNNY := "bunny"
const FROG := "frog"

const SKIN_SHEET := {
	BIRD: "res://potential_Assets/414106291_1106212887401608_3683585317607262297_n.png",
	BUNNY: "res://potential_Assets/843571651_1597512422056563_8475109056225243844_n.png",
	FROG: "res://potential_Assets/849134050_4846796575550706_3729985077334381458_n.png",
}

## Frame index tính theo hàng trên-xuống, trái-sang-phải của sheet.
const SKIN_STATES := {
	BIRD: {
		"idle": [0, 1, 2],
		"run_left": [3, 4, 5],
		"run_right": [6, 7, 8],
		"jump": [7],
		"flip": [9, 10, 11],
	},
	BUNNY: {
		"idle": [0, 1, 2, 3],
		"run": [20, 21, 22, 23],
		"jump": [4, 5, 6, 7],
		"crouch": [24, 25, 26, 27],
	},
	FROG: {
		"idle": [0, 1, 2, 3, 4, 5, 6, 7],
		"run": [16, 17, 18, 19, 20, 21, 22, 23],
		"jump": [8, 9, 10, 11, 12, 13, 14, 15],
		"flip": [24, 25, 26, 27, 28, 29, 30, 31],
	},
}


static func all_skins() -> Array:
	return [BIRD, BUNNY, FROG]


static func sheet_of(skin: String) -> String:
	return str(SKIN_SHEET.get(skin, ""))


static func states(skin: String) -> Dictionary:
	return (SKIN_STATES.get(skin, {}) as Dictionary).duplicate()


static func has_state(skin: String, state: String) -> bool:
	return (SKIN_STATES.get(skin, {}) as Dictionary).has(state)


## Texture từng frame của state (Atlas trực tiếp hoặc đã tách nền).
static func state_frames(skin: String, state: String) -> Array:
	var out: Array = []
	var sheet := sheet_of(skin)
	if sheet == "":
		return out
	var use_alpha: bool = bool(Frames.grid(sheet).get("has_alpha", true))
	for i in ((SKIN_STATES.get(skin, {}) as Dictionary).get(state, []) as Array):
		var idx: int = clampi(int(i), 0, maxi(Frames.frame_count(sheet) - 1, 0))
		if use_alpha:
			out.append(Frames.frame_texture(sheet, idx))
		else:
			out.append(Frames.keyed_frame(sheet, idx))
	return out


## VisualRoot chạy animation state, gắn vào player/enemy được ngay.
static func make_skin_visual(skin: String, state: String, fps: float = 8.0, target_height: float = 48.0, modulate: Color = Color.WHITE) -> Node2D:
	var root := Node2D.new()
	root.name = "VisualRoot"
	var frames_list: Array = state_frames(skin, state)
	var anim := AnimatedSprite2D.new()
	anim.name = "Body"
	anim.centered = true
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", maxf(fps, 0.01))
	for t in frames_list:
		frames.add_frame("default", t, 1.0 / maxf(fps, 0.01))
	anim.frames = frames
	var fs: Vector2i = Frames.grid(sheet_of(skin)).get("frame_size", Vector2i(1, 1))
	anim.scale = Frames.fit_scale(fs, target_height)
	anim.modulate = modulate
	if frames.get_frame_count("default") > 0:
		anim.play("default")
	root.add_child(anim)
	return root
