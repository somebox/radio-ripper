# WKCR radio-ripper

## Rips Audio MP3 Streams for Brute-Force Podcasting Pleasure

There's this FM [radio station in NYC](http://www.studentaffairs.columbia.edu/wkcr/) that I love. They broadcast their lovely programs live on the internet, but for legal reasons, cannot offer podcast feeds. So I created this.

This solution does the following:

* scrapes the [schedules](http://www.studentaffairs.columbia.edu/wkcr/schedule) of all programs and parses them.
* outputs the necessary `crontab` entries to record your favorite shows at the right times.
* uses [streamripper](http://streamripper.sourceforge.net/tutorialconsole.php) to capture live streams as individual mp3 files, and [mp3wrap](http://mp3wrap.sourceforge.net) to join multiple mp3s together.
* manages the files
* creates a private podcast RSS feed of your favorite program(s)

The final podcast file and MP3 folder structure can be made available on a web server, and added to iTunes (or any other podcasting app) for your private listening pleasure.

![](http://somebox.com/docs/radio-ripper-itunes.jpg)

## Installation

I suggest you put this on a private server somewhere, but you might want to run it on a local machine. The requirements are simply: a persistent internet connection, and a locally-accessible folder that is served by a web server.

### Requirements

  * rvm
  * ruby 2.0

### Install Dependencies

This solution uses **[streamripper](http://streamripper.sourceforge.net/tutorialconsole.php)** to record mp3 radio feeds, and **[mp3wrap](http://mp3wrap.sourceforge.net)** to combine several mp3s into one (which happens due to disconnects/reconnects).

(On Debian)

    $ aptitude install streamripper mp3wrap

(on OSX using homebrew)

    $ brew install streamripper mp3wrap

### Prepare

Clone a local copy of this repository via git. Then:

    $ cd radio-ripper
    $ bundle

### Customize

Create a config file and edit it:

    $ cp config/settings-example.yml config/settings.yml

Edit the config file. Set up the directories for storing mp3 files and feeds. The setting `feed_dir` should be a folder served by a web server. 

Be sure to also set the correct paths to streamripper and [mp3wrap](http://mp3wrap.sourceforge.net).

You can specify your favorite programs in the **favorites** section of the config file. 

To Get a list of available programs:

    $ rake wkcr:shows

### Set Up Scheduled Recordings

The cron task outputs the necessary commands for recording shows. Copy and paste the result into a crontab file.

    $ rake wkcr:cron

NOTE: I have not yet figured out a good way to schedule recording on OSX. Mavericks (10.9) and the new energy saver features make scheduling exact times even harder. Looking for ideas...

## Other Utilities

On OSX, there is a shortcut to tune into WKCR using VLC:

    $ rake wkcr:listen

To display the currently broadcast show:

    $ rake wkcr:current

To start an interactive console session:
  
    $ rake console

## Notes

The web scraper process employs a local disk cache, as to not be greedy. The default cache expiration is 1 day.

Dates are kept in the `America/New York` timezone, and converted to local time for the scheduling of recordings.

Pull requests are welcome. Open an issue with any ideas you may have.

## TODO

* Automatically install dependencies
* Automatically create/update cron jobs
* Support scheduling on OSX via launchd
* Create RSS feeds and subscription page
* Fix issue with dates: currently they show 1 week in the future. My guess is there's a date parse/set bug.
* Support other stations (considering WNYU or WBAI for some other favorites), and maybe a generic way to add favorites by time/url.
* Tests. This was written in a fury of hacking, with disregard for proper TDD. Tisk.

## Support WKCR

WKCR is a legendary FM broadcaster at Columbia University. Please consider [donating](https://giving.columbia.edu/giveonline/?schoolstyle=411) to this important station, one of the few remaining in the USA that plays incredible jazz and classical, and employs real DJs who know what they are talking about. Really, the programming is outstanding. They are completely listener-supported.

## Disclaimer

All contents are open-source, unlicensed, and unsupported. Enjoy, share, and realize that I offer no warranty or claim to anything you see here.

Also **be aware, that you should not use this to create a public feed of WKCR programs**. If they wanted this to happen, they would offer it themselves. This program is intended to be used for private recording and entertainment purposes. The moment you publish your recordings or feed, you are most probably breaking the law! 

## And Finally...

When I was a kid I recorded the radio on cassette tapes. Later on, I used [RadioShift, from Rouge Amoeba](http://rogueamoeba.com/radioshift/) to record my favorite internet streams. That program never quite reached a good point of polish, and was discontinued in 2011. Eventually I realized this could be done without too much effort using a few tools and Ruby. 

Overall, this app took about 8 hours of time to complete. Not bad for the result: I can listen to my favorite WKCR programs on the train or at home. And despite the time difference and changing broadcast schedules, I can be reasonably sure the recordings are correct. Bliss!
