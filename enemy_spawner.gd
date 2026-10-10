extends Node
## Bộ sinh quái theo màn (giống PvZ).
## Đọc cấu hình từ level_data.gd, tự sắp xếp thứ tự, thời điểm, hàng xuất hiện; quái vào từ
## mép phải lưới, đi sang trái. Có thanh tiến độ, thông báo đợt tấn công lớn, tín hiệu hoàn thành / thua.
##
## Cách gắn: thêm một node Node tên "EnemySpawner" vào scene chính, gắn script này.
## Chọn màn: đặt LevelData.current_level = n (khi use_global_level bật) hoặc đổi Level Number.

signal wave_started(number: int, total: int, is_final: bool)
signal huge_wave_warning
signal enemy_spawned(id: String, row: int)
signal level_cleared
signal level_failed

@export var auto_start: bool = true
@export var use_global_level: bool = true      # true = dùng LevelData.current_level
@export var level_number: int = 1              # dùng khi use_global_level = false
@export var grid: TileMapLayer                 # Để trống = tự tìm lưới trồng cây
@export var enemies_container: Node2D          # Để trống = thêm quái vào node cha của spawner
@export var spawn_margin: float = 140.0        # Khoảng cách từ mép phải lưới tới chỗ quái xuất hiện
@export var defeat_margin: float = 60.0        # Quái đi quá mép trái lưới bấy nhiêu px = thua
@export var seed_value: int = 0                # 0 = ngẫu nhiên mỗi lần; số khác = lịch cố định để test
@export var show_ui: bool = true
@export var print_plan: bool = true            # In lịch xuất hiện ra Output để chỉnh cân bằng

var _events: Array = []
var _waves: Array = []
var _total: int = 0
var _next_event: int = 0
var _spawned: int = 0
var _alive: int = 0
var _elapsed: float = 0.0
var _running: bool = false
var _level: int = 1
var _rows: int = 5
var _spawn_x: float = 0.0
var _left_x: float = 0.0
var _row_y: Array[float] = []
var _scenes: Dictionary = {}

var _ui: CanvasLayer
var _bar: ProgressBar
var _info: Label
var _banner: Label


func _ready() -> void:
	if show_ui:
		_build_ui()
	if auto_start:
		start_level.call_deferred(LevelData.current_level if use_global_level else level_number)


# ───────────────────────── ĐIỀU KHIỂN ─────────────────────────
func start_level(n: int) -> void:
	var level := LevelData.get_level(n)
	if level.is_empty():
		push_error("EnemySpawner: không có màn %d trong level_data.gd" % n)
		return
	if not _setup_geometry():
		return

	_level = n
	var rng := RandomNumberGenerator.new()
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()

	var plan := LevelData.build_schedule(level, _rows, rng)
	_events = plan["events"]
	_waves = plan["waves"]
	_total = int(plan["total"])
	for w in _waves:
		w["started"] = false
		w["warned"] = false

	_next_event = 0
	_spawned = 0
	_alive = 0
	_elapsed = 0.0
	_running = _total > 0

	if _bar:
		_bar.max_value = maxf(_total, 1)
		_bar.value = 0
	_update_info(0)
	if print_plan:
		_print_plan(level)


func stop() -> void:
	_running = false


# Toạ độ các hàng, mép phải (chỗ quái xuất hiện) và mép trái (vạch thua) theo lưới trồng cây
func _setup_geometry() -> bool:
	if grid == null:
		grid = get_tree().get_first_node_in_group("grid") as TileMapLayer
	if grid == null:
		push_error("EnemySpawner: không tìm thấy lưới (planting_grid). Gán 'Grid' trong Inspector.")
		return false

	var gs := Vector2i(8, 5)
	var gs_var = grid.get("grid_size")
	if gs_var is Vector2i:
		gs = gs_var
	_rows = gs.y
	var tile_w := float(grid.tile_set.tile_size.x) if grid.tile_set else 100.0

	_row_y.clear()
	for r in _rows:
		_row_y.append(grid.to_global(grid.map_to_local(Vector2i(0, r))).y)
	_spawn_x = grid.to_global(grid.map_to_local(Vector2i(gs.x - 1, 0))).x + tile_w / 2.0 + spawn_margin
	_left_x = grid.to_global(grid.map_to_local(Vector2i(0, 0))).x - tile_w / 2.0 - defeat_margin
	return true


# ───────────────────────── VÒNG LẶP ─────────────────────────
func _process(delta: float) -> void:
	if not _running:
		return
	_elapsed += delta

	# Cảnh báo / bắt đầu đợt
	for w in _waves:
		if w["final"] and not w["warned"] and _elapsed >= float(w["warn_time"]):
			w["warned"] = true
			huge_wave_warning.emit()
			_show_banner("ĐỢT TẤN CÔNG LỚN ĐANG TIẾN TỚI!", Color(1.0, 0.35, 0.3), 3.0)
		if not w["started"] and _elapsed >= float(w["time"]):
			w["started"] = true
			wave_started.emit(int(w["number"]), _waves.size(), bool(w["final"]))
			_update_info(int(w["number"]))

	# Sinh quái đến hạn
	while _next_event < _events.size() and float(_events[_next_event]["time"]) <= _elapsed:
		var ev: Dictionary = _events[_next_event]
		_spawn(str(ev["id"]), int(ev["row"]))
		_next_event += 1

	# Thua: quái vượt qua mép trái
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e is Node2D and e.global_position.x < _left_x:
			_fail()
			return

	# Thắng: đã sinh hết và không còn quái
	if _next_event >= _events.size() and _alive <= 0:
		_clear()


