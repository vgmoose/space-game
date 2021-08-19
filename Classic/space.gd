extends Node2D
class_name Space

# This class is a bit of a mess, but it basically does "everything else" in the game.
# The most vareresting function is rotating the bitmap (makeRotationMatrix).
#
# Other things it handles:
#	- Joystick input (p1Move)
#	- Bullet firing (p1Shoot)
#	- Star draw.drawing (renderStars)
#	- Status bar draw.drawing (renderTexts)
#	- Decompressing sprites (decompress_bitmap)
#	- Handling the menu at the title screen (doMenuAction)
#
# It relies heavily on a SpaceGlobals struct defined in space.h. This is a carry over from the libwiiu
# pong example, but also I believe neccesary since global variables don't seem to be able to be set(?)

var xMinBoundry = 0
var xMaxBoundry = 427
var yMinBoundry = 0
var yMaxBoundry = 240

var MAX_ENEMIES = 100

#var target = 
var images = Images.new()

var orig_ship = []
var rotated_ship = []
var title = []

var enemy_palette = images.enemy_palette
var title_palette = images.title_palette
var compressed_ship = images.compressed_ship
var compressed_ship2 = images.compressed_ship2
var ship_palette = images.ship_palette
var ship2_palette = images.ship2_palette
#var compressed_boss = images.compressed_boss
#var boss_palette = images.boss_palette
#var compressed_boss2 = images.compressed_boss2
#var boss2_palette = images.boss2_palette

var draw
var trigmath

var BULLET_COUNT = 20

# the original Space Game uses a few different speeds (bullet, player, enemies)
# but it didn't run at a reliable 60 fps (1/60 deltas)
# 30 fps "felt" too slow, so let's go with 40 fps
# as a baseline for how fast the game should expect to move
# this multiplier will modify all original game speeds to scale them back
# to one that feels more like how it ran on console
# it can be removed with password 60185
var FPS_MULT = 40

var spedUpMusic

func initBullets(mySpaceGlobals):
	mySpaceGlobals["bullets"] = []
	for x in range(BULLET_COUNT):
		var bullet = {
			"x": 0,
			"y": 0,
			"m_x": 0,
			"m_y": 0,
			"active": 0
		}
		mySpaceGlobals.bullets.append(bullet)

func _init(mySpaceGlobals):
	draw = Draw.new()
	trigmath = PRandom.new(mySpaceGlobals.seed)
	mySpaceGlobals["invalid"]= 1
	
	mySpaceGlobals["enemy"] = []
	
	spedUpMusic = load("res://Classic/speedcruise.mp3")
	
	for x in range(36):
		rotated_ship.append([])
		for y in range(36):
			rotated_ship[len(rotated_ship) - 1].append(0)

	for x in range(36):
		orig_ship.append([])
		for y in range(36):
			orig_ship[len(orig_ship) - 1].append(0)
	
	for x in range(100):
		title.append([])
		for y in range(200):
			title[len(title) - 1].append(0)
	
	for x in range(23):
		mySpaceGlobals.enemy.append([])
		for y in range(23):
			mySpaceGlobals.enemy[len(mySpaceGlobals.enemy) - 1].append(0)
			
	decompress_sprite(3061, 200, 100, images.compressed_title, title, 39);
	decompress_sprite(511, 36, 36, images.compressed_ship, orig_ship, 14);
	decompress_sprite(206, 23, 23, images.compressed_enemy, mySpaceGlobals.enemy, 9);
	
	initBullets(mySpaceGlobals)
	
	mySpaceGlobals["enemies"] = []
	for x in range(MAX_ENEMIES):
		var pos = {
			"x": 0,
			"y": 0,
			"m_x": 0,
			"m_y": 0,
			"active": 1
		}
		var enemy = {
			"position": pos,
			"angle": 0
		}
		var rotated_sprite = []
		for y in range(23):
			rotated_sprite.append([])
			for z in range(23):
				rotated_sprite[len(rotated_sprite) - 1].append(0)
		enemy["rotated_sprite"] = rotated_sprite
		mySpaceGlobals.enemies.append(enemy)

func blackout(g):
	g.labelController.makeAllInvisible()
	draw.fillScreen(g, 0,0,0,1)

func increaseScore(mySpaceGlobals, inc):

	# count the number of 5000s that fit into the score before adding
	var fiveThousandsBefore = mySpaceGlobals.score / 5000;

	# increase the score
	mySpaceGlobals.score += inc;

	# count them again
	var fiveThousandsAfter = mySpaceGlobals.score / 5000;

	# if it increased, levelup
	if (fiveThousandsAfter > fiveThousandsBefore):
		mySpaceGlobals.level += 1

