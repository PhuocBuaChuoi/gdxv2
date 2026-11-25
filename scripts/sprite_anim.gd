class_name SpriteAnim
extends RefCounted

## Shared helper for 4-frame (or N-frame) horizontal pixel-art spritesheet playback on Sprite2D.


static func setup_sheet(spr: Sprite2D, tex: Texture2D, total_frames: int = 4) -> void:
	if spr == null or tex == null:
		return
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.hframes = maxi(total_frames, 1)
	spr.vframes = 1
	spr.texture = tex
	spr.frame = 0


static func step_sheet(spr: Sprite2D, elapsed: float, fps: float = 6.0, total_frames: int = 4) -> void:
	if spr == null or total_frames <= 1:
		return
	if spr.hframes != total_frames:
		spr.hframes = total_frames
	spr.frame = int(floorf(maxf(elapsed, 0.0) * fps)) % total_frames
