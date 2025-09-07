extends Control

func _ready():
	# 连接按钮信号
	$CanvasLayer/VBoxContainer/StartButton.pressed.connect(_on_start_button_pressed)
	$CanvasLayer/VBoxContainer/SettingsButton.pressed.connect(_on_settings_button_pressed)
	$CanvasLayer/VBoxContainer/AboutButton.pressed.connect(_on_about_button_pressed)
	$CanvasLayer/VBoxContainer/QuitButton.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://src/scene/game.tscn")

func _on_settings_button_pressed():
	get_tree().change_scene_to_file("res://src/scene/settings.tscn")

func _on_about_button_pressed():
	get_tree().change_scene_to_file("res://src/scene/about.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
