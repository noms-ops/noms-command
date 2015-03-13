require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new

task :test => [:spec, :testcmd]

task :testcmd do
    ENV['RUBYLIB'] = ['lib', ENV['RUBYLIB']].join(':')
    ENV['PATH'] = ['bin', ENV['PATH']].join(':')
    Dir.new('spec').each do |script|
        next unless script =~ /\.sh$/
        puts script
        system(File.join('spec', script))
    end
end

# Start the DNC application web server on port 8787
task :start do
    FileUtils.rm_r 'test' if File.directory? 'test'
    system 'cp -R fixture test'
    system("sh -c '#{RbConfig.ruby} test/dnc.rb >test/dnc.out 2>&1 &'")
end

task :stop do
    Process.kill 'TERM', File.read('test/dnc.pid').to_i
    FileUtils.rm 'test/dnc.pid'
end

task :clean do
    rm_rf ['pkg', 'test']
end

