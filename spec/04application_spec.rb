#!/usr/bin/env rspec

require 'noms/command/application'

describe NOMS::Command::Application do

    before(:all) do
        # Start the DNC application web server on port 8787
        FileUtils.rm_r 'test' if File.directory? 'test'
        system 'cp -R fixture test'
        system("sh -c '#{RbConfig.ruby} test/dnc.rb >test/dnc.out 2>&1 &'")
        sleep 2
    end

    after(:all) do
        Process.kill 'TERM', File.read('test/dnc.pid').to_i
        FileUtils.rm 'test/dnc.pid'
    end

    describe '.new' do

        context 'with no arguments' do

            before(:each) do
                @doc = NOMS::Command::Application.new(NOMS::Command::Window.new($0),
                                                   'http://localhost:8787/dnc.json',
                                                   [])
            end

        end

    end

end

