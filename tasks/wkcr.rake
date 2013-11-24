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
      printf("%-40s\n %s\n %-40s\n", "#{s.name} (#{s.duration/60}m)", s.showtimes.join(', '), s.generes.join(', '))
    end
  end

  desc "rip current show"
  task :rip do
    show = WKCR::Show.current
    FileUtils.mkdir_p(show.mp3_path)
    system(show.stream_command)
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
