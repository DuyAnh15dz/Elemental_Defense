class_name CompoundData
extends RefCounted
## Bảng công thức hợp chất. Muốn thêm hợp chất mới: thêm một mục vào RECIPES.
##
## Các trường:
##   formula, name, equation   Hiển thị
##   inputs         Nguyên liệu {id: số lượng}. id là ký hiệu nguyên tố (H, O, C, Na) hoặc id hợp chất khác (H2).
##   cost           Giá hợp chất (năng lượng), chỉ trừ khi ghép thành công
##   conditions     Đáp án trắc nghiệm {catalyst, temperature, pressure}: id trong CATALYSTS / TEMPERATURES / PRESSURES
##   condition_note Ghi chú điều kiện hiện trong sách (tuỳ chọn)
##   stable         false = hợp chất không bền, tự phân hủy sau `lifetime` giây
##   hp, color      Chỉ số và màu hiển thị
##   behavior       Cơ chế trong game: type = energy | heal | dot | slow | bomb (xem compound_plant.gd)
##   stats, mechanic, properties, intro   Nội dung cho bách khoa
##
## Công thức được so khớp CHÍNH XÁC theo loại và số lượng nguyên liệu.

# ═══════════ LỰA CHỌN TRẮC NGHIỆM ═══════════
const PENALTY_RATIO := 0.5          # Chọn sai điều kiện: mất bấy nhiêu phần giá hợp chất
const SHOW_HINT_COUNT := true       # Báo "đúng k/3 điều kiện" khi chọn sai

const CATALYSTS := [
	{"id": "none", "name": "Không dùng xúc tác"},
	{"id": "Ni", "name": "Niken (Ni)"},
	{"id": "Pd", "name": "Paladi (Pd)"},
	{"id": "Fe", "name": "Sắt (Fe)"},
	{"id": "Pt", "name": "Platin (Pt)"},
	{"id": "V2O5", "name": "Vanadi(V) oxit (V₂O₅)"},
]
const TEMPERATURES := [
	{"id": "room", "name": "Nhiệt độ thường (khoảng 25 °C)"},
	{"id": "spark", "name": "Tia lửa điện / phóng điện"},
	{"id": "hot", "name": "Nhiệt độ cao (khoảng 500 °C)"},
	{"id": "cold", "name": "Làm lạnh (dưới 0 °C)"},
]
const PRESSURES := [
	{"id": "normal", "name": "Áp suất thường (1 atm)"},
	{"id": "high", "name": "Áp suất cao (từ 100 atm)"},
	{"id": "low", "name": "Áp suất thấp (gần chân không)"},
]

