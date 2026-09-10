class_name LevelTileMap extends TileMapLayer

const DEMO_ATLAS := preload("res://assets/tiles/demo1-atlas.png")
const CART_ATLAS := preload("res://assets/tiles/cartoon_terrain_atlas.png")
const TILE_SIZE := Vector2i(96, 96)
const MAP_MIN_X := -10
const MAP_MAX_X := 10
const MAP_MIN_Y := -20
const MAP_MAX_Y := 20

# source 0: demo1-atlas (96px, 13x13) — 草地与水域
const DEMO_SOURCE := 0
# demo1 水域格子坐标 (右列 + 中部几格)
const DEMO_LAKE_TILES := [Vector2i(12, 0), Vector2i(12, 1), Vector2i(12, 2), Vector2i(12, 3),
	Vector2i(12, 4), Vector2i(12, 5), Vector2i(7, 3), Vector2i(8, 3), Vector2i(8, 4),
	Vector2i(9, 4), Vector2i(10, 4), Vector2i(11, 4)]
# demo1 草地格子 (全部非水域格子)
const DEMO_GRASS_TILES := [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0),
	Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0), Vector2i(8, 0), Vector2i(9, 0),
	Vector2i(10, 0), Vector2i(11, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
	Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1),
	Vector2i(8, 1), Vector2i(9, 1), Vector2i(10, 1), Vector2i(11, 1), Vector2i(0, 2),
	Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2),
	Vector2i(6, 2), Vector2i(7, 2), Vector2i(8, 2), Vector2i(9, 2), Vector2i(10, 2),
	Vector2i(11, 2), Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3),
	Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(9, 3), Vector2i(10, 3),
	Vector2i(11, 3), Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4),
	Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4), Vector2i(12, 6), Vector2i(12, 7),
	Vector2i(12, 8), Vector2i(12, 9), Vector2i(12, 10), Vector2i(12, 11), Vector2i(12, 12),
]
# source 1: cartoon_terrain_atlas (64px, 8x2) — 高山与岩石 (行1)
const CART_SOURCE := 1
const CART_MOUNTAIN_TILES := [Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1)]
const CART_ROCK_TILES := [Vector2i(6, 1), Vector2i(7, 1)]

# 地形类型
const TERRAIN_GRASS := 0
const TERRAIN_LAKE := 1
const TERRAIN_MOUNTAIN := 2
const TERRAIN_ROCK := 3

var _active_level_index := -1


func _ready() -> void:
	# 瓦片地图暂下掉: 不构建、不生成
	pass


func configure(level_index: int) -> void:
	if tile_set == null:
		_build_tile_set()
	_active_level_index = posmod(level_index, 3)
	clear()
	for y in range(MAP_MIN_Y, MAP_MAX_Y + 1):
		for x in range(MAP_MIN_X, MAP_MAX_X + 1):
			var terrain := _pick_terrain(x, y)
			_set_terrain_cell(Vector2i(x, y), terrain)


func _set_terrain_cell(cell: Vector2i, terrain: int) -> void:
	var variant_hash := cell.x * 15485863 + cell.y * 32452843 + _active_level_index * 49979687
	if variant_hash < 0:
		variant_hash = -variant_hash
	match terrain:
		TERRAIN_GRASS:
			set_cell(cell, DEMO_SOURCE, DEMO_GRASS_TILES[variant_hash % DEMO_GRASS_TILES.size()])
		TERRAIN_LAKE:
			set_cell(cell, DEMO_SOURCE, DEMO_LAKE_TILES[variant_hash % DEMO_LAKE_TILES.size()])
		TERRAIN_MOUNTAIN:
			set_cell(cell, CART_SOURCE, CART_MOUNTAIN_TILES[variant_hash % CART_MOUNTAIN_TILES.size()])
		TERRAIN_ROCK:
			set_cell(cell, CART_SOURCE, CART_ROCK_TILES[variant_hash % CART_ROCK_TILES.size()])