func p1Shoot(mySpaceGlobals):

	if (mySpaceGlobals.playerExplodeFrame > 1):
		return;

	var xdif = 0;
	var ydif = 0;

	xdif = mySpaceGlobals.p1X - (mySpaceGlobals.p1X + (mySpaceGlobals.rstick_x * 18));
	ydif = mySpaceGlobals.p1Y - (mySpaceGlobals.p1Y + (mySpaceGlobals.rstick_y * 18));

	# if no joysticks were touched, but a touch is present
	if (xdif == 0 && ydif == 0 && mySpaceGlobals.touched):
		xdif = (mySpaceGlobals.p1X - mySpaceGlobals.touchX + 18);
		ydif = (mySpaceGlobals.p1Y - mySpaceGlobals.touchY + 18);

	if (xdif != 0 && ydif != 0):
		mySpaceGlobals.angle = atan2(xdif, ydif);

		# shoot a bullet
		# find an inactive bullet
		var theta = mySpaceGlobals.angle - PI

		var bulletsShot = int(mySpaceGlobals.doubleShot)
		for xx in range(BULLET_COUNT):
			if (mySpaceGlobals.bullets[xx].active != 1):
				var offsetX = int(bulletsShot==1)*9*cos(-theta) - int(bulletsShot==2)*9*cos(-theta)
				var offsetY = int(bulletsShot==1)*9*sin(-theta) - int(bulletsShot==2)*9*sin(-theta)
				bulletsShot += 1
				mySpaceGlobals.bullets[xx].x = mySpaceGlobals.p1X + 18 + offsetX;
				mySpaceGlobals.bullets[xx].y = mySpaceGlobals.p1Y + 18 + offsetY;
				mySpaceGlobals.bullets[xx].m_x = 9 * sin(theta); # 9 is the desired bullet speed
				mySpaceGlobals.bullets[xx].m_y = 9 * cos(theta); # we have to solve for the hypotenuese
				mySpaceGlobals.bullets[xx].active = 1;
				mySpaceGlobals.firstShotFired = 1;
				if (mySpaceGlobals.score >= 1000):
					mySpaceGlobals.displayHowToPlay = 0;
				if not mySpaceGlobals.tripleShot or bulletsShot >= 3:
					break;

	moveBullets(mySpaceGlobals);

#Updates player1 location
func p1Move(mySpaceGlobals):

	# can't move while exploding
	if (mySpaceGlobals.playerExplodeFrame > 1):
		return;

	# Handle analog stick movements
	var left_x = mySpaceGlobals.lstick_x;
	var left_y = mySpaceGlobals.lstick_y;

	# get the differences
	var xdif = left_x;
	var ydif = left_y;

	# Handle D-pad movements as well
	# max out speed at 1 or -1 in both directions
	xdif =  1 if (xdif >  1 || mySpaceGlobals.buttonRIGHT) else xdif;
	xdif = -1 if (xdif < -1 || mySpaceGlobals.buttonLEFT)  else xdif;
	ydif = -1 if (ydif < -1 || mySpaceGlobals.buttonUP)    else ydif;
	ydif =  1 if (ydif >  1 || mySpaceGlobals.buttonDOWN)  else ydif;

	# don't update angle if both are within -.1 < x < .1
	# (this is an expensive check... 128 bytes compared to just ==0)
	if (xdif < 0.1 && xdif > -0.1 && ydif < 0.1 && ydif > -0.1): return;

	# invalid view
	mySpaceGlobals.invalid = 1;

	# accept x and y movement from either stick
	var playerMaxSpeed = 5 * FPS_MULT * mySpaceGlobals.delta
	mySpaceGlobals.p1X += xdif * playerMaxSpeed;
	mySpaceGlobals.p1Y += ydif * playerMaxSpeed;

	# calculate angle to face
	mySpaceGlobals.angle = atan2(-ydif, xdif) - PI / 2.0;

	# update score if on a frame divisible by 60 (gain ~10 points every second)
	if (mySpaceGlobals.frame % 60 == 0):
		increaseScore(mySpaceGlobals, 10);

		# if the score is at least 50 and a shot hasn't been fired yet, display a message about shooting
		if (mySpaceGlobals.score >= 50 && !mySpaceGlobals.firstShotFired):
			mySpaceGlobals.displayHowToPlay = 1;

func checkPause(mySpaceGlobals):
	if (mySpaceGlobals.buttonPLUS):
		# switch to the pause state and mark view as invalid
		mySpaceGlobals.state = 3;
		mySpaceGlobals.invalid = 1;

func handleCollisions(mySpaceGlobals):

	var playerLeft = mySpaceGlobals.p1X;
	var playerRight = playerLeft + 36;
	var playerUp = mySpaceGlobals.p1Y;
	var playerDown = playerUp + 36;

	# don't let the player go offscreen
	if (playerLeft < xMinBoundry):
		mySpaceGlobals.p1X = xMinBoundry;
	if (playerRight > xMaxBoundry):
		mySpaceGlobals.p1X = xMaxBoundry - 36;
	if (playerUp < yMinBoundry + 20):
		mySpaceGlobals.p1Y = yMinBoundry + 20;
	if (playerDown > yMaxBoundry):
		mySpaceGlobals.p1Y = yMaxBoundry - 36;

	# check enemies if they collide with the player or any of the 20 active bullets
	for x in range(MAX_ENEMIES):
		if (mySpaceGlobals.enemies[x].position.active == 1):
			# collision checkin from here: http:#stackoverflow.com/a/1736741/1137828
			# check player

			var sqMe1 = ((mySpaceGlobals.enemies[x].position.x+7)-(mySpaceGlobals.p1X+9));
			var sqMe2 = ((mySpaceGlobals.enemies[x].position.y+7)-(mySpaceGlobals.p1Y+9));

			if (sqMe1*sqMe1 + sqMe2*sqMe2 <= (7+9)*(7+9)):
				if (mySpaceGlobals.playerExplodeFrame < 1):
					# player was hit
					mySpaceGlobals.playerExplodeFrame = 2;
					initGameState(mySpaceGlobals);
			for y in range(BULLET_COUNT):
				if (mySpaceGlobals.bullets[y].active == 1):
					sqMe1 = ((mySpaceGlobals.enemies[x].position.x+7)-(mySpaceGlobals.bullets[y].x+1));
					sqMe2 = ((mySpaceGlobals.enemies[x].position.y+7)-(mySpaceGlobals.bullets[y].y+1));

					if (sqMe1*sqMe1 + sqMe2*sqMe2 <= (7+1)*(7+1)):
						# enemy was hit, active = 2 is explode
						increaseScore(mySpaceGlobals, 100); # 100 points for killing enemy
						mySpaceGlobals.enemies[x].position.active = 2;

						# bullet is destroyed with enemy
						mySpaceGlobals.bullets[y].active = 0;
						break;

