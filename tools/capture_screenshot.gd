extends SceneTree

var _target_scene_path: String = "res://levels/level_01.tscn"
var _output_png_path: String = "artifacts/screenshots/screenshot.png"
var _frames_to_wait: int = 8
var _frame_count: int = 0
var _instantiated: Node = null

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and args[0] != "":
		_target_scene_path = args[0]
	if args.size() > 1 and args[1] != "":
		_output_png_path = args[1]
	if args.size() > 2:
		_frames_to_wait = maxi(1, int(args[2]))
	
	print("[ScreenshotTool] Target: %s -> Output: %s (frames: %d)" % [_target_scene_path, _output_png_path, _frames_to_wait])
	
	var res := load(_target_scene_path)
	if res is PackedScene:
		_instantiated = (res as PackedScene).instantiate()
		root.add_child(_instantiated)
	else:
		push_error("Failed to load scene: " + _target_scene_path)
		quit(1)

func _process(_delta: float) -> bool:
	_frame_count += 1
	if _frame_count >= _frames_to_wait:
		_capture()
		quit(0)
		return true
	return false

func _capture() -> void:
	var vp := root.get_viewport()
	if vp == null:
		push_error("Viewport is null!")
		return
	var img := vp.get_texture().get_image()
	if img == null:
		push_error("Viewport image is null!")
		return
	var dir := _output_png_path.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	
	var abs_path := ProjectSettings.globalize_path(_output_png_path)
	var err := img.save_png(abs_path)
	if err == OK:
		print("[ScreenshotTool] SUCCESS saved to: ", abs_path)
	else:
		push_error("[ScreenshotTool] Failed to save png, code: %d" % err)