const RECIPES := {
	# ═══════════ BỀN ═══════════
	"H2": {
		"formula": "H₂", "name": "Hiđro phân tử", "equation": "H + H → H₂",
		"inputs": {"H": 2},
		"cost": 20,
		"conditions": {"catalyst": "none", "temperature": "room", "pressure": "normal"},
		"stable": true, "hp": 80, "color": Color(0.45, 0.8, 1.0),
		"behavior": {"type": "energy", "interval": 7.0, "amount": 15},
		"stats": [["Máu", "80"], ["Năng lượng mỗi orb", "+15"], ["Chu kỳ", "7 giây"]],
		"mechanic": "Nhà máy năng lượng: cứ 7 giây tạo orb +15 (hai cây Hydro riêng lẻ chỉ cho +10).",
		"properties": [
			"Phân tử gồm hai nguyên tử H liên kết cộng hoá trị",
			"Khí nhẹ nhất, không màu, không mùi",
			"Cháy trong oxi toả nhiều nhiệt; hỗn hợp với không khí dễ nổ",
			"Dùng làm nhiên liệu và sản xuất amoniac",
		],
		"intro": "Các nguyên tử hiđro riêng lẻ rất không bền nên luôn kết đôi thành phân tử H₂, nhả bớt năng lượng khi liên kết.",
	},
	"H2O": {
		"formula": "H₂O", "name": "Nước", "equation": "2H₂ + O₂ → 2H₂O",
		"inputs": {"H2": 1, "O": 1},
		"cost": 40,
		"conditions": {"catalyst": "none", "temperature": "spark", "pressure": "normal"},
		"condition_note": "Cần tia lửa hoặc nhiệt để khơi mào phản ứng.",
		"stable": true, "hp": 120, "color": Color(0.3, 0.6, 1.0),
		"behavior": {"type": "heal", "interval": 1.0, "amount": 4, "radius": 150.0},
		"stats": [["Máu", "120"], ["Hồi máu", "4 máu/giây cho cây kề"], ["Bán kính", "150 px"]],
		"mechanic": "Tưới mát: mỗi giây hồi 4 máu cho mọi cây xung quanh.",
		"properties": [
			"Dung môi phổ biến nhất, cần thiết cho sự sống",
			"Sôi ở 100 °C, đóng băng ở 0 °C",
			"Phân tử phân cực, tạo liên kết hiđro",
			"Phản ứng mãnh liệt với kim loại kiềm như natri",
		],
		"intro": "Hiđro cháy trong oxi tạo ra nước và toả nhiều nhiệt. Phản ứng này không tự xảy ra ở nhiệt độ thường mà cần tia lửa hoặc nhiệt để khơi mào.",
	},
	"CO": {
		"formula": "CO", "name": "Cacbon monoxit", "equation": "2C + O₂ → 2CO",
		"inputs": {"C": 1, "O": 1},
		"cost": 30,
		"conditions": {"catalyst": "none", "temperature": "hot", "pressure": "normal"},
		"condition_note": "Cacbon cháy ở nhiệt độ cao trong điều kiện thiếu oxi.",
		"stable": true, "hp": 100, "color": Color(0.6, 0.6, 0.65),
		"behavior": {"type": "dot", "interval": 1.0, "amount": 5, "radius": 130.0},
		"stats": [["Máu", "100"], ["Sát thương", "5 mỗi giây"], ["Bán kính", "130 px"]],
		"mechanic": "Đám khí độc: gây 5 sát thương mỗi giây cho mọi quái trong vùng.",
		"properties": [
			"Khí không màu, không mùi, rất độc",
			"Cháy với ngọn lửa xanh tạo CO₂",
			"Chất khử mạnh, dùng trong luyện kim",
			"Sinh ra khi cacbon cháy thiếu oxi",
		],
		"intro": "Khi cacbon cháy mà thiếu oxi, sản phẩm không phải CO₂ mà là CO, một chất khí độc không thể nhận ra bằng mùi.",
	},
	"CO2": {
		"formula": "CO₂", "name": "Cacbon đioxit", "equation": "C + O₂ → CO₂",
		"inputs": {"C": 1, "O": 2},
		"cost": 45,
		"conditions": {"catalyst": "none", "temperature": "hot", "pressure": "normal"},
		"condition_note": "Đốt cacbon trong oxi dư.",
		"stable": true, "hp": 100, "color": Color(0.8, 0.9, 0.95),
		"behavior": {"type": "slow", "factor": 0.5, "radius": 160.0},
		"stats": [["Máu", "100"], ["Làm chậm", "50% tốc độ"], ["Bán kính", "160 px"]],
		"mechanic": "Đá khô: quái trong vùng bị làm chậm một nửa tốc độ.",
		"properties": [
			"Khí nặng hơn không khí, không duy trì sự cháy",
			"Dạng rắn gọi là đá khô, thăng hoa ở −78,5 °C",
			"Dùng trong bình chữa cháy",
			"Là khí nhà kính",
		],
		"intro": "CO₂ là sản phẩm của sự cháy hoàn toàn và của hô hấp. Vì không cháy và nặng hơn không khí, nó phủ lên lửa và dập tắt lửa.",
	},
	"CH4": {
		"formula": "CH₄", "name": "Metan", "equation": "C + 2H₂ → CH₄",
		"inputs": {"C": 1, "H2": 2},
		"cost": 60,
		"conditions": {"catalyst": "Ni", "temperature": "hot", "pressure": "high"},
		"stable": true, "hp": 40, "color": Color(1.0, 0.55, 0.2),
		"behavior": {"type": "bomb", "trigger": 120.0, "radius": 170.0, "damage": 220},
		"stats": [["Máu", "40"], ["Sát thương nổ", "220"], ["Kích hoạt", "120 px"], ["Bán kính nổ", "170 px"]],
		"mechanic": "Bom khí: nổ khi quái đến gần hoặc khi bị đánh, gây sát thương rất lớn diện rộng.",
		"properties": [
			"Thành phần chính của khí thiên nhiên",
			"Nhẹ hơn không khí, rất dễ cháy: CH₄ + 2O₂ → CO₂ + 2H₂O",
			"Hỗn hợp với không khí có thể gây nổ",
			"Là khí nhà kính mạnh",
		],
		"intro": "Metan là hiđrocacbon đơn giản nhất: một nguyên tử cacbon liên kết với bốn nguyên tử hiđro, tận dụng đủ hoá trị IV của cacbon.",
	},
	"NaOH": {
		"formula": "NaOH", "name": "Natri hiđroxit", "equation": "2Na + 2H₂O → 2NaOH + H₂",
		"inputs": {"Na": 1, "H2O": 1},
		"cost": 50,
		"conditions": {"catalyst": "none", "temperature": "room", "pressure": "normal"},
		"condition_note": "Phản ứng toả nhiệt mạnh và tự xảy ra ở nhiệt độ thường.",
		"stable": true, "hp": 90, "color": Color(0.85, 0.4, 0.95),
		"behavior": {"type": "dot", "interval": 1.0, "amount": 8, "radius": 120.0},
		"stats": [["Máu", "90"], ["Sát thương", "8 mỗi giây"], ["Bán kính", "120 px"]],
		"mechanic": "Kiềm ăn mòn: gây 8 sát thương mỗi giây cho quái trong vùng.",
		"properties": [
			"Bazơ mạnh, còn gọi là xút ăn da, tan nhiều trong nước",
			"Ăn mòn da, giấy và nhiều kim loại",
			"Hút ẩm mạnh",
			"Dùng sản xuất xà phòng, giấy",
		],
		"intro": "Khi natri gặp nước, phản ứng toả rất nhiều nhiệt và tạo ra dung dịch kiềm mạnh cùng khí hiđro.",
	},

	# ═══════════ KHÔNG BỀN (tự phân hủy) ═══════════
	"O3": {
		"formula": "O₃", "name": "Ozon", "equation": "3O₂ → 2O₃",
		"inputs": {"O": 3},
		"cost": 25,
		"conditions": {"catalyst": "none", "temperature": "spark", "pressure": "normal"},
		"stable": false, "lifetime": 8.0, "hp": 30, "color": Color(0.55, 0.85, 1.0),
		"behavior": {"type": "dot", "interval": 1.0, "amount": 10, "radius": 110.0},
		"stats": [["Máu", "30"], ["Sát thương", "10 mỗi giây"], ["Tồn tại", "8 giây"]],
		"mechanic": "Oxi hoá mạnh nhưng không bền: tự phân hủy thành O₂ sau 8 giây.",
		"properties": [
			"Dạng thù hình của oxi, có mùi hắc đặc trưng",
			"Chất oxi hoá rất mạnh",
			"Không bền, tự phân hủy thành O₂",
			"Tầng ozon hấp thụ tia cực tím từ Mặt Trời",
		],
		"intro": "Ba nguyên tử oxi tạo thành ozon, nhưng cấu trúc này kém bền hơn O₂ nên luôn có xu hướng trở lại dạng quen thuộc.",
	},
	"H2O2": {
		"formula": "H₂O₂", "name": "Hiđro peroxit", "equation": "H₂ + O₂ → H₂O₂",
		"inputs": {"H2": 1, "O": 2},
		"cost": 30,
		"conditions": {"catalyst": "Pd", "temperature": "room", "pressure": "normal"},
		"stable": false, "lifetime": 10.0, "hp": 40, "color": Color(0.7, 1.0, 0.85),
		"behavior": {"type": "dot", "interval": 1.0, "amount": 6, "radius": 110.0},
		"stats": [["Máu", "40"], ["Sát thương", "6 mỗi giây"], ["Tồn tại", "10 giây"]],
		"mechanic": "Sủi bọt oxi: gây sát thương nhẹ rồi tự phân hủy thành nước và oxi sau 10 giây.",
		"properties": [
			"Chất lỏng không màu, dùng làm chất tẩy và sát khuẩn",
			"Không bền: 2H₂O₂ → 2H₂O + O₂",
			"Vừa là chất oxi hoá vừa là chất khử",
			"Phân hủy nhanh khi có xúc tác hoặc ánh sáng",
		],
		"intro": "Chỉ hơn nước một nguyên tử oxi nhưng hiđro peroxit rất kém bền: nó tự phân hủy, giải phóng oxi dưới dạng bọt khí.",
	},
}


