extends Node

# Signal để UI cập nhật khi năng lượng thay đổi
signal chemical_energy_changed(new_value: int)

var chemical_energy: int = 0

func add_energy(amount: int) -> void:
	chemical_energy += amount
	chemical_energy_changed.emit(chemical_energy)
	print("[GameState] +", amount, " energy → total: ", chemical_energy)

func spend_energy(amount: int) -> bool:
	if chemical_energy < amount:
		return false
	chemical_energy -= amount
	chemical_energy_changed.emit(chemical_energy)
	print("[GameState] -", amount, " energy → total: ", chemical_energy)
	return true
