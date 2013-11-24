require 'rss/0.9'
require 'rss/maker'

DEBUG=ENV['DEBUG']

class Podcaster
  def self.manage
    shows = {}
    Dir.glob("#{CONFIG[:settings][:mp3_dir]}/*").each do |show_dir|
      show_name = File.basename(show_dir)
      shows[show_name] = {}
      Dir.glob("#{show_dir}/*.mp3").sort{|a,b| File.mtime(a) <=> File.mtime(b)}.each do |file|
        mp3 = File.basename(file)
        showtime = mp3.scan(/#{show_name}--(\w{3}[\d\-:]+[AP]M)/).first
        if showtime
          showtime = showtime.first
          shows[show_name][showtime] ||= []
          shows[show_name][showtime] << file
        end
      end
    end
    shows.keys.each do |show_name|
      puts show_name if DEBUG
      feed_dir = File.join(CONFIG[:settings][:feed_dir], show_name)
      shows[show_name].keys.each do |showtime|
        puts " @ #{showtime}" if DEBUG
        dest = "#{feed_dir}/#{showtime}.mp3"
        if File.exists?(dest)
          puts " * exists" if DEBUG
        else
          shows[show_name][showtime].each do |mp3|
            puts "   - #{File.basename(mp3)} | #{File.stat(mp3).mtime.to_s(:db)} | #{File.stat(mp3).size/1.kilobyte}k" if DEBUG
          end
          
          FileUtils.mkdir_p(feed_dir)
          files = shows[show_name][showtime]
          if files.count > 1
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

  def self.generate_feeds
    base = CONFIG[:settings][:base_url]
    feed_dir = CONFIG[:settings][:feed_dir]

    content = RSS::Maker.make('2.0') do |m|
      m.channel.title = "title"
      m.channel.description = "description"
      m.channel.link = "link"
      m.channel.language = "en"
      m.channel.about = "WKCR"
      m.items.do_sort = true # sort items by date
      m.channel.updated = Time.now.to_s
      m.channel.author = 'WKCR'

      # if @image != nil
      #   m.image.url = @image
      #   m.image.title = @title
      # end

      Dir.glob("#{feed_dir}/*").each do |show_dir|
        show_name = File.basename(show_dir)
        Dir.glob("#{show_dir}/*.mp3").sort{|a,b| File.mtime(a) <=> File.mtime(b)}.each do |file|
          mp3 = File.basename(file)
          showtime = mp3.scan(/\w{3}[\d\-:]+[AP]M/).first
          wday, date, time = showtime.scan(/(^\w{3})-([\d-]+)-([\d:]+[AP]M)$/).first

          item = m.items.new_item
          item.title = "#{show_name.titleize} - #{wday}, #{date} #{time}"
          ## add a base url 
          if base != ''
            link = base + '/' + URI::escape("#{show_name}/#{mp3}")
          else 
            link = URI::escape(file)
          end
          item.link = link          
          item.pubDate = Time.parse("#{date} #{time}")
          item.guid.content = link
          item.guid.isPermaLink = true
          item.enclosure.url = link
          item.enclosure.length = File.stat(file).size
          item.enclosure.type = "audio/mpeg"
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
