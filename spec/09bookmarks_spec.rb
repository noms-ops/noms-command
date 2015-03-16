#!/usr/bin/env rspec

require 'fileutils'

require 'noms/command'

describe NOMS::Command do

    before(:all) do
        # An application which echoes all arguments, not just argument arguments
        @url = %q(data:application/json,{"$doctype":"noms-v2","$script":["document.body = document.argv.join(' ')"],"$body":[]})
        FileUtils.mkdir_p 'test/etc/noms' unless File.directory? 'test/etc/noms'
        File.open('test/etc/noms/bookmarks.json', 'w') { |fh| fh.puts({'echo1' => @url}.to_json) }
    end

    describe '.run' do

        context 'with noms-v2 documents' do

            it "should set argv[0]" do
                expect {
                    NOMS::Command.run [@url, 'one', 'two', 'three']
                }.to output("#{@url} one two three\n").to_stdout
            end

            it "should parse initial options" do
                expect {
                    NOMS::Command.run ['--bookmarks=/dev/null', @url, 'one', 'two', 'three']
                }.to output("#{@url} one two three\n").to_stdout
            end

        end

    end

end


