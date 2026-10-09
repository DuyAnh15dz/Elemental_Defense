extends CanvasLayer
## Sổ tay hợp chất – hiển thị danh sách hợp chất đã khám phá.
## Bấm nút "Sổ tay [J]" (góc trên bên phải) hoặc phím J để mở, Esc để đóng.
## Khi mở, game tạm dừng. Hợp chất chưa khám phá hiện "???".
##
## Cách gắn: thêm node CanvasLayer tên "CompoundJournal" vào scene chính và gắn script này.

const PANEL_SIZE := Vector2(1000, 700)
const ITEM_HEIGHT := 56

var _root: Control
var _panel: PanelContainer
var _toggle_btn: Button
var _list_container: VBoxContainer
var _detail_label: RichTextLabel
var _count_label: Label
var _selected_id: String = ""

var _icon_style: StyleBoxFlat
var _icon_tex: TextureRect
var _icon_formula: Label


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_toggle_button()
	_build_window()
	_root.visible = false
	get_viewport().size_changed.connect(_fit_to_viewport)


# ───────────────────────── MỞ / ĐÓNG ─────────────────────────
func show_journal() -> void:
	_root.visible = true
	_toggle_btn.visible = false
	get_tree().paused = true
	_fit_to_viewport()
	_refresh_list()
	_select_first()


func hide_journal() -> void:
	_root.visible = false
	_toggle_btn.visible = true
	get_tree().paused = false


func _fit_to_viewport() -> void:
	if _panel == null:
		return
	var vs := get_viewport().get_visible_rect().size
	var k := minf(1.0, minf(vs.x / PANEL_SIZE.x, vs.y / PANEL_SIZE.y))
	_panel.pivot_offset = PANEL_SIZE / 2.0
	_panel.scale = Vector2(k, k)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_J:
			if _root.visible: hide_journal()
			else: show_journal()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and _root.visible:
			hide_journal()
			get_viewport().set_input_as_handled()


# ───────────────────────── DỰNG GIAO DIỆN ─────────────────────────
func _build_toggle_button() -> void:
	_toggle_btn = Button.new()
	_toggle_btn.text = "Sổ tay [J]"
	_toggle_btn.focus_mode = Control.FOCUS_NONE
	_toggle_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_toggle_btn.offset_left = -260
	_toggle_btn.offset_right = -160
	_toggle_btn.offset_top = 8
	_toggle_btn.offset_bottom = 44
	_toggle_btn.pressed.connect(show_journal)
	add_child(_toggle_btn)


func _build_window() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = PANEL_SIZE
	center.add_child(panel)
	_panel = panel

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# ── Tiêu đề ──
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := Label.new()
	title.text = "SỔ TAY HỢP CHẤT"
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_count_label = Label.new()
	_count_label.add_theme_font_size_override("font_size", 14)
	_count_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	header.add_child(_count_label)
	var close_btn := Button.new()
	close_btn.text = "Đóng [Esc]"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(hide_journal)
	header.add_child(close_btn)

	# ── Nội dung: danh sách trái + chi tiết phải ──
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(body)

	# Danh sách (bên trái)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(360, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)

	_list_container = VBoxContainer.new()
	_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_container.add_theme_constant_override("separation", 4)
	scroll.add_child(_list_container)

	# Chi tiết (bên phải)
	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 8)
	detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(detail_box)

	# Icon
	var icon_panel := Panel.new()
	icon_panel.custom_minimum_size = Vector2(120, 120)
	icon_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icon_style = StyleBoxFlat.new()
	_icon_style.set_corner_radius_all(10)
	_icon_style.set_border_width_all(2)
	_icon_style.border_color = Color(1, 1, 1, 0.35)
	icon_panel.add_theme_stylebox_override("panel", _icon_style)
	detail_box.add_child(icon_panel)

	_icon_tex = TextureRect.new()
	_icon_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icon_tex.offset_left = 8
	_icon_tex.offset_top = 8
	_icon_tex.offset_right = -8
	_icon_tex.offset_bottom = -8
	_icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_tex.visible = false
	icon_panel.add_child(_icon_tex)

	_icon_formula = Label.new()
	_icon_formula.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icon_formula.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_formula.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon_formula.add_theme_font_size_override("font_size", 40)
	icon_panel.add_child(_icon_formula)

	# Text chi tiết
	_detail_label = RichTextLabel.new()
	_detail_label.bbcode_enabled = true
	_detail_label.scroll_active = true
	_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_label.add_theme_font_size_override("normal_font_size", 14)
	_detail_label.add_theme_font_size_override("bold_font_size", 14)
	detail_box.add_child(_detail_label)


