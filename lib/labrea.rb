require 'digest/sha1'
require 'json'

class Labrea
  # Class initialization
  def initialize(filename, install_dir, config)
    @filename		= filename
    @install_dir	= install_dir
    @config	 	= config
    @working_dir	= Dir.pwd()
  end
  
  # Installation of binary archive
  def install
    extract_files()
    
    # Generate checksums and add to hash
    checksums = Hash.new
    if File.exists?(@install_dir)
      Dir.chdir(@install_dir) do |path|
	Dir.glob("**/*.*") do |file|
	  if File.file?(file)
	    if !@config.include? file
	      checksums[file] = sha1sum(file)
	      puts checksums
	    end
	  end
	end
      end
    end

    # Write out checksum file
    File.open("#{@install_dir}/checksum.txt", "w+") do |file|
      file.puts JSON.generate(checksums)
    end
  end
  
  # Update of binary archive
  def update
  end
  
  # Verification of binary archive
  def verify
    err_count = 0
    # Read checksums from file
    checksums = Hash.new
    File.open("#{@install_dir}/checksum.txt", "r+") do |file|
      checksums = JSON.load(file)
    end
    
    checksums.each_pair do |k,v|
      Dir.chdir(@install_dir) do |path|
	if sha1sum(k) != v
	  puts "#{k} verification: false, extracting file from archive"
	  err_count += 1
	  extract_file(k)
	else
	  puts "#{k} verification: true, nothing to do"
	end
      end
    end
    
    return err_count
  end
  
  def filetype(filename)
    filename.match('.*\.tgz') do |m|
      return :tgz
    end
    
    filename.match('.*\.tar\.gz') do |m|
      return :tgz
    end
    
    filename.match('.*\.zip') do |m|
      return :zip
    end
    
    filename.match('.*\.bz2') do |m|
      return :bz2
    end
    
    return :unknown
  end

  def extract_files()
    Dir.chdir(@working_dir) do |path|
      case filetype(@filename)
      when :tgz
	`tar -xzvf #{@filename} -C #{@install_dir}`
      when :zip
	`unzip #{@filename} -d #{@install_dir}`
      when :bz2
	`tar -xjvf #{@filename} -C #{@install_dir}`
      end
    end
  end
  
  def extract_file(file)
    Dir.chdir(@working_dir) do |path|
      case filetype(@filename)
      when :tgz
	`tar -xzvf #{@filename} -C #{@install_dir} #{file}`
      when :zip
	`unzip #{@filename} -d #{@install_dir} #{file}`
      when :bz2
	`tar -xjvf #{@filename} -C #{@install_dir} #{file}`
      end
    end
  end
  
  def sha1sum(file)
      if File.file?(file)
	return Digest::SHA1.hexdigest File.read(file)
      end
      
      return false
  end
end