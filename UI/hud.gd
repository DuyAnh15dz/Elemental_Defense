extends CanvasLayer

@onready var energy_label: Label = $EnergyPanel/HBoxContainer/EnergyLabel

func _ready() -> void:
	GameState.chemical_energy_changed.connect(_on_energy_changed)
	_update_display(GameState.chemical_energy)

func _on_energy_changed(new_value: int) -> void:
	_update_display(new_value)

func _update_display(value: int) -> void:
	energy_label.text = str(value)
	
	# Hiệu ứng pop
	var tween = create_tween()
	energy_label.scale = Vector2(1.3, 1.3)
	tween.tween_property(energy_label, "scale", Vector2(1.0, 1.0), 0.2)
