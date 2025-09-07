extends Control

# 设置项
var settings = {
	"master_volume": 1.0,
	"sfx_volume": 1.0,
	"music_volume": 1.0,
	"fullscreen": false,
	"vsync": true,
	"terrain_quality": 1.0,
	"city_density": 0.5
}

func _ready():
	# 连接按钮信号
	$CanvasLayer/VBoxContainer/BackButton.pressed.connect(_on_back_button_pressed)
	
	# 连接设置控件信号
	$CanvasLayer/VBoxContainer/ScrollContainer/VBoxContainer/AudioContainer/MasterVolumeContainer/MasterVolumeSlider.value_changed.connect(_on_master_volume_changed)
	$CanvasLayer/VBoxContainer/ScrollContainer/VBoxContainer/AudioContainer/SFXVolumeContainer/SFXVolumeSlider.value_changed.connect(_on_sfx_volume_changed)
	$CanvasLayer/VBoxContainer/ScrollContainer/VBoxContainer/AudioContainer/MusicVolumeContainer/MusicVolumeSlider.value_changed.connect(_on_music_volume_changed)
	$CanvasLayer/VBoxContainer/ScrollContainer/VBoxContainer/GraphicsContainer/FullscreenContainer/FullscreenCheckBox.toggled.connect(_on_fullscreen_toggled)
	$CanvasLayer/VBoxContainer/ScrollContainer/VBoxContainer/GraphicsContainer/VSyncContainer/VSyncCheckBox.toggled.connect(_on_vsync_toggled)
	$CanvasLayer/VBoxContainer/ScrollContainer/VBoxContainer/GameplayContainer/TerrainQualityContainer/TerrainQualitySlider.value_changed.connect(_on_terrain_quality_changed)
	$CanvasLayer/VBoxContainer/ScrollContainer/VBoxContainer/GameplayContainer/CityDensityContainer/CityDensitySlider.value_changed.connect(_on_city_density_changed)
	
	# 加载设置
	load_settings()
	update_ui()

func _on_back_button_pressed():
	save_settings()
	get_tree().change_scene_to_file("res://src/scene/menu.tscn")

func _on_master_volume_changed(value: float):
	settings.master_volume = value
	update_volume_label("MasterVolumeLabel", value)

func _on_sfx_volume_changed(value: float):
	settings.sfx_volume = value
	update_volume_label("SFXVolumeLabel", value)

func _on_music_volume_changed(value: float):
	settings.music_volume = value
	update_volume_label("MusicVolumeLabel", value)

func _on_fullscreen_toggled(enabled: bool):
	settings.fullscreen = enabled
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_vsync_toggled(enabled: bool):
	settings.vsync = enabled
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED)

func _on_terrain_quality_changed(value: float):
	settings.terrain_quality = value
	update_quality_label("TerrainQualityLabel", value)

func _on_city_density_changed(value: float):
	settings.city_density = value
	update_density_label("CityDensityLabel", value)

func update_volume_label(label_name: String, value: float):
	var container_path = ""
	if label_name == "MasterVolumeLabel":
		container_path = "MasterVolumeContainer"
	elif label_name == "SFXVolumeLabel":
		container_path = "SFXVolumeContainer"
	elif label_name == "MusicVolumeLabel":
		container_path = "MusicVolumeContainer"
	
	var label = $CanvasLayer/VBoxContainer/ScrollContainer/VBoxContainer/AudioContainer.get_node(container_path).get_node(label_name)
	label.text = str(int(value * 100)) + "%"

func update_quality_label(label_name: String, value: float):
	var label = $CanvasLayer/VBoxContainer/ScrollContainer/VBoxContainer/GameplayContainer/TerrainQualityContainer.get_node(label_name)
	var quality_text = ""
	if value <= 0.3:
		quality_text = "低"
	elif value <= 0.7:
		quality_text = "中"
	else:
		quality_text = "高"
	label.text = "地形质量: " + quality_text

func update_density_label(label_name: String, value: float):
	var label = $CanvasLayer/VBoxContainer/ScrollContainer/VBoxContainer/GameplayContainer/CityDensityContainer.get_node(label_name)
	var density_text = ""
	if value <= 0.3:
		density_text = "稀疏"
	elif value <= 0.7:
		density_text = "中等"
	else:
		density_text = "密集"
	label.text = "城市密度: " + density_text

func update_ui():
	# 更新音频设置
	$CanvasLayer/VBoxContainer/ScrollContainer/VBoxContainer/AudioContainer/MasterVolumeContainer/MasterVolumeSlider.value = settings.master_volume
	$CanvasLayer/VBoxContainer/ScrollContainer/VBoxContainer/AudioContainer/SFXVolumeContainer/SFXVolumeSlider.value = settings.sfx_volume
	$CanvasLayer/VBoxContainer/ScrollContainer/VBoxContainer/AudioContainer/MusicVolumeContainer/MusicVolumeSlider.value = settings.music_volume
	update_volume_label("MasterVolumeLabel", settings.master_volume)
	update_volume_label("SFXVolumeLabel", settings.sfx_volume)
	update_volume_label("MusicVolumeLabel", settings.music_volume)
	
	# 更新图形设置
	$CanvasLayer/VBoxContainer/ScrollContainer/VBoxContainer/GraphicsContainer/FullscreenContainer/FullscreenCheckBox.button_pressed = settings.fullscreen
	$CanvasLayer/VBoxContainer/ScrollContainer/VBoxContainer/GraphicsContainer/VSyncContainer/VSyncCheckBox.button_pressed = settings.vsync
	
	# 更新游戏设置
	$CanvasLayer/VBoxContainer/ScrollContainer/VBoxContainer/GameplayContainer/TerrainQualityContainer/TerrainQualitySlider.value = settings.terrain_quality
	$CanvasLayer/VBoxContainer/ScrollContainer/VBoxContainer/GameplayContainer/CityDensityContainer/CityDensitySlider.value = settings.city_density
	update_quality_label("TerrainQualityLabel", settings.terrain_quality)
	update_density_label("CityDensityLabel", settings.city_density)

func save_settings():
	var config = ConfigFile.new()
	for key in settings:
		config.set_value("settings", key, settings[key])
	config.save("user://settings.cfg")

func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		for key in settings:
			settings[key] = config.get_value("settings", key, settings[key])