# ───────────────────────── DANH SÁCH ─────────────────────────
func _refresh_list() -> void:
	for child in _list_container.get_children():
		child.queue_free()

	var all_ids := CompoundData.RECIPES.keys()
	all_ids.sort()

	var discovered_count := 0
	for id in all_ids:
		if Discoveries.is_discovered(id):
			discovered_count += 1

	_count_label.text = "Đã khám phá: %d / %d" % [discovered_count, all_ids.size()]

	for id in all_ids:
		_add_list_item(id)


func _add_list_item(id: String) -> void:
	var d: Dictionary = CompoundData.RECIPES[id]
	var known := Discoveries.is_discovered(id)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, ITEM_HEIGHT)
	btn.focus_mode = Control.FOCUS_NONE
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_size_override("font_size", 15)

	if known:
		btn.text = "  %s  –  %s" % [d["formula"], d["name"]]
	else:
		btn.text = "  ???  –  Chưa khám phá"
		btn.modulate = Color(0.6, 0.6, 0.65)

	btn.pressed.connect(_select.bind(id))

	if id == _selected_id:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.25, 0.4, 0.6, 0.6)
		s.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("normal", s)

	_list_container.add_child(btn)


func _select_first() -> void:
	for id in CompoundData.RECIPES.keys():
		if Discoveries.is_discovered(id):
			_select(id)
			return
	# Nếu chưa khám phá gì, chọn cái đầu
	var keys := CompoundData.RECIPES.keys()
	if not keys.is_empty():
		_select(keys[0])


func _select(id: String) -> void:
	_selected_id = id
	_refresh_list()
	_show_detail(id)


# ───────────────────────── CHI TIẾT ─────────────────────────
func _show_detail(id: String) -> void:
	var d: Dictionary = CompoundData.RECIPES[id]
	var known := Discoveries.is_discovered(id)

	# Icon / công thức
	_icon_formula.text = d["formula"] if known else "???"
	_icon_formula.visible = true
	_icon_tex.visible = false
	_icon_style.bg_color = (d["color"] as Color).darkened(0.55) if known else Color(0.15, 0.15, 0.2)

	if not known:
		_detail_label.text = "[center][color=#888888]Chưa khám phá hợp chất này.\n\nHãy ghép thử trong game để mở khoá.[/color][/center]"
		return

	var t := ""
	t += "[center][font_size=22][b]%s[/b][/font_size][/center]\n" % d["formula"]
	t += "[center][color=#ffd966]%s[/color][/center]\n\n" % d["name"]
	t += "[b]Phương trình:[/b] %s\n" % d["equation"]
	t += "[b]Giá ghép:[/b] %d năng lượng\n" % int(d["cost"])
	t += "[b]Điều kiện:[/b] %s\n" % CompoundData.condition_text(id)
	t += "\n"

	if not bool(d.get("stable", true)):
		t += "[color=#ff9f43]⚠ Không bền — tự phân hủy sau %d giây[/color]\n\n" % int(d.get("lifetime", 8))
	else:
		t += "[color=#9cff9c]✓ Bền vững[/color]\n\n"

	t += _h("Chỉ số trong game")
	for s in d["stats"]:
		t += "• [b]%s:[/b] %s\n" % [s[0], s[1]]

	if d.has("mechanic"):
		t += "\n" + _h("Cơ chế")
		t += str(d["mechanic"]) + "\n"

	if d.has("properties"):
		t += "\n" + _h("Tính chất hoá học")
		for p in d["properties"]:
			t += "• %s\n" % p

	if d.has("intro"):
		t += "\n" + _h("Giới thiệu")
		t += str(d["intro"]) + "\n"

	_detail_label.text = t
	_detail_label.scroll_to_line(0)


func _h(title: String) -> String:
	return "[b][color=#ffd966]%s[/color][/b]\n" % title
