extends CanvasLayer
## Bách khoa nguyên tố – bảng tuần hoàn.
## Bấm nút "Bách khoa [A]" (góc trên bên phải) hoặc phím A để mở, Esc để đóng.
## Khi mở, game tạm dừng. Ô viền xanh = cây, viền đỏ = quái, ô mờ = chưa có dữ liệu.
## Toàn bộ dữ liệu nằm trong element_data.gd.
##
## Cách gắn: thêm node CanvasLayer tên "Almanac" vào scene chính và gắn script này.

const CELL := Vector2(54, 44)
const GAP := 3.0
const PANEL_SIZE := Vector2(1100, 830)

# 18 cột; "." = ô trống, "L" = ghi chú lantanit, "A" = ghi chú actinit
const ROWS: Array[String] = [
	"H . . . . . . . . . . . . . . . . He",
	"Li Be . . . . . . . . . . B C N O F Ne",
	"Na Mg . . . . . . . . . . Al Si P S Cl Ar",
	"K Ca Sc Ti V Cr Mn Fe Co Ni Cu Zn Ga Ge As Se Br Kr",
	"Rb Sr Y Zr Nb Mo Tc Ru Rh Pd Ag Cd In Sn Sb Te I Xe",
	"Cs Ba L Hf Ta W Re Os Ir Pt Au Hg Tl Pb Bi Po At Rn",
	"Fr Ra A Rf Db Sg Bh Hs Mt Ds Rg Cn Nh Fl Mc Lv Ts Og",
]
const LANTHANIDES := "La Ce Pr Nd Pm Sm Eu Gd Tb Dy Ho Er Tm Yb Lu"
const ACTINIDES := "Ac Th Pa U Np Pu Am Cm Bk Cf Es Fm Md No Lr"

const CAT_COLORS := {
	"alkali": Color(0.93, 0.42, 0.38), "alkaline": Color(0.95, 0.66, 0.33),
	"transition": Color(0.45, 0.58, 0.85), "post": Color(0.42, 0.72, 0.72),
	"metalloid": Color(0.62, 0.78, 0.40), "nonmetal": Color(0.35, 0.78, 0.50),
	"halogen": Color(0.78, 0.74, 0.32), "noble": Color(0.68, 0.50, 0.85),
	"lanthanide": Color(0.82, 0.50, 0.70), "actinide": Color(0.78, 0.40, 0.55),
}
const COLOR_PLANT := Color(0.35, 1.0, 0.45)
const COLOR_ENEMY := Color(1.0, 0.30, 0.30)

var _root: Control
var _panel: PanelContainer
var _toggle_btn: Button
var _buttons: Dictionary = {}
var _selected: String = ""

var _icon_style: StyleBoxFlat
var _icon_tex: TextureRect
var _icon_sym: Label
var _name_label: Label
var _sub_label: Label
var _tag_label: Label
var _left_text: RichTextLabel
var _right_text: RichTextLabel


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS     # Vẫn hoạt động khi game tạm dừng
	_build_toggle_button()
	_build_window()
	_root.visible = false
	get_viewport().size_changed.connect(_fit_to_viewport)


# ───────────────────────── MỞ / ĐÓNG ─────────────────────────
func show_almanac() -> void:
	_root.visible = true
	_toggle_btn.visible = false
	get_tree().paused = true
	_fit_to_viewport()
	_select(_selected if _selected != "" else "H")


# Thu nhỏ bảng nếu cửa sổ game nhỏ hơn bảng (ví dụ 1152 x 648)
func _fit_to_viewport() -> void:
	if _panel == null:
		return
	var vs := get_viewport().get_visible_rect().size
	var k := minf(1.0, minf(vs.x / PANEL_SIZE.x, vs.y / PANEL_SIZE.y))
	_panel.pivot_offset = PANEL_SIZE / 2.0
	_panel.scale = Vector2(k, k)


func hide_almanac() -> void:
	_root.visible = false
	_toggle_btn.visible = true
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_A:
			if _root.visible: hide_almanac()
			else: show_almanac()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and _root.visible:
			hide_almanac()
			get_viewport().set_input_as_handled()