func makeScaleMatrix(frame, width, original, target, transIndex):

	for x in range(width):
		for y in range(width):
			target[x][y] = transIndex;
	var woffset = width/2;

	for x in range(width):
		for y in range(width):
			# rotate the pixel by the angle varo a new spot in the rotation matrix
			var newx = int((x-woffset)*frame + woffset);
			var newy = int((y-woffset)*frame + woffset);
			
			if (newx < 0 || newx >= width): continue;
			if (newy < 0 || newy >= width): continue;

			if (original[newx][newy] == transIndex): continue;

			target[newx][newy] = original[x][y];

func handleExplosions(mySpaceGlobals):
	
	# explode "animation" plays at half-speed, to be more visible
	var explosionCounter = 0.5

	for x in range(MAX_ENEMIES):
		if (mySpaceGlobals.enemies[x].position.active > 1):
			makeScaleMatrix(mySpaceGlobals.enemies[x].position.active/2.0, 23, mySpaceGlobals.enemy, mySpaceGlobals.enemies[x].rotated_sprite, 9);
			mySpaceGlobals.enemies[x].position.active += explosionCounter

			if (mySpaceGlobals.enemies[x].position.active > 20):
				mySpaceGlobals.enemies[x].position.active = 0;

	if (mySpaceGlobals.playerExplodeFrame > 1):
		makeScaleMatrix(mySpaceGlobals.playerExplodeFrame, 36, orig_ship, rotated_ship, mySpaceGlobals.transIndex);
		mySpaceGlobals.playerExplodeFrame += explosionCounter
		mySpaceGlobals.invalid = 1;

		if (mySpaceGlobals.playerExplodeFrame > 20):
			mySpaceGlobals.playerExplodeFrame = 0;
			mySpaceGlobals.lives -= 1;
			if (mySpaceGlobals.lives <= 0):
				# game over!
				mySpaceGlobals.state = 4;
				mySpaceGlobals.invalid = 1;
			else:
				mySpaceGlobals.renderResetFlag = 1;

func makeRotationMatrix(angle, width, original, target, transIndex):

	for x in range(width):
		for y in range(width):
			target[x][y] = transIndex;

	var woffset = width/2.0;

	# go though every pixel in the target bitmap
	for ix in range(width):
		for iy in range(width):
			# rotate the pixel by the angle varo a new spot in the rotation matrix
			var oldx = int((ix-woffset)*cos(angle) + (iy-woffset)*sin(angle) + woffset);
			var oldy = int((ix-woffset)*sin(angle) - (iy-woffset)*cos(angle) + woffset);

			if (oldx > width): oldx = width-1;
			if (oldy > width): oldy = width-1;

#			if (original[oldx][oldy] == transIndex): continue;

			if (oldx < 0 || oldx >= width): continue;
			if (oldy < 0 || oldy >= width): continue;

			# TODO: crashes with this below line! When trying to assign to target, but only after doing the above math
			target[ix][iy] = original[oldx][oldy];

func renderEnemies(mySpaceGlobals):

	# for all active bullets, advance them
	for x in range(BULLET_COUNT):
		if (mySpaceGlobals.bullets[x].active == 1):
			for z in range(4):
				for za in range(2):
					draw.drawPixel(mySpaceGlobals.graphics, mySpaceGlobals.bullets[x].x + z, mySpaceGlobals.bullets[x].y + za, 255, 0, 0);

	# for all active enemies, advance them
	for x in range(MAX_ENEMIES): # up to 100 enemies at once
		if (mySpaceGlobals.enemies[x].position.active >= 1):
			draw.drawBitmap(mySpaceGlobals.graphics, mySpaceGlobals.enemies[x].position.x, mySpaceGlobals.enemies[x].position.y, 23, 23, mySpaceGlobals.enemies[x].rotated_sprite, enemy_palette);

func render(mySpaceGlobals):

	if (mySpaceGlobals.invalid == 1):
		blackout(mySpaceGlobals.graphics);

		mySpaceGlobals.frame += 1;

		if (mySpaceGlobals.renderResetFlag):
			renderReset(mySpaceGlobals);

		renderStars(mySpaceGlobals);
		renderEnemies(mySpaceGlobals);
		renderShip(mySpaceGlobals);
		renderTexts(mySpaceGlobals);

		draw.flipBuffers(mySpaceGlobals.graphics);
		mySpaceGlobals.invalid = 0;

