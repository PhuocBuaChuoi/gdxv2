class_name PotentialAssets
extends RefCounted

## Asset boundary: visual files stay replaceable and are not hard-coded in gameplay scenes.
## Permission note supplied by the project owner on 2026-10-15:
## - character sheet: approved for this educational, non-commercial project.
## - two backgrounds: approved for unrestricted project use.
## - bunny and frog sheets: approved by the project/group or obtained with permission.

const CHARACTER_SHEET: String = "res://potential_Assets/414106291_1106212887401608_3683585317607262297_n.png"
const BACKGROUND_BRIGHT: String = "res://potential_Assets/662472400_1302237225149144_4015709686826161830_n.png"
const BACKGROUND_FOREST: String = "res://potential_Assets/846136344_1413298653730501_326156790486471431_n.png"
const BUNNY_SHEET: String = "res://potential_Assets/843571651_1597512422056563_8475109056225243844_n.png"
const FROG_SHEET: String = "res://potential_Assets/849134050_4846796575550706_3729985077334381458_n.png"

static func character_sheet() -> String:
	return CHARACTER_SHEET

static func backgrounds() -> Array[String]:
	return [BACKGROUND_BRIGHT, BACKGROUND_FOREST]

static func sprite_sheets() -> Array[String]:
	return [CHARACTER_SHEET, BUNNY_SHEET, FROG_SHEET]

static func all_paths() -> Array[String]:
	return [CHARACTER_SHEET, BACKGROUND_BRIGHT, BACKGROUND_FOREST, BUNNY_SHEET, FROG_SHEET]

static func sheet_metadata() -> Dictionary:
	return {
		CHARACTER_SHEET: {"columns": 3, "rows": 4, "frame_size": Vector2i(84, 102), "has_alpha": false},
		BUNNY_SHEET: {"columns": 4, "rows": 8, "frame_size": Vector2i(72, 72), "has_alpha": true},
		FROG_SHEET: {"columns": 8, "rows": 4, "frame_size": Vector2i(80, 80), "has_alpha": false},
	}

static func is_ready_for_visual_import() -> bool:
	for path in all_paths():
		if not FileAccess.file_exists(path):
			return false
	return true
