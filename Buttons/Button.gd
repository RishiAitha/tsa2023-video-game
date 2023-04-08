extends Button

export var hoverable = false
export var toggleable = false
var toggled = 0

var defaultAnim
var pressedAnim
var BlueAnim
var RedAnim
var YellowAnim
var GreenAnim
var otherDefaultAnim
var otherPressedAnim

var color = "Blue"

func _ready():
	$AnimatedSprite.position.x *= self.rect_size.x/128
	$AnimatedSprite.position.y *= self.rect_size.y/64
	if (toggleable):
		$AnimatedSprite.scale *= self.rect_size/32
	else:
		$AnimatedSprite.scale.x *= self.rect_size.x/128
		$AnimatedSprite.scale.y *= self.rect_size.y/64
	defaultAnim = load("res://Assets/" + self.name + ".png")
	pressedAnim = load("res://Assets/Pressed-" + self.name + ".png")
	if (hoverable):
		BlueAnim = load("res://Assets/Blue-" + self.name + ".png")
		RedAnim = load("res://Assets/Red-" + self.name + ".png")
		YellowAnim = load("res://Assets/Yellow-" + self.name + ".png")
		GreenAnim = load("res://Assets/Green-" + self.name + ".png")
	
	if (toggleable):
		otherDefaultAnim = load("res://Assets/Alt-" + self.name + ".png")
		otherPressedAnim = load("res://Assets/Alt-Pressed-" + self.name + ".png")
	
	$AnimatedSprite.animation = "default"
	for animation in $AnimatedSprite.frames.get_animation_names():
		$AnimatedSprite.frames.clear(animation)
	$AnimatedSprite.frames.add_frame("default", defaultAnim)
	$AnimatedSprite.frames.add_frame("pressed", pressedAnim)
	
	if (hoverable):
		$AnimatedSprite.frames.add_frame("Blue", BlueAnim)
		$AnimatedSprite.frames.add_frame("Red", RedAnim)
		$AnimatedSprite.frames.add_frame("Yellow", YellowAnim)
		$AnimatedSprite.frames.add_frame("Green", GreenAnim)
	
	if (toggleable):
		$AnimatedSprite.frames.add_frame("default", otherDefaultAnim)
		$AnimatedSprite.frames.add_frame("pressed", otherPressedAnim)

func _on_Button_button_down():
	$AnimatedSprite.animation = "pressed"
	if (toggleable):
		$AnimatedSprite.frame = toggled

func _on_Button_button_up():
	$AnimatedSprite.animation = "default"
	if (toggled == 0):
		toggled = 1
	else:
		toggled = 0
	if (toggleable):
		$AnimatedSprite.frame = toggled

func _on_Button_mouse_entered():
	if (hoverable):
		$AnimatedSprite.animation = color

func _on_Button_mouse_exited():
	$AnimatedSprite.animation = "default"
