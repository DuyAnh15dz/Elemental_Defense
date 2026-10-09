class_name CompoundPlant
extends Plant
## Cây dạng hợp chất, tạo bởi công cụ Ghép. Mọi thông số lấy từ CompoundData.RECIPES.
## Không cần ảnh: tự vẽ hình tròn màu kèm công thức hoá học.
##
## Các kiểu cơ chế (behavior.type):
##   energy  sinh orb năng lượng định kỳ
##   heal    hồi máu cho cây xung quanh
##   dot     gây sát thương theo thời gian cho quái trong bán kính
##   slow    làm chậm quái trong bán kính
##   bomb    nổ khi quái đến gần hoặc khi bị đánh
## Hợp chất không bền (stable = false) tự phân hủy sau `lifetime` giây, không hoàn lại nguyên liệu.

var compound_id: String = ""
var data: Dictionary = {}
var behavior: Dictionary = {}
var unstable: bool = false

var _color: Color = Color.WHITE
var _life_total: float = 1.0
var _life_left: float = 1.0
var _timer: float = 0.0
var _pulse: float = 0.0
var _exploded: bool = false
var _blast_t: float = 0.0
var _slowed: Dictionary = {}          # quái -> tốc độ gốc
var _orb_scene: PackedScene
var _flash_tween: Tween


# Gọi TRƯỚC khi add_child
func setup(id: String) -> void:
	compound_id = id
	data = CompoundData.RECIPES[id]
	behavior = data["behavior"]
	_color = data["color"]
	max_health = int(data["hp"])
	unstable = not bool(data.get("stable", true))
	if unstable:
		_life_total = float(data.get("lifetime", 8.0))
		_life_left = _life_total
	set_meta("element_id", id)

	# Vùng để quái nhận ra đây là cây (giống HitArea của các cây khác)
	var area := Area2D.new()
	area.name = "HitArea"
	area.collision_mask = 2
	var shape := CircleShape2D.new()
	shape.radius = 40.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	area.add_child(cs)
	add_child(area)


func _ready() -> void:
	super._ready()
	add_to_group("elements")
	_timer = float(behavior.get("interval", 1.0))
	for path in ["res://energy_orb.tscn", "res://UI/energy_orb.tscn"]:
		if ResourceLoader.exists(path):
			_orb_scene = load(path) as PackedScene
			break


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()
	if _is_dead or _exploded:
		return

	if unstable:
		_life_left -= delta
		if _life_left <= 0.0:
			_decompose()
			return

	match str(behavior.get("type", "")):
		"energy":
			if _tick(delta): _spawn_orb()
		"heal":
			if _tick(delta): _heal_neighbors()
		"dot":
			if _tick(delta): _damage_enemies_in_radius()
		"slow":
			_update_slow()
		"bomb":
			if not _enemies_within(float(behavior["trigger"])).is_empty():
				_explode()


# Đếm giờ theo `interval`, trả true khi tới lượt
func _tick(delta: float) -> bool:
	_timer -= delta
	if _timer <= 0.0:
		_timer = float(behavior.get("interval", 1.0))
		return true
	return false


# ───────────────────────── CƠ CHẾ ─────────────────────────
func _spawn_orb() -> void:
	if _orb_scene == null:
		return
	var orb = _orb_scene.instantiate()
	orb.global_position = global_position + Vector2(0, -20)
	orb.energy_value = int(behavior["amount"])
	get_tree().current_scene.add_child(orb)


func _heal_neighbors() -> void:
	var r := float(behavior["radius"])
	var amount := int(behavior["amount"])
	for p in get_tree().get_nodes_in_group("plants"):
		if p == self or not is_instance_valid(p) or not (p is Node2D):
			continue
		if global_position.distance_to(p.global_position) <= r and "current_health" in p and "max_health" in p:
			p.current_health = mini(int(p.max_health), int(p.current_health) + amount)


func _damage_enemies_in_radius() -> void:
	for e in _enemies_within(float(behavior["radius"])):
		if e.has_method("take_damage"):
			e.take_damage(int(behavior["amount"]))


