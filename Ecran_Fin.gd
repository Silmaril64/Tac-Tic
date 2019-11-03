extends Node2D

func _ready():
	$RichTextLabel.bbcode_text = "[center][b][color=#0101DF] WINNER: " + global.Winner + " [/color][/b] \n" + "[url]http://qlanneau.vvv.enseirb-matmeca.fr/[/url][/center]"
	pass
