extends Control

# 信号定义
signal start_game
signal open_settings
signal open_about
signal quit_game

func _ready():
	# 连接按钮信号
	$CanvasLayer/VBoxContainer/StartButton.pressed.connect(_on_start_button_pressed)
	$CanvasLayer/VBoxContainer/SettingsButton.pressed.connect(_on_settings_button_pressed)
	$CanvasLayer/VBoxContainer/AboutButton.pressed.connect(_on_about_button_pressed)
	$CanvasLayer/VBoxContainer/QuitButton.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed():
	start_game.emit()

func _on_settings_button_pressed():
	open_settings.emit()

func _on_about_button_pressed():
	open_about.emit()

func _on_quit_button_pressed():
	quit_game.emit()
