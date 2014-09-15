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

  def move from_dir, dest_numberOnly, dest_nameAndNumber, dest_nameOnly
#    puts "moving"
    @file_info.each do |imageFile|
      imageFile.move(from_dir, dest_numberOnly, dest_nameAndNumber, dest_nameOnly)
    end
#    puts "moving-done"
  end
end
