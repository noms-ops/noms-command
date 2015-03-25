#!ruby

require 'noms/command/version'
require 'noms/command/home'

require 'pstore'
require 'fileutils'

require 'noms/command'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::UserAgent < NOMS::Command::Base

end

class NOMS::Command::UserAgent::Cache

    @@format_version = '0'
    @@max_cache_size = 10 * 1024 * 1024
    @@trim_cache_size = 8 * 1024 * 1024
    @@location = File.join(NOMS::Command.home, 'cache', @@format_version)

    def self.clear!
        FileUtils.rm_r @@location if File.directory? @@location
        ensure_dir @@location
        meta = PStore.new(File.join(@@location, 'metadata.db'))
        meta.transaction do
            meta[:cache_size] = 0
            meta[:file_count] = 0
        end
    end

    def ensure_dir(dir)
        FileUtils.mkdir_p dir unless File.directory? dir
    end

    def initialize
        ensure_dir @@location
        @meta = PStore.new File.join(@@location, 'metadata.db')
        @meta.transaction do
            @meta[:cache_size] ||= 0
            @meta[:file_count] ||= 0

            if @meta[:cache_size] > @@max_cache_size
                trim!
            end
        end
    end

    def clear!
        FileUtils.rm_r @@location if File.directory? @@location
        ensure_dir @@location
        @meta.transaction do
            @meta[:cache_size] = 0
            @meta[:file_count] = 0
        end
    end

    def cache_dir(key=nil)
        if key
            File.join(@@location, 'data', key[0 .. 1])
        else
            File.join(@@location, 'data')
        end
    end

    def set(key, item_data)
        size = 0
        ensure_dir cache_dir(key)
        File.open(File.join(cache_dir(key), key), 'w') do |fh|
            fh.write item_data
            size = fh.stat.size
        end
        @meta.transaction do
            @meta[:cache_size] += size
            @meta[:file_count] += 1
        end
    end

    def freshen(key)
        cache_file = File.join(cache_dir(key), key)
        File.utime(Time.now, Time.now, cache_file)
    end

    def get(key)
        cache_file = File.join(cache_dir(key), key)
        obj = nil
        if File.exist? cache_file
            obj = File.open(cache_file, 'r') do |fh|
                fh.read
                # Marshal.load(fh)
            end
        end
        obj
    end

    def trim!
        # Trim cache, all within PStore transaction
        cache_size = 0
        files = Dir["#{@@location}/*/*"].map do |file|
            stat = File.stat(file)
            size = stat.size
            mtime = stat.mtime
            total += size
            [file, size, mtime]
        end.sort { |a, b| a[2] <=> b[2] }
        file_count = files.length
        while cache_size > @@trim_cache_size
            file, size, = files.shift
            File.unlink(file)
            cache_size -= size
        end
        @meta[:cache_size] = cache_size
        @meta[:file_count] = file_count
    end

end
