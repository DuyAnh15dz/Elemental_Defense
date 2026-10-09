class_name ElementData
extends RefCounted
## Dữ liệu bách khoa: bảng tuần hoàn + thông tin cây / quái.
## Muốn thêm cây hoặc quái mới: thêm một mục vào ENTRIES (key = ký hiệu hoá học).
##
## Các trường của một mục:
##   role         "plant" hoặc "enemy"
##   status       "ready" (đã có trong game) | "partial" (có chỉ số, nội tại chưa làm) | "planned" (đang thiết kế)
##   class        Phân loại ngắn, hiện dưới tên
##   mass         Khối lượng nguyên tử (chuỗi)
##   icon         Đường dẫn ảnh (có thể bỏ trống -> hiện ký hiệu hoá học)
##   scene        (cây) Scene để trồng
##   cost, cooldown   (cây) giá năng lượng, thời gian hồi (giây)
##   stats        Danh sách [tên chỉ số, giá trị]
##   passive_name, passive   Nội tại
##   reactions    (cây) Các phản ứng ghép nguyên tố
##   properties   Tính chất hoá học thực tế
##   intro        Giới thiệu
##   counter      (quái) Cách khắc chế

const SYMBOLS: Array[String] = ["H", "He", "Li", "Be", "B", "C", "N", "O", "F", "Ne", "Na", "Mg", "Al", "Si", "P", "S", "Cl", "Ar", "K", "Ca", "Sc", "Ti", "V", "Cr", "Mn", "Fe", "Co", "Ni", "Cu", "Zn", "Ga", "Ge", "As", "Se", "Br", "Kr", "Rb", "Sr", "Y", "Zr", "Nb", "Mo", "Tc", "Ru", "Rh", "Pd", "Ag", "Cd", "In", "Sn", "Sb", "Te", "I", "Xe", "Cs", "Ba", "La", "Ce", "Pr", "Nd", "Pm", "Sm", "Eu", "Gd", "Tb", "Dy", "Ho", "Er", "Tm", "Yb", "Lu", "Hf", "Ta", "W", "Re", "Os", "Ir", "Pt", "Au", "Hg", "Tl", "Pb", "Bi", "Po", "At", "Rn", "Fr", "Ra", "Ac", "Th", "Pa", "U", "Np", "Pu", "Am", "Cm", "Bk", "Cf", "Es", "Fm", "Md", "No", "Lr", "Rf", "Db", "Sg", "Bh", "Hs", "Mt", "Ds", "Rg", "Cn", "Nh", "Fl", "Mc", "Lv", "Ts", "Og"]
const NAMES: Array[String] = ["Hiđro", "Heli", "Liti", "Beri", "Bo", "Cacbon", "Nitơ", "Oxi", "Flo", "Neon", "Natri", "Magie", "Nhôm", "Silic", "Photpho", "Lưu huỳnh", "Clo", "Argon", "Kali", "Canxi", "Scandi", "Titan", "Vanadi", "Crom", "Mangan", "Sắt", "Coban", "Niken", "Đồng", "Kẽm", "Gali", "Gecmani", "Asen", "Selen", "Brom", "Krypton", "Rubidi", "Stronti", "Ytri", "Zirconi", "Niobi", "Molipden", "Tecneti", "Rutheni", "Rodi", "Paladi", "Bạc", "Cadmi", "Indi", "Thiếc", "Antimon", "Telu", "Iot", "Xenon", "Xesi", "Bari", "Lantan", "Xeri", "Praseodim", "Neodim", "Prometi", "Samari", "Europi", "Gadolini", "Tecbi", "Dysprosi", "Honmi", "Erbi", "Tuli", "Ytecbi", "Luteti", "Hafni", "Tantan", "Vonfram", "Reni", "Osmi", "Iridi", "Platin", "Vàng", "Thủy ngân", "Tali", "Chì", "Bitmut", "Poloni", "Atatin", "Radon", "Franxi", "Radi", "Actini", "Thori", "Protactini", "Urani", "Neptuni", "Plutoni", "Americi", "Curi", "Berkeli", "Californi", "Einsteini", "Fermi", "Mendelevi", "Nobeli", "Lawrenxi", "Rutherfordi", "Dubni", "Seaborgi", "Bohri", "Hassi", "Meitneri", "Darmstadti", "Roentgeni", "Copernixi", "Nihoni", "Flerovi", "Moscovi", "Livermori", "Tennessin", "Oganesson"]

