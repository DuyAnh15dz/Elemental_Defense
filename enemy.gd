extends CharacterBody2D

signal enemy_died

enum State { MOVING, ATTACKING, DYING }
var current_state: State = State.MOVING

@export var max_hp: int = 100
@export var speed: float = 40.0
@export var damage: int = 10
@export var attack_interval: float = 1.0
@export var direction: int = -1

var hp: int
var attack_timer: float = 0.0
var current_target: Node = null

# ⚠️ 2 NODE SPRITE RIÊNG
@onready var sprite_move: AnimatedSprite2D = $SpriteMove
@onready var sprite_attack: AnimatedSprite2D = $SpriteAttack
@onready var attack_area: Area2D = $AttackArea

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	_show_only("move")
	
	if direction > 0:
		sprite_move.flip_h = true
		sprite_attack.flip_h = true
	
	# Connect CẢ body VÀ area signal
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)
	attack_area.area_entered.connect(_on_attack_area_area_entered)   # ← THÊM
	attack_area.area_exited.connect(_on_attack_area_area_exited)     # ← THÊM
	
	sprite_attack.animation_finished.connect(_on_animation_finished)

# ─── HELPER: ẩn/hiện đúng sprite ───
func _show_only(anim_name: String) -> void:
	if anim_name == "move":
		sprite_move.visible = true
		sprite_attack.visible = false
		sprite_move.play("move")
	else:
		sprite_move.visible = false
		sprite_attack.visible = true
		sprite_attack.play(anim_name)

# ─── PHYSICS PROCESS ───
func _physics_process(delta: float) -> void:
	# DEBUG: kiểm tra overlap mỗi frame
	if current_state == State.MOVING:
		var bodies = attack_area.get_overlapping_bodies()
		if bodies.size() > 0:
			print("[Slime] Overlap bodies: ", bodies)
		var areas = attack_area.get_overlapping_areas()
		if areas.size() > 0:
			print("[Slime] Overlap areas: ", areas)
	
	match current_state:
		State.MOVING: _state_moving(delta)
		State.ATTACKING: _state_attacking(delta)
		State.DYING: velocity = Vector2.ZERO

func _state_moving(_delta: float) -> void:
	velocity.x = speed * direction
	velocity.y = 0
	move_and_slide()

func _state_attacking(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	
	if not is_instance_valid(current_target):
		_return_to_moving()
		return
	
	attack_timer += delta
	if attack_timer >= attack_interval:
		attack_timer = 0.0
		if current_target.has_method("take_damage"):
			current_target.take_damage(damage)

func _return_to_moving() -> void:
	current_state = State.MOVING
	current_target = null
	_show_only("move")

func _on_attack_area_body_exited(body: Node) -> void:
	if body == current_target:
		_return_to_moving()

func _on_animation_finished() -> void:
	if sprite_attack.animation == "death":
		enemy_died.emit()
		queue_free()

func take_damage(amount: int) -> void:
	if current_state == State.DYING:
		return
	
	hp -= amount
	if hp <= 0:
		_die()
	else:
		_flash_white()

func _die() -> void:
	current_state = State.DYING
	velocity = Vector2.ZERO
	set_collision_layer_value(2, false)
	attack_area.monitoring = false
	_show_only("death")

func _flash_white() -> void:
	var tween = create_tween()
	sprite_move.modulate = Color(5, 5, 5, 1)
	sprite_attack.modulate = Color(5, 5, 5, 1)
	tween.tween_property(sprite_move, "modulate", Color.WHITE, 0.1)
	tween.tween_property(sprite_attack, "modulate", Color.WHITE, 0.1)

func _on_attack_area_body_entered(body: Node) -> void:
	print("[Slime] AttackArea chạm: ", body.name, " | in_group plants? ", body.is_in_group("plants"))
	
	if current_state != State.MOVING:
		print("  → Bỏ qua: state = ", current_state)
		return
	if not body.is_in_group("plants"):
		print("  → Bỏ qua: không phải plants")
		return
	
	print("  → TẤN CÔNG!")
	current_target = body
	current_state = State.ATTACKING
	attack_timer = attack_interval
	_show_only("attack")

func _on_attack_area_area_entered(area: Area2D) -> void:
	print("[Slime] AttackArea chạm AREA: ", area.name)
	
	if current_state != State.MOVING:
		return
	
	# HitArea là con của cây → cần lấy node cha (cây gốc)
	var plant = area.get_parent()
	
	# Nếu HitArea là con trực tiếp của cây Oxy → plant = Oxygen
	if not plant.is_in_group("plants"):
		# Trường hợp dự phòng: chính area cũng có thể ở group plants
		if area.is_in_group("plants"):
			plant = area
		else:
			return
	
	print("  → TẤN CÔNG cây: ", plant.name)
	current_target = plant
	current_state = State.ATTACKING
	attack_timer = attack_interval
	_show_only("attack")

func _on_attack_area_area_exited(area: Area2D) -> void:
	if not is_instance_valid(current_target):
		return
	# Nếu HitArea rời đi và nó là con của current_target → quay lại moving
	if area.get_parent() == current_target:
		_return_to_moving()
