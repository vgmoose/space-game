extends Node2D

# This is from here: http://stackoverflow.com/a/1026370/1871287
# it is initially seeded with the time
var xseed

class_name PRandom

func _init(initialSeed):
	xseed = initialSeed

func prand ():
  var next = xseed;
  var result;
  next *= 1103515245;
  next += 12345;
  result =  int(next / 65536) % 2048;
  result = ~result

  next *= 1103515245;
  next += 12345;
  result <<= 10;
  result ^= int(next / 65536) % 1024;
  result = ~result

  next *= 1103515245;
  next += 12345;
  result <<= 10;
  result ^= int(next / 65536) % 1024;
  result = ~result

  xseed = next;

  return abs(result / 2147483647.0);
