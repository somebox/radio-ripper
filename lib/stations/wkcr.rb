require 'curb'
require 'nokogiri'
require 'chronic'
require 'moneta'

module WKCR
  class Schedule    
    NY_TZ = ActiveSupport::TimeZone.us_zones.find{|z| z.name.match("Eastern")}
    CACHE_TTL = CONFIG[:cache_ttl]

    def self.html_for_day(wday)
      cache = Moneta.new(:File, :dir => CONFIG[:settings][:cache_dir], :expires => true)
      if cache.key?(wday)
        # puts "* cache hit for #{wday}"
        return cache.load(wday, :expires => CACHE_TTL)
      else
        http = Curl.get("#{CONFIG[:wkcr][:schedule]}/#{wday}")
        html = http.body_str
        cache.store(wday, html, :expires => CACHE_TTL)
        puts "* wrote cache for #{wday}"
        return html
      end
      html
    end

    def self.load
      Chronic.time_class = NY_TZ
      %w(sunday monday tuesday wednesday thursday friday saturday).map do |wday|
        html = html_for_day(wday)
        doc = Nokogiri::HTML.parse(html)
        seen_am = false
        doc.css('.view-station-schedule-day tbody tr').map do |row|
          showtime = Chronic.parse(wday + ' ' + row.css('.views-field-start').text.strip)
          seen_am = true if showtime.hour <= 12
          next if !seen_am && showtime.hour > 12
          {
            :time  => showtime,
            :name  => row.css('.views-field-title').text.strip,
            :genre => row.css('.views-field-field-station-program-genre-value').text.strip
          }
        end.select{|r| r.present?}
      end.flatten
    end

    # a printable list of shows, with showtimes, generes, duration
    def self.list
      shows = WKCR::Show.all
      schedule = Hash.new
      shows.each do |show|
        schedule[show.name] ||= []
        schedule[show.name] << show.showtime
      end
      list = shows.uniq(&:name).sort{|a,b| a.name <=> b.name}
      list.map{|s| "#{s.name} (#{s.duration/60}m)\n #{s.generes.join(', ')}\n #{schedule[s.name].join(', ')}\n"}
    end
  end

  class Show
    attr_accessor :time, :name, :generes, :duration

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
      todays_shows = self.all.select{|s| s.time.localtime.wday == Time.now.wday}
      todays_shows.sort do |a,b|
        (a.time.localtime.seconds_since_midnight - Time.now.seconds_since_midnight).abs <=> (b.time.localtime.seconds_since_midnight - Time.now.seconds_since_midnight).abs
      end.first
    end

    def initialize(data)
      self.time = data[:time]
      self.name = data[:name]
      self.generes = data[:genre].split(/,/)
    end

    def summary
      sprintf("%-25.24s %s %dm", self.name, self.showtime, self.duration/60)
    end

    def showtime
      self.time.strftime('%a %I:%M%p')
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
      self.dirname.dasherize + '--' + self.time.strftime('%a-%Y-%m-%d-%H:%M%p') + '.mp3'
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
      rake = "#{ENV['MY_RUBY_HOME']}/bin/rake wkcr:rip # #{self.name}, #{self.showtime}, #{self.duration/60}m"
      %Q(#{crontab} cd "#{Dir.pwd}" && #{rake})
    end
  end
end
