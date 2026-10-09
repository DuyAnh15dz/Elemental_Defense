class_name LevelData
extends RefCounted
## Cấu hình các màn chơi + bộ sinh lịch xuất hiện của quái.
##
## Bạn chỉ cần khai báo loại quái và số lượng; hệ thống tự quyết định thứ tự, thời điểm
## và hàng xuất hiện (quái yếu ra trước, quái mạnh ra sau, mỗi đợt dàn đều các hàng).
##
## Các trường của một màn:
##   name          Tên màn
##   enemies       {id: số lượng}, ví dụ {"Hg": 10, "Pb": 3}      (bắt buộc)
##   waves         Số đợt tấn công (mặc định 3)
##   duration      Thời gian từ đợt đầu tới đợt cuối, giây (mặc định 90)
##   start_delay   Thời gian chờ trước quái đầu tiên, giây (mặc định 15)
##   final_wave    true = đợt cuối là "đợt tấn công lớn": nhiều quái dồn lại, có cảnh báo (mặc định true)
##   rows          Các hàng được dùng, 0 là hàng trên cùng. Bỏ trống = tất cả
##   final_share   Tỉ lệ quái dồn vào đợt cuối, 0 đến 0.9 (mặc định 0.4)
##   only_final    Danh sách id chỉ xuất hiện ở đợt cuối (ví dụ trùm)
##   min_wave      {id: đợt thấp nhất được xuất hiện, tính từ 1}
##
## Chọn màn đang chơi bằng LevelData.current_level (hoặc đặt ở EnemySpawner).

static var current_level: int = 1

const LEVELS := {
	1: {"name": "Màn 1", "enemies": {"Hg": 6},
		"waves": 2, "duration": 40.0, "start_delay": 12.0, "rows": [1, 2, 3]},
	2: {"name": "Màn 2", "enemies": {"Hg": 10},
		"waves": 3, "duration": 60.0, "start_delay": 12.0, "rows": [1, 2, 3]},
	3: {"name": "Màn 3", "enemies": {"Hg": 10, "Cd": 4},
		"waves": 3, "duration": 70.0},
	4: {"name": "Màn 4", "enemies": {"Hg": 12, "Cd": 6, "Ra": 2},
		"waves": 4, "duration": 80.0},
	5: {"name": "Màn 5", "enemies": {"Hg": 12, "Cd": 6, "Ra": 4, "Pb": 3},
		"waves": 4, "duration": 90.0},
	6: {"name": "Màn 6", "enemies": {"Hg": 14, "Cd": 8, "Ra": 6, "Pb": 5},
		"waves": 4, "duration": 100.0},
	7: {"name": "Màn 7", "enemies": {"Cd": 10, "Ra": 8, "Pb": 6, "U": 2},
		"waves": 5, "duration": 110.0, "min_wave": {"U": 3}},
	8: {"name": "Màn 8", "enemies": {"Hg": 12, "Cd": 10, "Ra": 8, "Pb": 8, "U": 4},
		"waves": 5, "duration": 120.0},
	9: {"name": "Màn 9", "enemies": {"Cd": 10, "Ra": 10, "Pb": 10, "U": 8},
		"waves": 6, "duration": 130.0},
	10: {"name": "Màn 10", "enemies": {"Hg": 10, "Cd": 10, "Ra": 10, "Pb": 10, "U": 8, "Pu": 1},
		"waves": 6, "duration": 150.0, "only_final": ["Pu"]},
}


static func level_count() -> int:
	return LEVELS.size()


static func get_level(n: int) -> Dictionary:
	return LEVELS.get(n, {})


