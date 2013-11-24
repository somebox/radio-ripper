# WKCR radio-ripper

## Rips Audio Streams for Brute-Force Podcasting Pleasure

There's an FM [radio station in NYC](http://www.studentaffairs.columbia.edu/wkcr/) that I love. They broadcast their lovely programs live on the internet, but for legal reasons, cannot offer podcast feeds. That forced me to write this solution, which:

* scrapes the [schedules](http://www.studentaffairs.columbia.edu/wkcr/schedule) of all programs and parses them,
* uses [streamripper](http://streamripper.sourceforge.net/tutorialconsole.php) to capture live streams as individual mp3 files, and [mp3wrap](http://mp3wrap.sourceforge.net) to join multiple mp3s together.
* creates a private podcast RSS feed of your favorite program(s)
* manages the files
* outputs the necessary `crontab` entries to record your favorites at the right times

The web scraper process employs a local disk cache, as to not be greedy. The default cache expiration is 1 day.

Dates are kept in the `America/New York` timezone, and converted to local time for the scheduling of recordings.

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

## TODO

* Automatically install dependencies
* Automatically create/update cron jobs
* Support scheduling on OSX via launchd
* Create RSS feeds and subscription page
* Fix issue with dates: currently they show 1 week in the future. My guess is there's a date parse/set bug.
* Tests. This was written in a fury of hacking, with disregard for proper TDD. Tisk.

## Support WKCR

WKCR is a legendary FM broadcaster at Columbia University. Please consider [donating](https://giving.columbia.edu/giveonline/?schoolstyle=411) to this important station, one of the few remaining in the USA that plays incredible jazz and classical, and employs real DJs who know what they are talking about. Really, the programming is outstanding. They are completely listener-supported.