func _build_tile_set() -> void:
	var terrain_tile_set := TileSet.new()
	terrain_tile_set.tile_size = TILE_SIZE
	# 地形物理层: 不可通行瓦片阻挡玩家
	terrain_tile_set.add_physics_layer()
	terrain_tile_set.set_physics_layer_collision_layer(0, 1)
	terrain_tile_set.set_physics_layer_collision_mask(0, 1)

	# source 0: demo1-atlas (96px)
	var demo_source := TileSetAtlasSource.new()
	demo_source.texture = DEMO_ATLAS
	demo_source.texture_region_size = TILE_SIZE
	for gy in range(13):
		for gx in range(13):
			demo_source.create_tile(Vector2i(gx, gy))
	terrain_tile_set.add_source(demo_source, DEMO_SOURCE)

	# source 1: cartoon_terrain_atlas (64px 瓦片, 与 96px 格子混用)
	var cart_source := TileSetAtlasSource.new()
	cart_source.texture = CART_ATLAS
	cart_source.texture_region_size = Vector2i(64, 64)
	for row in range(2):
		for column in range(8):
			cart_source.create_tile(Vector2i(column, row))
	terrain_tile_set.add_source(cart_source, CART_SOURCE)

	tile_set = terrain_tile_set
	# 为不可通行瓦片添加碰撞多边形 (湖泊用 demo1 水域, 高山/岩石用 cartoon)
	for atlas_coord in DEMO_LAKE_TILES:
		var tile_data: TileData = demo_source.get_tile_data(atlas_coord, 0)
		if tile_data != null:
			tile_data.add_collision_polygon(0)
			tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
				Vector2(0, 0), Vector2(96, 0), Vector2(96, 96), Vector2(0, 96),
			]))
	for atlas_coord in CART_MOUNTAIN_TILES + CART_ROCK_TILES:
		var tile_data: TileData = cart_source.get_tile_data(atlas_coord, 0)
		if tile_data != null:
			tile_data.add_collision_polygon(0)
			tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
				Vector2(0, 0), Vector2(64, 0), Vector2(64, 64), Vector2(0, 64),
			]))


func _pick_terrain(x: int, y: int) -> int:
	# 玩家出生区 (中心) 强制草地
	if absi(x) <= 1 and absi(y) <= 2:
		return TERRAIN_GRASS
	var level_seed := _active_level_index * 1013
	var lake_noise := _hash_noise(int(floor(float(x) / 4.0)), int(floor(float(y) / 4.0)), level_seed + 1)
	var mountain_noise := _hash_noise(int(floor(float(x) / 4.0)), int(floor(float(y) / 4.0)), level_seed + 2)
	var rock_noise := _hash_noise(int(floor(float(x) / 3.0)), int(floor(float(y) / 3.0)), level_seed + 3)
	var border_strength := _border_strength(x, y)
	# 最外圈2格: 高山护栏
	if border_strength > 0.93:
		return TERRAIN_MOUNTAIN
	if border_strength > 0.80 and mountain_noise < 0.25:
		return TERRAIN_MOUNTAIN
	# 湖泊
	if lake_noise < 0.12 and border_strength < 0.85:
		return TERRAIN_LAKE
	# 岩石
	if rock_noise < 0.05 and border_strength < 0.90:
		return TERRAIN_ROCK
	return TERRAIN_GRASS


func _border_strength(x: int, y: int) -> float:
	var nx := float(x - MAP_MIN_X) / float(MAP_MAX_X - MAP_MIN_X) * 2.0 - 1.0
	var ny := float(y - MAP_MIN_Y) / float(MAP_MAX_Y - MAP_MIN_Y) * 2.0 - 1.0
	return clampf(maxf(absf(nx), absf(ny)), 0.0, 1.0)


## 返回适合放置树木的草地格世界坐标 (避开出生区与地形边界)。
func get_tree_placements() -> Array[Vector2]:
	var placements: Array[Vector2] = []
	for y in range(MAP_MIN_Y + 2, MAP_MAX_Y - 1):
		for x in range(MAP_MIN_X + 2, MAP_MAX_X - 1):
			# 避开出生区 (±3格)
			if absi(x) <= 3 and absi(y) <= 4:
				continue
			# 只放在草地格上
			if _pick_terrain(x, y) != TERRAIN_GRASS:
				continue
			# 概率放置, 且避免与相邻树过近
			if _hash_noise(x, y, 777) < 0.07:
				placements.append(Vector2(x * 96.0 + 48.0, y * 96.0 + 48.0))
	return placements


func _hash_noise(x: int, y: int, seed: int) -> float:
	var value: int = x * 374761393 + y * 668265263 + seed * 1274126177
	value = (value ^ (value >> 13)) * 1274126177
	value = value ^ (value >> 16)
	return float((value & 0x7FFFFFFF) % 100000) / 100000.0
