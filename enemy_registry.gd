class_name EnemyRegistry
extends RefCounted
## Danh sách các loại quái. Mỗi loại có một id (ký hiệu hoá học, khớp với element_data.gd).
## Level (level_data.gd) chỉ cần gọi theo id, ví dụ {"Hg": 10, "Pb": 3}.
##
## Các trường của một loại quái:
##   scene            Scene quái (mặc định DEFAULT_SCENE). Có ảnh riêng thì đổi đường dẫn ở đây.
##   max_hp, speed, damage, attack_interval   Ghi đè chỉ số trong enemy.gd
##   tint             (tuỳ chọn) Phủ màu lên quái, dùng tạm khi chưa có ảnh riêng
##   visual_scale     (tuỳ chọn) Phóng to / thu nhỏ hình, không đổi vùng va chạm
##   rows             (tuỳ chọn) Chỉ xuất hiện ở các hàng này, ví dụ [0, 4]
##   threat           (tuỳ chọn) Độ nguy hiểm để sắp xếp: quái yếu ra trước, mạnh ra sau.
##                    Bỏ trống = tự tính từ máu và sát thương.

# Scene quái chung. Tạo bằng cách: chuột phải node Enemy > Save Branch as Scene > res://Enemy.tscn
const DEFAULT_SCENE := "res://Enemy.tscn"

const ENEMIES := {
	"Hg": {"max_hp": 100, "speed": 60.0, "damage": 10, "attack_interval": 1.0},
	"Cd": {"max_hp": 80,  "speed": 55.0, "damage": 6,  "attack_interval": 0.8,
		"tint": Color(1.0, 0.85, 0.5)},
	"Ra": {"max_hp": 120, "speed": 45.0, "damage": 8,  "attack_interval": 1.0,
		"tint": Color(0.6, 1.0, 0.6)},
	"Pb": {"max_hp": 300, "speed": 30.0, "damage": 15, "attack_interval": 1.5,
		"tint": Color(0.6, 0.65, 0.85), "visual_scale": 1.2},
	"U":  {"max_hp": 400, "speed": 25.0, "damage": 20, "attack_interval": 1.5,
		"tint": Color(0.55, 0.9, 0.35), "visual_scale": 1.3},
	"Pu": {"max_hp": 1500, "speed": 20.0, "damage": 40, "attack_interval": 2.0,
		"tint": Color(1.0, 0.45, 0.6), "visual_scale": 1.7},
}


static func exists(id: String) -> bool:
	return ENEMIES.has(id)


static func get_def(id: String) -> Dictionary:
	return ENEMIES.get(id, {})


static func scene_path(id: String) -> String:
	return str(get_def(id).get("scene", DEFAULT_SCENE))


static func threat(id: String) -> float:
	var d := get_def(id)
	if d.has("threat"):
		return float(d["threat"])
	return float(d.get("max_hp", 100)) / 100.0 + float(d.get("damage", 10)) / 10.0


static func allowed_rows(id: String) -> Array:
	return get_def(id).get("rows", [])
