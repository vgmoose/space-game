extends Node2D

var player

var graphics = {};
var a = 0;

var screenImage
var screenTexture
var editableScreen

var SCALER = 2
var windowSize
var gamepad

var initialized = false

var labelController

var gamepadTexture
var tabletTexture

var startedMusic = false

func _ready():
	player = find_node("AudioStreamPlayer")
	screenImage = find_node("TextureRect")
	gamepad = find_node("Gamepad")
	labelController = find_node("LabelController")
	gamepadTexture = gamepad.texture
	tabletTexture =  load("res://Classic/tablet.png")

#	get_tree().get_root().connect("size_changed", self.size_changed)
	get_tree().get_root().connect("size_changed", self, "size_changed")
	
	var imageTexture = ImageTexture.new()
	var dynImage = Image.new()

	dynImage.create(427, 240, false, Image.FORMAT_RGB8)
	dynImage.fill(Color(0, 0, 0))

	imageTexture.create_from_image(dynImage, 0)
	screenImage.texture = imageTexture
	
	screenTexture = imageTexture
	editableScreen = dynImage
	
#	labelController.drawString("start-game", "Start Game", 10, 10)
	
	mySpaceGlobals = {
		"buttonA": false,
		"buttonB": false,
		"buttonUP": false,
		"buttonDOWN": false,
		"buttonRIGHT": false,
		"buttonLEFT": false,
		"buttonPLUS": false,
		"rstick_x": 0,
		"lstick_x": 0,
		"rstick_y": 0,
		"lstick_y": 0,
		"touched": false,
		"allowInput": true
	}
	mySpaceGlobals["playerChoice"] = 0
	mySpaceGlobals["playerExplodeFrame"] = 0
	mySpaceGlobals["noEnemies"] = false
	
	graphics["classicMain"] = self
	graphics["nxFont"] = false
	graphics["spaceGlobals"] = mySpaceGlobals
	graphics["labelController"] = labelController
	
	graphics["editableScreen"] = editableScreen
	graphics["screenTexture"] = screenTexture

	graphics["flipColor"] = 0;

	mySpaceGlobals["graphics"] = graphics;
#	print("Space globals initialized\n");

	# Flag for restarting the entire game.
	mySpaceGlobals["restart"] = 1;

	# initial state is title screen
	mySpaceGlobals["state"] = 1;
	mySpaceGlobals["titleScreenRefresh"] = 1;

	# Flags for render states
	mySpaceGlobals["renderResetFlag"] = 0;
	mySpaceGlobals["menuChoice"] = 0; #  0 is play, 1 is password
	
	mySpaceGlobals["passwordList"] = []
	mySpaceGlobals["title"] = null
	mySpaceGlobals["orig_ship"] = null
	mySpaceGlobals["enemy"] = null
	
	mySpaceGlobals["lives"] = 4
	
	mySpaceGlobals["p1X"] = 0
	mySpaceGlobals["p1Y"] = 0
	mySpaceGlobals["angle"] = 0
	mySpaceGlobals["frame"] = 0
	
	mySpaceGlobals["tripleShot"] = false
	mySpaceGlobals["doubleShot"] = false
	
	size_changed()
	
	program_start()

var mySpaceGlobals
var space

func size_changed():
	windowSize = get_viewport_rect().size
	var width = 427
	var height = 240

	SCALER = max(min(int(windowSize.x / width), int(windowSize.y / height)), 1)
	screenImage.rect_scale = Vector2(SCALER, SCALER)
	screenImage.rect_position = Vector2(windowSize.x/2 - (width*SCALER)/2, windowSize.y/2 - (height*SCALER)/2)

	# position our non-nxFont fonts
	labelController.rect_position = screenImage.rect_position
	labelController.multiplier = SCALER
	labelController.updateFont()
	
#	var prevTexture = gamepad.texture
	
	if mySpaceGlobals.graphics.nxFont:
		gamepad.texture = tabletTexture
		gamepad.rect_scale = Vector2(0.5*0.49*SCALER, 0.5*0.49*SCALER)
		gamepad.rect_size = Vector2(3006, 1282)
		gamepad.rect_position = Vector2(
			-gamepad.rect_scale.x*0.215*gamepad.rect_size.x + screenImage.rect_position.x,
			-gamepad.rect_scale.y*0.11*gamepad.rect_size.y + screenImage.rect_position.y
		)
	else:
#		print("updating gamepad")
		gamepad.texture = gamepadTexture
		gamepad.rect_scale = Vector2(0.5*0.83*SCALER, 0.5*0.83*SCALER)
		gamepad.rect_size = Vector2(1875, 1103)
		gamepad.rect_position = Vector2(
			-gamepad.rect_scale.x*0.2237*gamepad.rect_size.x + screenImage.rect_position.x,
			-gamepad.rect_scale.y*0.2393*gamepad.rect_size.y + screenImage.rect_position.y
		)

func program_start():
	initialized = true
	
	# setup the password list
	var pwSeed = 27;
	var trigmath = PRandom.new(pwSeed)
	for x in range(100):
		var levelCode = int(trigmath.prand()*100000)
		mySpaceGlobals.passwordList.append(levelCode)

	#  set the starting time
	randomize()
	mySpaceGlobals["seed"] = randi()