# Sinh lịch xuất hiện. Trả về:
#   events: [{time, id, row, wave}] đã sắp theo thời gian
#   waves:  [{index, number, time, warn_time, final, count}]
#   total:  tổng số quái
static func build_schedule(level: Dictionary, grid_rows: int, rng: RandomNumberGenerator) -> Dictionary:
	var empty := {"events": [], "waves": [], "total": 0}

	# ── Các hàng được dùng ──
	var rows: Array[int] = []
	var cfg_rows: Array = level.get("rows", [])
	if cfg_rows.is_empty():
		for r in grid_rows:
			rows.append(r)
	else:
		for r in cfg_rows:
			if int(r) >= 0 and int(r) < grid_rows:
				rows.append(int(r))
	if rows.is_empty():
		return empty

	var wave_count: int = maxi(1, int(level.get("waves", 3)))
	var duration: float = float(level.get("duration", 90.0))
	var start_delay: float = float(level.get("start_delay", 15.0))
	var has_final: bool = bool(level.get("final_wave", true)) and wave_count >= 2
	var only_final: Array = level.get("only_final", [])
	var min_wave: Dictionary = level.get("min_wave", {})

	# ── 1. Gom toàn bộ quái, sắp theo độ nguy hiểm (có nhiễu để các loại trộn vào nhau) ──
	var pool: Array = []
	var tmin := INF
	var tmax := -INF
	var enemies_cfg: Dictionary = level.get("enemies", {})
	for id in enemies_cfg:
		if not EnemyRegistry.exists(id):
			push_warning("LevelData: không có loại quái '%s' trong EnemyRegistry" % id)
			continue
		var th := EnemyRegistry.threat(id)
		tmin = minf(tmin, th)
		tmax = maxf(tmax, th)
		for i in int(enemies_cfg[id]):
			pool.append({"id": id, "threat": th})
	var total := pool.size()
	if total == 0:
		return empty

	var noise := (tmax - tmin) * 0.3 + 0.05
	for e in pool:
		e["key"] = float(e["threat"]) + rng.randf_range(-noise, noise)
	pool.sort_custom(func(a, b): return a["key"] < b["key"])

	# ── 2. Chia số lượng từng đợt: tăng dần, đợt cuối chiếm khoảng 40% ──
	var normal_waves := wave_count - (1 if has_final else 0)
	var final_share := clampf(float(level.get("final_share", 0.4)), 0.0, 0.9) if has_final else 0.0
	var normal_total := int(floor(total * (1.0 - final_share)))
	var weights: Array[float] = []
	var wsum := 0.0
	for k in normal_waves:
		var w := 1.0 + 0.6 * k
		weights.append(w)
		wsum += w
	var sizes: Array[int] = []
	var used := 0
	for k in normal_waves:
		var n := int(floor(normal_total * weights[k] / wsum))
		sizes.append(n)
		used += n
	if has_final:
		sizes.append(total - used)
	else:
		sizes[normal_waves - 1] += total - used

	# ── 3. Cắt thành từng đợt (quái yếu ở đợt đầu) rồi áp ràng buộc only_final / min_wave ──
	var waves_pool: Array = []
	var idx := 0
	for k in wave_count:
		waves_pool.append(pool.slice(idx, idx + sizes[k]))
		idx += sizes[k]

	var last := wave_count - 1
	for k in wave_count:
		var keep: Array = []
		for e in waves_pool[k]:
			var target := k
			if e["id"] in only_final:
				target = last
			elif min_wave.has(e["id"]):
				target = maxi(k, mini(last, int(min_wave[e["id"]]) - 1))
			if target != k:
				waves_pool[target].append(e)
			else:
				keep.append(e)
		waves_pool[k] = keep

	# ── 4. Thời điểm và hàng xuất hiện ──
	var events: Array[Dictionary] = []
	var waves_info: Array[Dictionary] = []
	var steps := float(maxi(wave_count - 1, 1))
	var interval := duration / steps

	for k in wave_count:
		var members: Array = waves_pool[k]
		if members.is_empty():
			continue
		_shuffle(members, rng)

		var is_final := has_final and k == last
		var t0 := start_delay + duration * k / steps
		var spread := 5.0 if is_final else clampf(interval * 0.6, 3.0, 25.0)

		var times: Array[float] = []
		for i in members.size():
			times.append(t0 if i == 0 else t0 + rng.randf() * spread)
		times.sort()

		# Dàn đều các hàng: chọn hàng ít quái nhất trong đợt, tránh trùng hàng với con liền trước
		var usage := {}
		var last_row := -1
		for i in members.size():
			var id: String = members[i]["id"]
			var restr: Array = EnemyRegistry.allowed_rows(id)
			var allowed: Array[int] = []
			for r in rows:
				if restr.is_empty() or restr.has(r):
					allowed.append(r)
			if allowed.is_empty():
				allowed = rows

			var min_use := 1000000
			for r in allowed:
				min_use = mini(min_use, int(usage.get(r, 0)))
			var cands: Array[int] = []
			for r in allowed:
				if int(usage.get(r, 0)) == min_use:
					cands.append(r)
			if cands.size() > 1 and cands.has(last_row):
				cands.erase(last_row)

			var row: int = cands[rng.randi() % cands.size()]
			usage[row] = int(usage.get(row, 0)) + 1
			last_row = row
			events.append({"time": times[i], "id": id, "row": row, "wave": waves_info.size()})

		waves_info.append({
			"index": waves_info.size(), "number": waves_info.size() + 1,
			"time": t0, "warn_time": maxf(0.0, t0 - 4.0),
			"final": is_final, "count": members.size(),
		})

	events.sort_custom(func(a, b): return a["time"] < b["time"])
	return {"events": events, "waves": waves_info, "total": total}


static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
