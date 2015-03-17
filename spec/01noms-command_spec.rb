#!/usr/bin/env rspec

require 'spec_helper'

require 'noms/command'

describe NOMS::Command do

    before(:all) do
        setup_fixture 'test'
        File.open('test/foo.txt', 'w') do |fh|
            fh << <<-TEXT.gsub(/^\s+/,'')
                1: Test output
                2: from foo.txt
            TEXT
        end
    end

    after(:all)  { teardown_fixture 'test' }

    describe '.run' do
        context 'with one file argument' do
            it 'shows the file contents' do
                file = 'file://' + File.join(Dir.pwd, 'test', 'foo.txt')
                expect { NOMS::Command.run([file]) }.to output(/from foo.txt/).to_stdout
            end
        end
    end

end
