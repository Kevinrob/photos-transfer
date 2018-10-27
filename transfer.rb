require 'exifr'
require 'fileutils'
require 'progress_bar'

# Bash:
# sudo mount -t drvfs H: /mnt/h
# sudo mount -t drvfs '\\192.168.1.100\Multimedia\Photos' /mnt/Photos

# path = 'H:\DCIM\102D7000'
path = '/mnt/h/DCIM/102D7000'
# destination = '\\\\192.168.1.100\Multimedia\Photos\\'
destination = '/mnt/Photos/'

def get_image_date_time(file_path)
  exif = EXIFR::TIFF.new(file_path)
  exif.date_time
end

count = 0
errors = []

items = Dir.entries(path)
bar = ProgressBar.new(items.count)

items.each do |item|
  bar.increment!

  next if %w[. ..].include?(item)

  count += 1
  file_path = File.join(path, item)

  begin
    date = get_image_date_time(file_path)

    dir = date.strftime('%Y-%m-%d')
    destination_folder = File.join(destination, dir)

    if File.exist?(File.join(destination_folder, item))
      # print ' Already exist!'
    else
      FileUtils.mkdir_p(destination_folder)
      FileUtils.cp(file_path, File.join(destination_folder, item))
    end
  rescue StandardError => ex
    errors << { path: file_path, exception: ex }
  end
end

puts "#{count} images"

unless errors.empty?
  puts "#{errors.length} errors!"
  errors.each { |error| puts "#{error[:path]}: #{error[:exception]}" }
end
