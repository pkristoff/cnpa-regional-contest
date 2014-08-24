# To change this template, choose Tools | Templates
# and open the template in the editor.

class ImageFile
  attr_accessor :personName, :title, :origFileName, :meta_data, :time, :is_valid #, :meta_title, :meta_caption, :meta_imagesize, :meta_copyright
  def initialize(path, filename, filenum)
    @is_valid = true
    @filenum = filenum
    @origPath = path
    @origFileName = filename
    @time=File.mtime(filename)
    #    filename_parts = filename.split('.')[0].split('-')
    @personName, @title=ImageFile.get_person_and_title(filename)
    puts "ImageFile '#{@personName}': '#{@title}'"
    @meta_data={
      "File Size"=> "",
      "Date/Time Original"=>"",
      "Copyright Notice"=>"",
      "Image Size"=>"",
      "Title"=>"",
      "Caption-Abstract"=>""
    }
  end
  def move from_dir, dest_numberOnly, dest_nameAndNumber, dest_nameOnly, index
    xxx = "cp \"#{from_dir}#{@tempFilename}\" \"#{dest_nameAndNumber}#{'%03d' % index} - #{@personName} - #{@title}.jpg\""
    #    puts xxx
    system xxx
    xxx = "cp \"#{from_dir}#{@tempFilename}\" \"#{dest_nameOnly}#{@personName} - #{@title}.jpg\""
    #    puts xxx
    system xxx
    xxx = "mv \"#{from_dir}#{@tempFilename}\" \"#{dest_numberOnly}#{'%03d' % index}.jpg\""
    #    puts xxx
    system xxx
  end
  def person_name
    @personName
  end
  def file_num
    @filenum
  end
  def self.get_person_and_title(filename)
    #puts "   get_person_and_title #{filename}"
    filename_parts = filename.split('.')[0].split('-')
    #puts "   get_person_and_title #{filename_parts}"
    title_from_file = filename_parts[1..filename_parts.size-1].join(" ")
    title_from_file = title_from_file.gsub("_", " ").gsub("-", " ")
    return filename_parts[0].gsub("_", " ").gsub("-", " ").strip, title_from_file.strip
  end
  def add_meta_data(key, value)
    #puts "add_meta_data(key): #{key} value: #{value}"
    @meta_data[key] = value
  end
  def update(config)
    @tempFilename = @origFileName.gsub(" ", "_").gsub("(", "").gsub(")", "")
    xxx = "mv \"#{@origFileName}\" \"#{@tempFilename}\""
#    puts "Updating #{@tempFilename}"
    #    puts xxx
    system xxx
    if @meta_data["Title"].nil? or @meta_data["Title"].empty?
      ttl = @title
#      puts "  title #{ttl}"
      xxx = "exiftool -xmp:title=\"#{ttl}\" #{@tempFilename}"
#      puts "   title: '#{xxx}'"
      system xxx
    else
#      puts "  title - no update"
    end
    if @meta_data["Caption-Abstract"].nil? or @meta_data["Caption-Abstract"].empty?
      caption = @title
#      puts "  caption #{caption}"
      xxx = "exiftool -iptc:caption-abstract=\"#{caption}\" #{@tempFilename}"
#      puts "   title: '#{xxx}'"
      system xxx
    else
#      puts "  caption - no update"
    end
    if @meta_data["Copyright Notice"].nil? or @meta_data["Copyright Notice"].empty?
      date = @meta_data["Date/Time Original"]
      year = (date.nil? or date.empty?) ? "2014" : date.split(":")[0]
      copyright = "©#{year} #{@personName}"
#      puts "  copyright: #{copyright}"
      xxx = "exiftool -iptc:CopyrightNotice=\"#{copyright}\" #{@tempFilename}"
#     puts "   copyright: '#{xxx}'"
      system xxx
    else
#      puts "  copyright: no update"
    end
  end
  def dump(index,config)
    ans = []
    ans << "    Title(#{index+1}): #{@title}"
    ans << "      Meta Data:"
    @meta_data.each_pair do |key, value|
      ans << "        #{key}: #{(value and !value.empty?) ? value : '<EMPTY>'}: #{valid_message key, value, config}"
      #puts ans
    end
    ans << "\n\r"
    ans
  end

  def valid_message(key, value, config)
    #  puts "KEY=#{key}"
    #  puts "VALUE=|#{value}|"
    if key == "File Size"
      if !value
        @is_valid = false
        "<ERROR> File Size is missing"
      else
        split_value = value.strip.split(" ")
        #  puts "split_value=|#{split_value.size}|"
        num = split_value[0].to_f
        #  puts "num=|#{num}|"
        multiplier = split_value[1] == nil ? 0 : (split_value[1].strip == "MB" ? 1000000 : 1024)
        file_size = num*multiplier
        if file_size > (config["max_file_size_in_kb"]*1024)
          @is_valid = false
          "<ERROR> file size (#{file_size}) is greater than #{config["max_file_size_in_kb"]} KB"
        else
          "VALID"
        end
      end
    elsif key.strip == "Title"
      if value.nil? or value.strip == '<EMPTY>' or value.strip == ''
        "<ERROR> Title is missing"
      else
        "VALID"
      end
    elsif key.strip == "Date/Time Original"
      if value.nil? or value.strip == '<EMPTY>' or value.strip == ''
        @is_valid = false
        "<ERROR> Date/Time Original is missing"
      else
        # puts(value)
        days_from_oldest_date = (DateTime.strptime(value, "%Y:%m:%d %H:%M:%S")-config['oldest_Picture_Date']).to_i()
       (days_from_oldest_date >= 0) ? "VALID" : "INVALID - OLDER THAN #{config['oldest_Picture_Date']} by #{-days_from_oldest_date} days"
      end
    elsif key.strip == "Copyright Notice"
      if value.nil? or value.strip == '<EMPTY>' or value.strip == ''
        @is_valid = false
        "<ERROR> Copyright Notice is missing"
      else
        "VALID"
      end
    elsif key.strip == "Caption-Abstract"
      if value.nil? or value.strip == '<EMPTY>' or value.strip == ''
        @is_valid = false
        "<ERROR> Caption is missing"
      else
        "VALID"
      end
    elsif key.strip == "Image Size"
      if value.nil? or value.strip == '<EMPTY>' or value.strip == ''
        @is_valid = false
        "<ERROR> Image Size is missing"
      else
        size = value.strip.split("x")
        x=size[0].to_i
        y=size[1].to_i
        if x!=config["longest_side_size"] and y!=config["longest_side_size"]
          @is_valid = false
          "<INVALID> Largest side != #{config["longest_side_size"]}"
        else
          "VALID"
        end
      end
    else
      @is_valid = false
      "<UNKNOWWN KEY>"
    end
  end