# see the notes in images.c for more info on how this works
func decompress_sprite(arraysize, width, height, input, target, transIndex):

	var cx = 0
	var cy = 0;
	var posinrow = 0;
	# go through input array
	var x = 0
	while x < arraysize:
		var count = input[x];
		var value = input[x+1];

		if (count == -120): # full value rows of last index in palette
			for z in range(value):
				for za in range(width):
					target[cy+z][cx+za] = transIndex;
			cy += value;
			x += 2
			continue;

		if (count <= 0): # if it's negative, -count is value, and value is meaningless and advance by one
			value = -1*count;
			count = 1;
			x -= 1; # subtract one, so next time it goes up by 2, putting us at x+1

		for z in range(count):
			target[cy][cx] = value;
			cx += 1;

		posinrow += count
		if (posinrow >= width):
			posinrow = 0;
			cx = 0;
			cy+= 1;
		x += 2

func moveBullets(mySpaceGlobals):

	# for all active bullets, advance them
	for x in range(BULLET_COUNT):
		if (mySpaceGlobals.bullets[x].active == 1):
			mySpaceGlobals.bullets[x].x += mySpaceGlobals.bullets[x].m_x * FPS_MULT * mySpaceGlobals.delta
			mySpaceGlobals.bullets[x].y += mySpaceGlobals.bullets[x].m_y * FPS_MULT * mySpaceGlobals.delta

			if (mySpaceGlobals.bullets[x].x > xMaxBoundry ||
				mySpaceGlobals.bullets[x].x < xMinBoundry ||
				mySpaceGlobals.bullets[x].y > yMaxBoundry ||
				mySpaceGlobals.bullets[x].y < yMinBoundry + 20):
				mySpaceGlobals.bullets[x].active = 0;

			mySpaceGlobals.invalid = 1;

	for x in range(MAX_ENEMIES):
		if (mySpaceGlobals.enemies[x].position.active == 1):
			mySpaceGlobals.enemies[x].position.x += mySpaceGlobals.enemies[x].position.m_x * FPS_MULT * mySpaceGlobals.delta;
			mySpaceGlobals.enemies[x].position.y += mySpaceGlobals.enemies[x].position.m_y * FPS_MULT * mySpaceGlobals.delta;

			if (mySpaceGlobals.enemies[x].position.x > xMaxBoundry ||
				mySpaceGlobals.enemies[x].position.x < xMinBoundry ||
				mySpaceGlobals.enemies[x].position.y > yMaxBoundry ||
				mySpaceGlobals.enemies[x].position.y < yMinBoundry + 20):
				mySpaceGlobals.enemies[x].position.active = 0;

			# rotate the enemy slowly
			mySpaceGlobals.enemies[x].angle += 0.02 * FPS_MULT * mySpaceGlobals.delta;
			if (mySpaceGlobals.enemies[x].angle > 6.28318530):
				mySpaceGlobals.enemies[x].angle = 0.0;

			# TODO: the below crashes... with angle instead of 0
			makeRotationMatrix(mySpaceGlobals.enemies[x].angle, 23, mySpaceGlobals.enemy, mySpaceGlobals.enemies[x].rotated_sprite, 9);

			mySpaceGlobals.invalid = 1;

func renderTexts(mySpaceGlobals):

#	draw.fillRect(mySpaceGlobals.graphics, 0, 0, xMaxBoundry, 20, 0, 0, 0);

	var score
	if (mySpaceGlobals.dontKeepTrackOfScore == 1):
		score = "Score: N/A"
	else:
		score = "Score: %09d" % mySpaceGlobals.score
	draw.drawString(mySpaceGlobals.graphics, 0, 0, score);

	var level = "   Lv %d" % (mySpaceGlobals.level+1)
	draw.drawString(mySpaceGlobals.graphics, 27, 0, level);

	var lives = "   Lives: %d" % mySpaceGlobals.lives
	draw.drawString(mySpaceGlobals.graphics, 52, 0, lives);

	if (mySpaceGlobals.displayHowToPlay):
		var nag = "Rapid fire with right stick or touch!"
		draw.drawString(mySpaceGlobals.graphics, 17, 17, nag);

func renderShip(mySpaceGlobals):

	var posx = int(mySpaceGlobals.p1X);
	var posy = int(mySpaceGlobals.p1Y);

	if (mySpaceGlobals.playerExplodeFrame < 2):
		makeRotationMatrix(mySpaceGlobals.angle, 36, orig_ship, rotated_ship, mySpaceGlobals.transIndex);

	draw.drawBitmap(mySpaceGlobals.graphics, posx, posy, 36, 36, rotated_ship, mySpaceGlobals.curPalette);

func renderStars(mySpaceGlobals):

	# don't draw.draw stars if the player is on their last life and died
	if (mySpaceGlobals.lives == 1 && mySpaceGlobals.playerExplodeFrame > 1):
		return;

	draw.drawPixels(mySpaceGlobals.graphics, mySpaceGlobals.stars);

#Reset the game
func reset(mySpaceGlobals):
	mySpaceGlobals["button"] = 0;

	#Set flag to render reset screen;
	mySpaceGlobals.renderResetFlag = 1;

func initGameState(mySpaceGlobals):

#	# init bullets
	for x in range(BULLET_COUNT):
		mySpaceGlobals.bullets[x].active = 0;

	# init enemies
	for x in range(MAX_ENEMIES):
		mySpaceGlobals.enemies[x].position.active = 0;
		mySpaceGlobals.enemies[x].angle = 3.14;
		makeRotationMatrix(0, 23, mySpaceGlobals.enemy, mySpaceGlobals.enemies[x].rotated_sprite, 9);


