require 'exifr'
require 'fileutils'
require 'progress_bar'

drives = ('D'..'Z').select { |l| Dir.exist?("#{l}:/DCIM") }
abort 'No drive with DCIM found!' if drives.empty?

puts 'Select a drive:'
drives.each_with_index { |l, i| puts "#{i + 1}) #{l}:" }
print '> '
choice = gets.to_i
drive = drives[choice - 1] if choice.positive?
abort 'Invalid drive selection' unless drive

dcim_path = "#{drive}:/DCIM"
folders = Dir.entries(dcim_path).reject { |e| %w[. ..].include?(e) || !File.directory?(File.join(dcim_path, e)) }

if folders.empty?
  path = dcim_path
elsif folders.size == 1
  path = File.join(dcim_path, folders.first)
else
  puts 'Select a folder:'
  folders.each_with_index { |f, i| puts "#{i + 1}) #{f}" }
  print '> '
  choice = gets.to_i
  folder = folders[choice - 1] if choice.positive?
  abort 'Invalid folder selection' unless folder
  path = File.join(dcim_path, folder)
end

tmp_dir = File.join(File.dirname(__FILE__), 'tmp')
FileUtils.mkdir_p(tmp_dir)
config_file = File.join(tmp_dir, 'last_destination.txt')
default_destination = File.read(config_file).strip if File.exist?(config_file)

puts "Enter destination folder #{default_destination ? "[default: #{default_destination}]" : ''}:"
print '> '
input = gets.chomp
destination = input.empty? ? default_destination : input
abort 'No destination selected' if destination.nil? || destination.empty?
File.write(config_file, destination)

def get_image_date_time(file_path)
  exif = EXIFR::TIFF.new(file_path)
  exif.date_time
rescue
  exif = EXIFR::JPEG.new(file_path)
  exif.date_time
end

count = 0
errors = []
added_folders = []

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
      added_folders << destination_folder unless added_folders.include?(destination_folder)
    end
  rescue StandardError => ex
    errors << { path: file_path, exception: ex }
  end
end

puts "#{count} images"

unless added_folders.empty?
  puts 'Photos added to:'
  added_folders.each { |folder| puts " - #{folder}" }
end

unless errors.empty?
  puts "#{errors.length} errors!"
  errors.each { |error| puts "#{error[:path]}: #{error[:exception]}" }
end
