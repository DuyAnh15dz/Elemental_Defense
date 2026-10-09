class_name Discoveries
extends RefCounted
## Tiến trình khám phá, lưu vào user://discoveries.cfg.
##  - Hợp chất: mở khoá khi người chơi tự ghép ra lần đầu.
##  - Nguyên tố: mở theo màn (gọi Discoveries.unlock_element("N") khi qua màn).
## Chưa mở khoá thì bách khoa và bản xem trước hiện "???".

const SAVE_PATH := "user://discoveries.cfg"

# Nguyên tố có sẵn từ đầu. Sau này đổi thành mở theo màn.
const DEFAULT_ELEMENTS: Array[String] = ["H", "O", "C", "Na"]

static var _loaded: bool = false
static var _compounds: Dictionary = {}
static var _elements: Dictionary = {}


static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	for sym in DEFAULT_ELEMENTS:
		_elements[sym] = true
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		for id in cfg.get_value("discovery", "compounds", []):
			_compounds[id] = true
		for sym in cfg.get_value("discovery", "elements", []):
			_elements[sym] = true


static func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("discovery", "compounds", _compounds.keys())
	cfg.set_value("discovery", "elements", _elements.keys())
	cfg.save(SAVE_PATH)


static func is_discovered(compound_id: String) -> bool:
	_ensure()
	return _compounds.has(compound_id)


# Trả về true nếu đây là lần khám phá đầu tiên
static func discover(compound_id: String) -> bool:
	_ensure()
	if _compounds.has(compound_id):
		return false
	_compounds[compound_id] = true
	_save()
	return true


static func is_element_unlocked(sym: String) -> bool:
	_ensure()
	return _elements.has(sym)


static func unlock_element(sym: String) -> void:
	_ensure()
	if not _elements.has(sym):
		_elements[sym] = true
		_save()


# Xoá toàn bộ tiến trình (dùng khi test)
static func reset() -> void:
	_loaded = true
	_compounds.clear()
	_elements.clear()
	for sym in DEFAULT_ELEMENTS:
		_elements[sym] = true
	_save()
