extends Label

## Separate by [code];[\code]. Stores every random splash message.
@export_multiline var splash_messages = ""

func random_splash():
	
	var splashes = splash_messages.split(";")
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	text = splashes[ rng.randi_range(0, splashes.size() - 1) ].trim_prefix("\n")

func show_splash(splash: String): text = splash.replace("\\n", "\n")

func hide_splash(): text = ""
