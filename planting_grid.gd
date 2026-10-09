extends TileMapLayer
## Lưới trồng cây + thanh chọn cây + công cụ GHÉP hợp chất.
##
## Trồng cây:
## - Chọn cây ở thanh trên cùng: bấm để chọn, hoặc nhấn giữ rồi KÉO thả vào ô.
## - Bấm chuột trái vào ô trống để trồng. Chuột phải / Esc để huỷ chọn.
##
## Ghép cây (nút "Ghép cây" cuối thanh):
## - Bấm các cây KỀ NHAU trên lưới để chọn nguyên liệu (tối đa 6).
## - Bảng xem trước hiện hợp chất sẽ tạo (??? nếu chưa khám phá) và giá.
## - Bấm "Ghép" để mở bảng TRẮC NGHIỆM điều kiện phản ứng (xúc tác, nhiệt độ, áp suất).
##   Chọn đúng: trừ giá hợp chất, nguyên liệu biến mất, hợp chất xuất hiện ở ô chọn đầu tiên.
##   Chọn sai: từ chối ghép, nguyên liệu giữ nguyên, bị trừ năng lượng làm hình phạt.
## - Trong lúc dùng công cụ Ghép và trắc nghiệm, game TẠM DỪNG.
## - Chuột phải: bỏ chọn; chuột phải lần nữa hoặc Esc: thoát công cụ.
##
## Gắn script này vào node TileMapLayer.

const MAX_COMBINE := 6

@export var grid_size: Vector2i = Vector2i(8, 5)      # 8 cột x 5 hàng
@export var plants_container: Node2D                    # Để trống = tự tìm node "../Plants"
@export var auto_fill_tiles: bool = true                # Tự lát ô sáng/tối xen kẽ khi chạy game
@export var snap_existing_plants: bool = true           # Cây đã đặt tay trong scene sẽ được căn vào ô gần nhất
@export var starting_energy: int = 100                  # Năng lượng khởi đầu (0 = tắt)
@export var fx_duration: float = 0.45

# Danh sách cây lấy từ element_data.gd (giá, thời gian hồi sửa ở đó)
var plant_defs: Array[Dictionary] = ElementData.get_plant_defs()

var _selected: int = -1
var _dragging: bool = false
var _was_selected_before: bool = false
var _hover_cell: Vector2i = Vector2i(-1, -1)
var _occupied: Dictionary = {}         # Vector2i -> cây
var _fx: Dictionary = {}               # Vector2i -> tiến độ hiệu ứng 0..1
var _scenes: Array[PackedScene] = []
var _ghost_info: Array = []
var _cd_end: Array[float] = []
var _buttons: Array[Button] = []

# Công cụ ghép
var _combine_mode: bool = false
var _combine_cells: Array[Vector2i] = []
var _preview_note: String = ""
var _combine_btn: Button
var _preview_panel: PanelContainer
var _preview_label: RichTextLabel
var _confirm_btn: Button
var _quiz_open: bool = false
var _quiz_layer: Control
var _quiz_info: RichTextLabel
var _quiz_options: Dictionary = {}      # "catalyst"/"temperature"/"pressure" -> OptionButton

var _overlay: Node2D
var _ghost: Sprite2D
var _seed_bar: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS     # Vẫn nhận chuột khi game tạm dừng (lúc ghép / trắc nghiệm)
	add_to_group("grid")                        # Để EnemySpawner tìm thấy lưới
	if plants_container == null:
		plants_container = get_node_or_null("../Plants") as Node2D
	if plants_container == null:
		push_error("PlantingGrid: không tìm thấy node Plants! Hãy gán 'Plants Container' trong Inspector.")
	# Thêm tạm vào _ready() của planting_grid.gd
	# DEBUG CHI TIẾT
	print("=== GRID DEBUG ===")
	print("grid_size = ", grid_size)
	print("auto_fill_tiles = ", auto_fill_tiles)
	print("tile_set = ", tile_set)
	if tile_set:
		print("source_count = ", tile_set.get_source_count())
	
	var cells := get_used_cells()
	print("Total cells: ", cells.size())
	
	var rows_dict := {}
	for cell in cells:
		rows_dict[cell.y] = rows_dict.get(cell.y, 0) + 1
	print("Cells per row:")
	for r in rows_dict:
		print("  Row ", r, ": ", rows_dict[r], " cells")
	
	var cols_dict := {}
	for cell in cells:
		cols_dict[cell.x] = cols_dict.get(cell.x, 0) + 1
	print("Cells per column:")
	for c in cols_dict:
		print("  Col ", c, ": ", cols_dict[c], " cells")

	_fill_tiles()
	_load_plants()
	_build_overlay()
	_build_seed_bar()
	_build_preview_panel()
	_build_quiz_panel()
	_register_existing_plants()

	GameState.chemical_energy_changed.connect(func(_v): _refresh_buttons())
	if starting_energy > 0 and GameState.chemical_energy == 0:
		GameState.add_energy.call_deferred(starting_energy)


