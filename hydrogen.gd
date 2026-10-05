extends Plant

@export var energy_orb_scene: PackedScene       # ⚠️ Kéo energy_orb.tscn vào Inspector
@export var energy_per_orb: int = 5             # Năng lượng mỗi orb
@export var tick_interval: float = 7.0          # Giây giữa 2 lần spawn

var _tick_timer: float = 0.0
var _pulse_tween: Tween

func _ready() -> void:
	if super.has_method("_ready"):
		super._ready()
	
	max_health = 40
	current_health = max_health
	_tick_timer = tick_interval
	
	if energy_orb_scene == null:
		push_warning("Hydro: energy_orb_scene chưa được gán!")


func _process(delta: float) -> void:
	if _is_dead:
		return
	if energy_orb_scene == null:
		return
	
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		_spawn_orb()


func _spawn_orb() -> void:
	var orb = energy_orb_scene.instantiate()
	orb.global_position = global_position + Vector2(0, -20)   # spawn trên đầu cây
	orb.energy_value = energy_per_orb
	get_tree().current_scene.add_child(orb)
	
	_play_pulse_effect()
	print("[Hydro] Spawn orb")


func _play_pulse_effect() -> void:
	if not sprite:
		return
	
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	
	_pulse_tween = create_tween()
	sprite.modulate = Color(1.5, 1.5, 0.5, 1)
	_pulse_tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
