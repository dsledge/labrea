require 'rubygems'
require 'bundler/setup'

require 'digest/sha1'
require 'json'

module LabreaModule
  class Labrea
    # Class initialization
    def initialize(filename, install_dir, opts)
      @filename		= filename
      @install_dir	= install_dir
      @exclude 		= exclude
      @working_dir	= Dir.pwd()
      @changeset	= Array.new
      defaults = {
	:exclude => [],
	:checksum_file => "checksum.json"
      }
      opts = defaults.merge(opts)
      @exclude = opts[:exclude]
      @checksum_file = opts[:checksum_file]
    end

    attr_accessor :exclude
    attr_accessor :checksum_file

    # Installation of binary archive
    def install(testmode=false)
      @changeset.clear
      extract_files(testmode)

      #Generate checksums and add to hash
      checksums = Hash.new
      if File.exists?(@install_dir)
        Dir.chdir(@install_dir) do |path|
          @changeset.each do |file|
            checksums[file] = sha1sum(file) unless @exclude.include? file
          end
        end
      end

      # Write out checksum file
      File.open(checksum_fqn, "w+") do |file|
        file.puts JSON.generate(checksums)
      end unless testmode

      return @changeset
    end

    # Update of binary archive
    def update(testmode=false)
    end

    # Verification of binary archive
    def verify(testmode=false)
      @changeset.clear

      # Read checksums from file
      checksums = Hash.new
      File.open(checksum_fqn, "r") do |file|
	checksums = JSON.load(file)
      end

      checksums.each_pair do |k,v|
	if !@exclude.include? k
	  Dir.chdir(@install_dir) do |path|
	    if sha1sum(k) != v
	      extract_file(k, testmode)
	    end
	  end
	end
      end

      return @changeset
    end

    def filetype(filename)
      if filename.match('.*\.tgz')
	return :tgz
      end

      if filename.match('.*\.tar\.gz')
	return :tgz
      end

      if filename.match('.*\.zip')
	return :zip
      end

      if filename.match('.*\.bz2')
	return :bz2
      end

      return :unknown
    end

    def extract_files(testmode)
      if !File.exist?(@install_dir)
	Dir.mkdir(@install_dir)
      end
      Dir.chdir(@working_dir) do |path|
	@changeset << @install_dir

	case filetype(@filename)
	when :tgz
	  output = `tar -xvzf #{@filename} -C #{@install_dir} 2>/dev/null` unless testmode
	when :zip
	  `unzip #{@filename} -d #{@install_dir}` unless testmode
	  output = `zipinfo -1 #{@filename}`
	when :bz2
	  output = `tar -xvjf #{@filename} -C #{@install_dir} 2>/dev/null` unless testmode
	end
	@changeset |= output.split("\n") if output
      end
    end

    def extract_file(file, testmode)
      if !File.exist?(@install_dir)
	Dir.mkdir(@install_dir)
      end
      Dir.chdir(@working_dir) do |path|
	@changeset << file.to_s

	case filetype(@filename)
	when :tgz
	  `tar -xzf #{@filename} -C #{@install_dir} #{file}` unless testmode
	when :zip
	  `unzip -q #{@filename} -d #{@install_dir} #{file}` unless testmode
	when :bz2
	  `tar -xjf #{@filename} -C #{@install_dir} #{file}` unless testmode
	end
      end
    end

    def sha1sum(file)
	if File.file?(file)
	  return Digest::SHA1.hexdigest File.read(file)
	end

	return false
    end

    def checksum_fqn
      if @checksum_file =~ /^#{File::SEPARATOR}/
	@checksum_file
      else
	File.join(@install_dir,@checksum_file)
      end
    end
  end
end
