# Hisaishi Player

a web-based Karaoke player  
by the IT guys from SMASH!

[smash.org.au](http://www.smash.org.au/)

## Hints

We tested this player a lot in Chrome. If you could use that for the player 
that would be great, but it should work in a lot of other browsers too.

## Starting the player

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

## Searching for Songs

## Announcements

We're still working on this, but it will pretty much work the same way as the 
queue for songs does.  It'll just display messages instead of play songs.  As 
you'd expect.

## When you're done

Close the Queue tab in Safari, and quit the browser on the computer playing 
back songs.


