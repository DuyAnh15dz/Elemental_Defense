🧪 Elemental Defense — Game Context Document
Mục đích file này: Cung cấp đầy đủ bối cảnh dự án cho bất kỳ AI nào (ChatGPT, Claude, Gemini...) để hiểu game đang làm gì, kiến trúc ra sao, và có thể hỗ trợ lập trình mà không cần đọc lại toàn bộ codebase.

Cập nhật lần cuối: 2026-10-10

1. TỔNG QUAN DỰ ÁN
Thuộc tính	Giá trị
Tên game	Elemental Defense
Thể loại	Tower Defense (bảo vệ căn cứ)
Engine	Godot 4.4.1 stable
Ngôn ngữ	GDScript 100%
Chủ đề	Hoá học — nguyên tố, hợp chất, phản ứng
Cảm hứng	Plants vs Zombies (PvZ)
GitHub	https://github.com/DuyAnh15dz/Elemental_Defense
Ngôn ngữ hiển thị	Tiếng Việt
Nền tảng dev	Windows (Git Bash)
Ý tưởng cốt lõi
Người chơi trồng cây = nguyên tố hoá học (H, O, C, Na...) trên lưới 8×5 để chặn quái = kim loại nặng / phóng xạ (Hg, Pb, Cd, Ra, U, Pu...) đi từ phải sang trái. Điểm độc đáo: người chơi có thể ghép các cây kề nhau để tạo hợp chất (H₂O, CO₂, CH₄, NaOH...) thông qua một bài trắc nghiệm điều kiện phản ứng (xúc tác / nhiệt độ / áp suất). Mỗi cây và hợp chất đều mô phỏng tính chất hoá học thật của nguyên tố đó.

2. CƠ CHẾ GAMEPLAY
2.1 Trồng cây (Planting)
Lưới 8 cột × 5 hàng (TileMapLayer).

Chọn cây từ thanh chọn cây phía trên → click ô trống hoặc kéo-thả.

Mỗi cây có giá (năng lượng) và thời gian hồi (cooldown).

Cây chưa mở khoá sẽ ẩn khỏi thanh chọn.

2.2 Năng lượng (Chemical Energy)
Đơn vị tiền tệ: chemical_energy (quản lý bởi GameState.gd — autoload).

Nguồn thu: cây Hydro sinh orb năng lượng định kỳ; người chơi bấm orb để thu.

Nguồn chi: trồng cây, ghép hợp chất, phạt khi chọn sai điều kiện.

Năng lượng khởi đầu mặc định: 100.

2.3 Ghép hợp chất (Compound Crafting) — tính năng đặc trưng
Bật "Ghép cây" → game tạm dừng.

Chọn các cây kề nhau (tối đa 6 ô, kể cả chéo).

Hệ thống tra CompoundData.RECIPES xem tổ hợp khớp công thức nào.

Mở bảng trắc nghiệm 3 câu: Xúc tác / Nhiệt độ / Áp suất.

Đúng cả 3 → trừ giá, nguyên liệu biến mất, hợp chất xuất hiện.
Sai → mất một phần năng lượng (PENALTY_RATIO = 0.5), nguyên liệu giữ nguyên.

2.4 Quái (Enemies)
Đi từ mép phải sang mép trái lưới.

Gặp cây → tấn công theo attack_interval.

Vượt qua mép trái → thua màn.

Quái sinh theo cấu hình màn (level_data.gd), có đợt tấn công lớn cảnh báo trước.

2.5 Bách khoa (Almanac) — Phím A
Nhấn A hoặc nút "Bách khoa [A]" → mở, game tạm dừng.

Hiển thị bảng tuần hoàn 18 cột với màu theo nhóm nguyên tố.

Ô viền xanh = cây, viền đỏ = quái, ô mờ = chưa có trong game.

Bấm nguyên tố → xem chi tiết: tên, số hiệu, khối lượng, tính chất, chỉ số.

