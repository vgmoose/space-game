extends Control

# this class is focused on managing lifecycles/placements
# of Label nodes, which the original space game has no knowledge of
# This is to simulate the effect of OSScreen text on the wiiu,
# which did not have to obey specific pixel limitations

# it theoretically allows for localization by mapping
# a text's key/ID to a different translation, although
# there would be placement concerns that may need to
# be accounted for (and you'd need stuff like, align left, right, center, etc)


var allLabels
var posCache

var osScreenFont

var multiplier = 1
var FONT_SIZE = 12

func _ready():
	allLabels = {}
	posCache = {}
	
	osScreenFont = DynamicFont.new()
	osScreenFont.font_data = load("res://Classic/mplus-2m-medium.ttf")

	osScreenFont.size = FONT_SIZE * multiplier
	osScreenFont.font_data.antialiased = true
#	osScreenFont.font_data.hinting = DynamicFontData.HINTING_LIGHT

func makeAllInvisible():
	# call this at the start of a drawing frame
	for id in allLabels:
		allLabels[id].visible = false

func makeVisible(id):
	# call this during a drawing frame
	allLabels[id].visible = true

func updateFont():
	osScreenFont.size = FONT_SIZE * multiplier
	
	# update all labels for new scaling
	for id in allLabels:
		var label = allLabels[id]
		var pos = posCache[id]
		label.rect_position.x = pos.x * FONT_SIZE * multiplier / 1.75 + 5*multiplier
		label.rect_position.y = pos.y * FONT_SIZE * multiplier * 1.05
	
func drawString(id, text, x, y):
	# will try to draw a string with the given ID
	# at the given location, or update one if it
	# already exists
	
	# if the draw string isn't received for a certain ID
	# on the same frame, it will be hidden until seen
	# again. This way the code doesn't need to do anything
	# special to hide or manage these text labels
	var label
	if id in allLabels:
		label = allLabels[id]
	else:
		# create a new label with this ID
		label = Label.new()
		allLabels[id] = label
		label.set("custom_fonts/font", osScreenFont)
		self.add_child(label)
	
	posCache[id] = Vector2(x, y)

	label.rect_position.x = x * FONT_SIZE * multiplier / 1.75 + 5*multiplier
	label.rect_position.y = y * FONT_SIZE * multiplier * 1.05
	
	# some text spacing differences between the two fonts
	if text == "[[            ]]":
		text = " >>             <<"
	elif text == " Password":
		text = "Password"
	text = text.replace("   L", "L")
	text = text.replace("   Quit", "Quit").replace(" Quit", "Quit")
#	text = text.replace("MIT", " MIT")
	label.text = text
	label.visible = true

#func _process(delta):
#	pass
