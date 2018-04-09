require 'exifr'
require 'fileutils'

path = 'G:\DCIM\101D7000'
destination = '\\\\192.168.1.100\Multimedia\Photos\\'

def get_image_date_time(file_path)
  exif = EXIFR::TIFF.new(file_path)
  exif.date_time
end

count = 0
errors = []
Dir.foreach(path) do |item|
  next if %w[. ..].include?(item)

  count += 1
  file_path = path + '\\' + item
  print file_path + '... '

  begin
    date = get_image_date_time(file_path)

    dir = date.strftime('%Y-%m-%d')
    destination_folder = destination + dir + '\\'

    print '-> ' + destination_folder + item

    if File.exist?(destination_folder + item)
      print ' Already exist!'
    else
      FileUtils.mkdir_p(destination_folder)
      FileUtils.cp(file_path, destination_folder + item)
    end
  rescue StandardError => ex
    print 'Error with ' + file_path
    errors << { path: file_path, exception: ex }
  end

  print "\n"
end

print "#{count} images"

unless errors.empty?
  puts "#{errors.length} errors!"
  errors.each { |error| puts "#{error[:path]}: #{error[:exception]}" }
end
