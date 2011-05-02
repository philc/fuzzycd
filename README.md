Overview
========
fuzzycd enables you to use cd with partial directory names which are fuzzily matched. For example:
    $ cd photos/seattle
      => photos/2008-05-28 parasailing in Seattle
    $ cd code/player/playback
      => code/player/player_module_playback

If there is more than one directory that matches your expression, you'll get a menu to choose from.
    $ cd photos/christmas
    1.photos/2009-12-23 christmas eve party   2.photos/2009-12-24 christmas service
    3.photos/2009-12-25 christmas Day

Why?
====
fuzzycd helps you to be lazy and type just what's necessary to get where you're going. Life is too short to struggle through some of those long, tricky directory names, even with tab completion. If you have directories you navigate to ten times a day and symlinks aren't a workable option, this will save you keystrokes and put a smirk on your face as you effortlessly glide across your filesystem.

Setup
=====
Modify your ~/.profile (or ~/.bashrc, depending your operating system) and add the following lines. This assumes you put fuzzycd in the ~/scripts/ directory.

    export PATH=~/scripts/fuzzycd/:$PATH
    source ~/scripts/fuzzycd/fuzzycd_bash_wrapper.sh

This will effectively wrap the builtin bash cd command with the fuzzy cd command. Enjoy!

*Note*: If you have any other shell plugins which try to redefine the "cd" function (e.g. [rvm](https://rvm.beginrescueend.com/rvm) does this), make sure that the `source ... fuzzycd_bash_wrapper.sh` line comes last in your bash profile. fuzzycd plays nicely with other bash modification plugins, but it should be loaded last.

Improvements
============
If you have any improvements, feel free to send me an email or a pull request.