func initStars(mySpaceGlobals):

	mySpaceGlobals["stars"] = []

	# create the stars randomly
	for x in range(200):
		var star = {
			"x": 0,
			"y": 0,
			"r": 0,
			"g": 0,
			"b": 0
		}
		mySpaceGlobals.stars.append(star)
		mySpaceGlobals.stars[x].x = int(trigmath.prand()*xMaxBoundry);
		mySpaceGlobals.stars[x].y = int(trigmath.prand()*yMaxBoundry);
		var randomNum = int(trigmath.prand()*4);
#
#		# half of the time make them white, 1/4 yellow, 1/4 blue
		mySpaceGlobals.stars[x].r = 255 if (randomNum <= 2) else 0;
		mySpaceGlobals.stars[x].g = 255 if (randomNum <= 2) else 0;
		mySpaceGlobals.stars[x].b = 255 if (randomNum != 2) else 0;

func displayTitle(mySpaceGlobals):

	if (mySpaceGlobals.invalid == 1):
#		print("Blacking out\n");
		blackout(mySpaceGlobals.graphics);

#		print("draw.drawing stars\n");
		# draw.draw some stars
		renderStars(mySpaceGlobals);
#		print("draw.drawing \"text\"\n");

		# display the bitmap in upper center screen
		draw.drawBitmap(mySpaceGlobals.graphics, 107, 30, 200, 100, title, title_palette);

		var credits = "  by vgmoose";

		var musiccredits = "~*cruise*~ by (T-T)b"

		var license = "MIT License"

		var play = "Start Game"
		var password = " Password"

		#display the menu under it
		draw.drawString(mySpaceGlobals.graphics, 35, 10, credits);
		draw.drawString(mySpaceGlobals.graphics, 25, 13, play);
		draw.drawString(mySpaceGlobals.graphics, 25, 14, password);

		draw.drawString(mySpaceGlobals.graphics, 40, 17, musiccredits);
		draw.drawString(mySpaceGlobals.graphics, 0, 17, license);

		drawMenuCursor(mySpaceGlobals);

		draw.flipBuffers(mySpaceGlobals.graphics);
		mySpaceGlobals.invalid = 0;

func drawMenuCursor(mySpaceGlobals):

	# cover up any old cursors (used to be needed before changing to draw.draw everything mode)
	draw.fillRect(mySpaceGlobals.graphics, 138, 164, 16, 30, 0, 0, 0);
	draw.fillRect(mySpaceGlobals.graphics, 250, 164, 16, 30, 0, 0, 0);

	# display the cursor on the correct item
	var cursor = "[[            ]]"
	draw.drawString(mySpaceGlobals.graphics, 21, 13 + mySpaceGlobals.menuChoice, cursor);

func doMenuAction(mySpaceGlobals):

	# if we've seen the A button and B button not being pressed
	if (!(mySpaceGlobals.buttonA) && !(mySpaceGlobals.buttonB)):
		mySpaceGlobals.allowInput = 1;

	# title screen and B was pressed, exit fully
	if (mySpaceGlobals.state == 1 && mySpaceGlobals.buttonB && mySpaceGlobals.allowInput):
		mySpaceGlobals.quit = 1;

	if (mySpaceGlobals.buttonA && mySpaceGlobals.allowInput):
		# if we're on the title menu
		if (mySpaceGlobals.state == 1):
			if (mySpaceGlobals.menuChoice == 0):
				totallyRefreshState(mySpaceGlobals);

				# start game chosen
				mySpaceGlobals.state = 7; # switch to game state
				mySpaceGlobals.renderResetFlag = 1; # redraw.draw screen
			elif (mySpaceGlobals.menuChoice == 1):
				# password screen chosen
				mySpaceGlobals.state = 2;

		# password screen
#		elif (mySpaceGlobals.state == 2):
#		{
#			# this is handled by the password menu action function
#		}
		# pause screen
		elif (mySpaceGlobals.state == 3):
			if (mySpaceGlobals.menuChoice == 0):
				# resume chosen
				mySpaceGlobals.state = 7; # switch to game state

			elif (mySpaceGlobals.menuChoice == 1):
				# quit chosen
				totallyRefreshState(mySpaceGlobals);
				mySpaceGlobals.state = 1;
		# game over screen
		elif (mySpaceGlobals.state == 4):
			totallyRefreshState(mySpaceGlobals);

			if (mySpaceGlobals.menuChoice == 0):
				# try again chosen

				#player stays on the same level
				mySpaceGlobals.state = 7; # switch to game state

			elif (mySpaceGlobals.menuChoice == 1):
				# quit chosen
				mySpaceGlobals.state = 1;

		# reset the choice
		mySpaceGlobals.menuChoice = 0;

		# disable menu input after selecting to prevent double selects
		mySpaceGlobals.allowInput = 0;

		# mark view invalid to redraw.draw
		mySpaceGlobals.invalid = 1;

	var stickY = mySpaceGlobals.lstick_y + mySpaceGlobals.rstick_y;

	if (mySpaceGlobals.buttonDOWN || stickY > 0.3):
		mySpaceGlobals.menuChoice = 1;
		mySpaceGlobals.invalid = 1;

	if (mySpaceGlobals.buttonUP || stickY < -0.3):
		mySpaceGlobals.menuChoice = 0;
		mySpaceGlobals.invalid = 1;

