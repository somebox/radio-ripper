# WKCR radio-ripper

## Rips Audio Streams for Brute-Force Podcasting Pleasure

There's an FM [radio station in NYC](http://www.studentaffairs.columbia.edu/wkcr/) that I love. They broadcast their lovely programs live on the internet, but for legal reasons, cannot offer podcast feeds. That forced me to write this solution, which:

* scrapes the [schedules](http://www.studentaffairs.columbia.edu/wkcr/schedule) of all programs and parses them,
* uses [streamripper](http://streamripper.sourceforge.net/tutorialconsole.php) to capture live streams as properly-labeled mp3 files,
* creates a private podcast RSS feeds of your favorite program(s)
* manages the crontab of the whole process

The web scraper employs a local disk cache, as to not be greedy. The default cache expiration is 1 day.

The dates are kept in the `America/New York` timezone, and converted to local time for scheduling recordings.

## Installation

### Requirements

  * rvm
  * ruby 2.0
  * streamripper

### Set up

    $ cd radio-ripper
    $ bundle

### Install Streamripper

(On Debian)

    $ aptitude install streamripper

### Customize

Create a config file and edit it:

    $ cp config/settings-example.yml config/settings.yml

Set up the directories for storing mp3 files and feeds. Be sure to also set the correct path to streamripper.

### Set Up Scheduled Recordings

The cron task outputs the necessary commands for recording shows. Copy and paste the result into a crontab file in `/etc/cron.d`.

    $ rake wkcr:cron

## TODO

* Automatically install dependencies
* Automatically create/update cron jobs
* Support scheduling on OSX via launchd
* Create RSS feeds and subscription page

## Support WKCR

WKCR is a legendary FM broadcaster at Columbia University. Please consider [donating](https://giving.columbia.edu/giveonline/?schoolstyle=411) to this important station, one of the few remaining in the USA that plays incredible jazz and classical, and employs real DJs who know what they are talking about. Really, the programming is outstanding. They are completely listener-supported.
