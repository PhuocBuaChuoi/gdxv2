class_name LocalePack
extends RefCounted

## Language Pack loader & switcher ("vi" / "en") persisted in user://save_data.cfg.

const SAVE_PATH := "user://save_data.cfg"
const DEFAULT_LOCALE := "vi"
const SUPPORTED := ["vi", "en"]
const PACK_PATHS := {
	"vi": "res://resources/lang/vi.json",
	"en": "res://resources/lang/en.json",
}

static var _loaded: bool = false
static var _locale: String = DEFAULT_LOCALE
static var _cache: Dictionary = {}
static var _listeners: Array[Callable] = []


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	for code in SUPPORTED:
		var path := str(PACK_PATHS.get(code, ""))
		if path != "" and FileAccess.file_exists(path):
			var raw := FileAccess.get_file_as_string(path)
			var parsed: Variant = JSON.parse_string(raw)
			if parsed is Dictionary:
				_cache[code] = parsed
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		var saved := str(cfg.get_value("settings", "locale", DEFAULT_LOCALE))
		if SUPPORTED.has(saved):
			_locale = saved


static func subscribe(cb: Callable) -> void:
	if not _listeners.has(cb):
		_listeners.append(cb)


static func unsubscribe(cb: Callable) -> void:
	_listeners.erase(cb)


static func get_locale() -> String:
	_ensure_loaded()
	return _locale


static func set_locale(code: String, persist: bool = true) -> void:
	_ensure_loaded()
	var target := code if SUPPORTED.has(code) else DEFAULT_LOCALE
	var changed := _locale != target
	_locale = target
	if persist:
		var cfg := ConfigFile.new()
		cfg.load(SAVE_PATH)
		cfg.set_value("settings", "locale", _locale)
		cfg.save(SAVE_PATH)
	if changed:
		var alive: Array[Callable] = []
		for cb in _listeners:
			if cb.is_valid():
				alive.append(cb)
				cb.call(_locale)
		_listeners = alive


static func cycle_locale() -> String:
	var cur := get_locale()
	var idx := SUPPORTED.find(cur)
	var next_code: String = SUPPORTED[(idx + 1) % SUPPORTED.size()]
	set_locale(next_code)
	return next_code


static func tr_key(key: String, args: Array = []) -> String:
	_ensure_loaded()
	var pack := _cache.get(_locale, _cache.get(DEFAULT_LOCALE, {})) as Dictionary
	var text := str(pack.get(key, key))
	if args.is_empty():
		return text
	return text % args
