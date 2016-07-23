= glgames: squeeze =

* squeeze - squeeze game
* Copyright (C) 2009-2016 by Michael Nagel

= screenshot =

![squeeze screenshot](/website/squeeze-screenshot.png?raw=true "squeeze screenshot")

= Installation (on ubuntu) =

== Ubuntu ==

```
sudo apt install ruby ruby-sdl ruby-dev
gem install --user-install opengl glu
```

== Fedora ==

run in root terminal:

```
yum groupinstall "Development Tools"
yum install ruby rubygems ruby-devel

yum install SDL-devel SDL_ttf-devel SDL_image-devel freeglut-devel
gem install rubysdl ruby-opengl

yum install bitstream-vera-fonts
```

= Starting the Game =

* open the folder where you extracted the archive
* double-click 'squeeze' to run the game
* resolution and fullscreen mode can be configured in the startup script

= Playing the Game =

== Target ==

* Your target in each level is to fill the screen with bubbles.
* Do not spawn a bubble within another bubble.

== Hints ==

* You need to score 100 points in each level to proceed.
* If you cause a crash, the limit is raised.
* Big bubbles score more points than small ones.
* Press ENTER when you cannot place any more bubbles.
* It is OK to collide while inflating a bubble. You must spawn at a valid position, though.

== Controls ==

* click&hold left mouse: inflate a bubble.
* release left mouse: spawn a bubble.
* enter: restart game.


== Feedback ==

Use https://github.com/mnagel/squeeze
