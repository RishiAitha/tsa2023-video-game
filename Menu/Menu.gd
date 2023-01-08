extends Node

func _ready():
	$Start.show()
	$"2Player".hide()
	$"3Player".hide()
	$"4Player".hide()
	$MainMenu.hide()
	$ScrollContainer.hide()
	$BGMusic.play()

func _on_Start_pressed():
	$Start.hide()
	$"2Player".show()
	$"3Player".show()
	$"4Player".show()

func _on_2Player_pressed():
	$BGMusic.stop()
	ColorsSingleton.colors = ["Blue", "dead", "Yellow", "dead"]
	get_tree().change_scene("res://Main/Main.tscn")

func _on_3Player_pressed():
	$BGMusic.stop()
	ColorsSingleton.colors = ["Blue", "Red", "Yellow", "dead"]
	get_tree().change_scene("res://Main/Main.tscn")

func _on_4Player_pressed():
	$BGMusic.stop()
	ColorsSingleton.colors = ["Blue", "Red", "Yellow", "Green"]
	get_tree().change_scene("res://Main/Main.tscn")

func _on_HowToPlay_pressed():
	$Start.hide()
	$"2Player".hide()
	$"3Player".hide()
	$"4Player".hide()
	$HowToPlay.hide()
	$MusicCredits.hide()
	$MainMenu.show()
	$ScrollContainer.show()

func _on_MainMenu_pressed():
	$ScrollContainer.hide()
	$MainMenu.hide()
	$Start.show()
	$HowToPlay.show()
	$MusicCredits.show()