# ───────────────────────── SINH QUÁI ─────────────────────────
func _spawn(id: String, row: int) -> void:
	var def := EnemyRegistry.get_def(id)
	var path := EnemyRegistry.scene_path(id)
	if not _scenes.has(path):
		if not ResourceLoader.exists(path):
			push_error("EnemySpawner: không tìm thấy scene '%s'. Hãy lưu node Enemy thành scene (xem hướng dẫn)." % path)
			_running = false
			return
		_scenes[path] = load(path)
	var e := (_scenes[path] as PackedScene).instantiate() as Node2D

	# Ghi đè chỉ số TRƯỚC khi vào cây để enemy.gd đọc đúng trong _ready
	for key in ["max_hp", "speed", "damage", "attack_interval"]:
		if def.has(key):
			e.set(key, def[key])
	e.name = "%s_%d" % [id, _spawned + 1]

	var container: Node = enemies_container if enemies_container else get_parent()
	container.add_child(e)
	e.global_position = Vector2(_spawn_x, _row_y[row])

	if def.has("tint"):
		e.modulate = def["tint"]
	var vs := float(def.get("visual_scale", 1.0))
	if vs != 1.0:
		var hb := e.get_node_or_null("HealthBar") as HealthBar
		if hb:
			hb.offset.y *= vs
			hb.bar_size.x *= vs
			
		for n in ["SpriteMove", "SpriteAttack"]:
			var s := e.get_node_or_null(n) as Node2D
			if s:
				s.scale *= vs

	_spawned += 1
	_alive += 1
	e.tree_exited.connect(_on_enemy_gone)
	if _bar:
		_bar.value = _spawned
	enemy_spawned.emit(id, row)


func _on_enemy_gone() -> void:
	_alive = maxi(0, _alive - 1)


# ───────────────────────── KẾT THÚC MÀN ─────────────────────────
func _clear() -> void:
	_running = false
	print("[Spawner] Hoàn thành màn ", _level)
	_show_banner("HOÀN THÀNH MÀN %d!" % _level, Color(0.5, 1.0, 0.55), 4.0)
	level_cleared.emit()


func _fail() -> void:
	_running = false
	print("[Spawner] Thua: quái đã vượt qua phòng tuyến")
	_show_banner("KẺ ĐỊCH ĐÃ VƯỢT QUA PHÒNG TUYẾN!", Color(1.0, 0.3, 0.3), 5.0)
	level_failed.emit()


# ───────────────────────── GIAO DIỆN ─────────────────────────
func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 3
	add_child(_ui)

	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_bar.offset_left = -170
	_bar.offset_right = 170
	_bar.offset_top = -26
	_bar.offset_bottom = -10
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_bar)

	_info = Label.new()
	_info.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_info.offset_left = -170
	_info.offset_right = 170
	_info.offset_top = -52
	_info.offset_bottom = -28
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.add_theme_font_size_override("font_size", 14)
	_info.add_theme_constant_override("outline_size", 4)
	_info.add_theme_color_override("font_outline_color", Color.BLACK)
	_ui.add_child(_info)

	_banner = Label.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_left = -400
	_banner.offset_right = 400
	_banner.offset_top = 120
	_banner.offset_bottom = 180
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 34)
	_banner.add_theme_constant_override("outline_size", 8)
	_banner.add_theme_color_override("font_outline_color", Color.BLACK)
	_banner.modulate.a = 0.0
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_banner)


func _update_info(wave_number: int) -> void:
	if _info:
		_info.text = "Màn %d · Đợt %d/%d" % [_level, wave_number, _waves.size()]


func _show_banner(text: String, color: Color, seconds: float) -> void:
	if _banner == null:
		return
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(seconds)
	t.tween_property(_banner, "modulate:a", 0.0, 0.6)


# ───────────────────────── GỠ LỖI ─────────────────────────
func _print_plan(level: Dictionary) -> void:
	print("═══ %s: %d quái, %d đợt ═══" % [level.get("name", "Màn %d" % _level), _total, _waves.size()])
	for w in _waves:
		var counts := {}
		var rows_used := {}
		for ev in _events:
			if int(ev["wave"]) == int(w["index"]):
				counts[ev["id"]] = int(counts.get(ev["id"], 0)) + 1
				rows_used[ev["row"]] = int(rows_used.get(ev["row"], 0)) + 1
		print("  Đợt %d%s | từ %.0fs | %d quái %s | hàng %s" % [
			w["number"], " (LỚN)" if w["final"] else "", w["time"], w["count"], counts, rows_used])
