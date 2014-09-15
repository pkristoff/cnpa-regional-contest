
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
  def set_random_numbers()
    image_files_ans = Array.new()
    @people_files.each_value do | image_files |
      image_files.file_info.each { |image_file| image_files_ans.push(image_file) }
    end
    image_files_ans.shuffle().shuffle().each_with_index do |image_file, file_num |
      puts "oldNum=#{image_file.filenum} newNum=#{file_num}"
      image_file.filenum=file_num
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
    sorted_people_files = get_sorted_files
    sorted_people_files.each do |key_value |
      key_value[1].move(source, dest_numberOnly, dest_nameAndNumber, dest_nameOnly)
    end
  end
end