func displayPause(mySpaceGlobals):

	if (mySpaceGlobals.invalid == 1):
		blackout(mySpaceGlobals.graphics);

		# display the password here
		var resume = "Resume"
		var quit = " Quit"

		draw.drawString(mySpaceGlobals.graphics, 27, 13, resume);
		draw.drawString(mySpaceGlobals.graphics, 27, 14, quit);

		drawMenuCursor(mySpaceGlobals);

		draw.flipBuffers(mySpaceGlobals.graphics);
		mySpaceGlobals.invalid = 0;
		
enum { A, B, X, Y, Z, UP, DOWN, LEFT, RIGHT }
func doPasswordMenuAction(mySpaceGlobals):

	# if we've seen up, down, left, right, and a buttons not being pressed
	if (!(mySpaceGlobals.buttonA   ||
		mySpaceGlobals.buttonUP    ||
		mySpaceGlobals.buttonDOWN  ||
		mySpaceGlobals.buttonLEFT  ||
		mySpaceGlobals.buttonRIGHT   )):
		mySpaceGlobals.allowInput = 1;

	if (mySpaceGlobals.allowInput):
		if (mySpaceGlobals.buttonB):
			# go back to title screen
			mySpaceGlobals.state = 1;

			# update the menu choice
			mySpaceGlobals.menuChoice = 0;

			# disable menu input after selecting to prevent double selects
			mySpaceGlobals.allowInput = 0;

			# mark view invalid to redraw.draw
			mySpaceGlobals.invalid = 1;

		if (mySpaceGlobals.buttonA):
			# try the password
			tryPassword(mySpaceGlobals);

			# disable menu input after selecting to prevent double selects
			mySpaceGlobals.allowInput = 0;

			# update the menu choice
			mySpaceGlobals.menuChoice = 0;

			# mark view invalid to redraw.draw
			mySpaceGlobals.invalid = 1;

		var stickY = mySpaceGlobals.lstick_y + mySpaceGlobals.rstick_y;
		var stickX = mySpaceGlobals.lstick_x + mySpaceGlobals.rstick_x;
		var down   = (mySpaceGlobals.buttonDOWN  || stickY < -0.3);
		var up     = (mySpaceGlobals.buttonUP    || stickY >  0.3);
		var left   = (mySpaceGlobals.buttonLEFT  || stickX < -0.3);
		var right  = (mySpaceGlobals.buttonRIGHT || stickX >  0.3);

		if (up || down):
			var offset = 1
			# keep going up in the 10s place to match current choice
			for x in range(4 - mySpaceGlobals.menuChoice):
				offset *= 10;

			if (up):
				mySpaceGlobals.passwordEntered += offset;
			if (down):
				mySpaceGlobals.passwordEntered -= offset;

			mySpaceGlobals.invalid = 1;
			mySpaceGlobals.allowInput = 0;

		if (left || right):
			if (right):
				mySpaceGlobals.menuChoice += 1;
			if (left):
				mySpaceGlobals.menuChoice -= 1;

			# bound the menu choices
			if (mySpaceGlobals.menuChoice < 0):
				mySpaceGlobals.menuChoice = 0;
			if (mySpaceGlobals.menuChoice > 4):
				mySpaceGlobals.menuChoice = 4;

			mySpaceGlobals.invalid = 1;
			mySpaceGlobals.allowInput = 0;

		# bound the password
		if (mySpaceGlobals.passwordEntered < 0):
			mySpaceGlobals.passwordEntered = 0;
		if (mySpaceGlobals.passwordEntered > 99999):
			mySpaceGlobals.passwordEntered = 99999;

func displayPasswordScreen(mySpaceGlobals):

	if (mySpaceGlobals.invalid == 1):
		blackout(mySpaceGlobals.graphics);

#		draw.drawPasswordMenuCursor(mySpaceGlobals);
		var password = "Password:"
		var up_cur = [" ", " ", " ", " ", " "]
		var cur_pw = "%05d" % mySpaceGlobals.passwordEntered
		var down_cur = [" ", " ", " ", " ", " "]

		# draw.draw arrow cursor varo cursor strings
		up_cur[mySpaceGlobals.menuChoice] = 'v';
		down_cur[mySpaceGlobals.menuChoice] = '^';

		draw.drawString(mySpaceGlobals.graphics, 19, 8, password);

		draw.drawString(mySpaceGlobals.graphics, 32, 7, "%s%s%s%s%s" % up_cur)
		draw.drawString(mySpaceGlobals.graphics, 32, 8, cur_pw);
		draw.drawString(mySpaceGlobals.graphics, 32, 9, "%s%s%s%s%s" % down_cur)

		draw.flipBuffers(mySpaceGlobals.graphics);
		mySpaceGlobals.invalid = 0;

func addNewEnemies(mySpaceGlobals):

	if (mySpaceGlobals.noEnemies || mySpaceGlobals.playerExplodeFrame > 1):
		return;

	# here we make a new enemy with a certain speed based on the level

	# get a random position from one of the sides with a random var 0-3
	var side = int(trigmath.prand()*4);