func _update_slow() -> void:
	var inside := _enemies_within(float(behavior["radius"]))
	for e in inside:
		if not _slowed.has(e):
			_slowed[e] = e.speed
			e.speed = e.speed * float(behavior["factor"])
	for e in _slowed.keys():
		if not is_instance_valid(e) or not inside.has(e):
			if is_instance_valid(e):
				e.speed = _slowed[e]
			_slowed.erase(e)


func _restore_slow() -> void:
	for e in _slowed.keys():
		if is_instance_valid(e):
			e.speed = _slowed[e]
	_slowed.clear()


func _enemies_within(r: float) -> Array:
	var out: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e is Node2D and e.get("current_state") != 2 \
				and global_position.distance_to(e.global_position) <= r:
			out.append(e)
	return out


func _explode() -> void:
	if _exploded or _is_dead:
		return
	_exploded = true
	remove_from_group("plants")
	print("[", name, "] BÙM! ", data["formula"], " phát nổ")
	if hit_area:
		hit_area.set_deferred("monitorable", false)
	for e in _enemies_within(float(behavior["radius"])):
		if e.has_method("take_damage"):
			e.take_damage(int(behavior["damage"]))
	var tween := create_tween()
	tween.tween_method(func(v: float): _blast_t = v, 0.0, 1.0, 0.35)
	tween.tween_callback(queue_free)


# ───────────────────────── SÁT THƯƠNG / CHẾT / PHÂN HỦY ─────────────────────────
func take_damage(amount: int) -> void:
	if _is_dead or _exploded:
		return
	if str(behavior.get("type", "")) == "bomb":
		_explode()      # Khí metan bị đánh trúng là bốc cháy
		return
	super.take_damage(amount)


func _flash() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	modulate = Color(2, 0.5, 0.5, 1)
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "modulate", Color.WHITE, 0.15)


func _die() -> void:
	_is_dead = true
	remove_from_group("plants")
	_restore_slow()
	print("[", name, "] Cây đã chết")
	_fade_and_free()


func _decompose() -> void:
	_is_dead = true
	remove_from_group("plants")
	_restore_slow()
	print("[", name, "] ", data["formula"], " không bền, đã phân hủy")
	_fade_and_free()


func _fade_and_free() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)


func _exit_tree() -> void:
	_restore_slow()


# ───────────────────────── VẼ ─────────────────────────
func _draw() -> void:
	if _exploded:
		var fade := 1.0 - _blast_t
		var r := float(behavior["radius"]) * _blast_t
		draw_circle(Vector2.ZERO, r, Color(1.0, 0.7, 0.2, 0.5 * fade))
		draw_circle(Vector2.ZERO, r * 0.5, Color(1.0, 1.0, 0.8, 0.7 * fade))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(1.0, 0.45, 0.1, fade), 4.0)
		return

	var t := str(behavior.get("type", ""))
	var area_r := float(behavior.get("radius", 0.0))
	if t in ["heal", "dot", "slow"] and area_r > 0.0:
		var pulse := 0.5 + 0.5 * sin(_pulse * 3.0)
		draw_circle(Vector2.ZERO, area_r, Color(_color, 0.06 + 0.04 * pulse))
		draw_arc(Vector2.ZERO, area_r, 0.0, TAU, 64, Color(_color, 0.35), 2.0)

	draw_circle(Vector2.ZERO, 34.0, Color(_color.darkened(0.4), 0.95))
	draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 40, Color.WHITE, 3.0)

	var txt: String = data["formula"]
	var fs := 22 if txt.length() <= 3 else 16
	draw_string(ThemeDB.fallback_font, Vector2(-40, fs * 0.35), txt, HORIZONTAL_ALIGNMENT_CENTER, 80, fs, Color.WHITE)

	if unstable:
		var frac := clampf(_life_left / _life_total, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 40.0, -PI / 2.0, -PI / 2.0 + TAU * frac, 40, Color(1.0, 0.45, 0.3), 4.0)
