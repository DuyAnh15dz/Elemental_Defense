extends Plant
## Cacbon (C) – cây phòng thủ (tank).
## Đặc tính hoá học được đưa vào game:
##  1. Liên kết cộng hoá trị bền  -> máu rất cao (cây "tường").
##  2. Dạng thù hình: than -> kim cương. Bị đánh liên tục = tích "áp suất";
##     đủ ngưỡng thì nén thành KIM CƯƠNG (máu cao hơn, hồi máu, phản sát thương).
##  3. Hoá trị 4: chuẩn bị cho hệ thống phản ứng (C + 4H -> CH4, C + O -> CO, C + 2O -> CO2...).

@export var symbol: String = "C"
@export var valence: int = 4                      # Số liên kết tối đa (dùng cho hệ thống ghép nguyên tố sau này)

@export_group("Than (dạng thường)")
@export var carbon_hp: int = 150

@export_group("Kim cương (dạng nén)")
@export var pressure_threshold: int = 100         # Tổng sát thương nhận vào để hoá kim cương
@export var diamond_hp: int = 300
@export_range(0.0, 1.0) var diamond_heal_ratio: float = 0.5   # Hồi bao nhiêu % máu tối đa khi hoá kim cương
@export var reflect_damage: int = 5               # Sát thương phản lại kẻ đang tấn công
@export var diamond_texture: Texture2D            # Có ảnh kim cương thì kéo vào đây, không thì tự vẽ hình viên ngọc

var pressure: int = 0
var is_diamond: bool = false
var _flash_tween: Tween


func _ready() -> void:
	super._ready()
	add_to_group("elements")
	max_health = carbon_hp
	current_health = max_health


func take_damage(amount: int) -> void:
	if _is_dead:
		return
	super.take_damage(amount)
	if _is_dead:
		return

	if is_diamond:
		_reflect_damage()
	else:
		pressure += amount
		if pressure >= pressure_threshold:
			_become_diamond()


# ─── THAN -> KIM CƯƠNG ───
func _become_diamond() -> void:
	is_diamond = true
	max_health = diamond_hp
	current_health = maxi(current_health, int(diamond_hp * diamond_heal_ratio))
	print("[", name, "] Áp suất đủ lớn -> KIM CƯƠNG! HP: ", current_health, "/", max_health)

	if diamond_texture and sprite:
		sprite.texture = diamond_texture
	elif sprite:
		sprite.visible = false          # Ẩn than, dùng hình viên ngọc vẽ trong _draw()
	queue_redraw()

	# Hiệu ứng: sáng loé + nảy lên
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	modulate = Color(3, 3, 3, 1)
	scale = Vector2(1.3, 1.3)
	_flash_tween = create_tween().set_parallel(true)
	_flash_tween.tween_property(self, "modulate", Color.WHITE, 0.4)
	_flash_tween.tween_property(self, "scale", Vector2.ONE, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ─── PHẢN SÁT THƯƠNG (chỉ kim cương) ───
func _reflect_damage() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.get("current_target") == self and e.has_method("take_damage"):
			e.take_damage(reflect_damage)


# ─── HIỆU ỨNG (ghi đè của Plant để hoạt động với cả hình viên ngọc) ───
func _flash() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	modulate = Color(2, 0.5, 0.5, 1)
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "modulate", Color.WHITE, 0.15)


func _die() -> void:
	_is_dead = true
	remove_from_group("plants")
	print("[", name, "] Cây đã chết")
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)


# ─── VẼ VIÊN KIM CƯƠNG (khi chưa có ảnh) ───
func _draw() -> void:
	if not is_diamond or diamond_texture:
		return
	var r := 36.0
	var c := Vector2(0, -3)
	var outline := PackedVector2Array([
		c + Vector2(-r * 0.6, -r * 0.7), c + Vector2(r * 0.6, -r * 0.7),
		c + Vector2(r, -r * 0.15), c + Vector2(0, r), c + Vector2(-r, -r * 0.15),
	])
	draw_colored_polygon(outline, Color(0.55, 0.9, 1.0, 0.95))
	var line_col := Color(1, 1, 1, 0.9)
	draw_polyline(outline + PackedVector2Array([outline[0]]), line_col, 2.0)
	draw_line(c + Vector2(-r, -r * 0.15), c + Vector2(r, -r * 0.15), line_col, 1.5)
	draw_line(c + Vector2(-r * 0.6, -r * 0.7), c + Vector2(-r * 0.3, -r * 0.15), line_col, 1.5)
	draw_line(c + Vector2(r * 0.6, -r * 0.7), c + Vector2(r * 0.3, -r * 0.15), line_col, 1.5)
	draw_line(c + Vector2(-r * 0.3, -r * 0.15), c + Vector2(0, r), line_col, 1.5)
	draw_line(c + Vector2(r * 0.3, -r * 0.15), c + Vector2(0, r), line_col, 1.5)
