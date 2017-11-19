require 'exifr'
require 'fileutils'

path = 'G:\DCIM\101D7000'
destination = '\\\\192.168.1.100\Multimedia\Photos\\'

count = 0
errors = []
Dir.foreach(path) do |item|
  next if item == '.' || item == '..'
  # do work on real items

  count += 1
  file_path = path + "\\" + item
  print file_path + '... '

  begin
    exif = EXIFR::TIFF.new(file_path)
    date = exif.date_time

    dir = date.strftime('%Y-%m-%d')
    destination_folder = destination + dir + '\\'

    print '-> ' + destination_folder + item

    if File.exist?(destination_folder + item)
      print ' Already exist!'
    else
      FileUtils.mkdir_p(destination_folder)
      FileUtils.cp(file_path, destination_folder + item)
    end
  rescue Exception
    print 'Error with ' + file_path
    errors << file_path
  end

  print "\n"
end

print "#{count} images"

unless errors.empty?
  puts "#{errors.length} errors!"
  errors.each { |error| puts error }
end