2.6 Sổ tay hợp chất (Compound Journal) — Phím J
Nhấn J hoặc nút "Sổ tay [J]" → mở, game tạm dừng.

Danh sách hợp chất bên trái, chi tiết bên phải.

Hợp chất chưa khám phá → hiển thị "???".

Chỉ hiển thị 1 tab duy nhất (danh sách đã khám phá) — đã bỏ ý tưởng 2 tab để giữ đơn giản.

2.7 Khám phá (Discoveries)
Lưu vào user://discoveries.cfg.

Nguyên tố mở theo màn (hiện tại mặc định: H, O, C, Na).

Hợp chất mở khi người chơi tự ghép thành công lần đầu.

Chưa mở khoá → hiện "???".

2.8 Kết thúc màn
Thắng: hết events + không còn quái → level_cleared signal.

Thua: quái vượt mép trái → level_failed signal.

Hiện tại chưa có UI popup thắng/thua — chỉ có banner hiển thị.

3. KIẾN TRÚC THƯ MỤC
text
res://
├── project.godot
├── icon.svg
├── README.md
├── .gitignore
│
├── UI/                          # Giao diện
│   ├── energy_orb.tscn          # Orb năng lượng
│   └── compound_journal.gd      # Sổ tay hợp chất (CanvasLayer)
│
├── elemental/                   # Ảnh sprite cây
│   ├── coal.png, hydrogen.png, Oxygen.png, Sodium.png, ...
│
├── enemy/                       # Sprite quái
│
├── Plant/                       # Scene cây
│   ├── Hydro.tscn
│   ├── Coal.tscn
│   ├── Oxy.tscn
│   └── Sodium.tscn
│
├── Enemy.tscn                   # Scene quái chung
│
├── almanac.gd                   # Bách khoa
├── carbon.gd                    # Cây Cacbon (than → kim cương)
├── compound_data.gd             # Bảng công thức + điều kiện trắc nghiệm
├── compound_plant.gd            # Cây hợp chất (dùng chung)
├── discoveries.gd               # Tiến trình khám phá
├── element_data.gd              # Bảng tuần hoàn + ENTRIES
├── enemy.gd                     # Quái (state machine)
├── enemy_registry.gd            # Danh sách loại quái
├── enemy_spawner.gd             # Sinh quái theo lịch màn
├── game_state.gd                # Autoload: chemical_energy
├── hydrogen.gd                  # Cây Hydro
├── level_data.gd                # Cấu hình 10 màn
├── oxy_bullet.gd                # Đạn Oxy
├── oxygen.gd                    # Cây Oxy
├── plant_base_stat.gd           # class_name Plant — base class
├── planting_grid.gd             # Lưới, chọn cây, công cụ ghép
└── sodium.gd                    # Cây Natri (mìn nổ)
4. CÁC CLASS / FILE CHÍNH
4.1 Base & Data
File	Vai trò
plant_base_stat.gd	class_name Plant — base cho mọi cây. Có max_health, current_health, take_damage(), _die(), _flash(). Tự add vào group "plants".
element_data.gd	class_name ElementData. Chứa: SYMBOLS (118 nguyên tố), NAMES, mảng phân loại (NONMETAL, ALKALI...), ENTRIES (thông tin cây/quái), CATEGORY_NAMES, hàm category(), get_plant_defs().
compound_data.gd	class_name CompoundData. Chứa RECIPES (8 công thức), CATALYSTS, TEMPERATURES, PRESSURES cho trắc nghiệm. Hàm evaluate(), count_correct(), penalty().
enemy_registry.gd	class_name EnemyRegistry. Danh sách 6 loại quái (Hg, Cd, Ra, Pb, U, Pu) với chỉ số và tint màu.
level_data.gd	class_name LevelData. LEVELS (10 màn), build_schedule() sinh lịch quái theo độ nguy hiểm + nhiễu.
discoveries.gd	class_name Discoveries. Static class lưu tiến trình vào user://discoveries.cfg.
4.2 Cây (Plants)
File	Nguyên tố	Cơ chế	Giá	Cooldown
hydrogen.gd	H	Sinh orb năng lượng +25 mỗi 7s	25	3s
oxygen.gd	O	Raycast phát hiện quái cùng hàng, bắn 10 dmg mỗi 1.5s, tầm 800px	50	5s
carbon.gd	C	Tank 150 HP. Đủ 100 sát thương → kim cương (300 HP, hồi 50%, phản 5 dmg)	50	8s
sodium.gd	Na	Mìn: ngâm dầu 5s, quái vào 80px → nổ 150 dmg bán kính 130px	75	10s
compound_plant.gd	Hợp chất	class_name CompoundPlant. Tự vẽ hình tròn + công thức. 5 behavior: energy, heal, dot, slow, bomb. Hợp chất không bền tự phân huỷ.	Theo RECIPES	—
4.3 Quái (Enemies)
ID	Máu	Tốc độ	Sát thương	Nhịp	Ghi chú
Hg	120	60	10	1.0s	Cơ bản (slime)
Cd	80	55	6	0.8s	Tint vàng nhạt
Ra	120	45	8	1.0s	Tint xanh lá
Pb	300	30	15	1.5s	Tank, tint xanh xám
U	400	25	20	1.5s	Tank nặng, tint xanh lá đậm
Pu	1500	20	40	2.0s	Trùm, tint hồng
enemy.gd: State machine MOVING / ATTACKING / DYING. 2 sprite (move + attack). Dùng AttackArea phát hiện cây qua body hoặc area.

