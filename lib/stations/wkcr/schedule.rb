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
      WKCR::Show.all.tap do |shows|
        schedule = {}
        shows.each do |show|
          schedule[show.name] ||= []
          schedule[show.name] << show.showtime
        end
        shows.uniq!(&:name).sort{|a,b| a.name <=> b.name}
        shows.each do |show|
          show.showtimes << schedule[show.name]
        end
      end
    end
  end
end
