#!/usr/bin/env rspec

require 'fileutils'
require 'noms/command'

describe NOMS::Command do

    before(:all) do
        FileUtils.mkdir_p 'test'
        File.open('test/foo.txt', 'w') do |fh|
            fh << <<-TEXT.gsub(/^\s+/,'')
                1: Test output
                2: from foo.txt
            TEXT
        end
    end

    after(:all)  { FileUtils.rm_r 'test' }

    describe '.run' do
        context 'with one file argument' do
            it 'shows the file contents' do
                file = 'file://' + File.join(Dir.pwd, 'test', 'foo.txt')
                expect { NOMS::Command.run([file]) }.to output(/from foo.txt/).to_stdout
            end
        end
    end

end
