extends Node2D

var font

class_name Draw

func _init():
	font = FontBitmap.getFont()
	var images = Images.new()

func flipBuffers(g):
	# todo: commit set image data??
	pass
#	g.classicMain.update()

# This is the main function that does the grunt work of drawing to both screens. It takes in the
# Services structure that is constructed in program.c, which contains the pointer to the function
# that is responsible for putting a pixel on the screen. By doing it this way, the OSScreenPutPixelEx function pointer is only
# looked up once, at the program initialization, which makes successive calls to this pixel caller quicker.
func putAPixel(gr, x, y, r, g, b):

	if (gr.flipColor):
		var temp = r;
		r = b;
		b = temp;
	
#	x *= 2;
#	y *= 2;

	if x < 0 or x >= 427 or y < 0 or y >= 240 or gr.editableScreen == null:
		return
	
	gr.editableScreen.set_pixel(x, y, Color(r/255.0, g/255.0, b/255.0))

#	draw_rect(Rect2(x, y, 1, 1), Color(r/255.0, g/255.0, b/255.0))
#
#	gr.pixels.append(Vector2(x, y))
#	gr.colors.append(Color(r/255.0, g/255.0, b/255.0))

func drawString(g, xi, yi, string):
	# for every character in the string, if it's within range, render it at the current position
	# and move over 8 characters

	xi *= 6.25;
	yi *= 13;

	var i = 0;
	for nexts in string:
		i += 1
		var next = ord(nexts)
		# actually draw this char pixel by pixel, if it's within range
		if (next >= 0 && next < 128):
			var bitmap = font[next];
#			var out = ""
			for x in range(8):
				for y in range(8):
					if (bitmap[x] & 1 << y):
#						out += "*"
						putAPixel(g, xi+y+i*8, yi+x, 0xff, 0xff, 0xff)
#					else:
#						out += " "
#				out += "\n"
#			print(out)

func fillScreen(gr, r, g, b, a):
	gr.editableScreen.unlock()
	gr.editableScreen.fill(Color(r, g, b))
	gr.editableScreen.lock()

# draw black rect all at once
func fillRect(gr, ox, oy, width, height, r, g, b):
	for rx in range(width):
		for ry in range(height):
			var x = ox + rx;
			var y = oy + ry;

			# do actual pixel drawing logic
			putAPixel(gr, x, y, r, g, b);

# This function draws a "bitmap" in a very particular fashion: it takes as input the matrix of chars to draw.
# In this matrix, each char represents the index to look it up in the palette variable which is also passed.
# Alpha isn't used here, and instead allows the "magic color" of 0x272727 to be "skipped" when drawing.
# By looking up the color in the palette, the bitmap can be smaller. Before compression was implemented, this was
# more important. A potential speedup may be to integrate the three pixel colors into a matrix prior to this function.
func drawBitmap(gr, ox, oy, width, height, input, palette):
	for rx in range(width):
		for ry in range(height):
			var color = palette[input[ry][rx]];
			var r = color[2];
			var g = color[1];
			var b = color[0];

			# transparent pixels
			if (r == 0x27 && g == 0x27 && b == 0x27):
				continue;

			var x = ox + rx;
			var y = oy + ry;

			# do actual pixel drawing logic
			putAPixel(gr, x, y, r, g, b);

# This is primarly used for drawing the stars, and takes in a pixel map. It is similar to bitmap, but now
# it takes the whole pixel map as well as which portion of it to actually draw. At the beginning, all of the stars
# are drawn, but whenever the ship moves, only the stars underneath the ship need to be redrawn.
func drawPixels(g, pixels):
	for rx in range(200):
		var x = pixels[rx].x;
		var y = pixels[rx].y;

		putAPixel(g, x, y, pixels[rx].r, pixels[rx].g, pixels[rx].b);

func drawPixel(gr, x, y, r, g, b):
	putAPixel(gr, x, y, r, g, b);
