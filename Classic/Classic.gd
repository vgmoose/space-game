extends Node2D

var player

var graphics = {};
var a = 0;

var screenImage
var screenTexture
var editableScreen

func _ready():
	player = find_node("AudioStreamPlayer")
	screenImage = find_node("TextureRect")
	
	var imageTexture = ImageTexture.new()
	var dynImage = Image.new()

	dynImage.create(427, 240, false, Image.FORMAT_RGB8)
	dynImage.fill(Color(0, 0, 0))

	imageTexture.create_from_image(dynImage)
	screenImage.texture = imageTexture
	
	screenTexture = imageTexture
	editableScreen = dynImage
	
	program_start()

var mySpaceGlobals
var space

#func _draw():
#	if graphics.blackout != null:
#		draw_rect(Rect2(0, 0, 427, 240), graphics.blackout)
#		graphics.blackout = null
#
#	if len(graphics.pixels) == 0 or len(graphics.colors) == 0 \
#		or len(graphics.pixels) != len(graphics.colors):
#		return
#
#	for x in range(len(graphics.pixels)):
#		var pixel = graphics.pixels[x]
#		var color = graphics.colors[x]
#		draw_rect(Rect2(pixel.x, pixel.y, 1, 1), color)

func program_start():
#	print("Very first main entered\n");

	graphics.pixels = []
	graphics.colors = []
	
	graphics.classicMain = self
	
	graphics.editableScreen = editableScreen

	graphics.flipColor = 0;

	mySpaceGlobals = {};
	mySpaceGlobals.graphics = graphics;
#	print("Space globals initialized\n");

	# Flag for restarting the entire game.
	mySpaceGlobals.restart = 1;

	# initial state is title screen
	mySpaceGlobals.state = 1;
	mySpaceGlobals.titleScreenRefresh = 1;

	# Flags for render states
	mySpaceGlobals.renderResetFlag = 0;
	mySpaceGlobals.menuChoice = 0; #  0 is play, 1 is password
	
	mySpaceGlobals.passwordList = []
	mySpaceGlobals.title = null
	mySpaceGlobals.orig_ship = null
	mySpaceGlobals.enemy = null
	
	mySpaceGlobals.lives = 4
	
	mySpaceGlobals.p1X = 0
	mySpaceGlobals.p1Y = 0
	mySpaceGlobals.angle = 0
	mySpaceGlobals.frame = 0
	


	# setup the password list
	var pwSeed = 27;
	var trigmath = PRandom.new(pwSeed)
	for x in range(100):
		mySpaceGlobals.passwordList.append(int(trigmath.prand()*100000))

#	print("About to set the time\n");
	#  set the starting time
	randomize()
	mySpaceGlobals.seed = randi()
#	print("Set the time!\n");

	var pad_data = {}

	#  decompress compressed things into their arrays, final argument is the transparent color in their palette
	var images = Images.new()
	var draw = Draw.new()
	space = Space.new(mySpaceGlobals)
#	print("Initialized space object")
#
#	#  setup palette and transparent index
	mySpaceGlobals.curPalette = images.ship_palette;
	mySpaceGlobals.transIndex = 14;

	mySpaceGlobals.passwordEntered = 0;
	mySpaceGlobals.quit = 0;

	#  initialize starfield for this game
	space.initStars(mySpaceGlobals);

	mySpaceGlobals.invalid = 1;
#	print("About to enter main loop\n");
#
	mySpaceGlobals.touched = 0
	mySpaceGlobals.touchX = 0
	mySpaceGlobals.touchY = 0

func _process(delta):
	# redraw every frame, like old space game handled it
	a += 1
	
	# get lock for drawing
	editableScreen.lock()

	# Get the status of the controller
	mySpaceGlobals.buttonA = Input.is_action_pressed("ui_accept")
	mySpaceGlobals.buttonB = Input.is_action_pressed("ui_cancel")
	mySpaceGlobals.buttonUP    = Input.is_action_pressed("ui_up")
	mySpaceGlobals.buttonDOWN  = Input.is_action_pressed("ui_down")
	mySpaceGlobals.buttonRIGHT = Input.is_action_pressed("ui_right")
	mySpaceGlobals.buttonLEFT  = Input.is_action_pressed("ui_left")

	mySpaceGlobals.rstick_x = 0
	mySpaceGlobals.lstick_x = 0
	mySpaceGlobals.rstick_y = 0
	mySpaceGlobals.lstick_y = 0

	mySpaceGlobals.touched = Input.is_mouse_button_pressed(1)

	if (mySpaceGlobals.touched):
		var pos = self.get_global_mouse_position()
		mySpaceGlobals.touchX = pos.x / 2; #  (( / 9) - 11);
		mySpaceGlobals.touchY = pos.y / 2; #  ((3930 - vpad_data.touched_y) / 16);
		print(mySpaceGlobals.touchX, " ", mySpaceGlobals.touchY)

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
#			if (mySpaceGlobals.lives <= 0 && mySpaceGlobals.state == 4):
#				return

		#  add any new enemies
		space.addNewEnemies(mySpaceGlobals);

		# Render the scene
		space.render(mySpaceGlobals);

		#  check for pausing
		space.checkPause(mySpaceGlobals);
		
	editableScreen.unlock()
	screenTexture.set_data(editableScreen)
	screenImage.texture = screenTexture

	# To exit the game
#		if (mySpaceGlobals.button & PAD_BUTTON_MINUS):
#			break;

