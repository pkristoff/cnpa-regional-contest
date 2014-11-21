class DirectoryInfo
  attr_accessor :testdata_dir, :numberOnly_dir, :nameAndNumber_dir, :name_dir, :orig_image_dir_txt, :extensions, :exiftool_info_file, :file_info

  def initialize(source_dir)

    @extensions = ['.jpeg', '.jpg', '.JPG', '.JPEG']

    @testdata_dir = "#{source_dir}/testdata/"
    @numberOnly_dir = "#{source_dir}/numberOnly/"
    @nameAndNumber_dir = "#{source_dir}/nameAndNumber/"
    @name_dir = "#{source_dir}/nameOnly/"
    @orig_image_dir_txt = "#{source_dir}/Originals/"
    @exiftool_info_file = "exifInfo.txt"
    @file_info = "#{source_dir}/fileInfo.txt"

    clean_up_previous_run

  end

  def clean_up_previous_run


    unless File.exist?(@testdata_dir)
      Dir.mkdir(@testdata_dir)
    end
    unless File.exist?(@numberOnly_dir)
      Dir.mkdir(@numberOnly_dir)
    end
    unless File.exist?(@nameAndNumber_dir)
      Dir.mkdir(@nameAndNumber_dir)
    end
    unless File.exist?(@name_dir)
      Dir.mkdir(@name_dir)
    end

    clean_up_directory @testdata_dir
    clean_up_directory @nameAndNumber_dir
    clean_up_directory @numberOnly_dir
    clean_up_directory @name_dir

    copy_files_from_orig

  end

  def copy_files_from_orig
    Dir.chdir(orig_image_dir_txt) do |path|
      image_dir = Dir.new(".")
      image_dir.each do |filename|
        #      puts "cp #{File.extname(filename)}"
        if @extensions.include?(File.extname(filename))
          #      puts "cp2 #{filename}"
          FileUtils.copy_file("#{filename}", "#{testdata_dir}/#{File.basename(filename)}", true)
        end
      end
    end
  end

  def clean_up_directory directory
    Dir.chdir(directory) do |path|
      image_dir = Dir.new(".")
      image_dir.each do |filename|
        #      puts "rm #{path}"
        if File.file?(filename)
          #      puts "rm2 #{filename}"
          File.delete(filename)
        end
      end
    end
  end


end