end

# a person has multiple files
class ImageFiles

  attr_accessor :file_info

  def initialize ()
    @file_info = []
  end
  def add_meta_data(title, key, value)
    #puts "  add_meta_data(arg): '#{title}'"
    #@file_info.each { |imageFile| puts "    ImageFiles.add_meta_data.Title: '#{imageFile.title}'" }
    @file_info.detect { |imageFile| imageFile.title==title }.add_meta_data(key, value)
  end
  def add_file_info(imageFile)
    @file_info.push(imageFile)
  end

  def dump(config)
    ans = []
    ans << "#{@file_info[0].person_name}(#{@file_info[0].time})"
    @file_info.each_index do |i|
      ans << @file_info[i].dump(i,config)
    end
    File.open(config["directory_info"].file_info,mode="a") do |file|
      file.write(ans)
    end
    puts ans
  end

  def update(config)
#    puts "update"
    @file_info.each do |imageFile|
      imageFile.update(config)
    end
#    puts "update-done"
  end

  def move from_dir, dest_numberOnly, dest_nameAndNumber, dest_nameOnly, index
#    puts "moving"
    @file_info.each do |imageFile|
      imageFile.move(from_dir, dest_numberOnly, dest_nameAndNumber, dest_nameOnly, index)
      index += 1
    end
#    puts "moving-done"
    index
  end
end

class PeopleFiles
  attr_accessor :people_files, :extensions
  def initialize (path, extensions)
    @extensions = extensions
    @people_files = {}

    image_dir = Dir.new(".")
    i=1
    image_dir.each do |filename|

      #    puts "filename: #{filename}"

      if jpeg?(filename)
        file_info = ImageFile.new(path, filename, i)
        #puts "#{i}: #{filename}"
        if ! @people_files[file_info.person_name]
          @people_files[file_info.person_name]=ImageFiles.new()
        end
        @people_files[file_info.person_name].add_file_info(file_info)
      end
      i +=1
    end
  end
  def jpeg? filename
#    puts "jpeg?: #{@extensions}"
#    puts "jpeg?: '#{filename}'"
#    puts "jpeg?: '#{File.extname(filename)}'"
#    puts "jpeg?: #{@extensions.include?(File.extname(filename))}"
    @extensions.include?(File.extname(filename))
  end
  def add_people (lines)

    info_filename = nil
    person_name = nil
    title = nil
    person = nil

    lines.each do |line|
 #     puts "  Line: #{line}"
      if line.include?('=====')
        info_filename = line["======== ./".size,line.size].strip
 #       puts "filename=#{info_filename}"
        person_name,title = ImageFile.get_person_and_title(File.basename(info_filename))
 #       puts "person_name: #{person_name}"
 #       puts "title: #{title}"
        person = @people_files[person_name]
        #puts "person: #{person}"
      else
        if jpeg?(info_filename)
          line_split = line.split(':')
#          puts "    split: #{line_split}"
          if line_split.size >= 2
            key = line_split[0].strip
            value = line[line_split[0].size+1..line.size].strip
#            puts "    key:'#{key}' value:'#{value}'"
            #value = line_split[1].strip
            #puts "person_name1: #{person_name} - person: #{person}"
            person.add_meta_data(title, key, value)
          elsif (key = line_split[0].strip) == "Date/Time Original"
            value = (line_split[1..line_split.size]*":").strip
#            puts "    key:'#{key}' value:'#{value}'"
            #          person_name,title=ImageFile.get_person_and_title(File.basename(info_filename))
            #puts "person_name2: #{person_name} - person: #{person}"
            person.add_meta_data(title, key, value)
          else
            puts "gobbled #{line}"
          end
        end
      end
    end
  end
  def dump(config)
    sorted_people_files = get_sorted_files
    sorted_people_files.each do |key_value |
      puts key_value[1].dump(config)
    end
  end
  def update(config)
    sorted_people_files = get_sorted_files
    sorted_people_files.each do |key_value |
      key_value[1].update(config)
    end
  end
  def get_sorted_files
    @people_files.sort_by{|k, v| v.file_info[0].time}
  end
  def move source, dest_numberOnly, dest_nameAndNumber, dest_nameOnly
    i = 1
    sorted_people_files = get_sorted_files
    sorted_people_files.each do |key_value |
      i = key_value[1].move(source, dest_numberOnly, dest_nameAndNumber, dest_nameOnly, i)
    end
  end
end