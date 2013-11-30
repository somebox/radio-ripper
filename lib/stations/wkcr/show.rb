module WKCR
  class Show
    attr_accessor :time, :name, :generes, :duration, :showtimes

    def initialize(data)
      self.time = data[:time]
      self.name = data[:name]
      self.generes = data[:genre].split(/,/)
      self.showtimes = []
    end

    def self.all
      shows = WKCR::Schedule.load.map do |data|
        new(data)
      end
      # set durations, in seconds
      (1..shows.length).to_a.each do |i|
        if i > 0
          duration = shows[i % shows.length].time - shows[i-1].time
          duration += 3600*24*7 if duration < 0
          shows[i-1].duration = duration.to_i
        end
      end
      shows
    end

    def self.favorites
      shows = WKCR::Show.all
      favs = []
      CONFIG[:favorites].each do |fav_regex|
        shows.each do |show|
          if show.name.match(Regexp.new(fav_regex,'i'))
            favs << show
          end
        end
      end
      favs.uniq
    end

    # selects the show that is broadcasting next
    def self.current
      now = (Time.now - 1.minutes)
      todays_shows = self.all.select{|s| s.time.localtime.wday == now.wday}
      todays_shows.sort do |a,b|
        (a.time.localtime.seconds_since_midnight - now.seconds_since_midnight).abs <=> (b.time.localtime.seconds_since_midnight - now.seconds_since_midnight).abs
      end.first
    end

    def summary
      sprintf("%-25.24s %s %dm", self.name, self.showtime, self.duration/60)
    end

    def showtime
      self.time.strftime('%a, %b %d %I:%M%p')
    end

    def dirname
      self.name.gsub(/\s+/,'_').gsub(/[\W]+/,'').dasherize
    end

    # full path to where mp3 are stored for this show
    def mp3_path
      File.join(CONFIG[:settings][:mp3_dir], self.dirname)
    end

    # the mp3 filename for this show, with extension. URI-safe.
    def filename
      self.dirname.dasherize + '--' + self.time.strftime('%a-%Y-%m-%d-%I%M%p') + '.mp3'
    end

    # total time to record audio, with pre and post-roll, in seconds
    def record_duration
      CONFIG[:settings][:pre_roll].to_i + CONFIG[:settings][:post_roll].to_i + self.duration
    end

    # command-line to rip the stream for this show
    def stream_command
      dest = File.join(self.mp3_path, self.filename)
      %Q(#{CONFIG[:settings][:streamripper]} "#{CONFIG[:wkcr][:stream]}" -d "#{self.mp3_path}" -A -s -a "#{self.filename}" -l #{self.record_duration})
    end

    # the full cron line with schedule
    def cron_line
      # m h dom mon wday
      t = self.time.localtime - CONFIG[:settings][:pre_roll].to_i.seconds
      crontab = "#{t.min} #{t.hour} * * #{t.wday}"
      comment = "# #{self.name}, every #{self.time.strftime('%a at %I:%M%p')} for #{self.duration/60}m"
      log = ">> #{CONFIG[:settings][:logfile]} 2>&1"
      %Q(#{crontab} cd "#{Dir.pwd}" && bin/record #{log} #{comment})
    end
  end
end