enemy_spawner.gd: UI progress bar, label đợt, banner cảnh báo. Signal: wave_started, huge_wave_warning, level_cleared, level_failed.

4.4 UI / Grid
File	Vai trò
planting_grid.gd	Lõi gameplay: lưới, chọn cây, công cụ ghép, bảng trắc nghiệm. Group "grid". process_mode = ALWAYS.
almanac.gd	CanvasLayer bách khoa bảng tuần hoàn. Mở bằng phím A.
compound_journal.gd	CanvasLayer sổ tay hợp chất. Mở bằng phím J.
4.5 Khác
File	Vai trò
game_state.gd	Autoload. Quản lý chemical_energy, signal chemical_energy_changed.
oxy_bullet.gd	Đạn Oxy. Bay thẳng, đổi frame, pop khi trúng quái.
5. LUỒNG HOẠT ĐỘNG CHÍNH
5.1 Trồng cây
text
Click nút cây → _on_seed_down(i)
  → check Discoveries.is_element_unlocked + cooldown + energy
Click ô trống → _try_plant(cell)
  → GameState.spend_energy(cost)
  → instantiate scene → add vào Plants container → bind vào _occupied[cell]
  → hiệu ứng pop
5.2 Ghép hợp chất
text
Bấm "Ghép cây" → _enter_combine() → paused = true
Chọn cây kề nhau → _toggle_combine_cell(cell)
  → _refresh_preview() → CompoundData.evaluate(ids)
Bấm "Ghép" → _confirm_combine() → _open_quiz(id)
Chọn 3 điều kiện → _submit_quiz()
  → CompoundData.count_correct(id, chosen) == 3?
    → Đúng: _combine_success() → trừ giá, xoá nguyên liệu, spawn CompoundPlant
    → Sai:  _combine_failure() → trừ phạt, giữ nguyên liệu
5.3 Sinh quái
text
EnemySpawner.start_level(n)
  → LevelData.get_level(n)
  → _setup_geometry() (đọc lưới grid)
  → LevelData.build_schedule(level, rows, rng)
     → Sắp quái theo threat + nhiễu
     → Chia đợt (đợt cuối chiếm ~40%)
     → Áp ràng buộc only_final / min_wave
     → Sinh events [{time, id, row, wave}]
  → _process(delta) sinh quái theo thời gian
  → Win: hết events + _alive == 0 → _clear()
  → Lose: quái vượt mép trái → _fail()