# ───────────────────────── KHỞI TẠO ─────────────────────────
func _fill_tiles() -> void:
	if not auto_fill_tiles or tile_set == null or tile_set.get_source_count() == 0:
		return
	var src := tile_set.get_source_id(0)
	for r in grid_size.y:
		for c in grid_size.x:
			set_cell(Vector2i(c, r), src, Vector2i((r + c) % 2, 0))


func _load_plants() -> void:
	for def in plant_defs:
		var scene := load(def["scene"]) as PackedScene
		_scenes.append(scene)
		_cd_end.append(0.0)
		# Đọc sprite của cây để làm "bóng mờ" (không thêm vào cây thật)
		var info = null
		if scene:
			var inst := scene.instantiate()
			var spr := inst.get_node_or_null("Sprite2D") as Sprite2D
			if spr:
				info = {"tex": spr.texture, "scale": spr.scale, "off": spr.position}
			inst.free()
		_ghost_info.append(info)


func _build_overlay() -> void:
	# Lớp vẽ ô sáng: nằm dưới cây, trên nền
	_overlay = Node2D.new()
	_overlay.z_as_relative = false
	_overlay.z_index = -1
	_overlay.draw.connect(_on_overlay_draw)
	add_child(_overlay)

	_ghost = Sprite2D.new()
	_ghost.z_as_relative = false
	_ghost.z_index = 50
	_ghost.visible = false
	add_child(_ghost)