# Tìm hợp chất khớp với danh sách nguyên liệu. Trả về {"id": ...} hoặc {} nếu không có.
static func evaluate(ids: Array) -> Dictionary:
	var counts := {}
	for id in ids:
		counts[id] = int(counts.get(id, 0)) + 1
	for cid in RECIPES:
		if _same(RECIPES[cid]["inputs"], counts):
			return {"id": cid}
	return {}


static func _same(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for k in a:
		if not b.has(k) or int(b[k]) != int(a[k]):
			return false
	return true


# Tên hiển thị của một id (nguyên tố giữ nguyên, hợp chất dùng công thức)
static func display_id(id: String) -> String:
	if RECIPES.has(id):
		return RECIPES[id]["formula"]
	return id


static func option_name(options: Array, id: String) -> String:
	for o in options:
		if o["id"] == id:
			return o["name"]
	return id


static func condition_text(id: String) -> String:
	var c: Dictionary = RECIPES[id]["conditions"]
	var t := "Xúc tác: %s · Nhiệt độ: %s · Áp suất: %s" % [
		option_name(CATALYSTS, str(c["catalyst"])),
		option_name(TEMPERATURES, str(c["temperature"])),
		option_name(PRESSURES, str(c["pressure"])),
	]
	if RECIPES[id].has("condition_note"):
		t += "\n" + str(RECIPES[id]["condition_note"])
	return t


# Số điều kiện chọn đúng (0..3). chosen = {catalyst, temperature, pressure}
static func count_correct(id: String, chosen: Dictionary) -> int:
	var want: Dictionary = RECIPES[id]["conditions"]
	var n := 0
	for k in ["catalyst", "temperature", "pressure"]:
		if str(want[k]) == str(chosen.get(k, "")):
			n += 1
	return n


static func penalty(id: String) -> int:
	return int(ceil(float(RECIPES[id]["cost"]) * PENALTY_RATIO))
