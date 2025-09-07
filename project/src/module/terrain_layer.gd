extends TileMapLayer

# 地图生成参数
const MAP_WIDTH = 128
const MAP_HEIGHT = 128

# 陆地海洋比例控制 (0.0 = 全海洋, 1.0 = 全陆地)
var land_ratio = 0.45  # 默认40%陆地，60%海洋

# 地形分布比例控制 (各比例之和应为1.0)
var ocean_deep_ratio = 0.8    # 深水占海洋的比例
var ocean_shallow_ratio = 0.2 # 浅水占海洋的比例
var land_grass_ratio = 0.6    # 草地占陆地的比例
var land_stone_ratio = 0.3    # 石头占陆地的比例
var land_snow_ratio = 0.1     # 雪地占陆地的比例

# 地形阈值 (会根据比例动态调整)
var deep_water_threshold: float
var water_threshold: float
var grass_threshold: float
var stone_threshold: float

# 地形瓦片名称到source_id的映射 (不包含city)
const TERRAIN_TILE_TYPES = {
	"deep_water": 5,  # 深水
	"water": 1,       # 浅水
	"grass": 0,       # 草地
	"stone": 3,       # 石头
	"snow": 4         # 雪地
}

# 噪声生成器
var noise: FastNoiseLite

func _ready():
	# 初始化噪声生成器
	noise = FastNoiseLite.new()
	noise.frequency = 0.1
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# 计算初始地形阈值
	calculate_terrain_thresholds()
	
	# 设置输入监听
	set_process_input(true)

func _input(event):
	# 检测按键1生成地形地图
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			generate_terrain_map()

func generate_terrain_map():
	# 每次生成时使用新的随机种子
	noise.seed = randi()
	
	# 清除现有瓦片
	clear()
	
	# 计算地图的起始坐标，使地图以原点为中心
	var start_x = -MAP_WIDTH / 2
	var start_y = -MAP_HEIGHT / 2
	
	# 生成地形地图
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			# 计算实际的世界坐标
			var world_x = start_x + x
			var world_y = start_y + y
			
			# 获取噪声值 (-1 到 1)
			var noise_value = noise.get_noise_2d(world_x, world_y)
			
			# 根据噪声值决定瓦片类型
			var tile_name = get_tile_type_from_noise(noise_value)
			set_terrain_tile_by_name(Vector2i(world_x, world_y), tile_name)
	
	print("地形地图生成完成！尺寸: ", MAP_WIDTH, "x", MAP_HEIGHT, " 种子: ", noise.seed)
	print("地图范围: X[", start_x, " 到 ", start_x + MAP_WIDTH - 1, "] Y[", start_y, " 到 ", start_y + MAP_HEIGHT - 1, "]")

func get_tile_type_from_noise(noise_value: float) -> String:
	# 根据噪声值返回对应的瓦片类型
	if noise_value < deep_water_threshold:
		return "deep_water"
	elif noise_value < water_threshold:
		return "water"
	elif noise_value < grass_threshold:
		return "grass"
	elif noise_value < stone_threshold:
		return "stone"
	else:
		return "snow"

func set_terrain_tile_by_name(tile_position: Vector2i, tile_name: String):
	# 根据瓦片名称设置地形瓦片
	if tile_name in TERRAIN_TILE_TYPES:
		var source_id = TERRAIN_TILE_TYPES[tile_name]
		set_cell(tile_position, source_id, Vector2i(0, 0))
	else:
		print("警告: 未知的地形瓦片类型: ", tile_name)

func calculate_terrain_thresholds():
	# 根据陆地比例和地形分布比例计算地形阈值
	# 噪声值范围是-1到1，总共2个单位
	var ocean_ratio = 1.0 - land_ratio
	
	# 计算海洋部分的阈值
	# 深水占海洋的指定比例
	deep_water_threshold = -1.0 + (ocean_ratio * 2.0 * ocean_deep_ratio)
	water_threshold = -1.0 + (ocean_ratio * 2.0)
	
	# 陆地部分从water_threshold开始
	var land_range = 2.0 - (ocean_ratio * 2.0)
	grass_threshold = water_threshold + (land_range * land_grass_ratio)
	stone_threshold = water_threshold + (land_range * (land_grass_ratio + land_stone_ratio))
	
	print("=== 地形分布比例 ===")
	print("陆地: ", land_ratio * 100, "% | 海洋: ", ocean_ratio * 100, "%")
	print("海洋分布 - 深水: ", ocean_deep_ratio * 100, "% | 浅水: ", ocean_shallow_ratio * 100, "%")
	print("陆地分布 - 草地: ", land_grass_ratio * 100, "% | 石头: ", land_stone_ratio * 100, "% | 雪地: ", land_snow_ratio * 100, "%")
	print("地形阈值 - 深水:", deep_water_threshold, " 浅水:", water_threshold, " 草地:", grass_threshold, " 石头:", stone_threshold)
