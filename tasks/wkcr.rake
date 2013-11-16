namespace :wkcr do
  desc "get station schedules and output cron lines"
  task :cron do
    shows = WKCR::Show.favorites.map do |show|
      puts show.cron_line
      puts
    end
  end

  task :shows do
    puts WKCR::Schedule.list
  end

  desc "rip current show"
  task :rip do
    show = WKCR::Show.current
    #puts "rip #{show.name} at #{show.time.localtime.strftime('%H:%M')} for #{show.duration/60}m"
    FileUtils.mkdir_p(show.mp3_path)
    system(show.stream_command)
  end
end
