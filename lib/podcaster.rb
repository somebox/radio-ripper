require 'rss/0.9'
require 'rss/maker'

DEBUG=ENV['DEBUG']

class Podcaster
  # Manages mp3 recordings:
  # * traverses the mp3 download dir
  # * examines each show directory for mp3s
  # * sorts the mp3s by show date
  # * combines multiple mp3s into one (due to disconnects)
  # * copies the recording to the feed directory
  # * finally, removes the source files from the mp3 download dir
  def self.manage
    shows = {}
    Dir.glob("#{CONFIG[:settings][:mp3_dir]}/*").each do |show_dir|
      show_name = File.basename(show_dir)
      shows[show_name] = {}
      Dir.glob("#{show_dir}/*.{mp3,aac}").sort{|a,b| File.mtime(a) <=> File.mtime(b)}.each do |file_path|
        filename = File.basename(file_path)
        showtime = filename.scan(/#{show_name}--(\w{3}[\d\-:]+[AP]M)/).first
        if showtime
          showtime = showtime.first
          shows[show_name][showtime] ||= []
          shows[show_name][showtime] << file_path
        end
      end
    end
    shows.keys.each do |show_name|
      puts show_name if DEBUG
      feed_dir = File.join(CONFIG[:settings][:feed_dir], show_name)
      shows[show_name].keys.each do |showtime|
        puts " @ #{showtime}" if DEBUG
        files = shows[show_name][showtime]
        kind = files.first.to_s.split('.').last
        dest = "#{feed_dir}/#{showtime}.#{kind}"
        if File.exists?(dest)
          puts " * exists" if DEBUG
        else
          files.each do |file_path|
            puts "   - #{File.basename(file_path)} | #{File.stat(file_path).mtime.to_s(:db)} | #{File.stat(file_path).size/1.kilobyte}k" if DEBUG
          end
          
          FileUtils.mkdir_p(feed_dir)
          if kind == 'mp3' && files.count > 1
            join_mp3s(files, dest)
          else
            FileUtils.cp(files.first, dest)
          end
          # cleanup
          files.each do |file|
            FileUtils.rm(file)
          end
        end
      end
    end
  end

  # Generates podcast RSS feed of available shows
  def self.generate_feeds
    base = CONFIG[:settings][:base_url]
    feed_dir = CONFIG[:settings][:feed_dir]

    content = RSS::Maker.make('2.0') do |m|
      m.channel.title = "WKCR Podcasts"
      m.channel.description = "Various programs recorded (unofficially) from WKCR"
      m.channel.link = "www.wkcr.org"
      m.channel.language = "en"
      m.channel.about = "WKCR"
      m.items.do_sort = true # sort items by date
      m.channel.updated = Time.now.to_s
      m.channel.author = 'WKCR'
      m.image.title = 'WKCR'
      m.image.url = "http://daniel-levin.com/assets/images/records/wkcr.gif"

      # if @image != nil
      #   m.image.url = @image
      #   m.image.title = @title
      # end

      Dir.glob("#{feed_dir}/*").each do |show_dir|
        show_name = File.basename(show_dir)
        Dir.glob("#{show_dir}/*.{mp3,aac}").sort{|a,b| File.mtime(a) <=> File.mtime(b)}.each do |file_path|
          filename = File.basename(file_path)
          kind = filename.split('.').last
          showtime = filename.scan(/\w{3}[\d\-:]+[AP]M/).first

          wday, date, time = showtime.scan(/(^\w{3})-([\d-]+)-([\d:]+[AP]M)$/).first

          t = Chronic.parse("#{date} #{time}")
          next if !t || t < 15.days.ago

          item = m.items.new_item
          item.title = "#{show_name.titleize} - #{wday}, #{date} #{time}"
          p item.title if DEBUG
          ## add a base url 
          if base != ''
            link = base + '/' + URI::escape("#{show_name}/#{filename}")
          else 
            link = URI::escape(file_path)
          end
          item.link = link          
          item.pubDate = File.mtime(file_path)
          item.guid.content = link
          item.guid.isPermaLink = true
          item.enclosure.url = link
          item.enclosure.length = File.stat(file_path).size
          item.enclosure.type = "audio/#{kind == 'mp3' ? 'mpeg' : kind}"
        end
      end
    end

    # write the feed RSS
    File.open("#{feed_dir}/podcast.rss", 'w') do |file|
      file.write(content.to_s)
    end
  end

  # combine several MP3s that were split due to disconnects
  # use mp3wrap to join them.
  def self.join_mp3s(files, dest)
    quoted_files = files.map{|f| %Q("#{f}")}.join(' ')
    mp3wrap = CONFIG[:settings][:mp3wrap]
    command = %Q{#{mp3wrap} "#{dest}" #{quoted_files}}
    puts command if DEBUG
    system(command)
    # rename it, because mp3wrap annoyingly adds '_MP3WRAP' to the end
    FileUtils.mv(dest.gsub(/\.mp3$/,'_MP3WRAP.mp3'), dest)
  end
end
