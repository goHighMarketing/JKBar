# JKBar
A Quickshell Bar for BSPWM

This is a pet project I built for my BSPWM desktop as an alternative to Polybar.  
I wanted something a little more modern that I could enjoy in an X11 environment.

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