5.4 Quái tấn công cây
text
Quái MOVING → va chạm AttackArea với cây
  → _on_attack_area_body_entered (nếu cây là CharacterBody2D)
    hoặc _on_attack_area_area_entered (nếu cây có HitArea)
  → current_state = ATTACKING, current_target = cây
  → Mỗi attack_interval giây: current_target.take_damage(damage)
  → Cây chết hoặc rời vùng → _return_to_moving()
6. QUY ƯỚC CODE
6.1 Đặt tên
File GDScript: snake_case.gd

Class name: PascalCase (Plant, CompoundData, LevelData...)

Signal: snake_case (enemy_died, level_cleared)

Biến private: _prefix_gạch_dưới

Hằng số: UPPER_SNAKE_CASE

6.2 Group (rất quan trọng)
Group	Chứa
"plants"	Mọi cây đang sống
"enemies"	Mọi quái đang sống
"elements"	Cây có đặc tính nguyên tố (Cacbon, Natri...)
"grid"	Lưới trồng cây (để EnemySpawner tìm)
6.3 Collision Layer / Mask
Layer 1: nền / lưới

Layer 2: quái (enemy body)

AttackArea của quái: collision_mask = 2

EnemyDetector của Oxy: collision_mask = 2, collide_with_bodies = true

HitArea của cây: collision_mask = 2

6.4 Pause mode
planting_grid.gd: process_mode = ALWAYS

almanac.gd: process_mode = ALWAYS

compound_journal.gd: process_mode = ALWAYS

Khi ghép / mở bách khoa / sổ tay: get_tree().paused = true

6.5 Ngôn ngữ & comment
Comment code: tiếng Việt

Text trong game: tiếng Việt

Tên biến / hàm: tiếng Anh

7. NGUYÊN TẮC THIẾT KẾ
Hoá học phải chính xác — Mỗi cây/quái/hợp chất mô phỏng tính chất hoá học thật:

Cacbon hoá kim cương khi chịu áp suất cao.

Natri nổ khi gặp nước (quái slime = nước).

Hydro sinh năng lượng (nhiên liệu của sao).

Oxy bắn thẳng (oxi hoá).

Không cần ảnh cho hợp chất — CompoundPlant tự vẽ hình tròn + công thức.

Data-driven — Thêm cây/quái/màn/hợp chất mới chỉ cần sửa file data.

Trắc nghiệm điều kiện — Cơ chế giáo dục: người chơi phải nhớ điều kiện phản ứng thật.

UI code-generated — Hầu hết UI dựng bằng code, không cần scene phức tạp.

8. TÌNH TRẠNG HIỆN TẠI
Đã hoàn thành ✅
☑ Lưới trồng cây 8×5 chuẩn (đã sửa lỗi tile rác hàng -1)
☑ 4 cây cơ bản: H, O, C, Na
☑ Hệ thống trồng cây + năng lượng + cooldown
☑ Công cụ ghép hợp chất + trắc nghiệm điều kiện
☑ 8 hợp chất: H₂, H₂O, CO, CO₂, CH₄, NaOH, O₃, H₂O₂
☑ Bách khoa bảng tuần hoàn đầy đủ 118 nguyên tố (phím A)
☑ Sổ tay hợp chất (phím J) — 1 tab, hiển thị hợp chất đã khám phá
☑ 6 loại quái: Hg, Cd, Ra, Pb, U, Pu
☑ 10 màn với lịch sinh quái tự động
☑ Hệ thống khám phá (Discoveries) lưu file
☑ UI: progress bar, banner cảnh báo, trắc nghiệm
☑ Push lên GitHub thành công
Đang phát triển / dự kiến 🚧
□ Màn hình Loading — ảnh nền + thanh loading (chưa làm)
□ Màn hình Menu chính — nút Chơi / Bách khoa / Cài đặt / Thoát (chưa làm)
□ Popup thắng/thua — hiện chỉ có banner, chưa có UI chọn "Chơi tiếp / Về menu"
□ Nội tại quái (passive) — hiện chỉ có chỉ số, chưa có hiệu ứng đặc biệt
□ Mở khoá nguyên tố theo màn (hiện mặc định H, O, C, Na)
□ Thêm cây mới: N (Nitơ), S (Lưu huỳnh), Cl (Clo)...
□ Thêm hợp chất: NaCl, H₂SO₄, HNO₃...
□ Hệ thống phản ứng giữa các nguyên tố trên lưới
□ Art chính thức cho quái (hiện dùng tint + sprite tạm)
□ Âm thanh / nhạc nền
9. ĐIỂM CẦN LƯU Ý KHI SỬA CODE
⚠️ Các điểm dễ gây lỗi:

TileMapLayer dễ bị dư tile rác — Luôn clear() trong _fill_tiles() trước khi fill, để tránh tile vẽ tay trong editor gây lệch lưới (đã từng bị lỗi hàng -1).

Enemy AttackArea phải kết nối cả 4 signal: body_entered, body_exited, area_entered, area_exited — vì cây có thể là CharacterBody2D hoặc có HitArea (Area2D con).

CompoundPlant.setup(id) phải gọi TRƯỚC add_child() — vì _ready() sẽ đọc data đã setup.

Thêm cây mới phải cập nhật 3 nơi:

element_data.gd → ENTRIES + PLANT_ORDER

Discoveries.DEFAULT_ELEMENTS (nếu muốn mở từ đầu)

Scene + script cây (nếu cần cơ chế riêng)

Thêm quái mới phải cập nhật:

enemy_registry.gd → ENEMIES

element_data.gd → ENTRIES (role = "enemy")

Thêm hợp chất chỉ cần thêm vào CompoundData.RECIPES.

get_tree().paused = true — Nhớ reset về false khi đóng panel, nếu không game sẽ đứng mãi.

Tween khi pause: dùng .set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) nếu muốn tween chạy khi game pause.

UI code-generated: Khi tạo Control bằng code, nhớ set size_flags_horizontal/vertical = SIZE_EXPAND_FILL nếu muốn nó giãn ra — mặc định là SIZE_SHRINK_BEGIN.


**Cập nhật hình ảnh nguyên tố** — Khi có **hình pixel art** cho nguyên tố nào (cây hoặc quái), cập nhật hình ảnh của nguyên tố đó vào game:
    - **Cây:** thay sprite tại `res://elemental/<tên_file>.png`, cập nhật đường dẫn trong `element_data.gd` → `ENTRIES[sym]["icon"]`, và gán texture vào `Sprite2D` trong scene cây tương ứng (`Hydro.tscn`, `Coal.tscn`...).
    - **Quái:** bỏ `tint` màu trong `enemy_registry.gd` → `ENEMIES[id]`, và gán sprite mới vào scene `Enemy.tscn` (hoặc tạo scene riêng cho từng loại quái nếu cần animation khác nhau).
    - **Hợp chất:** nếu có icon riêng, thêm trường `icon` vào `CompoundData.RECIPES[id]` và cập nhật `CompoundPlant._draw()` để dùng texture thay vì vẽ hình tròn.
    - **Bách khoa (Almanac):** icon hiển thị tự động lấy từ `ENTRIES[sym]["icon"]` → không cần sửa gì thêm.
    
10. CÁCH CHẠY & TEST
bash
# Clone
git clone https://github.com/DuyAnh15dz/Elemental_Defense.git

# Mở bằng Godot 4.4.1+
# Import project.godot → F5 để chạy

