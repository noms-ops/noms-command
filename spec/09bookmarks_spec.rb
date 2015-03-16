#!/usr/bin/env rspec

require 'noms/command'

describe NOMS::Command do

    before(:all) do
        # An application which echoes all arguments, not just argument arguments
        @url = %q(data:application/json,{"$doctype":"noms-v2","$script":["document.body = document.argv.join(' ')"],"$body":[]})
    end

    describe '.run' do

        context 'with noms-v2 documents' do

            it "should set argv[0]" do
                expect {
                    NOMS::Command.run [@url, 'one', 'two', 'three']
                }.to output("#{@url} one two three\n").to_stdout
            end

        end

    end

end