#	# randomly decide to set starting angle right for the player
#	var seekPlayer = trigmath.prand(mySpaceGlobals.seed)*2;

	var difficulty = mySpaceGlobals.level/100.0;

	var randVal = trigmath.prand();

	# set the enemy count (max enemies on screen at once) based on level
	var enemyCount = 10 + difficulty*90*randVal;

	if (enemyCount > 100): enemyCount = 100;

	# set speed randomly within difficulty range
	var speed = 3 + (difficulty)*12*randVal;

	var startx
	var starty

	var theta = trigmath.prand()*PI;
	randVal = trigmath.prand();

	# horiz size
	if (side < 2):
		startx = 0 if (side == 0) else xMaxBoundry;
		starty = randVal*yMaxBoundry;

		if (startx != 0):
			theta -= PI;
	else:
		starty = 20 if (side == 2) else yMaxBoundry;
		startx = randVal*xMaxBoundry;

		if (starty == 20):
			theta -= PI / 2.0;
		else:
			theta += PI / 2.0;

	# seek directly to the player
	if (mySpaceGlobals.enemiesSeekPlayer == 1):
		var xdif = startx + 11 - (mySpaceGlobals.p1X + 18);
		var ydif = starty + 11 - (mySpaceGlobals.p1Y + 18);

		theta = atan2(xdif, ydif) - PI;

	for xx in range(enemyCount):
		if (mySpaceGlobals.enemies[xx].position.active == 0):
			mySpaceGlobals.enemies[xx].position.x = startx;
			mySpaceGlobals.enemies[xx].position.y = starty;
			mySpaceGlobals.enemies[xx].position.m_x = speed*sin(theta); # speed is the desired enemy speed
			mySpaceGlobals.enemies[xx].position.m_y = speed*cos(theta); # we have to solve for the hypotenuese
			mySpaceGlobals.enemies[xx].position.active = 1;
			break;

func totallyRefreshState(mySpaceGlobals):

	initGameState(mySpaceGlobals);
	mySpaceGlobals["displayHowToPlay"] = 0;
	mySpaceGlobals["firstShotFired"] = 0;
	mySpaceGlobals["lives"] = 3;
	mySpaceGlobals["playerExplodeFrame"] = 0;
	mySpaceGlobals["score"] = 0;
	mySpaceGlobals["level"] = 0;
	mySpaceGlobals["dontKeepTrackOfScore"] = int(mySpaceGlobals.doubleShot or mySpaceGlobals.tripleShot)
	mySpaceGlobals["noEnemies"] = 0;
	mySpaceGlobals["enemiesSeekPlayer"] = 0;

func displayGameOver(mySpaceGlobals):
	
	if (mySpaceGlobals.invalid == 1):
		blackout(mySpaceGlobals.graphics);

		var gameover = "Game Over!"
		draw.drawString(mySpaceGlobals.graphics, 25, 5, gameover);

		# only display score + pw if the player didn't use cheats
		if (mySpaceGlobals.dontKeepTrackOfScore != 1):
			var finalscore = "Score: %08d" % mySpaceGlobals.score
			var passw = "Lv %d Password: %05d" % [mySpaceGlobals.level+1, mySpaceGlobals.passwordList[mySpaceGlobals.level]]

			draw.drawString(mySpaceGlobals.graphics, 23, 7, finalscore);
			draw.drawString(mySpaceGlobals.graphics, 21, 8, passw);

		var resume = "Try Again"
		var quit = "   Quit"

		draw.drawString(mySpaceGlobals.graphics, 25, 13, resume);
		draw.drawString(mySpaceGlobals.graphics, 25, 14, quit);

		self.drawMenuCursor(mySpaceGlobals);

		draw.flipBuffers(mySpaceGlobals.graphics);
		mySpaceGlobals.invalid = 0;


func tryPassword(mySpaceGlobals):

	# Dear Github Viewer,
	#
	# 		Well, here's where you see the passwords I guess!
	#		With the exception of a few hardcoded ones, the
	#		level passwords are generated and checked against
	#		a seeded random list from program.c
	#
	# Enjoy!

	# Invincibility
	if (mySpaceGlobals.passwordEntered == 55225):
		mySpaceGlobals.playerExplodeFrame = 1;
		mySpaceGlobals.dontKeepTrackOfScore = 1;
		mySpaceGlobals.state = 7;

	# 99 Lives
	if (mySpaceGlobals.passwordEntered == 99499):
	
		mySpaceGlobals.lives = 99;
		mySpaceGlobals.dontKeepTrackOfScore = 1;
		mySpaceGlobals.state = 7;

	# No Enemies (loner mode)
	if (mySpaceGlobals.passwordEntered == 82571):
	
		mySpaceGlobals.noEnemies = 1;
		mySpaceGlobals.dontKeepTrackOfScore = 1;
		mySpaceGlobals.state = 7;

	# Play as original spaceship (only if changed)
	if (mySpaceGlobals.passwordEntered == 00000 && mySpaceGlobals.playerChoice != 0):
	
		mySpaceGlobals.playerChoice = 0;
		decompress_sprite(511, 36, 36, compressed_ship, orig_ship, 14);
		mySpaceGlobals.curPalette = ship_palette;
		mySpaceGlobals.transIndex = 14;
		mySpaceGlobals.state = 7;

	# Play as galaga ship
	if (mySpaceGlobals.passwordEntered == 12345):
	
		mySpaceGlobals.playerChoice = 3;
		decompress_sprite(452, 36, 36, compressed_ship2, orig_ship, 5);
		mySpaceGlobals.curPalette = ship2_palette;
		mySpaceGlobals.transIndex = 5;
		mySpaceGlobals.state = 7;

	# double shot (previously turn player into boss1)
	if (mySpaceGlobals.passwordEntered == 24177):
		mySpaceGlobals.tripleShot = true
		mySpaceGlobals.doubleShot = true
		BULLET_COUNT = 60
		initBullets(mySpaceGlobals)
		mySpaceGlobals.dontKeepTrackOfScore = 1;