# Thứ tự cây trên thanh chọn cây
const PLANT_ORDER: Array[String] = ["H", "O", "C", "Na"]

const NONMETAL: Array[String] = ["H", "C", "N", "O", "P", "S", "Se"]
const NOBLE: Array[String] = ["He", "Ne", "Ar", "Kr", "Xe", "Rn", "Og"]
const HALOGEN: Array[String] = ["F", "Cl", "Br", "I", "At", "Ts"]
const ALKALI: Array[String] = ["Li", "Na", "K", "Rb", "Cs", "Fr"]
const ALKALINE: Array[String] = ["Be", "Mg", "Ca", "Sr", "Ba", "Ra"]
const METALLOID: Array[String] = ["B", "Si", "Ge", "As", "Sb", "Te"]
const POST_TRANSITION: Array[String] = ["Al", "Ga", "In", "Sn", "Tl", "Pb", "Bi", "Po", "Nh", "Fl", "Mc", "Lv"]

const ENTRIES := {
	# ═══════════════════ CÂY ═══════════════════
	"H": {
		"role": "plant", "status": "ready", "class": "Hỗ trợ · Nguồn năng lượng",
		"mass": "1,008",
		"icon": "res://elemental/hydro.png", "scene": "res://Hydro.tscn",
		"cost": 25, "cooldown": 3.0,
		"stats": [["Máu", "40"], ["Chu kỳ tạo orb", "7 giây"], ["Năng lượng mỗi orb", "+25"]],
		"passive_name": "Nhiên liệu của các vì sao",
		"passive": "Cứ 7 giây tạo ra một orb năng lượng +5 phía trên cây. Bấm vào orb để thu thập trước khi nó biến mất.",
		"reactions": ["H + H → H₂ (cây phân tử, dự kiến)", "H₂ + O → H₂O (cây nước, dự kiến)", "C + 4H → CH₄ (khí metan, dự kiến)"],
		"properties": [
			"Nguyên tố nhẹ nhất, số hiệu nguyên tử 1",
			"Ở điều kiện thường là khí H₂ không màu, không mùi",
			"Cháy trong oxi tạo nước và toả nhiều nhiệt: 2H₂ + O₂ → 2H₂O",
			"Hoá trị I; hỗn hợp H₂ và không khí rất dễ nổ",
		],
		"intro": "Hiđro là nguyên tố phổ biến nhất vũ trụ và là nhiên liệu của các ngôi sao, nơi hạt nhân hiđro hợp nhất thành heli và giải phóng năng lượng khổng lồ. Trên Trái Đất, hiđro có mặt trong nước và trong hầu hết hợp chất hữu cơ.",
	},
	"O": {
		"role": "plant", "status": "ready", "class": "Tấn công · Tầm xa",
		"mass": "15,999",
		"icon": "res://elemental/Oxygen.png", "scene": "res://Oxy.tscn",
		"cost": 50, "cooldown": 5.0,
		"stats": [["Máu", "50"], ["Sát thương mỗi viên", "10"], ["Tốc độ bắn", "1,5 giây / viên"], ["Tầm bắn", "800 px (cùng hàng)"]],
		"passive_name": "Chất oxi hoá",
		"passive": "Tự động bắn thẳng theo hàng khi có quái trong tầm. Là nguyên liệu của nhiều phản ứng ghép: nước, khí CO, CO₂...",
		"reactions": ["H₂ + O → H₂O (dự kiến)", "C + O → CO, C + 2O → CO₂ (dự kiến)"],
		"properties": [
			"Chiếm khoảng 21% thể tích không khí",
			"Duy trì sự cháy và sự hô hấp của sinh vật",
			"Chất oxi hoá mạnh, tạo oxit với hầu hết các nguyên tố",
			"Hoá trị II; tồn tại ở dạng O₂ và ozon O₃",
		],
		"intro": "Oxi là nguyên tố phổ biến nhất trong vỏ Trái Đất và là thành phần không thể thiếu của hô hấp. Nhờ khả năng oxi hoá mạnh, oxi tham gia vào phản ứng cháy, gỉ sét và vô số phản ứng khác.",
	},
	"C": {
		"role": "plant", "status": "ready", "class": "Phòng thủ · Tường",
		"mass": "12,011",
		"icon": "res://elemental/coal.png", "scene": "res://Coal.tscn",
		"cost": 50, "cooldown": 8.0,
		"stats": [["Máu (than)", "150"], ["Ngưỡng áp suất", "100 sát thương"], ["Máu (kim cương)", "300, hồi 50%"], ["Phản sát thương", "5 (kim cương)"]],
		"passive_name": "Than → Kim cương",
		"passive": "Bị đánh đủ 100 sát thương, cây bị nén thành kim cương: máu tối đa tăng lên 300, hồi 50% máu và phản 5 sát thương lên kẻ đang tấn công.",
		"reactions": ["C + 4H → CH₄ (bom khí metan, dự kiến)", "C + O → CO (khí độc, dự kiến)", "C + 2O → CO₂ (đá khô làm chậm quái, dự kiến)", "Than hoạt tính hấp phụ kim loại nặng (dự kiến)"],
		"properties": [
			"Hoá trị IV, tạo 4 liên kết cộng hoá trị bền",
			"Nhiều dạng thù hình: kim cương, than chì, fullerene",
			"Kim cương cứng nhất trong các chất tự nhiên; than chì mềm và dẫn điện",
			"Cháy trong oxi tạo CO₂, thiếu oxi tạo CO độc",
			"Than hoạt tính hấp phụ được nhiều chất độc",
		],
		"intro": "Cacbon là nền tảng của sự sống: khung xương của mọi hợp chất hữu cơ. Cùng một nguyên tố nhưng sắp xếp nguyên tử khác nhau cho ra than đen mềm hoặc kim cương cứng nhất, đó là hiện tượng thù hình.",
	},
	"Na": {
		"role": "plant", "status": "ready", "class": "Mìn · Sát thương diện rộng",
		"mass": "22,990",
		"icon": "res://elemental/Sodium.png", "scene": "res://Sodium.tscn",
		"cost": 75, "cooldown": 10.0,
		"stats": [["Máu", "30"], ["Thời gian ngâm dầu", "5 giây"], ["Bán kính kích hoạt", "110 px"], ["Bán kính nổ", "130 px"], ["Sát thương nổ", "150"]],
		"passive_name": "Phản ứng mãnh liệt",
		"passive": "Sau khi ngâm dầu xong, cây nổ khi quái đến gần hoặc bị đánh, gây sát thương diện rộng kèm ngọn lửa vàng rồi biến mất. Nếu bị ăn khi chưa sẵn sàng thì không nổ.",
		"reactions": ["Na + H₂O → NaOH + H₂ (nổ mạnh hơn, dự kiến)", "Na + Cl → NaCl (muối làm chậm quái, dự kiến)"],
		"properties": [
			"Kim loại kiềm mềm, cắt được bằng dao, nhẹ hơn nước",
			"Rất hoạt động nên phải bảo quản ngâm trong dầu hoả",
			"Tác dụng mãnh liệt với nước: 2Na + 2H₂O → 2NaOH + H₂",
			"Cháy với ngọn lửa màu vàng đặc trưng",
			"Hoá trị I, tạo ion Na⁺ trong muối ăn NaCl",
		],
		"intro": "Natri là kim loại kiềm có mặt trong muối ăn và nước biển. Dạng nguyên chất của nó phản ứng dữ dội với nước và hơi ẩm, vì vậy trong phòng thí nghiệm luôn được giữ trong dầu hoả.",
	},

	# ═══════════════════ QUÁI (kim loại nặng & phóng xạ) ═══════════════════
	"Hg": {
		"role": "enemy", "status": "partial", "class": "Kim loại nặng · Dạng lỏng",
		"mass": "200,59",
		"icon": "res://elemental/slime_mobi_1.png",
		"stats": [["Máu", "100"], ["Tốc độ", "60"], ["Sát thương", "10 mỗi lần"], ["Nhịp đánh", "1 giây"]],
		"passive_name": "Vũng thủy ngân (dự kiến)",
		"passive": "Khi chết để lại một vũng độc, ô đó không thể trồng cây trong 5 giây.",
		"properties": [
			"Kim loại duy nhất ở thể lỏng ở nhiệt độ phòng",
			"Rất nặng: khối lượng riêng khoảng 13,5 g/cm³",
			"Hơi thủy ngân độc, tích tụ trong chuỗi thức ăn và tổn hại hệ thần kinh",
			"Tạo hỗn hống với nhiều kim loại như Na, Ag, Au",
		],
		"intro": "Thủy ngân từng được dùng trong nhiệt kế và phong vũ biểu. Vì hơi và hợp chất của nó rất độc, ngày nay việc sử dụng bị hạn chế nghiêm ngặt. Trong game, đây là loại quái cơ bản, hiện dùng hình dạng slime.",
		"counter": "Natri (nổ diện rộng), lưu huỳnh khi có trong game (Hg + S → HgS ít độc).",
	},
	"Pb": {
		"role": "enemy", "status": "planned", "class": "Kim loại nặng · Tank",
		"mass": "207,2",
		"stats": [["Máu", "300"], ["Tốc độ", "30"], ["Sát thương", "15 mỗi lần"], ["Nhịp đánh", "1,5 giây"]],
		"passive_name": "Giáp chì",
		"passive": "Giảm 50% sát thương từ đạn, nhưng chịu trọn sát thương từ vụ nổ.",
		"properties": [
			"Kim loại nặng, mềm, khối lượng riêng khoảng 11,3 g/cm³",
			"Chặn được tia X và tia gamma nên dùng làm áo chì, tấm chắn",
			"Ion chì gây ngộ độc thần kinh, tích tụ trong xương",
			"Hoá trị II và IV",
		],
		"intro": "Chì được con người dùng từ thời cổ đại làm ống nước và sơn. Về sau người ta phát hiện chì gây hại cho thần kinh, đặc biệt ở trẻ em, nên đã loại bỏ khỏi xăng, sơn và đường ống.",
		"counter": "Natri (sát thương nổ), than hoạt tính hấp phụ ion chì.",
	},
	"Cd": {
		"role": "enemy", "status": "planned", "class": "Kim loại nặng · Gây độc",
		"mass": "112,41",
		"stats": [["Máu", "80"], ["Tốc độ", "55"], ["Sát thương", "6 mỗi lần"], ["Nhịp đánh", "0,8 giây"]],
		"passive_name": "Độc tích luỹ",
		"passive": "Mỗi đòn đánh gây nhiễm độc 3 sát thương/giây trong 5 giây, cộng dồn nhiều lần.",
		"properties": [
			"Kim loại mềm màu trắng bạc, hoá trị II",
			"Dùng trong pin Ni–Cd và mạ chống gỉ",
			"Độc, tích tụ ở thận và xương, gây bệnh itai-itai",
			"Thường lẫn trong quặng kẽm",
		],
		"intro": "Cadmi là sản phẩm phụ của việc luyện kẽm. Khi thải ra đất và nước, nó đi vào cây trồng như lúa gạo rồi tích tụ trong cơ thể người nên là chất ô nhiễm đáng lo ngại.",
		"counter": "Cacbon (than hoạt tính hấp phụ), hạ nhanh bằng Oxy trước khi chúng đến gần.",
	},
	"Ra": {
		"role": "enemy", "status": "planned", "class": "Phóng xạ · Phát bức xạ",
		"mass": "226",
		"stats": [["Máu", "120"], ["Tốc độ", "45"], ["Sát thương", "8 mỗi lần"], ["Nhịp đánh", "1 giây"]],
		"passive_name": "Bức xạ",
		"passive": "Mỗi giây gây 2 sát thương cho mọi cây trong bán kính 1 ô quanh nó, kể cả khi chưa đánh.",
		"properties": [
			"Kim loại kiềm thổ phóng xạ, phát sáng nhẹ trong bóng tối",
			"Ra-226 có chu kỳ bán rã khoảng 1600 năm",
			"Tính chất hoá học giống bari",
			"Phân rã thành khí radon cũng phóng xạ",
		],
		"intro": "Radi được Marie và Pierre Curie tách ra năm 1898. Từng được dùng làm sơn dạ quang cho mặt đồng hồ, nhưng người tiếp xúc nhiều bị tổn thương nghiêm trọng, và từ đó con người hiểu rõ hơn mối nguy của bức xạ.",
		"counter": "Hạ gục từ xa bằng Oxy trước khi quái vào bán kính bức xạ.",
	},
	"U": {
		"role": "enemy", "status": "planned", "class": "Phóng xạ · Tank nặng",
		"mass": "238,03",
		"stats": [["Máu", "400"], ["Tốc độ", "25"], ["Sát thương", "20 mỗi lần"], ["Nhịp đánh", "1,5 giây"]],
		"passive_name": "Phân rã alpha",
		"passive": "Cứ 4 giây bắn một hạt alpha gây 8 sát thương lên cây gần nhất trong 2 ô. Khi chết để lại bãi bức xạ 6 giây.",
		"properties": [
			"Kim loại rất nặng, khối lượng riêng khoảng 19,1 g/cm³",
			"U-238 có chu kỳ bán rã khoảng 4,5 tỉ năm",
			"U-235 phân hạch được, dùng làm nhiên liệu lò phản ứng hạt nhân",
			"Vừa độc hoá học vừa phóng xạ",
		],
		"intro": "Urani là nguyên tố nặng nhất tồn tại với lượng đáng kể trong tự nhiên. Từ khi phát hiện hiện tượng phân hạch, nó trở thành nhiên liệu của các nhà máy điện hạt nhân.",
		"counter": "Natri (nổ sát thương cao), sát thương dồn nhanh từ nhiều cây Oxy cùng hàng.",
	},
	"Pu": {
		"role": "enemy", "status": "planned", "class": "Phóng xạ · Trùm",
		"mass": "244",
		"stats": [["Máu", "1500"], ["Tốc độ", "20"], ["Sát thương", "40 mỗi lần"], ["Nhịp đánh", "2 giây"]],
		"passive_name": "Khối tới hạn",
		"passive": "Quái phóng xạ trong 2 ô quanh nó tăng 25% sát thương. Khi chết nổ gây 100 sát thương lên mọi cây trong 2 ô.",
		"properties": [
			"Nguyên tố nhân tạo là chủ yếu, chỉ có vết trong tự nhiên",
			"Pu-239 phân hạch được, dùng trong lò phản ứng hạt nhân",
			"Cực độc: hạt bụi rất nhỏ cũng nguy hiểm khi hít phải",
			"Phát nhiệt khi phân rã",
		],
		"intro": "Plutoni được tổng hợp lần đầu năm 1940 và là một trong những nguyên tố nặng quan trọng nhất của công nghệ hạt nhân. Trong game, đây là quái trùm cuối của loại phóng xạ.",
		"counter": "Tập trung hạ các quái phóng xạ xung quanh trước, rồi dùng Cacbon kim cương làm tường chặn.",
	},
}

