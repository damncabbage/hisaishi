# Hisaishi Player

a web-based Karaoke player  
by the IT guys from SMASH!

[smash.org.au](http://www.smash.org.au/)

## Hints

We tested this player a lot in Chrome. If you could use that for the player 
that would be great, but it should work in a lot of other browsers too.

## Requires

We recommend that you use RVM and a Ruby version of at least 1.9.2.  
Check out [rvm.io](https://rvm.io/) for info on how to install it.

## Setting up the player to run at startup (Mac OS X)

**NOTE:** this requires a little technical know-how and the administrator password.

We've got a plist that sets up the player to run on startup.  To set it up for your 
username, open **au.org.smash.hisaishi.playerlaunch.plist** and change the following: 

**UserName**  
Should be the user that owns the directory you put Hisaishi in.

**WorkingDirectory**  
The path to the directory you put Hisaishi in.  You can find this out by typing  
<code>pwd</code>  
into the command line.

To load the updated plist, type  
<code>sudo launchctl load au.org.smash.hisaishi.playerlaunch.plist</code>  
and Hisaishi should run when you start your Mac.

To remove it, type  
<code>sudo launchctl remove au.org.smash.hisaishi.playerlaunch</code>  
and it should shut down and no longer launch on startup.

## Starting the player

**NOTE:** this requires a little technical know-how.

The computer is set up with a particular directory that has all of Hisaishi's 
stuff in.  Open up Terminal and type  
**cd path/to/hisaishi**

Once there, type
**./hisaishi.sh**  
to run Hisaishi.

It will tell you something along the lines of:

> == Sinatra/1.3.2 has taken the stage on 4567 for development with backup from Thin  
> Thin web server (v1.3.1 codename Triple Espresso)  
> Maximum connections set to 1024  
> Listening on 0.0.0.0:4567, CTRL+C to stop

This means that you can open up  
**http://localhost:4567/**  
in your browser and start the player.  You will automatically see the player 
come up.

## Connecting the iPad

Make sure the iPad and the computer that runs Hisaishi are on the same network.
Sharing the computer's wifi might help.

First you'll need to know what URL to hit.  On the computer running Hisaishi,
go to  
**http://localhost:4567/diagnostic**

If you need to enter the PIN, please do so.

There'll be a specially crafted **Queue URL** ready for you to use.

Grab your iPad, open Safari, and enter this URL in Safari. Enter the PIN 
when prompted, and you should see the Queue screen!

## Queue Management

Songs play sequentially top to bottom in the queue.

You can perform various actions on individual songs (playing, stopping, 
pausing, rewinding, moving to the end of the queue, moving after currently 
playing song) by touching them.

You can also reorder them by touching the Edit button in the top left corner, 
and touch-dragging the songs into the order you want.  When done, touch the 
Done button in the top left corner to commit your changes.

## Searching for Songs

Start entering a song title, and touch Done or outside the search bar to let 
songs come up.  Touch one, and it'll let you add one with the nickname of any 
singer.  If you're logged in with the PIN, you can do so without having to 
wait for 5 minutes between submissions.

## Announcements

This works pretty much the same way as the Queue does, but with a couple of 
exceptions.

Announcements works by scanning a list of announcements and making any that have 
the status Pending display, one by one.  You can add them using the 
**Add Announcement** button.

To retrigger an announcement that has been played, or doesn't have Pending 
status, just tap it.

## When you're done

Close the Queue tab in Safari, and quit the browser on the computer playing 
back songs.

Go to the terminal running Hisaishi, and type Ctrl+C to quit.