# Test nhanh
- Nhấn A → mở bách khoa (bảng tuần hoàn)
- Nhấn J → mở sổ tay hợp chất
- Trồng Hydro → chờ 7s → bấm orb
- Trồng Oxy → thấy bắn đạn
- Bấm "Ghép cây" → chọn 2 Hydro kề nhau → ghép H₂
- Chọn 3 điều kiện đúng → thành công
11. GỢI Ý CHO AI HỖ TRỢ
Khi người dùng hỏi về dự án này, AI nên:

Hiểu ngữ cảnh: Đây là game giáo dục hoá học, không chỉ tower defense thường.

Tôn trọng tính chính xác hoá học: Nếu thêm nguyên tố/hợp chất, kiểm tra tính chất thật.

Data-driven mindset: Ưu tiên sửa file data thay vì hard-code.

Comment tiếng Việt: Giữ phong cách comment hiện tại.

Godot 4 API: Dùng đúng API Godot 4 (không dùng Godot 3).

Group-based logic: Tận dụng get_tree().get_nodes_in_group() thay vì hard reference.

UI code-generated: Ưu tiên dựng UI bằng code thay vì scene phức tạp.

Khi user yêu cầu "hướng dẫn": Chỉ liệt kê các bước cần làm, không viết code ngay (trừ khi được yêu cầu).

12. KẾ HOẠCH TƯƠNG LAI — MÀN HÌNH LOADING & MENU
Người dùng đã hỏi về việc này nhưng chưa muốn làm ngay.

Màn hình Loading
Tạo LoadingScreen.tscn — Control full rect + TextureRect nền + ProgressBar + Label

Script loading_screen.gd — dùng ResourceLoader.load_threaded_request() để load ngầm

Đặt làm main scene trong Project Settings

Thêm await timer tối thiểu 1.5-2s nếu load nhanh quá

Test → tự chuyển sang menu

Màn hình Menu chính
Tạo MainMenu.tscn — Control full rect + TextureRect nền

Thêm 4 nút: Chơi / Bách khoa / Cài đặt / Thoát

Script main_menu.gd — kết nối signal pressed chuyển scene

(Tuỳ chọn) Label chào mừng đọc từ save

(Tuỳ chọn) Nhạc nền + âm thanh click

Luồng scene
text
LoadingScreen → MainMenu → node_2d (game) → (thắng/thua) → MainMenu hoặc màn tiếp
Xử lý kết thúc màn
Thêm popup thắng/thua trong enemy_spawner.gd

Nút "Chơi tiếp" (nếu thắng), "Thử lại" (nếu thua), "Về menu"

13. LIÊN HỆ / TÁC GIẢ
GitHub: DuyAnh15dz

Repo: Elemental_Defense

File này được cập nhật lần cuối ngày 2026-10-10. Cập nhật khi có thay đổi lớn về kiến trúc hoặc cơ chế.

text

---

**Những thay đổi chính so với bản trước:**

| Mục | Thay đổi |
|-----|---------|
| **Ngày cập nhật** | 2026-10-10 |
| **Engine** | Ghi rõ Godot 4.4.1 stable |
| **Mục 2.6** | Thêm phần **Sổ tay hợp chất (phím J)** |
| **Mục 4.2** | Thêm bảng chỉ số cụ thể của từng cây |
| **Mục 4.3** | Thêm bảng chỉ số chi tiết của từng quái |
| **Mục 8** | Đánh dấu ✅ đã sửa lỗi lưới tile, ✅ đã push GitHub |
| **Mục 9** | Thêm ghi chú về tile rác hàng -1, UI code-generated cần `SIZE_EXPAND_FILL` |
| **Mục 12** | **MỚI** — Kế hoạch tương lai cho Loading Screen & Main Menu (chưa làm) |
| **Mục 11** | Thêm ghi chú "Khi user yêu cầu hướng dẫn — chỉ liệt kê bước, không code ngay" |