#	print("Set the time!\n");

	var pad_data = {}

	#  decompress compressed things into their arrays, final argument is the transparent color in their palette
	var images = Images.new()
	var draw = Draw.new()
	space = Space.new(mySpaceGlobals)
#	print("Initialized space object")
#
#	#  setup palette and transparent index
	mySpaceGlobals["curPalette"] = images.ship_palette;
	mySpaceGlobals["transIndex"] = 14;

	mySpaceGlobals["passwordEntered"] = 0;
	mySpaceGlobals["quit"] = 0;

	#  initialize starfield for this game
	space.initStars(mySpaceGlobals);

	mySpaceGlobals["invalid"] = 1;
#	print("About to enter main loop\n");
#
	mySpaceGlobals["touched"] = 0
	mySpaceGlobals["touchX"] = 0
	mySpaceGlobals["touchY"] = 0
	
	mySpaceGlobals["level"] = 0
	mySpaceGlobals["enemiesSeekPlayer"] = 0
	mySpaceGlobals["dontKeepTrackOfScore"] = 0
	mySpaceGlobals["score"] = 0
	mySpaceGlobals["displayHowToPlay"] = false
	
#	Engine.set_target_fps(90)

func _process(delta):
	if not initialized:
		program_start()
	# redraw every frame, like old space game handled it
	a += 1
#	Engine.set_target_fps(60)
#	print(Engine.get_frames_per_second())
	# get lock for drawing
	editableScreen.lock()
	
	# keep track of the time inbetween frames
	# (this is new for space game)
	mySpaceGlobals.delta = delta

	# Get the status of the controller
	mySpaceGlobals.buttonA = Input.is_action_pressed("accept")
	mySpaceGlobals.buttonB = Input.is_action_pressed("cancel")
	mySpaceGlobals.buttonUP    = Input.is_action_pressed("up")
	mySpaceGlobals.buttonDOWN  = Input.is_action_pressed("down")
	mySpaceGlobals.buttonRIGHT = Input.is_action_pressed("right")
	mySpaceGlobals.buttonLEFT  = Input.is_action_pressed("left")
	mySpaceGlobals.buttonPLUS = Input.is_action_pressed("pause")

#	mySpaceGlobals.rstick_x = Input.get_axis("shoot_left", "shoot_right")
#	mySpaceGlobals.lstick_x = Input.get_axis("left", "right")
#	mySpaceGlobals.rstick_y = Input.get_axis("shoot_down", "shoot_up")
#	mySpaceGlobals.lstick_y = Input.get_axis("down", "up")
	mySpaceGlobals.rstick_x = Input.get_joy_axis(0, 2)
	mySpaceGlobals.lstick_x = Input.get_joy_axis(0, 0)
	mySpaceGlobals.rstick_y = Input.get_joy_axis(0, 3)
	mySpaceGlobals.lstick_y = Input.get_joy_axis(0, 1)

	mySpaceGlobals.touched = Input.is_mouse_button_pressed(1)

	if (mySpaceGlobals.touched):
		var pos = self.get_local_mouse_position()
		mySpaceGlobals.touchX = (pos.x - screenImage.rect_position.x) / SCALER; #  (( / 9) - 11);
		mySpaceGlobals.touchY = (pos.y - screenImage.rect_position.y) / SCALER; #  ((3930 - vpad_data.touched_y) / 16);
	if (mySpaceGlobals.restart == 1):
		space.reset(mySpaceGlobals);
		mySpaceGlobals.restart = 0;

	if (mySpaceGlobals.state == 1): #  title screen
		space.displayTitle(mySpaceGlobals);
		space.doMenuAction(mySpaceGlobals);
	elif (mySpaceGlobals.state == 2): #  password screen
		space.displayPasswordScreen(mySpaceGlobals);
		space.doPasswordMenuAction(mySpaceGlobals);
	elif (mySpaceGlobals.state == 3): #  pause screen
		space.displayPause(mySpaceGlobals);
		space.doMenuAction(mySpaceGlobals);
	elif  (mySpaceGlobals.state == 4): #  game over screen
		space.displayGameOver(mySpaceGlobals);
		space.doMenuAction(mySpaceGlobals);
	elif (mySpaceGlobals.state == -27): #  for password inputs
		pass
	else: 	#  game play
		# Update location of player1 and 2 paddles
		space.p1Move(mySpaceGlobals);

		#  perform any shooting
		space.p1Shoot(mySpaceGlobals);

		#  handle any collisions
		space.handleCollisions(mySpaceGlobals);

		#  do explosions
		space.handleExplosions(mySpaceGlobals);

		#  if we're out of lives, break
		if (mySpaceGlobals.lives <= 0 && mySpaceGlobals.state == 4):
			return

		#  add any new enemies
		space.addNewEnemies(mySpaceGlobals);

		# Render the scene
		space.render(mySpaceGlobals);

		#  check for pausing
		space.checkPause(mySpaceGlobals);
		
	editableScreen.unlock()
	screenTexture.set_data(editableScreen)
	screenImage.texture = screenTexture
	
	if not startedMusic:
		player.playing = true
		startedMusic = true

	# To exit the game
#		if (mySpaceGlobals.button & PAD_BUTTON_MINUS):
#			break;