const CATEGORY_NAMES := {
	"alkali": "Kim loại kiềm", "alkaline": "Kim loại kiềm thổ", "transition": "Kim loại chuyển tiếp",
	"post": "Kim loại yếu", "metalloid": "Á kim", "nonmetal": "Phi kim",
	"halogen": "Halogen", "noble": "Khí hiếm", "lanthanide": "Lantanit", "actinide": "Actinit",
}


static func category(sym: String, z: int) -> String:
	if sym in NONMETAL: return "nonmetal"
	if sym in NOBLE: return "noble"
	if sym in HALOGEN: return "halogen"
	if sym in ALKALI: return "alkali"
	if sym in ALKALINE: return "alkaline"
	if sym in METALLOID: return "metalloid"
	if sym in POST_TRANSITION: return "post"
	if z >= 57 and z <= 71: return "lanthanide"
	if z >= 89 and z <= 103: return "actinide"
	return "transition"


# Tạo danh sách cây cho thanh chọn cây (planting_grid.gd dùng)
static func get_plant_defs() -> Array[Dictionary]:
	var defs: Array[Dictionary] = []
	for sym in PLANT_ORDER:
		var e: Dictionary = ENTRIES[sym]
		defs.append({
			"symbol": sym,
			"name": NAMES[SYMBOLS.find(sym)],
			"scene": e["scene"],
			"icon": e["icon"],
			"cost": e["cost"],
			"cooldown": e["cooldown"],
		})
	return defs
