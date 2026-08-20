# JKBar
A Quickshell Bar for BSPWM

This is a pet project I built for my BSPWM desktop as an alternative to Polybar.  
I wanted something a little more modern that I could enjoy in an X11 environment.

New:  

* Wallpaper selector now has right-click preview window.  Both wallpaper drawer and preview closes when clicking outside of the drawer.

* Wallpaper Drawer and Control Centre Popup has a light-box effect when opened if using picom with blur.

* Improvements to general aesthetics and colours.

* Added full colour Emojis for the bar items and weather module.

* Buttons now have a hover glow effect when moused over.

Dependencies:  Quickshell, JetBrainsMono Nerd Font, feh (for wallpaper), gsimplecal (calendar when righ-clicking clock), pavucontrol (for right-click volume).
  xdotool (for active window)

The obvious minimum requirements:  BSPWM, sxhkd, rofi, a polkit (ie, lxpolkit, or mate-polkit), and a working config of course.

Make a folder in your config directory (ie - ~/.config/bspwm/jkbar) and extract the qml files there.

Add this to your config startup:  

killall qs

qs -p ~/.config/bspwm/jkbar/shell.qml &

Even though it satisfies my own needs, JKBar should probably be considered a starting point for customizing your own quickshell bar as the code may need some tweaking to suit your own environment.

My video featuring JKBar can be found here:

https://www.youtube.com/watch?v=hHRG6Z3KZpc

* For full color Emojis in the bar use "Twemoji Mozilla" fonts.

* To install them, open your terminal & add these lines:

      mkdir ~/.local/share/fonts

      wget -O ~/.local/share/fonts/TwemojiMozilla.ttf https://github.com/mozilla/twemoji-colr/releases/download/v0.7.0/Twemoji.Mozilla.ttf

      clear cache:  fc-cache -fv