# ───────────────────────── DỰNG GIAO DIỆN ─────────────────────────
func _build_toggle_button() -> void:
	_toggle_btn = Button.new()
	_toggle_btn.text = "Bách khoa [A]"
	_toggle_btn.focus_mode = Control.FOCUS_NONE
	_toggle_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_toggle_btn.offset_left = -150
	_toggle_btn.offset_right = -10
	_toggle_btn.offset_top = 8
	_toggle_btn.offset_bottom = 44
	_toggle_btn.pressed.connect(show_almanac)
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
		margin.add_theme_constant_override("margin_" + side, 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Tiêu đề
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := Label.new()
	title.text = "BÁCH KHOA NGUYÊN TỐ"
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "Đóng [Esc]"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(hide_almanac)
	header.add_child(close_btn)

	# Bảng tuần hoàn
	var table_w := 18.0 * (CELL.x + GAP) - GAP
	var y_lan := 7.0 * (CELL.y + GAP) + 14.0
	var y_act := y_lan + CELL.y + GAP
	var table := Control.new()
	table.custom_minimum_size = Vector2(table_w, y_act + CELL.y)
	var table_center := CenterContainer.new()
	table_center.add_child(table)
	vbox.add_child(table_center)

	for r in ROWS.size():
		var tokens := ROWS[r].split(" ")
		for c in tokens.size():
			var pos := Vector2(c * (CELL.x + GAP), r * (CELL.y + GAP))
			match tokens[c]:
				".": pass
				"L": _make_marker("57–71", pos, table)
				"A": _make_marker("89–103", pos, table)
				_: _make_cell(tokens[c], pos, table)

	var lan := LANTHANIDES.split(" ")
	for i in lan.size():
		_make_cell(lan[i], Vector2((i + 2) * (CELL.x + GAP), y_lan), table)
	var act := ACTINIDES.split(" ")
	for i in act.size():
		_make_cell(act[i], Vector2((i + 2) * (CELL.x + GAP), y_act), table)

	# Chú thích
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 18)
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(legend)
	_legend_item(legend, COLOR_PLANT, "Cây")
	_legend_item(legend, COLOR_ENEMY, "Quái (kim loại nặng, phóng xạ)")
	_legend_item(legend, Color(0.3, 0.3, 0.3), "Chưa có trong game")

	# Chi tiết
	var detail := HBoxContainer.new()
	detail.add_theme_constant_override("separation", 12)
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(detail)

	var left_col := VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(210, 0)
	left_col.add_theme_constant_override("separation", 4)
	detail.add_child(left_col)

	var icon_panel := Panel.new()
	icon_panel.custom_minimum_size = Vector2(140, 140)
	icon_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icon_style = StyleBoxFlat.new()
	_icon_style.set_corner_radius_all(10)
	_icon_style.set_border_width_all(2)
	_icon_style.border_color = Color(1, 1, 1, 0.35)
	icon_panel.add_theme_stylebox_override("panel", _icon_style)
	left_col.add_child(icon_panel)

	_icon_tex = TextureRect.new()
	_icon_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icon_tex.offset_left = 10
	_icon_tex.offset_top = 10
	_icon_tex.offset_right = -10
	_icon_tex.offset_bottom = -10
	_icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_panel.add_child(_icon_tex)

	_icon_sym = Label.new()
	_icon_sym.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icon_sym.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_sym.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon_sym.add_theme_font_size_override("font_size", 60)
	icon_panel.add_child(_icon_sym)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 22)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_col.add_child(_name_label)

	_sub_label = Label.new()
	_sub_label.add_theme_font_size_override("font_size", 13)
	_sub_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_col.add_child(_sub_label)

	_tag_label = Label.new()
	_tag_label.add_theme_font_size_override("font_size", 13)
	_tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tag_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_col.add_child(_tag_label)

	_left_text = _make_rich()
	detail.add_child(_left_text)
	_right_text = _make_rich()
	detail.add_child(_right_text)


func _make_rich() -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.scroll_active = true
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	r.custom_minimum_size = Vector2(300, 230)
	r.add_theme_font_size_override("normal_font_size", 15)
	r.add_theme_font_size_override("bold_font_size", 15)
	return r


func _legend_item(parent: Control, color: Color, text: String) -> void:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var swatch := ColorRect.new()
	swatch.color = color
	swatch.custom_minimum_size = Vector2(16, 16)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(swatch)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	box.add_child(lbl)
	parent.add_child(box)


# ───────────────────────── Ô NGUYÊN TỐ ─────────────────────────
func _make_cell(sym: String, pos: Vector2, parent: Control) -> void:
	var z := ElementData.SYMBOLS.find(sym) + 1
	if z == 0:
		push_warning("Bách khoa: không có nguyên tố '%s'" % sym)
		return

	var btn := Button.new()
	btn.position = pos
	btn.custom_minimum_size = CELL
	btn.size = CELL
	btn.text = sym
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_constant_override("outline_size", 3)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	btn.tooltip_text = ElementData.NAMES[z - 1]
	btn.pressed.connect(_select.bind(sym))
	parent.add_child(btn)

	var num := Label.new()
	num.text = str(z)
	num.position = Vector2(4, 1)
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	num.add_theme_font_size_override("font_size", 9)
	num.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	btn.add_child(num)

	_buttons[sym] = btn
	_apply_style(sym)


func _make_marker(text: String, pos: Vector2, parent: Control) -> void:
	var btn := Button.new()
	btn.position = pos
	btn.size = CELL
	btn.custom_minimum_size = CELL
	btn.text = text
	btn.disabled = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 11)
	var s := _style(Color(0.2, 0.2, 0.25), Color(0, 0, 0, 0.5), 1)
	btn.add_theme_stylebox_override("disabled", s)
	parent.add_child(btn)


