$LOAD_PATH.unshift File.dirname($0)
require File.expand_path(File.dirname(__FILE__) + '/people_files')
require File.expand_path(File.dirname(__FILE__) + '/image_files')
require File.expand_path(File.dirname(__FILE__) + '/image_file')
require File.expand_path(File.dirname(__FILE__) + '/directory_info')
require 'fileutils'
require 'date'

puts ARGV
puts "that was argV"
ARGV.each do|a|
  puts "xxx"
  puts "Argument: #{a}"
end

configFile = ARGV[0]


source_dir = nil
age_in_months = 24
longest_side_size=1024

config = {}

Dir.chdir('.') do |path|

  puts "current path #{path}"

  end

  lines = IO.readlines(configFile)
  lines.each do |line|
    split = line.chomp().split("=")
    case
      when split[0] == "sourceDir"
        config["directory_info"] = DirectoryInfo.new(split[1])
      when split[0] == "longestSideSize"
        config["longest_side_size"] = split[1].to_i
      when split[0] == "closingDate"
        config["closing_date"] = DateTime.strptime(split[1], "%Y:%m:%d %H:%M:%S")
      when split[0] == "oldestPictureDate"
        config["oldest_Picture_Date"] = DateTime.strptime(split[1], "%Y:%m:%d %H:%M:%S")
        when split[0] == "maxFileSizeInKb"
          config["max_file_size_in_kb"] = split[1].to_i
      else
        raise MyException.new
    end
  end

directory_info = config["directory_info"]

Dir.chdir(directory_info.testdata_dir) do |path|

  puts "current path #{path}"

  people_files = PeopleFiles.new(path, directory_info.extensions)

  xxx = "exiftool -imagesize -iptc:CopyrightNotice -iptc:caption-abstract -xmp:title -DateTimeOriginal -FileSize ./* > #{directory_info.exiftool_info_file}"
  #  xxx = "exiftool  ./* > #{directory_info.exiftool_info_file}"
  system xxx

  lines = IO.readlines(directory_info.exiftool_info_file)
  people_files.add_people(lines)

  people_files.set_random_numbers()
  puts "================ randomize people done =================="
  people_files.dump(config)
  puts "================ init done =================="
  people_files.update(config)
  puts "================ update done =================="
  #system 'mkdir /tmp/cnpa'

  people_files.move(directory_info.testdata_dir, directory_info.numberOnly_dir, directory_info.nameAndNumber_dir, directory_info.name_dir)
  puts "================ Move done =================="
end

