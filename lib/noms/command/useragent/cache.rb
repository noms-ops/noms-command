#!ruby

require 'noms/command/version'

require 'pstore'

require 'noms/command/base'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::UserAgent < NOMS::Command::Base

end

class NOMS::Command::UserAgent::Cache

    @@max_cache_size = 10 * 1024 * 1024

    def ensure_dir(dir)
        FileUtils.mkdir_p dir unless File.directory? dir
    end

    def initialize
        @location = File.join(ENV['HOME'], '.noms', 'cache', '0')
        ensure_dir @location
        @meta = PStore.new File.join(@location, 'metadata.db')
        @meta.transaction do
            @meta[:cache_size] ||= 0
            @meta[:file_count] ||= 0

            if @meta[:cache_size] > 10 * 1024 * 1024
                clean!
            end
        end
    end

    def cache_dir(key=nil)
        if key
            File.join(@location, 'data', key[0 .. 1])
        else
            File.join(@location, 'data')
        end
    end

    def set(request, response)
        $stderr.puts "STORING #{request.cache_key}"
        size = 0
        key = request.cache_key
        ensure_dir cache_dir(key)
        File.open(File.join(cache_dir(key), key), 'w') do |fh|
            Marshal.dump(response, fh)
            size = fh.stat.size
        end
        @meta.transaction do
            @meta[:cache_size] += size
            @meta[:file_count] += 1
        end
    end

    def get(request)
        $stderr.puts "FINDING #{request.cache_key}"
        key = request.cache_key
        cache_file = File.join(cache_dir(key), key)
        obj = nil
        if File.exist? cache_file
            $stderr.puts "CACHE HIT ON #{request.cache_key}: #{request.url}"
            obj = File.open(cache_file, 'r') { |fh| Marshal.load(fh) }
            $stderr.puts "LOADED #{obj.class}"
        end
        obj
    end

    def clean!

    end

end
