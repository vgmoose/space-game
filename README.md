## Space Game
This is a Godot port of the Wii U homebrew app [Space Game](https://github.com/vgmoose/wiiu-space) (and [Space Game NX](https://github.com/vgmoose/space-nx)). The goal of this port is to more easily bring it to other devices, as running homebrew can be a complicated process.

### Downloads
Linux, Mac, and Windows builds are available [here](https://github.com/vgmoose/space-game/actions). A video of the gameplay is [here](https://www.youtube.com/watch?v=KMuicPmOIHw).

<img width="410" alt="Screen Shot 2021-08-18 at 10 29 57 PM" src="https://user-images.githubusercontent.com/2467473/130005538-674e0de2-c7ad-4568-b638-1be8c8e4f2f2.png"> <img width="410" alt="Screen Shot 2021-08-18 at 10 31 29 PM" src="https://user-images.githubusercontent.com/2467473/130005559-661d7db4-5808-46bb-adbe-9f3783e4c9e4.png">


### Credits and License
This program is licensed under [the MIT license](https://opensource.org/licenses/MIT), which grants anyone permission to do pretty much whatever they want as long as the copyright notice stays intact.*
 - Programmed by [VGMoose](https://github.com/vgmoose)
 - Original codebase based on [libwiiu pong](https://github.com/wiiudev/libwiiu/tree/master/osscreenexamples/pong) by [Relys](https://github.com/Relys)
 - Music is [\~\*cruise\*\~](https://t-tb.bandcamp.com/track/cruise) by [(T-T)b](https://t-tb.bandcamp.com/)*
 - Space ship sprite by [Gungriffon Geona](http://shmups.system11.org/viewtopic.php?p=421436&sid=c7c9dc0b51eb40aa10bd77f724f45bb1#p421436)
 - Logo font by [Iconian Fonts](http://www.dafont.com/ozda.font) 
 - OSScreen-similar font by [M+ Fonts](http://mplus-fonts.osdn.jp/about-en2.html)
 - libwiiu/bugfixes: [MarioNumber1](https://github.com/MarioNumber1), [CreeperMario](https://github.com/CreeperMario),  [brienj](https://github.com/xhp-creations), [NWPlayer123](https://github.com/NWPlayer123), [dimok](https://github.com/dimok789)
 
 *The song [\~\*cruise\*\~](https://t-tb.bandcamp.com/track/cruise) is available under [CC BY-NC-ND](https://ptesquad.bandcamp.com/album/pizza-planet-ep), and is excluded from the MIT licensing.

### How it works

The [space.gd](https://github.com/vgmoose/space-game/blob/main/Classic/space.gd) file is a direct port of [space.c](https://github.com/vgmoose/wiiu-space/blob/hbl_elf/src/space.c) from the original, with syntax and other changes made to simulate OSScreen behavior. The graphics specific stuff happens in [draw.gd](https://github.com/vgmoose/space-game/blob/main/Classic/draw.gd)/[draw.c](https://github.com/vgmoose/wiiu-space/blob/hbl_elf/src/draw.c). A lot of the OSScreen abstraction was also already done in Space NX's [draw.c](https://github.com/vgmoose/space-nx/blob/master/draw.c) when it was ported to SDL, and the Godot requirements are similar.

Space Game NX uses a Bitmap font to get around the lack of an OSScreen font in SDL. In this version, a [LabelController](https://github.com/vgmoose/space-game/blob/main/Classic/LabelController.gd) class keeps track of all requested strings to draw on-screen, and then renders it with Godot's own text engine and a TTF font. Labels are given a somewhat-unique ID based on their coordinates to allow them to be re-used, and are made visible when the frame is drawn. This allows the game to look more similarly to how it looked on the Wii U, where the in-game pixels were larger than the pixels in the font. The NX bitmap font can be toggled with the code `11111` on the Password screen.

All of the same bitmap compression/rendering/matrix logic is done as described in the [original readme](https://github.com/vgmoose/wiiu-space#compressing-bitmaps), which is incidentally not a great strategy for making a Godot game! This makes the code not very useful as a reference for Godot, although seeing how some pixel-effects (like the explosions) occur, or using a TextureRect to draw pixel sprites could be helpful.

Due to it using the same prng method, all old passwords should work from previous versions of Space Game!

### Gameplay Differences

The big change is that now Space Game runs at 60fps when it can, and when it can't it maintains the same speed of objects in game.  Godot will try to maintain 60fps, but may bump down to 30fps if 60 is too demanding. This difference means that regardless of the fps, the gameplay should "feel" the same speed (which is important, as later levels will make the enemies faster). In the previous homebrew versions the game would render each frame as fast as it could, which turned out to come in lower than 60fps or allow inconsistent slowing down depending on what was occurring on screen.

The code `22222` is also added to toggle the music playing within the code, and some other passwords also had their functionality change. For example, the code `24177` now enables a new double firing function from the ship, whereas before it would transform the player's sprite. Some passwords also now also open URLs as easter eggs. Like in the original, certain cheats will disable the score counter. The code `77777` to swap the red and blue channels from the NX port is also present!

<img width="410" alt="Screen Shot 2021-08-19 at 12 02 03 AM" src="https://user-images.githubusercontent.com/2467473/130005764-2e9437a1-4d2d-4710-a410-f9f65cf05231.png"> <img width="410" alt="Screen Shot 2021-08-19 at 12 01 31 AM" src="https://user-images.githubusercontent.com/2467473/130005776-3d1f634c-5348-458b-8af1-70aeabb74e86.png">


### A final note
This is technically the fourth port of Space Game! The porting history is as follows:

[Wii U Space Game (2016)](https://github.com/vgmoose/wiiu-space) -> [JSpaceGame (2017)](https://github.com/vgmoose/JSpaceGame/) -> [Space Game NX (2018)](https://github.com/vgmoose/space-nx) -> [Space Game (2021)](https://github.com/vgmoose/space-game) (You are here).

To hear more about the Java port, I wrote a [blog post](https://gbatemp.net/blog/vgmoose.382062/) about it in 2017, and you can compare [Space.java](https://github.com/vgmoose/JSpaceGame/blob/master/src/Space.java) against the .gd and .c files :smiley:

Space Game NX (an SDL program) was intended to be the "final form" of this small game, but using a game engine like Godot allows for better control over the FPS issue as mentioned earlier, but also personally gives me greater confidence in the codebase being more accessible in the future in a way that SDL fell a little short. Trying to explain to others how to play Space Game always forces me to start off with a "Well..." as I picture the homebrewing paths, Java path, or trying to get SDL working with their setup (aka Controllers, framerate, OS concerns, etc). Now it can be easily brought to computers, phones, consoles, or other Godot projects!

That is also the reasoning behind just naming this "Space Game"– I want this version to be "the thing" I'm referring to when I picture the original game, in the absense of a nearby Wii U of course!