func _build_seed_bar() -> void:
	_seed_bar = CanvasLayer.new()
	_seed_bar.layer = 2
	add_child(_seed_bar)

	var box := HBoxContainer.new()
	box.position = Vector2(200, 8)
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seed_bar.add_child(box)

	for i in plant_defs.size():
		var def := plant_defs[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(76, 96)
		btn.pivot_offset = btn.custom_minimum_size / 2.0
		btn.focus_mode = Control.FOCUS_NONE
		btn.icon = load(def["icon"]) as Texture2D
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		btn.add_theme_constant_override("icon_max_width", 56)
		btn.text = str(def["cost"])
		btn.tooltip_text = "%s – %d năng lượng" % [def["name"], def["cost"]]
		btn.visible = Discoveries.is_element_unlocked(str(def.get("symbol", "")))   # Chưa mở khoá thì ẩn
		btn.button_down.connect(_on_seed_down.bind(i))
		btn.button_up.connect(_on_seed_up.bind(i))
		box.add_child(btn)
		_buttons.append(btn)

	# Nút công cụ Ghép
	_combine_btn = Button.new()
	_combine_btn.custom_minimum_size = Vector2(76, 96)
	_combine_btn.pivot_offset = _combine_btn.custom_minimum_size / 2.0
	_combine_btn.focus_mode = Control.FOCUS_NONE
	_combine_btn.text = "Ghép\ncây"
	_combine_btn.tooltip_text = "Công cụ ghép: chọn các cây kề nhau để tạo hợp chất"
	_combine_btn.pressed.connect(_toggle_combine)
	box.add_child(_combine_btn)


func _build_preview_panel() -> void:
	_preview_panel = PanelContainer.new()
	_preview_panel.position = Vector2(660, 8)
	_preview_panel.custom_minimum_size = Vector2(340, 0)
	_preview_panel.visible = false
	_seed_bar.add_child(_preview_panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	_preview_panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	margin.add_child(vb)

	_preview_label = RichTextLabel.new()
	_preview_label.bbcode_enabled = true
	_preview_label.fit_content = true
	_preview_label.scroll_active = false
	_preview_label.custom_minimum_size = Vector2(320, 70)
	_preview_label.add_theme_font_size_override("normal_font_size", 13)
	_preview_label.add_theme_font_size_override("bold_font_size", 13)
	vb.add_child(_preview_label)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	vb.add_child(hb)

	_confirm_btn = Button.new()
	_confirm_btn.text = "Ghép"
	_confirm_btn.focus_mode = Control.FOCUS_NONE
	_confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_btn.pressed.connect(_confirm_combine)
	hb.add_child(_confirm_btn)

	var clear_btn := Button.new()
	clear_btn.text = "Bỏ chọn"
	clear_btn.focus_mode = Control.FOCUS_NONE
	clear_btn.pressed.connect(func():
		_combine_cells.clear()
		_preview_note = ""
		_refresh_preview()
	)
	hb.add_child(clear_btn)

	var exit_btn := Button.new()
	exit_btn.text = "Thoát"
	exit_btn.focus_mode = Control.FOCUS_NONE
	exit_btn.pressed.connect(_exit_combine)
	hb.add_child(exit_btn)


# Gắn các cây đã đặt tay trong scene vào lưới
func _register_existing_plants() -> void:
	if plants_container == null:
		return
	for p in plants_container.get_children():
		if not (p is Node2D):
			continue
		var sym := _symbol_for_scene(p.scene_file_path)
		if sym != "":
			p.set_meta("element_id", sym)
		var cell := local_to_map(to_local(p.global_position))
		cell = Vector2i(clampi(cell.x, 0, grid_size.x - 1), clampi(cell.y, 0, grid_size.y - 1))
		if _occupied.has(cell):
			continue
		if snap_existing_plants:
			p.global_position = _cell_center_global(cell)
		_bind_plant_to_cell(p, cell)


func _symbol_for_scene(path: String) -> String:
	for def in plant_defs:
		if def["scene"] == path:
			return str(def.get("symbol", ""))
	return ""


# ───────────────────────── VÒNG LẶP ─────────────────────────
func _process(delta: float) -> void:
	# Đang tạm dừng: đóng băng thời gian hồi chiêu
	if get_tree().paused:
		for i in _cd_end.size():
			_cd_end[i] += delta

	# Đang ghép mà game bị mở lại (ví dụ vừa đóng bách khoa) thì dừng lại tiếp
	if _combine_mode and not get_tree().paused:
		get_tree().paused = true

	# Tạm dừng do nơi khác (bách khoa...): không xử lý lưới
	if get_tree().paused and not _combine_mode:
		return

	_hover_cell = local_to_map(to_local(get_global_mouse_position()))

	for cell in _fx.keys():
		_fx[cell] += delta / fx_duration
		if _fx[cell] >= 1.0:
			_fx.erase(cell)

	if _combine_mode:
		_prune_combine_cells()

	_update_ghost()
	_refresh_buttons()
	_overlay.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# Đang trắc nghiệm: chỉ Esc để huỷ
	if _quiz_open:
		if event.is_action_pressed("ui_cancel"):
			_close_quiz()
			get_viewport().set_input_as_handled()
		return
	# Tạm dừng do nơi khác (bách khoa...) thì bỏ qua
	if get_tree().paused and not _combine_mode:
		return

	# ── Công cụ ghép ──
	if _combine_mode:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_toggle_combine_cell(_hover_cell)
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				if _combine_cells.is_empty():
					_exit_combine()
				else:
					_combine_cells.clear()
					_preview_note = ""
					_refresh_preview()
		elif event.is_action_pressed("ui_cancel"):
			_exit_combine()
		return

	# ── Trồng cây ──
	if _selected < 0:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_plant(_hover_cell)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_deselect()
	elif event.is_action_pressed("ui_cancel"):
		_deselect()


# ───────────────────────── CHỌN CÂY ─────────────────────────
func _on_seed_down(i: int) -> void:
	if _combine_mode:
		_exit_combine()
	if not _can_use(i):
		_deny(i)
		return
	_was_selected_before = (_selected == i)
	_selected = i
	_dragging = true


func _on_seed_up(i: int) -> void:
	if not _dragging or _selected != i:
		return
	_dragging = false
	if _in_bounds(_hover_cell):
		_try_plant(_hover_cell)            # Kéo thả vào ô
	elif _was_selected_before:
		_deselect()                        # Bấm lại cùng cây -> bỏ chọn


func _deselect() -> void:
	_selected = -1
	_dragging = false
	_ghost.visible = false


func _can_use(i: int) -> bool:
	if not Discoveries.is_element_unlocked(str(plant_defs[i].get("symbol", ""))):
		return false
	var ready := Time.get_ticks_msec() / 1000.0 >= _cd_end[i]
	return ready and GameState.chemical_energy >= int(plant_defs[i]["cost"])


# Lắc nút khi không đủ năng lượng / đang hồi
func _deny(i: int) -> void:
	_shake(_buttons[i])


func _shake(btn: Control) -> void:
	var t := create_tween()
	t.tween_property(btn, "rotation_degrees", 8.0, 0.05)
	t.tween_property(btn, "rotation_degrees", -8.0, 0.08)
	t.tween_property(btn, "rotation_degrees", 0.0, 0.05)


# ───────────────────────── TRỒNG CÂY ─────────────────────────
func _try_plant(cell: Vector2i) -> bool:
	if _selected < 0 or plants_container == null:
		return false
	if not _in_bounds(cell) or _occupied.has(cell):
		return false

	var i := _selected
	var def := plant_defs[i]
	if not _can_use(i) or not GameState.spend_energy(int(def["cost"])):
		_deny(i)
		return false

	var plant := _scenes[i].instantiate() as Node2D
	plant.set_meta("element_id", str(def.get("symbol", "")))
	plants_container.add_child(plant)
	plant.global_position = _cell_center_global(cell)
	_bind_plant_to_cell(plant, cell)
	_pop_effect(plant, cell)

	_cd_end[i] = Time.get_ticks_msec() / 1000.0 + float(def["cooldown"])
	print("[Grid] Trồng ", def["name"], " tại ô ", cell)
	_deselect()
	return true


# Hiệu ứng xuất hiện: cây nảy lên + ô loé sáng
func _pop_effect(plant: Node2D, cell: Vector2i) -> void:
	plant.scale = Vector2(0.2, 0.2)
	plant.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)\
		.tween_property(plant, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fx[cell] = 0.0


func _bind_plant_to_cell(plant: Node2D, cell: Vector2i) -> void:
	_occupied[cell] = plant
	plant.tree_exited.connect(func():
		if _occupied.get(cell) == plant:
			_occupied.erase(cell)
	)


# ───────────────────────── CÔNG CỤ GHÉP ─────────────────────────
func _toggle_combine() -> void:
	if _combine_mode:
		_exit_combine()
	else:
		_enter_combine()


func _enter_combine() -> void:
	_deselect()
	_combine_mode = true
	_combine_cells.clear()
	_preview_note = ""
	_preview_panel.visible = true
	get_tree().paused = true          # Game tạm dừng trong lúc ghép
	_refresh_preview()


func _exit_combine() -> void:
	_close_quiz()
	_combine_mode = false
	_combine_cells.clear()
	_preview_note = ""
	_preview_panel.visible = false
	get_tree().paused = false


func _toggle_combine_cell(cell: Vector2i) -> void:
	if not _in_bounds(cell) or not _occupied.has(cell):
		return
	var p = _occupied[cell]
	if not is_instance_valid(p) or str(p.get_meta("element_id", "")) == "":
		return
	if _combine_cells.has(cell):
		_combine_cells.erase(cell)
	elif _combine_cells.size() < MAX_COMBINE:
		_combine_cells.append(cell)
	_preview_note = ""
	_refresh_preview()


# Bỏ các ô mà cây đã chết / biến mất
func _prune_combine_cells() -> void:
	var keep: Array[Vector2i] = []
	for c in _combine_cells:
		if _occupied.has(c) and is_instance_valid(_occupied[c]):
			keep.append(c)
	if keep.size() != _combine_cells.size():
		_combine_cells = keep
		_refresh_preview()


func _selected_ids() -> Array:
	var ids: Array = []
	for c in _combine_cells:
		ids.append(str(_occupied[c].get_meta("element_id", "")))
	return ids


# Các cây phải liền nhau (kể cả chéo)
func _selection_connected() -> bool:
	if _combine_cells.size() <= 1:
		return true
	var seen := {_combine_cells[0]: true}
	var stack: Array[Vector2i] = [_combine_cells[0]]
	while not stack.is_empty():
		var cur: Vector2i = stack.pop_back()
		for c in _combine_cells:
			if not seen.has(c) and maxi(absi(c.x - cur.x), absi(c.y - cur.y)) == 1:
				seen[c] = true
				stack.append(c)
	return seen.size() == _combine_cells.size()


func _refresh_preview() -> void:
	if not _combine_mode:
		return
	var t := ""
	if _preview_note != "":
		t += _preview_note + "\n"

	var ids := _selected_ids()
	if ids.is_empty():
		t += "[b]Công cụ ghép[/b]\nBấm các cây kề nhau để chọn nguyên liệu.\nChuột phải để bỏ chọn / thoát."
		_confirm_btn.disabled = true
		_preview_label.text = t
		return

	var names := PackedStringArray()
	for id in ids:
		names.append(CompoundData.display_id(id))
	t += "[b]Nguyên liệu:[/b] %s\n" % " + ".join(names)

	if not _selection_connected():
		t += "[color=#ff9f43]Các cây phải nằm kề nhau.[/color]"
		_confirm_btn.disabled = true
		_preview_label.text = t
		return

	var res := CompoundData.evaluate(ids)
	if res.is_empty():
		t += "[color=#aaaaaa]Không có hợp chất nào từ tổ hợp này.[/color]"
		_confirm_btn.disabled = true
		_preview_label.text = t
		return

	var id: String = res["id"]
	var d: Dictionary = CompoundData.RECIPES[id]
	_confirm_btn.disabled = false
	if Discoveries.is_discovered(id):
		t += "[b][color=#ffd966]%s[/color][/b] (%s)\n" % [d["formula"], d["name"]]
		t += "%s\n" % d["equation"]
		t += "Giá: [b]%d[/b] năng lượng (phạt nếu sai điều kiện: %d)\n" % [int(d["cost"]), CompoundData.penalty(id)]
		t += "Điều kiện: %s\n" % CompoundData.condition_text(id)
		if not bool(d.get("stable", true)):
			t += "[color=#ff9f43]Không bền: tự phân hủy sau %d giây[/color]\n" % int(d.get("lifetime", 8))
		t += str(d["mechanic"])
		_confirm_btn.text = "Ghép (giá %d)" % int(d["cost"])
	else:
		t += "[b][color=#ffd966]???[/color][/b]\n??? → ???\nGiá: ???\nĐiều kiện: ???\nCơ chế: ???\n"
		t += "[color=#aaaaaa]Chưa khám phá. Ghép thử để tìm hiểu (chọn sai sẽ bị phạt).[/color]"
		_confirm_btn.text = "Thử ghép"
	_preview_label.text = t


func _confirm_combine() -> void:
	if not _combine_mode or plants_container == null or _quiz_open:
		return
	if _combine_cells.is_empty() or not _selection_connected():
		return
	var res := CompoundData.evaluate(_selected_ids())
	if res.is_empty():
		return

	# Phải đủ năng lượng cho hợp chất thì mới được thử
	var d: Dictionary = CompoundData.RECIPES[res["id"]]
	if GameState.chemical_energy < int(d["cost"]):
		_preview_note = "[color=#ff6b6b]Không đủ năng lượng![/color]"
		_refresh_preview()
		_shake(_confirm_btn)
		return
	_open_quiz(res["id"])


# ───────────────────────── TRẮC NGHIỆM ĐIỀU KIỆN ─────────────────────────
func _build_quiz_panel() -> void:
	_quiz_layer = Control.new()
	_quiz_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_quiz_layer.visible = false
	_seed_bar.add_child(_quiz_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_quiz_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quiz_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	margin.add_child(vb)

	var title := Label.new()
	title.text = "CHỌN ĐIỀU KIỆN PHẢN ỨNG"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	_quiz_info = RichTextLabel.new()
	_quiz_info.bbcode_enabled = true
	_quiz_info.fit_content = true
	_quiz_info.scroll_active = false
	_quiz_info.custom_minimum_size = Vector2(460, 40)
	_quiz_info.add_theme_font_size_override("normal_font_size", 14)
	_quiz_info.add_theme_font_size_override("bold_font_size", 14)
	vb.add_child(_quiz_info)

	_add_quiz_row(vb, "catalyst", "Chất xúc tác", CompoundData.CATALYSTS)
	_add_quiz_row(vb, "temperature", "Nhiệt độ", CompoundData.TEMPERATURES)
	_add_quiz_row(vb, "pressure", "Áp suất", CompoundData.PRESSURES)

	var warn := Label.new()
	warn.text = "Chọn sai điều kiện, phản ứng không xảy ra và bạn bị trừ năng lượng."
	warn.add_theme_font_size_override("font_size", 12)
	warn.add_theme_color_override("font_color", Color(1.0, 0.7, 0.4))
	warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(warn)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	vb.add_child(hb)
	var go := Button.new()
	go.text = "Tiến hành phản ứng"
	go.focus_mode = Control.FOCUS_NONE
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.pressed.connect(_submit_quiz)
	hb.add_child(go)
	var cancel := Button.new()
	cancel.text = "Huỷ"
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.pressed.connect(_close_quiz)
	hb.add_child(cancel)


func _add_quiz_row(parent: Control, key: String, label_text: String, options: Array) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(110, 0)
	row.add_child(lbl)
	var opt := OptionButton.new()
	opt.focus_mode = Control.FOCUS_NONE
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in options.size():
		opt.add_item(options[i]["name"])
		opt.set_item_metadata(i, options[i]["id"])
	row.add_child(opt)
	_quiz_options[key] = opt


func _open_quiz(id: String) -> void:
	var names := PackedStringArray()
	for sid in _selected_ids():
		names.append(CompoundData.display_id(sid))
	var t := "[b]Nguyên liệu:[/b] %s\n" % " + ".join(names)
	if Discoveries.is_discovered(id):
		t += "[b]Phản ứng:[/b] %s" % CompoundData.RECIPES[id]["equation"]
	else:
		t += "[b]Phản ứng:[/b] ???"
	_quiz_info.text = t
	for key in _quiz_options:
		(_quiz_options[key] as OptionButton).select(0)
	_quiz_open = true
	_quiz_layer.visible = true


func _close_quiz() -> void:
	_quiz_open = false
	if _quiz_layer:
		_quiz_layer.visible = false


func _submit_quiz() -> void:
	if not _quiz_open:
		return
	var res := CompoundData.evaluate(_selected_ids())
	if res.is_empty() or not _selection_connected():
		_close_quiz()
		return
	var id: String = res["id"]
	var d: Dictionary = CompoundData.RECIPES[id]

	var chosen := {}
	for key in _quiz_options:
		var opt: OptionButton = _quiz_options[key]
		chosen[key] = str(opt.get_item_metadata(opt.selected))
	var correct := CompoundData.count_correct(id, chosen)
	_close_quiz()

	if correct == 3:
		_combine_success(id, d)
	else:
		_combine_failure(id, correct)


# Chọn sai: từ chối ghép, giữ nguyên nguyên liệu, trừ năng lượng
func _combine_failure(id: String, correct: int) -> void:
	var lost := mini(GameState.chemical_energy, CompoundData.penalty(id))
	if lost > 0:
		GameState.spend_energy(lost)
	_preview_note = "[color=#ff6b6b][b]Phản ứng không xảy ra![/b] Điều kiện không phù hợp. Mất %d năng lượng.[/color]" % lost
	if CompoundData.SHOW_HINT_COUNT:
		_preview_note += "\n[color=#ffb86b]Đúng %d/3 điều kiện.[/color]" % correct
	print("[Grid] Ghép thất bại (", id, "): đúng ", correct, "/3, mất ", lost)
	_refresh_preview()
	_shake(_confirm_btn)


# Chọn đúng: trừ giá hợp chất, nguyên liệu biến mất, hợp chất xuất hiện
func _combine_success(id: String, d: Dictionary) -> void:
	if not GameState.spend_energy(int(d["cost"])):
		_preview_note = "[color=#ff6b6b]Không đủ năng lượng![/color]"
		_refresh_preview()
		return

	var anchor := _combine_cells[0]
	for c in _combine_cells:
		var old = _occupied.get(c)
		_occupied.erase(c)
		if is_instance_valid(old):
			old.queue_free()

	var plant := CompoundPlant.new()
	plant.setup(id)
	plants_container.add_child(plant)
	plant.global_position = _cell_center_global(anchor)
	_bind_plant_to_cell(plant, anchor)
	_pop_effect(plant, anchor)

	var is_new := Discoveries.discover(id)
	print("[Grid] Ghép thành công: ", d["formula"], " tại ô ", anchor)

	_combine_cells.clear()
	_preview_note = "[color=#9cff9c][b]Phản ứng thành công: %s[/b][/color]" % d["formula"]
	if is_new:
		_preview_note = "[color=#7fe3ff][b]Khám phá hợp chất mới: %s (%s)![/b][/color]" % [d["formula"], d["name"]]
	if not bool(d.get("stable", true)):
		_preview_note += "\n[color=#ff9f43]Hợp chất không bền, sẽ tự phân hủy sau %d giây.[/color]" % int(d.get("lifetime", 8))
	_refresh_preview()


# ───────────────────────── TIỆN ÍCH ─────────────────────────
func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y


func _tile_size() -> Vector2:
	return Vector2(tile_set.tile_size) if tile_set else Vector2(100, 100)


func _cell_center_global(cell: Vector2i) -> Vector2:
	return to_global(map_to_local(cell))


func _cell_rect(cell: Vector2i) -> Rect2:
	var ts := _tile_size()
	return Rect2(map_to_local(cell) - ts / 2.0, ts)


func _refresh_buttons() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for i in _buttons.size():
		var btn := _buttons[i]
		var left := _cd_end[i] - now
		btn.text = ("%.0fs" % ceil(left)) if left > 0.0 else str(plant_defs[i]["cost"])
		if i == _selected:
			btn.modulate = Color(1.4, 1.4, 0.9)
		elif _can_use(i):
			btn.modulate = Color.WHITE
		else:
			btn.modulate = Color(0.5, 0.5, 0.5)
	if _combine_btn:
		_combine_btn.modulate = Color(0.6, 1.2, 1.4) if _combine_mode else Color.WHITE


func _update_ghost() -> void:
	if _selected < 0 or _ghost_info[_selected] == null:
		_ghost.visible = false
		return
	var info = _ghost_info[_selected]
	_ghost.texture = info["tex"]
	_ghost.scale = info["scale"]
	_ghost.visible = true
	if _in_bounds(_hover_cell):
		_ghost.global_position = _cell_center_global(_hover_cell) + info["off"]
		_ghost.modulate = Color(1, 1, 1, 0.65) if not _occupied.has(_hover_cell) else Color(1, 0.4, 0.4, 0.5)
	else:
		_ghost.global_position = get_global_mouse_position()
		_ghost.modulate = Color(1, 1, 1, 0.35)


# ───────────────────────── VẼ Ô SÁNG ─────────────────────────
func _on_overlay_draw() -> void:
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 5.0)

	# Chế độ trồng cây: ô trống sáng, ô trỏ chuột sáng mạnh
	if _selected >= 0:
		for r in grid_size.y:
			for c in grid_size.x:
				var cell := Vector2i(c, r)
				if not _occupied.has(cell):
					_overlay.draw_rect(_cell_rect(cell).grow(-3), Color(1, 1, 1, 0.08 + 0.05 * pulse))
		if _in_bounds(_hover_cell):
			var col := Color(1.0, 0.95, 0.4) if not _occupied.has(_hover_cell) else Color(1.0, 0.3, 0.3)
			var rect := _cell_rect(_hover_cell).grow(-2)
			_overlay.draw_rect(rect, Color(col, 0.28 + 0.15 * pulse))
			_overlay.draw_rect(rect, Color(col, 0.95), false, 3.0)

	# Chế độ ghép: ô có cây sáng xanh lơ, ô đã chọn có số thứ tự và đường nối
	if _combine_mode:
		var cyan := Color(0.4, 0.9, 1.0)
		for cell in _occupied.keys():
			if _in_bounds(cell):
				_overlay.draw_rect(_cell_rect(cell).grow(-3), Color(cyan, 0.10 + 0.05 * pulse))
		for i in range(_combine_cells.size() - 1):
			_overlay.draw_line(map_to_local(_combine_cells[i]), map_to_local(_combine_cells[i + 1]), Color(cyan, 0.9), 4.0)
		for i in _combine_cells.size():
			var rect := _cell_rect(_combine_cells[i]).grow(-2)
			_overlay.draw_rect(rect, Color(cyan, 0.25))
			_overlay.draw_rect(rect, Color(cyan, 1.0), false, 4.0)
			_overlay.draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, 24), str(i + 1),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
		if _in_bounds(_hover_cell) and _occupied.has(_hover_cell):
			_overlay.draw_rect(_cell_rect(_hover_cell).grow(-2), Color.WHITE, false, 3.0)

	# Hiệu ứng vừa trồng / ghép xong: viền sáng nở ra rồi mờ dần
	for cell in _fx:
		var t: float = _fx[cell]
		var rect := _cell_rect(cell)
		_overlay.draw_rect(rect.grow(lerpf(-6.0, 14.0, t)), Color(1, 1, 0.6, (1.0 - t) * 0.9), false, 4.0)
		_overlay.draw_rect(rect.grow(-6), Color(1, 1, 1, (1.0 - t) * 0.45))
