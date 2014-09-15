# To change this template, choose Tools | Templates
# and open the template in the editor.

class ImageFile
  attr_accessor :filenum, :personName, :title, :origFileName, :meta_data, :time, :is_valid #, :meta_title, :meta_caption, :meta_imagesize, :meta_copyright
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
  def move from_dir, dest_numberOnly, dest_nameAndNumber, dest_nameOnly
    xxx = "cp \"#{from_dir}#{@tempFilename}\" \"#{dest_nameAndNumber}#{'%03d' % filenum} - #{@personName} - #{@title}.jpg\""
    #    puts xxx
    system xxx
    xxx = "cp \"#{from_dir}#{@tempFilename}\" \"#{dest_nameOnly}#{@personName} - #{@title}.jpg\""
    #    puts xxx
    system xxx
    xxx = "mv \"#{from_dir}#{@tempFilename}\" \"#{dest_numberOnly}#{'%03d' % filenum}.jpg\""
    #    puts xxx
    system xxx
  end
  def person_name
    @personName
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
