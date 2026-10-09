extends Plant
## Natri (Na) – cây "mìn hoá học".
## Đặc tính hoá học được đưa vào game:
##  1. Kim loại kiềm mềm, kém bền  -> máu rất thấp.
##  2. Bảo quản ngâm dầu hoả       -> cần thời gian "ngâm dầu" (arm_time) mới sẵn sàng.
##  3. Phản ứng mãnh liệt với nước -> slime (mềm, lỏng) chạm vào là NỔ, ngọn lửa vàng đặc trưng.
##  4. Hoá trị 1 (ion Na+)         -> chuẩn bị cho phản ứng sau này (Na + Cl -> NaCl, Na + H2O -> NaOH + H2...).

@export var symbol: String = "Na"
@export var valence: int = 1
@export var sodium_hp: int = 30

@export_group("Kích hoạt")
@export var arm_time: float = 5.0           # Giây "ngâm dầu" trước khi sẵn sàng (0 = sẵn sàng ngay)
@export var trigger_radius: float = 80.0   # Quái vào bán kính này là phát nổ

@export_group("Vụ nổ")
@export var blast_radius: float = 130.0
@export var blast_damage: int = 150
@export var blast_duration: float = 0.35

var is_armed: bool = false
var _arm_timer: float = 0.0
var _exploded: bool = false
var _blast_t: float = 0.0
var _idle_color: Color = Color(0.55, 0.55, 0.7, 1)   # Màu tối khi còn ngâm dầu
var _flash_tween: Tween

@onready var trigger_area: Area2D = get_node_or_null("TriggerArea")


func _ready() -> void:
	super._ready()
	add_to_group("elements")
	max_health = sodium_hp
	current_health = max_health
	_arm_timer = arm_time

	# Chỉnh bán kính vùng kích hoạt theo biến export
	if trigger_area:
		var shape_node = trigger_area.get_node_or_null("CollisionShape2D")
		if shape_node and shape_node.shape is CircleShape2D:
			var circle := shape_node.shape.duplicate() as CircleShape2D
			circle.radius = trigger_radius
			shape_node.shape = circle
	else:
		push_warning("Natri: không tìm thấy node TriggerArea!")

	if arm_time <= 0.0:
		_arm()
	elif sprite:
		sprite.modulate = _idle_color


func _process(delta: float) -> void:
	if _is_dead or _exploded:
		return

	if not is_armed:
		_arm_timer -= delta
		if _arm_timer <= 0.0:
			_arm()
		return

	_check_trigger()


# ─── SẴN SÀNG ───
func _arm() -> void:
	is_armed = true
	_idle_color = Color.WHITE
	print("[", name, "] Natri đã sẵn sàng!")
	if sprite:
		if _flash_tween and _flash_tween.is_valid():
			_flash_tween.kill()
		sprite.modulate = Color(2, 1.8, 0.6, 1)       # Loé vàng
		_flash_tween = create_tween()
		_flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.4)


# ─── KÍCH NỔ KHI QUÁI ĐẾN GẦN ───
func _check_trigger() -> void:
	if not trigger_area:
		return
	for body in trigger_area.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			_explode()
			return


# Bị đánh khi đã sẵn sàng -> nổ luôn. Chưa sẵn sàng -> bị ăn như cây thường.
func take_damage(amount: int) -> void:
	if _is_dead or _exploded:
		return
	if is_armed:
		_explode()
	else:
		super.take_damage(amount)


func _explode() -> void:
	if _exploded or _is_dead:
		return
	_exploded = true
	remove_from_group("plants")
	print("[", name, "] BÙM! Natri phát nổ")

	if sprite:
		sprite.visible = false
	# Để quái đang tấn công thôi nhắm vào cây này
	if hit_area:
		hit_area.set_deferred("monitorable", false)

	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.has_method("take_damage") \
				and global_position.distance_to(e.global_position) <= blast_radius:
			e.take_damage(blast_damage)

	var tween = create_tween()
	tween.tween_method(_set_blast, 0.0, 1.0, blast_duration)
	tween.tween_callback(queue_free)


func _set_blast(value: float) -> void:
	_blast_t = value
	queue_redraw()


# ─── HIỆU ỨNG ───
func _flash() -> void:
	if not sprite:
		return
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	sprite.modulate = Color(2, 0.5, 0.5, 1)
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "modulate", _idle_color, 0.15)


# Ngọn lửa vàng của natri lan ra theo bán kính nổ
func _draw() -> void:
	if not _exploded:
		return
	var fade := 1.0 - _blast_t
	var r := blast_radius * _blast_t
	draw_circle(Vector2.ZERO, r, Color(1.0, 0.85, 0.1, 0.55 * fade))
	draw_circle(Vector2.ZERO, r * 0.5, Color(1.0, 1.0, 0.8, 0.7 * fade))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(1.0, 0.6, 0.1, fade), 4.0)