#		mySpaceGlobals.playerChoice = 1;
#		decompress_sprite(662, 36, 36, compressed_boss2, orig_ship, 39);
#		mySpaceGlobals.curPalette = boss2_palette;
#		mySpaceGlobals.transIndex = 39;
		mySpaceGlobals.state = 7;
#
#	# triple shot (previously turn player into boss2)
	if (mySpaceGlobals.passwordEntered == 37124):
		mySpaceGlobals.tripleShot = true
		mySpaceGlobals.doubleShot = false
		BULLET_COUNT = 100
		initBullets(mySpaceGlobals)
		mySpaceGlobals.dontKeepTrackOfScore = 1;
		# rest in peace Etika
		OS.shell_open("https://www.youtube.com/watch?v=1qX75J4_-e8")
#		mySpaceGlobals.playerChoice = 2;
#		decompress_sprite(740, 36, 36, compressed_boss, orig_ship, 39);
#		mySpaceGlobals.curPalette = boss_palette;
#		mySpaceGlobals.transIndex = 39;
		mySpaceGlobals.state = 7;

	# Enemies come right for you (kamikaze mode)
	if (mySpaceGlobals.passwordEntered == 30236):
	
		mySpaceGlobals.enemiesSeekPlayer = 1;
		mySpaceGlobals.dontKeepTrackOfScore = 1;
		mySpaceGlobals.state = 7;

	# start installer for IOSU Exploit
	if (mySpaceGlobals.passwordEntered == 41666):
	
		blackout(mySpaceGlobals.graphics);
		draw.drawString(mySpaceGlobals.graphics, 3, 7, "Installing IOSU Exploit...");
		draw.drawString(mySpaceGlobals.graphics, 3, 8, "This may take a while.");
		draw.flipBuffers(mySpaceGlobals.graphics);
		mySpaceGlobals.state = -27;

	# flip R and B channels for all colors
	if (mySpaceGlobals.passwordEntered == 77777):
		mySpaceGlobals.graphics.flipColor = !mySpaceGlobals.graphics.flipColor;
		mySpaceGlobals.state = 27;
		
	# toggle the space nx bitmap font
	if mySpaceGlobals.passwordEntered == 11111:
		mySpaceGlobals.graphics.nxFont = not mySpaceGlobals.graphics.nxFont
		mySpaceGlobals.graphics.classicMain.size_changed()
	
	# toggle the audio playing
	if mySpaceGlobals.passwordEntered == 22222:
		var player = mySpaceGlobals.graphics.classicMain.player
		player.playing = not player.playing
	
	# play whole game at faster speed, and switch audio
	if mySpaceGlobals.passwordEntered == 60185:
		if FPS_MULT == 60:
			FPS_MULT = 80 # go even further beyond
		else:
			FPS_MULT = 60
		var player = mySpaceGlobals.graphics.classicMain.player
		var isPlaying = player.playing
		player.stream = spedUpMusic
		player.playing = isPlaying
		mySpaceGlobals.state = 27;
	
	# some t-tb tracks
	if mySpaceGlobals.passwordEntered == 00001:
		OS.shell_open("https://t-tb.bandcamp.com/track/cruise")
	
	if mySpaceGlobals.passwordEntered == 00002:
		OS.shell_open("https://t-tb.bandcamp.com/track/scream-pictures")
	
	if mySpaceGlobals.passwordEntered == 00003:
		OS.shell_open("https://t-tb.bandcamp.com/track/slimers")
	
	if mySpaceGlobals.passwordEntered == 00004:
		OS.shell_open("https://t-tb.bandcamp.com/track/frog-song")
	
	if mySpaceGlobals.passwordEntered == 00005:
		OS.shell_open("https://www.youtube.com/watch?v=Tb02CNlhkPA")
	
	if mySpaceGlobals.passwordEntered == 00006:
		OS.shell_open("https://www.youtube.com/watch?v=a6oWk-BJ8bI")
	
	if mySpaceGlobals.passwordEntered == 00007:
		OS.shell_open("https://www.youtube.com/watch?v=wcMLFMsIVis")

	# 100 passwords, one for each level
	for x in range(100):
	
		if (mySpaceGlobals.passwordEntered == mySpaceGlobals.passwordList[x]):
			mySpaceGlobals.level = x;
			break;

		if (x==99): # no password was right
			return;

	# switch to the game state
	mySpaceGlobals.state = 7;

	# They are generated

func renderReset(mySpaceGlobals):

	initGameState(mySpaceGlobals);
	mySpaceGlobals.p1X = 200;
	mySpaceGlobals.p1Y = 100;
	mySpaceGlobals.renderResetFlag = 0;
	mySpaceGlobals.invalid = 1;
