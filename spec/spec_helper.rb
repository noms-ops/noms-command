#!ruby

require 'fileutils'

def server_running?(pidfile="test/dnc.pid")
    begin
        Process.kill 0, File.read(pidfile).to_i
        true
    rescue Errno::ESRCH, Errno::ENOENT
        false
    end
end

def setup_fixture(dir='test')
    system "cp -R fixture #{dir}" unless File.directory? dir
end

def start_server(dir='test')
    unless server_running? "#{dir}/dnc.pid"
        system "sh -c '#{RbConfig.ruby} #{dir}/dnc.rb >#{dir}/dnc.out 2>&1 &'"
        sleep 2
    end
end

def stop_server(dir='test')
    if server_running? "#{dir}/dnc.pid"
        begin
            Process.kill 'TERM', File.read("#{dir}/dnc.pid").to_i
            sleep 2
        rescue Errno::ESRCH
        end
        FileUtils.rm "#{dir}/dnc.pid"
    end
end

def teardown_fixture(dir='test')
    if File.directory? dir
        FileUtils.rm_r dir
    end
end