func _style(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(4)
	return s


func _apply_style(sym: String) -> void:
	var btn: Button = _buttons[sym]
	var z := ElementData.SYMBOLS.find(sym) + 1
	var base: Color = CAT_COLORS[ElementData.category(sym, z)]
	var entry: Dictionary = ElementData.ENTRIES.get(sym, {})
	var has_entry := not entry.is_empty()

	var bg := base if has_entry else base.darkened(0.55)
	var border := Color(0, 0, 0, 0.5)
	var bw := 1
	if has_entry:
		border = COLOR_PLANT if entry["role"] == "plant" else COLOR_ENEMY
		bw = 3
	if sym == _selected:
		border = Color.WHITE
		bw = 4

	btn.add_theme_stylebox_override("normal", _style(bg, border, bw))
	btn.add_theme_stylebox_override("hover", _style(bg.lightened(0.2), border, bw))
	btn.add_theme_stylebox_override("pressed", _style(bg.lightened(0.3), border, bw))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", Color.WHITE if has_entry else Color(1, 1, 1, 0.6))


# ───────────────────────── HIỂN THỊ CHI TIẾT ─────────────────────────
func _select(sym: String) -> void:
	var prev := _selected
	_selected = sym
	if prev != "" and _buttons.has(prev):
		_apply_style(prev)
	_apply_style(sym)
	_show_detail(sym)


func _show_detail(sym: String) -> void:
	var z := ElementData.SYMBOLS.find(sym) + 1
	var cat := ElementData.category(sym, z)
	var cat_name: String = ElementData.CATEGORY_NAMES[cat]
	var entry: Dictionary = ElementData.ENTRIES.get(sym, {})

	_name_label.text = "%s (%s)" % [ElementData.NAMES[z - 1], sym]
	var sub := "Số hiệu %d · %s" % [z, cat_name]
	if entry.has("mass"):
		sub += "\nKhối lượng: %s" % entry["mass"]
	_sub_label.text = sub

	# Biểu tượng: ảnh nếu có, không thì ký hiệu hoá học
	_icon_style.bg_color = (CAT_COLORS[cat] as Color).darkened(0.55)
	_icon_tex.texture = null
	_icon_sym.text = sym
	_icon_sym.visible = true
	if entry.has("icon") and ResourceLoader.exists(entry["icon"]):
		_icon_tex.texture = load(entry["icon"]) as Texture2D
		_icon_sym.visible = false

	# Nhãn vai trò / trạng thái
	if entry.is_empty():
		_tag_label.text = "Chưa có trong game"
		_tag_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	else:
		var role := "CÂY" if entry["role"] == "plant" else "QUÁI"
		var status := ""
		match entry["status"]:
			"ready": status = "Đã có trong game"
			"partial": status = "Có chỉ số, nội tại đang thiết kế"
			_: status = "Đang thiết kế"
		_tag_label.text = "%s · %s\n%s" % [role, entry["class"], status]
		_tag_label.add_theme_color_override("font_color", COLOR_PLANT if entry["role"] == "plant" else COLOR_ENEMY)

	_left_text.text = _build_left(entry)
	_right_text.text = _build_right(entry, cat_name)
	_left_text.scroll_to_line(0)
	_right_text.scroll_to_line(0)


func _h(title: String) -> String:
	return "[b][color=#ffd966]%s[/color][/b]\n" % title


func _build_left(entry: Dictionary) -> String:
	if entry.is_empty():
		return "[color=#aaaaaa]Nguyên tố này chưa có trong game.\n\nĐể thêm cây hoặc quái dùng nguyên tố này, thêm một mục vào element_data.gd.[/color]"

	var t := _h("Chỉ số")
	for s in entry["stats"]:
		t += "[b]%s:[/b] %s\n" % [s[0], s[1]]
	if entry["role"] == "plant":
		t += "[b]Giá:[/b] %d năng lượng\n" % int(entry["cost"])
		t += "[b]Hồi chiêu:[/b] %d giây\n" % int(round(float(entry["cooldown"])))

	t += "\n" + _h("Nội tại: " + str(entry["passive_name"])) + str(entry["passive"]) + "\n"

	if entry.has("reactions"):
		t += "\n" + _h("Phản ứng ghép")
		for r in entry["reactions"]:
			t += "• %s\n" % r
	return t


func _build_right(entry: Dictionary, cat_name: String) -> String:
	if entry.is_empty():
		return _h("Phân loại") + cat_name + "\n"

	var t := _h("Tính chất hoá học")
	for p in entry["properties"]:
		t += "• %s\n" % p
	t += "\n" + _h("Giới thiệu") + str(entry["intro"]) + "\n"
	if entry.has("counter"):
		t += "\n" + _h("Khắc chế") + str(entry["counter"]) + "\n"
	return t
