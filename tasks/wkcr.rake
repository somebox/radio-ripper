namespace :wkcr do
  desc "get station schedules and output cron lines"
  task :cron do
    shows = WKCR::Show.favorites.map do |show|
      puts show.cron_line
      puts
    end
  end

  desc "display the schedule of shows"
  task :shows do
    WKCR::Schedule.list.map do |s| 
      printf("%s (%s, %s)\n 🕑 %s\n", 
        "#{s.name}", 
        "#{s.duration/60}m",
        s.generes[0..4].join(', '), 
        s.showtimes.join(', ')
      )
    end
  end

  desc "rip current show"
  task :rip do
    # record show stream
    start = Time.now
    show = WKCR::Show.current
    puts "Ripping: #{show.summary}"
    FileUtils.mkdir_p(show.mp3_path)
    puts show.stream_command
    system(show.stream_command)
    puts "done after #{((Time.now - start)/60).to_i}m"

    # afterwards, merge/copy/cleanup and update podcast RSS
    Podcaster.manage
    Podcaster.generate_feeds
  end

  desc "create podcast feed and tend to files"
  task :podcast do
    Podcaster.manage
    Podcaster.generate_feeds
  end

  desc "currently playing show (or about to start)"
  task :current do
    puts WKCR::Show.current.summary
  end

  desc "tune in and listen"
  task :listen do
    system("open '#{CONFIG[:wkcr][:stream]}' -a vlc")
  end
end
